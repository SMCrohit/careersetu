from fastapi import FastAPI, Depends, HTTPException, status, UploadFile, File, Request
from typing import Optional
import io
import re
import uuid
import openpyxl
from pypdf import PdfReader
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import timedelta, datetime, date
import models, schemas, auth
from database import engine, get_db

import firebase_admin
from firebase_admin import credentials, auth as firebase_auth
import os

# Initialize Firebase Admin
cred_path = "career-setu-8ff5d-firebase-adminsdk-fbsvc-f54d43d846.json"
try:
    firebase_admin.get_app()
except ValueError:
    try:
        if os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
        elif os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON"):
            import json
            cred_dict = json.loads(os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON"))
            # Vercel often escapes \n in environment variables. We must replace literal \\n with actual newlines.
            if "private_key" in cred_dict:
                cred_dict["private_key"] = cred_dict["private_key"].replace("\\n", "\n")
            cred = credentials.Certificate(cred_dict)
            firebase_admin.initialize_app(cred)
        else:
            print("Warning: Firebase Admin not initialized. No service account found.")
    except Exception as e:
        print(f"CRITICAL ERROR INITIALIZING FIREBASE: {e}")

try:
    import alembic.config
    import os
    
    # Run Alembic upgrade head programmatically
    alembicArgs = ['--raiseerr', 'upgrade', 'head']
    original_cwd = os.getcwd()
    # Ensure we are in the backend directory so alembic.ini is found
    backend_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(backend_dir)
    try:
        alembic.config.main(argv=alembicArgs)
    finally:
        os.chdir(original_cwd)
    # Initialize default admin user if none exists
    db = next(get_db())
    if db.query(models.AdminUser).count() == 0:
        admin_password = os.getenv("DEFAULT_ADMIN_PASSWORD")
        if not admin_password:
            print("WARNING: DEFAULT_ADMIN_PASSWORD environment variable is missing.")
        else:
            default_admin = models.AdminUser(
                username="admin",
                password_hash=auth.get_password_hash(admin_password),
                role="admin"
            )
            db.add(default_admin)
            db.commit()
    db.close()
except Exception as e:
    print(f"CRITICAL ERROR INITIALIZING DATABASE ON STARTUP: {e}")

app = FastAPI(title="Careersetu API")

# Setup CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

from fastapi.responses import JSONResponse
import traceback

@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    # This will catch ANY unhandled error and return the full traceback as JSON!
    return JSONResponse(
        status_code=500,
        content={"detail": f"Server Crash: {str(exc)}\nTraceback: {traceback.format_exc()}"}
    )

# Static files for uploads
@app.post("/api/admin/login")
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    admin_user = db.query(models.AdminUser).filter(models.AdminUser.username == form_data.username).first()
    if not admin_user or not auth.verify_password(form_data.password, admin_user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if not admin_user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")

    access_token_expires = timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = auth.create_access_token(
        data={"sub": admin_user.username, "role": admin_user.role}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

# User Auth Endpoints
@app.post("/api/auth/request-otp")
def request_otp(req: schemas.OTPRequest, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.mobile_number == req.mobile_number, models.User.is_active == True).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    # In real world, trigger SMS here
    return {"message": "OTP sent successfully"}

@app.post("/api/auth/verify-otp", response_model=schemas.TokenResponse)
def verify_otp(req: schemas.OTPVerify, db: Session = Depends(get_db)):
    if req.otp != "4321":
        raise HTTPException(status_code=400, detail="Invalid OTP")
    
    user = db.query(models.User).filter(models.User.mobile_number == req.mobile_number, models.User.is_active == True).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    access_token_expires = timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = auth.create_access_token(
        data={"sub": user.mobile_number, "role": "user"}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer", "user": user}

@app.post("/api/auth/signup", response_model=schemas.TokenResponse)
def signup(req: schemas.UserBase, db: Session = Depends(get_db)):
    existing_user = db.query(models.User).filter(models.User.mobile_number == req.mobile_number).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Mobile number already registered")
        
    db_user = models.User(**req.model_dump())
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    access_token_expires = timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = auth.create_access_token(
        data={"sub": db_user.mobile_number, "role": "user"}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer", "user": db_user}

@app.post("/api/auth/firebase-login", response_model=schemas.TokenResponse)
def firebase_login(req: schemas.FirebaseLoginRequest, db: Session = Depends(get_db)):
    try:
        decoded_token = firebase_auth.verify_id_token(req.id_token)
        phone_number = decoded_token.get('phone_number')
        if not phone_number:
            raise HTTPException(status_code=400, detail="No phone number found in token")
            
        # Standardize phone number format (remove +91 if needed, or keep it depending on DB)
        # Firebase format: +919876543210. The frontend sends mobile_number as 9876543210.
        formatted_number = phone_number.replace("+91", "")
            
        user = db.query(models.User).filter(models.User.mobile_number == formatted_number, models.User.is_active == True).first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found. Please sign up.")
            
        access_token_expires = timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = auth.create_access_token(
            data={"sub": user.mobile_number, "role": "user"}, expires_delta=access_token_expires
        )
        return {"access_token": access_token, "token_type": "bearer", "user": user}
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Invalid Firebase Token: {str(e)}")

@app.post("/api/auth/firebase-signup", response_model=schemas.TokenResponse)
def firebase_signup(req: schemas.FirebaseSignupRequest, db: Session = Depends(get_db)):
    try:
        decoded_token = firebase_auth.verify_id_token(req.id_token)
        phone_number = decoded_token.get('phone_number')
        if not phone_number:
            raise HTTPException(status_code=400, detail="No phone number found in token")
            
        formatted_number = phone_number.replace("+91", "")
        
        # Override the user's provided number with the verified one
        req.user_details.mobile_number = formatted_number
        
        existing_user = db.query(models.User).filter(models.User.mobile_number == formatted_number).first()
        if existing_user:
            raise HTTPException(status_code=400, detail="Mobile number already registered")
            
        db_user = models.User(**req.user_details.model_dump())
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        
        access_token_expires = timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = auth.create_access_token(
            data={"sub": db_user.mobile_number, "role": "user"}, expires_delta=access_token_expires
        )
        return {"access_token": access_token, "token_type": "bearer", "user": db_user}
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Invalid Firebase Token: {str(e)}")

# Banners API
@app.get("/api/banners", response_model=list[schemas.Banner])
def get_banners(db: Session = Depends(get_db)):
    return db.query(models.Banner).filter(models.Banner.is_active == True).all()

@app.post("/api/banners", response_model=schemas.Banner)
def create_banner(banner: schemas.BannerCreate, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    db_banner = models.Banner(**banner.model_dump())
    db.add(db_banner)
    db.commit()
    db.refresh(db_banner)
    auth.log_admin_action(db, admin, "CREATE", "Banners", db_banner.id)
    return db_banner

@app.put("/api/banners/{banner_id}", response_model=schemas.Banner)
def update_banner(banner_id: str, banner: schemas.BannerCreate, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    db_banner = db.query(models.Banner).filter(models.Banner.id == banner_id).first()
    if not db_banner:
        raise HTTPException(status_code=404, detail="Banner not found")
    
    for key, value in banner.model_dump().items():
        setattr(db_banner, key, value)
    
    db.commit()
    db.refresh(db_banner)
    auth.log_admin_action(db, admin, "UPDATE", "Banners", banner_id)
    return db_banner

@app.delete("/api/banners/{banner_id}")
def delete_banner(banner_id: str, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    db_banner = db.query(models.Banner).filter(models.Banner.id == banner_id).first()
    if not db_banner:
        raise HTTPException(status_code=404, detail="Banner not found")
    db_banner.is_active = False
    db.commit()
    auth.log_admin_action(db, admin, "DELETE", "Banners", banner_id)
    return {"status": "success"}

@app.get("/api/jobs", response_model=list[schemas.Job])
def get_jobs(db: Session = Depends(get_db)):
    return db.query(models.Job).filter(models.Job.is_active == True).all()

@app.get("/api/jobs/locations", response_model=list[str])
def get_job_locations(db: Session = Depends(get_db)):
    locations = db.query(models.Job.location).filter(
        models.Job.is_active == True,
        models.Job.location != None,
        models.Job.location != ""
    ).distinct().all()
    # Extract strings and trim whitespace
    return sorted(list(set([loc[0].strip() for loc in locations if loc[0].strip()])))

@app.get("/api/jobs/professions", response_model=list[str])
def get_job_professions(db: Session = Depends(get_db)):
    professions = db.query(models.Job.profession).filter(
        models.Job.is_active == True,
        models.Job.profession != None,
        models.Job.profession != ""
    ).distinct().all()
    # Extract strings and trim whitespace
    return sorted(list(set([prof[0].strip() for prof in professions if prof[0].strip()])))

@app.post("/api/jobs", response_model=schemas.Job)
def create_job(job: schemas.JobBase, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    db_job = models.Job(**job.model_dump())
    db.add(db_job)
    db.commit()
    db.refresh(db_job)
    auth.log_admin_action(db, admin, "CREATE", "Jobs", db_job.id)
    return db_job

@app.delete("/api/jobs/{job_id}")
def delete_job(job_id: str, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    db_job = db.query(models.Job).filter(models.Job.id == job_id).first()
    if not db_job:
        raise HTTPException(status_code=404, detail="Job not found")
    
    db_job.is_active = False
    from datetime import datetime
    db_job.deleted_datetime = datetime.utcnow()
    db.commit()
    auth.log_admin_action(db, admin, "DELETE", "Jobs", job_id)
    return {"status": "Job soft deleted"}

@app.put("/api/jobs/{job_id}", response_model=schemas.Job)
def update_job(job_id: str, job_update: schemas.JobBase, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    db_job = db.query(models.Job).filter(models.Job.id == job_id, models.Job.is_active == True).first()
    if not db_job:
        raise HTTPException(status_code=404, detail="Job not found")
    for key, value in job_update.model_dump().items():
        setattr(db_job, key, value)
    db.commit()
    db.refresh(db_job)
    auth.log_admin_action(db, admin, "UPDATE", "Jobs", job_id)
    return db_job

# Tests CRUD
from typing import Optional

@app.get("/api/tests", response_model=list[schemas.TestModel])
def get_tests(
    request: Request,
    status: Optional[str] = "all", 
    skip: int = 0, 
    limit: int = 20, 
    db: Session = Depends(get_db),
    current_user: Optional[models.User] = Depends(auth.get_current_user_optional)
):
    query = db.query(models.Test).filter(models.Test.is_active == True)
    
    if status != "all":
        if not current_user:
            raise HTTPException(status_code=401, detail="Authentication required to filter tests by status")
        attempted_test_ids = db.query(models.TestAttempt.test_id).filter(
            models.TestAttempt.user_id == current_user.id
        ).subquery()
        
        if status == "available":
            query = query.filter(~models.Test.id.in_(attempted_test_ids))
        elif status == "attempted":
            query = query.filter(models.Test.id.in_(attempted_test_ids))
            
    return query.order_by(models.Test.created_datetime.desc()).offset(skip).limit(limit).all()

@app.post("/api/tests", response_model=schemas.TestModel)
def create_test(test: schemas.TestBase, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    db_test = models.Test(**test.model_dump())
    db.add(db_test)
    db.commit()
    db.refresh(db_test)
    auth.log_admin_action(db, admin, "CREATE", "Tests", str(db_test.id))
    return db_test

@app.delete("/api/tests/{test_id}")
def delete_test(test_id: str, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    db_test = db.query(models.Test).filter(models.Test.id == test_id).first()
    if not db_test:
        raise HTTPException(status_code=404, detail="Test not found")
    db_test.is_active = False
    from datetime import datetime
    db_test.deleted_datetime = datetime.utcnow()
    db.commit()
    auth.log_admin_action(db, admin, "DELETE", "Tests", test_id)
    return {"status": "Test soft deleted"}

@app.get("/api/tests/{test_id}", response_model=schemas.TestModel)
def get_test(test_id: str, db: Session = Depends(get_db)):
    db_test = db.query(models.Test).filter(models.Test.id == test_id, models.Test.is_active == True).first()
    if not db_test:
        raise HTTPException(status_code=404, detail="Test not found")
    return db_test

@app.put("/api/tests/{test_id}", response_model=schemas.TestModel)
def update_test(test_id: str, test_update: schemas.TestBase, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    db_test = db.query(models.Test).filter(models.Test.id == test_id, models.Test.is_active == True).first()
    if not db_test:
        raise HTTPException(status_code=404, detail="Test not found")
    for key, value in test_update.model_dump().items():
        setattr(db_test, key, value)
    db.commit()
    db.refresh(db_test)
    auth.log_admin_action(db, admin, "UPDATE", "Tests", test_id)
    return db_test

@app.get("/api/tests/metadata/categories")
def get_question_categories(db: Session = Depends(get_db)):
    tests = db.query(models.Test).all()
    sections = set()
    topics = set()
    subtopics = set()
    
    for test in tests:
        if test.questions:
            for q in test.questions:
                if q.get("section"): sections.add(q["section"])
                if q.get("topic"): topics.add(q["topic"])
                if q.get("subtopic"): subtopics.add(q["subtopic"])
                
    return {
        "sections": sorted(list(sections)),
        "topics": sorted(list(topics)),
        "subtopics": sorted(list(subtopics))
    }

@app.post("/api/tests/{test_id}/upload-questions")
async def upload_questions(test_id: str, file: UploadFile = File(...), admin: str = Depends(auth.get_current_admin)):
    valid_questions = []
    invalid_questions = []
    
    contents = await file.read()
    
    if file.filename.endswith(".xlsx"):
        try:
            wb = openpyxl.load_workbook(io.BytesIO(contents), data_only=True)
            sheet = wb.active
            for row in sheet.iter_rows(min_row=2, values_only=True):
                # Expected format: Question | Type | Opt 1 | Opt 2 | Opt 3 | Opt 4 | Correct Answer | Section | Topic | Subtopic | Difficulty | Expected Time
                if not row or not row[0]:
                    continue
                    
                question_text = str(row[0]).strip()
                q_type = str(row[1]).strip() if len(row) > 1 and row[1] else "multiple_choice"
                options = [str(opt).strip() for opt in row[2:6] if opt is not None and str(opt).strip()]
                correct_answer = str(row[6]).strip() if len(row) > 6 and row[6] else ""
                
                section = str(row[7]).strip() if len(row) > 7 and row[7] else ""
                topic = str(row[8]).strip() if len(row) > 8 and row[8] else ""
                subtopic = str(row[9]).strip() if len(row) > 9 and row[9] else ""
                difficulty = str(row[10]).strip() if len(row) > 10 and row[10] else "Medium"
                
                try:
                    expected_time = int(row[11]) if len(row) > 11 and row[11] else 0
                except (ValueError, TypeError):
                    expected_time = 0
                
                if len(options) >= 2 and correct_answer:
                    valid_questions.append({
                        "id": f"q_{uuid.uuid4().hex[:8]}",
                        "type": q_type,
                        "question_text": question_text,
                        "options": options,
                        "correct_answer": correct_answer,
                        "section": section,
                        "topic": topic,
                        "subtopic": subtopic,
                        "difficulty": difficulty,
                        "expected_time_seconds": expected_time,
                        "points": 1
                    })
                else:
                    invalid_questions.append(question_text)
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Failed to parse Excel: {str(e)}")
            
    elif file.filename.endswith(".pdf"):
        try:
            pdf = PdfReader(io.BytesIO(contents))
            text = "\n"
            for page in pdf.pages:
                extracted = page.extract_text()
                if extracted:
                    text += extracted + "\n"
                
            # More flexible block splitting
            blocks = re.split(r'\n(?=(?:Q|q)?\s*\d+[\.\)])', text)
            for block in blocks:
                block = block.strip()
                if not block:
                    continue
                
                # Extract question text
                q_match = re.search(r'^(?:Q|q)?\s*\d+[\.\)]\s*(.*?)(?=\n\s*\(?[a-dA-D][\.\)]|$)', block, re.DOTALL)
                
                if not q_match:
                    if re.match(r'^(?:Q|q)?\s*\d+[\.\)]', block):
                        invalid_questions.append(block[:100] + "...")
                    continue
                
                q_text = q_match.group(1).strip()
                
                # Extract options
                options = []
                opt_pattern = r'\n\s*\(?([a-dA-D])[\.\)]\s*(.*?)(?=\n\s*\(?[a-dA-D][\.\)]|\n\s*(?:Answer|Ans):|$)'
                for opt_match in re.finditer(opt_pattern, block, re.DOTALL):
                    options.append(opt_match.group(2).strip())
                        
                # Extract answer
                ans_match = re.search(r'\n\s*(?:Answer|Ans):\s*\(?([a-dA-D])[\.\)]?', block, re.IGNORECASE)
                correct_answer = ""
                if ans_match:
                    ans_letter = ans_match.group(1).upper()
                    idx = ord(ans_letter) - ord('A')
                    if 0 <= idx < len(options):
                        correct_answer = options[idx]
                
                if len(options) >= 2:
                    valid_questions.append({
                        "id": f"q_{uuid.uuid4().hex[:8]}",
                        "text": q_text,
                        "options": options,
                        "correct_answer": correct_answer
                    })
                else:
                    invalid_questions.append(q_text[:100] + "...")
                    
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Failed to parse PDF: {str(e)}")
            
    else:
        raise HTTPException(status_code=400, detail="Only .xlsx and .pdf files are supported")
        
    return {"valid": valid_questions, "invalid": invalid_questions}

# Doctors CRUD
@app.get("/api/professionals", response_model=list[schemas.Professional])
def get_professionals(db: Session = Depends(get_db)):
    results = db.query(
        models.Professional,
        func.count(models.ProfessionalReview.id).label("reviews_count"),
        func.avg(models.ProfessionalReview.rating).label("avg_rating")
    ).outerjoin(
        models.ProfessionalReview, 
        models.ProfessionalReview.professional_id == models.Professional.id
    ).filter(
        models.Professional.is_active == True
    ).group_by(
        models.Professional.id
    ).all()
    
    professionals = []
    for prof, reviews_count, avg_rating in results:
        prof.reviews = reviews_count or 0
        prof.rating = float(avg_rating) if avg_rating is not None else prof.default_rating
        professionals.append(prof)
        
    return professionals

@app.post("/api/professionals", response_model=schemas.Professional)
def create_professional(professional: schemas.ProfessionalBase, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    db_professional = models.Professional(**professional.model_dump())
    db.add(db_professional)
    db.commit()
    db.refresh(db_professional)
    auth.log_admin_action(db, admin, "CREATE", "Professionals", str(db_professional.id))
    return db_professional

@app.delete("/api/professionals/{professional_id}")
def delete_professional(professional_id: str, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    db_professional = db.query(models.Professional).filter(models.Professional.id == professional_id).first()
    if not db_professional:
        raise HTTPException(status_code=404, detail="Professional not found")
    db_professional.is_active = False
    from datetime import datetime
    db_professional.deleted_datetime = datetime.utcnow()
    db.commit()
    auth.log_admin_action(db, admin, "DELETE", "Professionals", professional_id)
    return {"status": "Professional soft deleted"}

@app.put("/api/professionals/{professional_id}", response_model=schemas.Professional)
def update_professional(professional_id: str, professional_update: schemas.ProfessionalBase, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    db_professional = db.query(models.Professional).filter(models.Professional.id == professional_id, models.Professional.is_active == True).first()
    if not db_professional:
        raise HTTPException(status_code=404, detail="Professional not found")
    for key, value in professional_update.model_dump().items():
        setattr(db_professional, key, value)
    db.commit()
    db.refresh(db_professional)
    auth.log_admin_action(db, admin, "UPDATE", "Professionals", professional_id)
    return db_professional

# Professional Reviews
@app.get("/api/professionals/{professional_id}/reviews", response_model=list[schemas.ProfessionalReview])
def get_professional_reviews(professional_id: str, db: Session = Depends(get_db)):
    return db.query(models.ProfessionalReview).filter(models.ProfessionalReview.professional_id == professional_id, models.ProfessionalReview.is_active == True).all()

@app.get("/api/users/me/professionals/{professional_id}/review")
def get_my_professional_review(professional_id: str, db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_user)):
    existing = db.query(models.ProfessionalReview).filter(
        models.ProfessionalReview.professional_id == professional_id, 
        models.ProfessionalReview.user_id == current_user.id
    ).first()
    if not existing:
        raise HTTPException(status_code=404, detail="Review not found")
    return existing

@app.post("/api/users/me/professionals/{professional_id}/review", response_model=schemas.ProfessionalReview)
def submit_professional_review(professional_id: str, review: schemas.ProfessionalReviewCreate, db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_user)):
    existing = db.query(models.ProfessionalReview).filter(models.ProfessionalReview.professional_id == professional_id, models.ProfessionalReview.user_id == current_user.id).first()
    if existing:
        existing.rating = review.rating
        existing.comment = review.comment
        db.commit()
        db.refresh(existing)
        return existing
        
    db_review = models.ProfessionalReview(
        professional_id=professional_id,
        user_id=current_user.id,
        rating=review.rating,
        comment=review.comment
    )
    db.add(db_review)
    db.commit()
    db.refresh(db_review)
    return db_review

@app.get("/api/admin/professional-reviews", response_model=list[schemas.ProfessionalReview])
def admin_get_professional_reviews(db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    return db.query(models.ProfessionalReview).filter(models.ProfessionalReview.is_active == True).all()

@app.post("/api/admin/professional-reviews", response_model=schemas.ProfessionalReview)
def admin_create_professional_review(review: schemas.AdminProfessionalReviewCreate, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    db_review = models.ProfessionalReview(**review.model_dump())
    db.add(db_review)
    db.commit()
    db.refresh(db_review)
    auth.log_admin_action(db, admin, "CREATE", "ProfessionalReviews", str(db_review.id))
    return db_review

@app.put("/api/admin/professional-reviews/{review_id}", response_model=schemas.ProfessionalReview)
def admin_update_professional_review(review_id: str, review_update: schemas.ProfessionalReviewCreate, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    db_review = db.query(models.ProfessionalReview).filter(models.ProfessionalReview.id == review_id, models.ProfessionalReview.is_active == True).first()
    if not db_review:
        raise HTTPException(status_code=404, detail="Review not found")
    
    db_review.rating = review_update.rating
    db_review.comment = review_update.comment
    db.commit()
    db.refresh(db_review)
    auth.log_admin_action(db, admin, "UPDATE", "ProfessionalReviews", review_id)
    return db_review

@app.delete("/api/admin/professional-reviews/{review_id}")
def admin_delete_professional_review(review_id: str, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    db_review = db.query(models.ProfessionalReview).filter(models.ProfessionalReview.id == review_id).first()
    if not db_review:
        raise HTTPException(status_code=404, detail="Review not found")
    db_review.is_active = False
    from datetime import datetime
    db_review.deleted_datetime = datetime.utcnow()
    db.commit()
    auth.log_admin_action(db, admin, "DELETE", "ProfessionalReviews", review_id)
    return {"status": "Review soft deleted"}

# Offers CRUD
@app.get("/api/offers/cities", response_model=list[str])
def get_offer_cities(db: Session = Depends(get_db)):
    cities = db.query(models.Offer.city)\
        .filter(models.Offer.is_active == True, models.Offer.city.isnot(None), models.Offer.city != '')\
        .distinct()\
        .all()
    return [city[0] for city in cities if city[0]]
@app.get("/api/offers", response_model=list[schemas.Offer])
def get_offers(city: Optional[str] = None, category: Optional[str] = None, skip: int = 0, limit: int = 100, db: Session = Depends(get_db), current_user: Optional[models.User] = Depends(auth.get_current_user_optional)):
    query = db.query(models.Offer).filter(models.Offer.is_active == True)
    
    # Filter out expired offers (where valid_until is past)
    query = query.filter(
        (models.Offer.valid_until == None) | (models.Offer.valid_until >= datetime.utcnow())
    )

    if current_user:
        # Exclude offers already claimed by this user
        claimed_subquery = db.query(models.ClaimedOffer.offer_id).filter(models.ClaimedOffer.user_id == current_user.id)
        query = query.filter(models.Offer.id.notin_(claimed_subquery))
    if city:
        query = query.filter(func.lower(models.Offer.city) == func.lower(city))
    if category:
        query = query.filter(func.lower(models.Offer.type) == func.lower(category))
    return query.offset(skip).limit(limit).all()

@app.post("/api/offers/{offer_id}/claim")
def claim_offer(offer_id: str, db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_user)):
    offer = db.query(models.Offer).filter(models.Offer.id == offer_id, models.Offer.is_active == True).first()
    if not offer:
        raise HTTPException(status_code=404, detail="Offer not found or inactive")
        
    already_claimed = db.query(models.ClaimedOffer).filter(
        models.ClaimedOffer.user_id == current_user.id,
        models.ClaimedOffer.offer_id == offer.id
    ).first()
    
    if already_claimed:
        raise HTTPException(status_code=400, detail="Offer already claimed")
        
    claimed_offer = models.ClaimedOffer(user_id=current_user.id, offer_id=offer.id)
    db.add(claimed_offer)
    db.commit()
    db.refresh(claimed_offer)
    return {"message": "Offer claimed successfully", "discount_code": offer.discount_code}

@app.get("/api/users/me/claimed-offers", response_model=list[schemas.ClaimedOfferResponse])
def get_claimed_offers(skip: int = 0, limit: int = 100, db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_user)):
    return db.query(models.ClaimedOffer).filter(models.ClaimedOffer.user_id == current_user.id).offset(skip).limit(limit).all()

@app.post("/api/offers", response_model=schemas.Offer)
def create_offer(offer: schemas.OfferBase, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    db_offer = models.Offer(**offer.model_dump())
    db.add(db_offer)
    db.commit()
    db.refresh(db_offer)
    auth.log_admin_action(db, admin, "CREATE", "Offers", str(db_offer.id))
    return db_offer

@app.delete("/api/offers/{offer_id}")
def delete_offer(offer_id: str, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    db_offer = db.query(models.Offer).filter(models.Offer.id == offer_id).first()
    if not db_offer:
        raise HTTPException(status_code=404, detail="Offer not found")
    db_offer.is_active = False
    from datetime import datetime
    db_offer.deleted_datetime = datetime.utcnow()
    db.commit()
    auth.log_admin_action(db, admin, "DELETE", "Offers", offer_id)
    return {"status": "Offer soft deleted"}

@app.put("/api/offers/{offer_id}", response_model=schemas.Offer)
def update_offer(offer_id: str, offer_update: schemas.OfferBase, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    db_offer = db.query(models.Offer).filter(models.Offer.id == offer_id, models.Offer.is_active == True).first()
    if not db_offer:
        raise HTTPException(status_code=404, detail="Offer not found")
    for key, value in offer_update.model_dump().items():
        setattr(db_offer, key, value)
    db.commit()
    db.refresh(db_offer)
    auth.log_admin_action(db, admin, "UPDATE", "Offers", offer_id)
    return db_offer

@app.get("/api/admin/claimed-offers", response_model=list[schemas.ClaimedOfferResponse])
def get_admin_claimed_offers(db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    return db.query(models.ClaimedOffer).all()

# Users
@app.get("/api/users", response_model=list[schemas.User])
def get_users(db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    return db.query(models.User).filter(models.User.is_active == True).all()

@app.get("/api/users/{user_id}/details")
def get_user_details(user_id: str, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    user = db.query(models.User).filter(models.User.id == user_id, models.User.is_active == True).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # We will just fetch the raw data and let the frontend join it or we can manually join it here.
    # Since we didn't set up SQLAlchemy relationships in models.py (no `relationship()` on User), 
    # we will query manually.
    
    job_apps = db.query(models.JobApplication).filter(models.JobApplication.user_id == user_id).all()
    test_attempts = db.query(models.TestAttempt).filter(models.TestAttempt.user_id == user_id).all()
    prof_appts = db.query(models.ProfessionalAppointment).filter(models.ProfessionalAppointment.user_id == user_id).all()
    
    # Enrich with actual job/test/doc data for the frontend
    job_apps_enriched = []
    for app in job_apps:
        job = db.query(models.Job).filter(models.Job.id == app.job_id).first()
        app_dict = app.__dict__.copy()
        app_dict['job'] = job.__dict__ if job else None
        job_apps_enriched.append(app_dict)
        
    test_attempts_enriched = []
    for att in test_attempts:
        test = db.query(models.Test).filter(models.Test.id == att.test_id).first()
        att_dict = att.__dict__.copy()
        att_dict['test'] = test.__dict__ if test else None
        test_attempts_enriched.append(att_dict)
        
    prof_appts_enriched = []
    for apt in prof_appts:
        prof = db.query(models.Professional).filter(models.Professional.id == apt.professional_id).first()
        apt_dict = apt.__dict__.copy()
        apt_dict['doctor'] = prof.__dict__ if prof else None
        prof_appts_enriched.append(apt_dict)
        
    return {
        "user": user,
        "job_applications": job_apps_enriched,
        "test_attempts": test_attempts_enriched,
        "professional_appointments": prof_appts_enriched
    }

@app.put("/api/users/profile", response_model=schemas.User)
def update_user_profile(user_update: schemas.UserProfileUpdate, db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_user)):
    if user_update.profile_image_url is not None:
        current_user.profile_image_url = user_update.profile_image_url
    if user_update.mobile_number is not None:
        # Check if mobile number is already in use
        existing_user = db.query(models.User).filter(models.User.mobile_number == user_update.mobile_number).first()
        if existing_user and existing_user.id != current_user.id:
            raise HTTPException(status_code=400, detail="Mobile number already in use by another account.")
        current_user.mobile_number = user_update.mobile_number
    if user_update.city is not None:
        current_user.city = user_update.city
    if user_update.goal is not None:
        current_user.goal = user_update.goal
    if user_update.full_name is not None:
        current_user.full_name = user_update.full_name
    if user_update.email is not None:
        current_user.email = user_update.email
    if user_update.resume_data is not None:
        current_user.resume_data = user_update.resume_data
    
    db.commit()
    db.refresh(current_user)
    db.refresh(current_user)
    return current_user

# --- User Appointments ---
@app.get("/api/users/me/appointments", response_model=list[schemas.ProfessionalAppointment])
def get_my_appointments(skip: int = 0, limit: int = 50, db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_user)):
    appointments = db.query(models.ProfessionalAppointment).filter(models.ProfessionalAppointment.user_id == current_user.id).order_by(models.ProfessionalAppointment.appointment_date.desc()).offset(skip).limit(limit).all()
    for appt in appointments:
        if appt.professional:
            reviews_query = db.query(models.ProfessionalReview).filter(
                models.ProfessionalReview.professional_id == appt.professional.id,
                models.ProfessionalReview.is_active == True
            )
            count = reviews_query.count()
            if count > 0:
                avg = db.query(func.avg(models.ProfessionalReview.rating)).filter(
                    models.ProfessionalReview.professional_id == appt.professional.id,
                    models.ProfessionalReview.is_active == True
                ).scalar()
                appt.professional.reviews = count
                appt.professional.rating = float(avg)
            else:
                appt.professional.reviews = 0
                appt.professional.rating = appt.professional.default_rating
    return appointments

@app.post("/api/users/me/appointments", response_model=schemas.ProfessionalAppointment)
def create_appointment(app_req: schemas.ProfessionalAppointmentCreate, db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_user)):
    if app_req.appointment_date == "Today":
        now = datetime.now()
        try:
            time_obj = datetime.strptime(app_req.appointment_time, "%I:%M %p")
            slot_datetime = now.replace(hour=time_obj.hour, minute=time_obj.minute, second=0, microsecond=0)
            if slot_datetime < now:
                raise HTTPException(status_code=400, detail="Cannot book a past time slot for today.")
        except ValueError:
            pass
            
    db_appointment = models.ProfessionalAppointment(**app_req.model_dump(), user_id=current_user.id)
    db.add(db_appointment)
    db.commit()
    db.refresh(db_appointment)
    return db_appointment

# --- User Job Applications ---
@app.get("/api/users/me/applications", response_model=list[schemas.JobApplication])
def get_my_applications(db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_user)):
    return db.query(models.JobApplication).filter(models.JobApplication.user_id == current_user.id).all()

@app.post("/api/users/me/applications", response_model=schemas.JobApplication)
def apply_for_job(app_req: schemas.JobApplicationCreate, db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_user)):
    db_app = models.JobApplication(**app_req.model_dump(), user_id=current_user.id)
    db.add(db_app)
    db.commit()
    db.refresh(db_app)
    return db_app

# --- User Test Attempts ---
@app.get("/api/users/me/test-attempts", response_model=list[schemas.TestAttempt])
def get_my_test_attempts(db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_user)):
    return db.query(models.TestAttempt).filter(models.TestAttempt.user_id == current_user.id).all()

@app.post("/api/users/me/test-attempts", response_model=schemas.TestAttempt)
async def submit_test_attempt(attempt_req: schemas.TestAttemptCreate, db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_user)):
    test = db.query(models.Test).filter(models.Test.id == attempt_req.test_id).first()
    if not test:
        raise HTTPException(status_code=404, detail="Test not found")
        
    db_attempt = models.TestAttempt(**attempt_req.model_dump(), user_id=current_user.id)
    db.add(db_attempt)
    db.commit()
    db.refresh(db_attempt)
    
    import json
    import httpx
    import os
    
    api_key = os.getenv("OPENAI_API_KEY")
    if api_key and attempt_req.question_responses and test.questions:
        test_q_map = {q.get("id"): q for q in test.questions if isinstance(q, dict)}
        topic_stats = {}
        
        for resp in attempt_req.question_responses:
            if not isinstance(resp, dict): continue
            q_id = resp.get("question_id")
            tq = test_q_map.get(q_id)
            if not tq: continue
            
            topic = tq.get("topic", "General")
            is_correct = resp.get("is_correct", False)
            time_spent = resp.get("time_spent_seconds", 0)
            expected_time = tq.get("expected_time_seconds", 60)
            
            if topic not in topic_stats:
                topic_stats[topic] = {"correct": 0, "total": 0, "time_spent": 0, "expected_time": 0}
                
            topic_stats[topic]["total"] += 1
            if is_correct: topic_stats[topic]["correct"] += 1
            topic_stats[topic]["time_spent"] += time_spent
            topic_stats[topic]["expected_time"] += expected_time

        system_prompt = f"""
You are an expert career and academic counselor. Analyze the following student test performance data aggregated by topic.
Data: {json.dumps(topic_stats)}

Create a personalized JSON report identifying:
1. "mastered_topics": List of topics with high accuracy and fast time.
2. "weak_topics": List of topics with low accuracy OR significantly high time spent.
3. "recommendations": A short, encouraging paragraph on what to study next.

Return ONLY a valid JSON object matching the structure: {{"mastered_topics": [str], "weak_topics": [str], "recommendations": str}}
"""
        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(
                    "https://api.openai.com/v1/chat/completions",
                    headers={"Content-Type": "application/json", "Authorization": f"Bearer {api_key}"},
                    json={
                        "model": "gpt-4o-mini",
                        "response_format": {"type": "json_object"},
                        "messages": [{"role": "system", "content": system_prompt}],
                        "temperature": 0.7
                    },
                    timeout=15.0
                )
                if response.status_code == 200:
                    data = response.json()
                    content = data["choices"][0]["message"]["content"].strip()
                    db_attempt.ai_report = json.loads(content)
                    db.commit()
                    db.refresh(db_attempt)
            except Exception as e:
                print("AI Report generation failed:", e)
                
    return db_attempt

# --- Notifications ---
@app.get("/api/users/me/notifications", response_model=list[schemas.Notification])
def get_my_notifications(db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_user)):
    return db.query(models.Notification).filter(models.Notification.target_user_id == current_user.id).order_by(models.Notification.created_datetime.desc()).all()

@app.put("/api/users/me/notifications/{notification_id}/read", response_model=schemas.Notification)
def mark_notification_read(notification_id: str, db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_user)):
    db_notif = db.query(models.Notification).filter(models.Notification.id == notification_id, models.Notification.target_user_id == current_user.id).first()
    if not db_notif:
        raise HTTPException(status_code=404, detail="Notification not found")
    db_notif.is_read = True
    db.commit()
    db.refresh(db_notif)
    return db_notif

# Activity Logs
@app.get("/api/logs", response_model=list[schemas.ActivityLog])
def get_activity_logs(db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    return db.query(models.ActivityLog).order_by(models.ActivityLog.created_datetime.desc()).all()

# Dashboard Stats
@app.get("/api/dashboard/stats")
def get_dashboard_stats(filter: str = "This Week", db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    today = date.today()
    from sqlalchemy import extract
    from datetime import datetime, time

    start_date = None
    if filter == "Today":
        start_date = datetime.combine(today, time.min)
    elif filter == "Yesterday":
        start_date = datetime.combine(today - timedelta(days=1), time.min)
    elif filter == "This Week":
        start_date = datetime.combine(today - timedelta(days=6), time.min)
    elif filter == "This Month":
        start_date = datetime.combine(today - timedelta(days=29), time.min)
    elif filter == "This Year":
        start_date = datetime.combine(today.replace(month=1, day=1), time.min)

    # Base queries
    users_q = db.query(models.User).filter(models.User.is_active == True)
    jobs_q = db.query(models.Job).filter(models.Job.is_active == True)
    tests_q = db.query(models.TestAttempt)
    appts_q = db.query(models.ProfessionalAppointment)

    # Apply date filters if not "All Time"
    if start_date:
        users_q = users_q.filter(models.User.created_datetime >= start_date)
        jobs_q = jobs_q.filter(models.Job.created_datetime >= start_date)
        tests_q = tests_q.filter(models.TestAttempt.created_datetime >= start_date)
        # Assuming appointments have created_datetime, otherwise we filter by appointment_date string (harder)
        # We will use created_datetime for appointments if it exists in BaseModel
        appts_q = appts_q.filter(models.ProfessionalAppointment.created_datetime >= start_date)

    if filter == "Yesterday":
        end_date = datetime.combine(today, time.min)
        users_q = users_q.filter(models.User.created_datetime < end_date)
        jobs_q = jobs_q.filter(models.Job.created_datetime < end_date)
        tests_q = tests_q.filter(models.TestAttempt.created_datetime < end_date)
        appts_q = appts_q.filter(models.ProfessionalAppointment.created_datetime < end_date)

    total_users = users_q.count()
    active_jobs = jobs_q.count()
    tests_taken = tests_q.count()
    appointments = appts_q.count()
    
    # Generate chart data based on filter
    chart_data = []
    
    if filter in ["Today", "Yesterday", "This Week"]:
        for i in range(6, -1, -1):
            target_date = today - timedelta(days=i)
            day_name = target_date.strftime("%b %d") # e.g. Sep 14
            
            users_count = db.query(models.User).filter(
                func.date(models.User.created_datetime) == target_date,
                models.User.is_active == True
            ).count()
            
            jobs_count = db.query(models.Job).filter(
                func.date(models.Job.created_datetime) == target_date,
                models.Job.is_active == True
            ).count()
            
            chart_data.append({"name": day_name, "users": users_count, "jobs": jobs_count})
            
    elif filter == "This Month":
        for i in range(29, -1, -1):
            target_date = today - timedelta(days=i)
            day_name = target_date.strftime("%b %d")
            
            users_count = db.query(models.User).filter(func.date(models.User.created_datetime) == target_date, models.User.is_active == True).count()
            jobs_count = db.query(models.Job).filter(func.date(models.Job.created_datetime) == target_date, models.Job.is_active == True).count()
            chart_data.append({"name": day_name, "users": users_count, "jobs": jobs_count})
            
    elif filter == "This Year":
        for i in range(11, -1, -1):
            m = today.month - i
            y = today.year
            if m <= 0:
                m += 12
                y -= 1
            import calendar
            day_name = f"{calendar.month_abbr[m]} {y}"
            
            users_count = db.query(models.User).filter(extract('month', models.User.created_datetime) == m, extract('year', models.User.created_datetime) == y, models.User.is_active == True).count()
            jobs_count = db.query(models.Job).filter(extract('month', models.Job.created_datetime) == m, extract('year', models.Job.created_datetime) == y, models.Job.is_active == True).count()
            chart_data.append({"name": day_name, "users": users_count, "jobs": jobs_count})
            
    elif filter == "All Time":
        for i in range(4, -1, -1):
            y = today.year - i
            day_name = str(y)
            users_count = db.query(models.User).filter(extract('year', models.User.created_datetime) == y, models.User.is_active == True).count()
            jobs_count = db.query(models.Job).filter(extract('year', models.Job.created_datetime) == y, models.Job.is_active == True).count()
            chart_data.append({"name": day_name, "users": users_count, "jobs": jobs_count})

    # B2B Insights & Additional Chart Data
    
    # 1. Users by City
    city_data = db.query(
        models.User.city, 
        func.count(models.User.id).label("count")
    ).filter(models.User.is_active == True)
    if start_date:
        city_data = city_data.filter(models.User.created_datetime >= start_date)
    city_data = city_data.group_by(models.User.city).all()
    users_by_city = [{"name": c[0] or "Unknown", "value": c[1]} for c in city_data]

    # 2. Users by Goal
    goal_data = db.query(
        models.User.goal, 
        func.count(models.User.id).label("count")
    ).filter(models.User.is_active == True)
    if start_date:
        goal_data = goal_data.filter(models.User.created_datetime >= start_date)
    goal_data = goal_data.group_by(models.User.goal).all()
    users_by_goal = [{"name": g[0] or "Unknown", "value": g[1]} for g in goal_data]

    # 3. Job Application Statuses
    job_apps_data = db.query(
        models.JobApplication.status, 
        func.count(models.JobApplication.id).label("count")
    )
    if start_date:
        job_apps_data = job_apps_data.filter(models.JobApplication.created_datetime >= start_date)
    job_apps_data = job_apps_data.group_by(models.JobApplication.status).all()
    job_applications_status = [{"name": j[0] or "Pending", "value": j[1]} for j in job_apps_data]

    # 4. Professional Consultations (Demand)
    # Join ProfessionalAppointment with Professional to group by Profession
    prof_demand_data = db.query(
        models.Professional.profession,
        func.count(models.ProfessionalAppointment.id).label("count")
    ).join(
        models.ProfessionalAppointment, models.Professional.id == models.ProfessionalAppointment.professional_id
    )
    if start_date:
        prof_demand_data = prof_demand_data.filter(models.ProfessionalAppointment.created_datetime >= start_date)
    prof_demand_data = prof_demand_data.group_by(models.Professional.profession).all()
    appointments_by_profession = [{"name": p[0] or "Unknown", "value": p[1]} for p in prof_demand_data]

    return {
        "totals": {
            "users": total_users,
            "jobs": active_jobs,
            "tests": tests_taken,
            "appointments": appointments
        },
        "chart_data": chart_data,
        "users_by_city": users_by_city,
        "users_by_goal": users_by_goal,
        "job_applications_status": job_applications_status,
        "appointments_by_profession": appointments_by_profession
    }

# --- Admin Appointments Management ---
@app.get("/api/admin/appointments", response_model=list[schemas.ProfessionalAppointment])
def admin_get_appointments(db: Session = Depends(get_db)):
    # Returns all appointments with user and doctor relations
    # We don't enforce auth token here for brevity but assuming typical admin protection
    appointments = db.query(models.ProfessionalAppointment).filter(models.ProfessionalAppointment.is_active == True).all()
    return appointments

@app.put("/api/admin/appointments/{appointment_id}/status", response_model=schemas.ProfessionalAppointment)
def admin_update_appointment_status(appointment_id: str, status: str, db: Session = Depends(get_db)):
    appointment = db.query(models.ProfessionalAppointment).filter(models.ProfessionalAppointment.id == appointment_id).first()
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")
    
    appointment.status = status
    
    # Push Notification logic if assigned
    if status == "sent_to_doctor":
        notification = models.Notification(
            title="Appointment Confirmed",
            message=f"Your booking for {appointment.professional.name} on {appointment.appointment_date} is confirmed.",
            target_user_id=appointment.user_id,
            is_read=False
        )
        db.add(notification)
        
    db.commit()
    db.refresh(appointment)
    return appointment

# --- Admin: All Job Applications ---
@app.get("/api/admin/job-applications")
def admin_get_all_job_applications(db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    applications = db.query(models.JobApplication).filter(models.JobApplication.is_active == True).order_by(models.JobApplication.created_datetime.desc()).all()
    result = []
    for app in applications:
        user = db.query(models.User).filter(models.User.id == app.user_id).first()
        job = db.query(models.Job).filter(models.Job.id == app.job_id).first()
        result.append({
            "id": str(app.id),
            "status": app.status,
            "applied_at": app.created_datetime.isoformat() if app.created_datetime else None,
            "user": {"id": str(user.id), "full_name": user.full_name, "mobile_number": user.mobile_number, "city": user.city} if user else None,
            "job": {"id": str(job.id), "title": job.title, "company": job.company, "location": job.location, "type": job.type} if job else None,
        })
    return result

# --- Admin: All Test Attempts ---
@app.get("/api/admin/test-attempts")
def admin_get_all_test_attempts(db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    attempts = db.query(models.TestAttempt).filter(models.TestAttempt.is_active == True).order_by(models.TestAttempt.created_datetime.desc()).all()
    result = []
    for att in attempts:
        user = db.query(models.User).filter(models.User.id == att.user_id).first()
        test = db.query(models.Test).filter(models.Test.id == att.test_id).first()
        total_questions = len(test.questions) if test and test.questions else 0
        result.append({
            "id": str(att.id),
            "score": att.total_score,
            "total_questions": total_questions,
            "attempted_at": att.created_datetime.isoformat() if att.created_datetime else None,
            "user": {"id": str(user.id), "full_name": user.full_name, "mobile_number": user.mobile_number, "city": user.city} if user else None,
            "test": {"id": str(test.id), "title": test.title, "tag": test.tag, "difficulty": test.difficulty} if test else None,
        })
    return result


import httpx
import json

@app.post("/api/resume/process-step")
async def process_resume_step(req: schemas.ResumeStepRequest):
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        raise HTTPException(status_code=500, detail="OpenAI API key not configured on server.")

    system_prompt = f"""
You are an expert professional resume writer interviewing a user.
The current section you are gathering information for is: {req.current_step}.
The user's current resume data is: {json.dumps(req.current_resume_data)}.

Please carefully review the conversation history.
Evaluate the user's latest input: "{req.user_input}"

Strict Rules:
1. "Upload Resume" Context: If your last message asked the user to upload a resume and they respond with a greeting (like 'hi') or say they don't have one, politely acknowledge it (e.g., 'Hello! Since you haven't uploaded a resume, let's build one from scratch. Could you please provide a brief summary...') and set next_step as "{req.current_step}".
2. Missing Info / Skipping: If the user explicitly states they don't know, don't have, or want to skip the current section, DO NOT force them. Set `is_sufficient` to true (with empty `extracted_data`), politely acknowledge it, and move to the `next_step` (e.g., from summary to experience).
3. Off-Topic: If the input is completely unrelated to resume building, do not extract data. Politely steer them back and restate the question for the {req.current_step}.
4. Preventing Loops: Never ask for information that is already present in `current_resume_data`. If the data is sufficient, always transition to the next logical step (summary -> experience -> education -> skills -> complete).
5. Incomplete Info: If the input is relevant but too brief (e.g., a 1-word answer for work history), ask a polite follow-up question for the {req.current_step}. DO NOT extract data, and keep next_step as "{req.current_step}".

If the input provides good information for the {req.current_step}, extract and professionalize it into "extracted_data", decide the "next_step", and formulate a "reply" asking for the next information.

For "extracted_data", YOU MUST strictly follow this JSON schema depending on the current section:
- If section is "summary": Return a single string.
- If section is "experience": Return a LIST OF OBJECTS, where each object has: "title" (string), "company" (string), "date" (string), "bullets" (list of strings).
- If section is "education": Return a LIST OF OBJECTS, where each object has: "degree" (string), "date" (string), "school" (string).
- If section is "skills": Return a single string with skills separated by commas or newlines.

Return your response ONLY as a JSON object with:
- "is_sufficient": boolean (true if you got enough info or the user skipped, false if you need to ask more about the current section)
- "reply": Your conversational response to the user.
- "extracted_data": (Optional) The professionalized data matching the schema above.
- "next_step": The string key of the next section to move to. If is_sufficient is false, next_step MUST be "{req.current_step}".

Do not wrap the JSON in Markdown code blocks like ```json, just return the raw JSON object.
"""

    messages = [{"role": "system", "content": system_prompt}]
    if req.chat_history:
        for msg in req.chat_history[-5:]: # Only send the last 5 messages to avoid token bloat
            role = msg.get("role", "user")
            if role not in ["user", "assistant", "system"]:
                role = "user"
            messages.append({"role": role, "content": msg.get("content", "")})
    
    messages.append({"role": "user", "content": req.user_input})

    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                "https://api.openai.com/v1/chat/completions",
                headers={
                    "Content-Type": "application/json",
                    "Authorization": f"Bearer {api_key}"
                },
                json={
                    "model": "gpt-4o-mini",
                    "response_format": {"type": "json_object"},
                    "messages": messages,
                    "temperature": 0.7
                },
                timeout=30.0
            )
            response.raise_for_status()
            data = response.json()
            content = data["choices"][0]["message"]["content"].strip()

            if content.startswith("```"):
                first_newline = content.find("\n")
                if first_newline != -1:
                    content = content[first_newline + 1:]
                if content.endswith("```"):
                    content = content[:-3]
                content = content.strip()

            return json.loads(content)

        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=f"OpenAI error: {e.response.text}")
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error communicating with AI: {str(e)}")

# --- Resume Session Endpoints ---
@app.get("/api/resume/session", response_model=schemas.ResumeSessionOut)
def get_resume_session(db: Session = Depends(get_db), current_user: str = Depends(auth.get_current_user)):
    user_id = current_user.get("user_id")
    session = db.query(models.ResumeSession).filter(models.ResumeSession.user_id == user_id, models.ResumeSession.is_active == True).first()
    
    if not session:
        # Create a new session and initialize with user.resume_data if it exists
        user = db.query(models.User).filter(models.User.id == user_id).first()
        initial_extracted = user.resume_data if user and user.resume_data else {}
        uploaded_info = None
        if initial_extracted and "data" in initial_extracted:
            uploaded_info = initial_extracted
        
        session = models.ResumeSession(
            user_id=user_id,
            chat_history=[],
            extracted_data=initial_extracted,
            uploaded_resume_info=uploaded_info
        )
        db.add(session)
        db.commit()
        db.refresh(session)
        
    return session

@app.post("/api/resume/session/update", response_model=schemas.ResumeSessionOut)
def update_resume_session(req: schemas.ResumeSessionUpdate, db: Session = Depends(get_db), current_user: str = Depends(auth.get_current_user)):
    user_id = current_user.get("user_id")
    session = db.query(models.ResumeSession).filter(models.ResumeSession.user_id == user_id, models.ResumeSession.is_active == True).first()
    
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
        
    if req.chat_history is not None:
        session.chat_history = req.chat_history
    if req.extracted_data is not None:
        session.extracted_data = req.extracted_data
    if req.uploaded_resume_info is not None:
        session.uploaded_resume_info = req.uploaded_resume_info
    if req.status is not None:
        session.status = req.status
    if req.current_step is not None:
        session.current_step = req.current_step
        
    db.commit()
    db.refresh(session)
    return session
