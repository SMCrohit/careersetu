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
from sqlalchemy import func, or_
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
    # Database initialization is now handled externally/via migrations
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
        uid = decoded_token.get("uid")
        phone_number = decoded_token.get('phone_number')
        email = decoded_token.get('email')
            
        user = db.query(models.User).filter(
            (models.User.firebase_uid == uid) | 
            (models.User.email == email) | 
            (models.User.mobile_number == (phone_number.replace("+91", "") if phone_number else None))
        ).first()

        if not user:
            raise HTTPException(status_code=404, detail="User account not found. Please sign up first.")
            
        if not user.is_active:
            raise HTTPException(status_code=403, detail="Your account has been deactivated. Please contact support.")
            
        if not user.firebase_uid:
            user.firebase_uid = uid
            db.commit()
            
        access_token_expires = timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = auth.create_access_token(
            data={"sub": user.mobile_number or user.email, "role": user.role}, expires_delta=access_token_expires
        )
        return {"access_token": access_token, "token_type": "bearer", "user": user, "message": "Login successful"}
    except HTTPException as e:
        raise e
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=401, detail=f"Authentication failed: {str(e)}")

@app.post("/api/auth/firebase-signup", response_model=schemas.TokenResponse)
def firebase_signup(req: schemas.FirebaseSignupRequest, db: Session = Depends(get_db)):
    try:
        decoded_token = firebase_auth.verify_id_token(req.id_token)
        uid = decoded_token.get("uid")
        phone_number = decoded_token.get('phone_number')
        email = decoded_token.get('email')
            
        formatted_number = phone_number.replace("+91", "") if phone_number else None
        
        # Override the user's provided data with the verified one from Firebase
        if formatted_number:
            req.user_details.mobile_number = formatted_number
        if email:
            req.user_details.email = email
            
        req.user_details.firebase_uid = uid
        
        existing_user = db.query(models.User).filter(
            (models.User.firebase_uid == uid) |
            (models.User.mobile_number == formatted_number) |
            (models.User.email == email)
        ).first()
        
        if existing_user:
            raise HTTPException(status_code=400, detail="An account with this mobile number or email is already registered.")
            
        db_user = models.User(**req.user_details.model_dump())
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        
        access_token_expires = timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = auth.create_access_token(
            data={"sub": db_user.mobile_number or db_user.email, "role": db_user.role}, expires_delta=access_token_expires
        )
        return {"access_token": access_token, "token_type": "bearer", "user": db_user, "message": "Account created successfully"}
    except HTTPException as e:
        raise e
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=401, detail=f"Registration failed: {str(e)}")

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



@app.get("/api/jobs/companies")
def get_all_companies(db: Session = Depends(get_db)):
    companies = db.query(models.Job.company_name).distinct().all()
    return [c[0] for c in companies if c[0]]

@app.get("/api/job-applications")
def get_all_job_applications(
    status: str = None,
    company_name: str = None,
    applied_start: str = None,
    applied_end: str = None,
    min_match: int = None,
    max_match: int = None,
    search: str = None,
    page: int = 1,
    limit: int = 10,
    db: Session = Depends(get_db), 
    admin: str = Depends(auth.get_current_admin)
):
    query = db.query(models.JobApplication)
    
    if status:
        query = query.filter(models.JobApplication.status == status)
    
    if min_match is not None:
        query = query.filter(models.JobApplication.ai_match_score >= min_match)
    if max_match is not None:
        query = query.filter(models.JobApplication.ai_match_score <= max_match)
        
    if applied_start:
        from datetime import datetime
        try:
            start_dt = datetime.strptime(applied_start, "%Y-%m-%d")
            query = query.filter(models.JobApplication.created_datetime >= start_dt)
        except ValueError:
            pass
            
    if applied_end:
        from datetime import datetime
        try:
            end_dt = datetime.strptime(applied_end, "%Y-%m-%d").replace(hour=23, minute=59, second=59)
            query = query.filter(models.JobApplication.created_datetime <= end_dt)
        except ValueError:
            pass
            
    if company_name:
        query = query.join(models.Job).filter(models.Job.company_name == company_name)

    # Search by applicant name, email, or job title via joins
    if search:
        search_term = f"%{search}%"
        query = query.join(models.StudentProfile, models.JobApplication.student_profile_id == models.StudentProfile.id, isouter=True)\
                     .join(models.User, models.StudentProfile.user_id == models.User.id, isouter=True)\
                     .join(models.Job, models.JobApplication.job_id == models.Job.id, isouter=True)\
                     .filter(
                         (models.User.full_name.ilike(search_term)) |
                         (models.User.email.ilike(search_term)) |
                         (models.Job.title.ilike(search_term))
                     )
        
    total = query.count()
    applications = query.order_by(models.JobApplication.created_datetime.desc()).offset((page - 1) * limit).limit(limit).all()
    
    results = []
    for app in applications:
        job = app.job
        sp = app.student_profile
        user = sp.user if sp else None
        
        results.append({
            "id": str(app.id),
            "applicant": {
                "full_name": user.full_name if user else "Unknown",
                "email": user.email if user else None,
                "mobile_number": user.mobile_number if user else None,
            },
            "job": {
                "title": job.title if job else "Unknown",
                "company_name": job.company_name if job else "Unknown",
                "application_routing_mode": job.application_routing_mode if job else "manual_review"
            },
            "status": app.status,
            "applied_datetime": app.created_datetime.isoformat() if hasattr(app, 'created_datetime') and app.created_datetime else None,
            "resume_snapshot_url": app.resume_snapshot_url,
            "cover_letter": app.cover_letter,
            "screening_responses": app.screening_responses,
            "ai_match_score": app.ai_match_score,
            "notes_by_admin": app.notes_by_admin,
            "employer_feedback": app.employer_feedback,
            "interview_datetime": app.interview_datetime.isoformat() if app.interview_datetime else None
        })
    
    return {"data": results, "total": total}

@app.put("/api/job-applications/{app_id}")
def update_job_application(app_id: str, data: dict, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    app = db.query(models.JobApplication).filter(models.JobApplication.id == app_id).first()
    if not app:
        raise HTTPException(status_code=404, detail="Application not found")
        
    if "status" in data:
        app.status = data["status"]
    if "notes_by_admin" in data:
        app.notes_by_admin = data["notes_by_admin"]
    if "interview_datetime" in data:
        from datetime import datetime
        app.interview_datetime = datetime.fromisoformat(data["interview_datetime"]) if data["interview_datetime"] else None
        
    db.commit()
    auth.log_admin_action(db, admin, "UPDATE", "JobApplication", app_id, {"status": app.status})
    return {"status": "success"}

@app.get("/api/jobs")
def get_jobs(
    status: str = None, 
    type: str = None, 
    city: str = None, 
    min_salary: int = None, 
    max_salary: int = None,
    experience: str = None,
    application_routing_mode: str = None,
    created_start: str = None,
    created_end: str = None,
    db: Session = Depends(get_db)
):
    query = db.query(models.Job).filter(models.Job.is_active == True)
    
    if application_routing_mode:
        query = query.filter(models.Job.application_routing_mode == application_routing_mode)
        
    if created_start:
        from datetime import datetime
        try:
            start_dt = datetime.strptime(created_start, "%Y-%m-%d")
            query = query.filter(models.Job.created_datetime >= start_dt)
        except ValueError:
            pass
            
    if created_end:
        from datetime import datetime
        try:
            end_dt = datetime.strptime(created_end, "%Y-%m-%d").replace(hour=23, minute=59, second=59)
            query = query.filter(models.Job.created_datetime <= end_dt)
        except ValueError:
            pass
            
    if status:
        query = query.filter(models.Job.status == status)
    if type:
        query = query.filter(models.Job.job_type == type)
    if min_salary is not None:
        query = query.filter(models.Job.salary_max >= min_salary)
    if max_salary is not None:
        query = query.filter(models.Job.salary_min <= max_salary)
    
    from sqlalchemy import cast, String
    if city:
        query = query.filter(cast(models.Job.location, String).ilike(f"%{city}%"))
        
    if experience:
        if experience == 'Fresher (0 yrs)':
            query = query.filter(models.Job.experience_required_years == 0)
        elif experience == '1-3 Years':
            query = query.filter(models.Job.experience_required_years <= 3)
        elif experience == '3-5 Years':
            query = query.filter(models.Job.experience_required_years >= 3)
        elif experience == '5+ Years':
            query = query.filter(models.Job.experience_required_years >= 5)
            
    jobs = query.order_by(models.Job.created_datetime.desc()).all()
    
    results = []
    for j in jobs:
        j_dict = {c.name: getattr(j, c.name) for c in j.__table__.columns}
        j_dict['applicants_count'] = db.query(models.JobApplication).filter(models.JobApplication.job_id == j.id).count()
        results.append(j_dict)
        
    return results

@app.get("/api/admin/jobs")
def get_admin_jobs(
    page: int = 1,
    limit: int = 10,
    search: Optional[str] = None,
    status: Optional[str] = None, 
    type: Optional[str] = None, 
    city: Optional[str] = None, 
    min_salary: Optional[int] = None, 
    max_salary: Optional[int] = None,
    experience: Optional[str] = None,
    application_routing_mode: Optional[str] = None,
    created_start: Optional[str] = None,
    created_end: Optional[str] = None,
    db: Session = Depends(get_db),
    admin: str = Depends(auth.get_current_admin)
):
    query = db.query(models.Job).filter(models.Job.is_active == True)
    
    if search:
        from sqlalchemy import cast, String
        query = query.filter(
            models.Job.title.ilike(f"%{search}%") | 
            models.Job.company.ilike(f"%{search}%") |
            cast(models.Job.location, String).ilike(f"%{search}%")
        )
        
    if application_routing_mode:
        query = query.filter(models.Job.application_routing_mode == application_routing_mode)
        
    if created_start:
        from datetime import datetime
        try:
            start_dt = datetime.strptime(created_start, "%Y-%m-%d")
            query = query.filter(models.Job.created_datetime >= start_dt)
        except ValueError:
            pass
            
    if created_end:
        from datetime import datetime
        try:
            end_dt = datetime.strptime(created_end, "%Y-%m-%d").replace(hour=23, minute=59, second=59)
            query = query.filter(models.Job.created_datetime <= end_dt)
        except ValueError:
            pass
            
    if status:
        query = query.filter(models.Job.status == status)
    if type:
        query = query.filter(models.Job.job_type == type)
    if min_salary is not None:
        query = query.filter(models.Job.salary_max >= min_salary)
    if max_salary is not None:
        query = query.filter(models.Job.salary_min <= max_salary)
    
    from sqlalchemy import cast, String
    if city:
        query = query.filter(cast(models.Job.location, String).ilike(f"%{city}%"))
        
    if experience:
        if experience == 'Fresher (0 yrs)':
            query = query.filter(models.Job.experience_required_years == 0)
        elif experience == '1-3 Years':
            query = query.filter(models.Job.experience_required_years <= 3)
        elif experience == '3-5 Years':
            query = query.filter(models.Job.experience_required_years >= 3)
        elif experience == '5+ Years':
            query = query.filter(models.Job.experience_required_years >= 5)

    total = query.count()
    jobs = query.order_by(models.Job.created_datetime.desc()).offset((page - 1) * limit).limit(limit).all()
    
    results = []
    for j in jobs:
        j_dict = {c.name: getattr(j, c.name) for c in j.__table__.columns}
        j_dict['applicants_count'] = db.query(models.JobApplication).filter(models.JobApplication.job_id == j.id).count()
        results.append(j_dict)
        
    return {"data": results, "total": total}

@app.get("/api/jobs/locations", response_model=list[str])
def get_job_locations(db: Session = Depends(get_db)):
    jobs = db.query(models.Job.location).filter(
        models.Job.is_active == True,
        models.Job.location != None
    ).all()
    
    unique_cities = set()
    for (loc,) in jobs:
        if isinstance(loc, dict) and loc.get("city"):
            unique_cities.add(loc["city"].strip())
        elif isinstance(loc, str) and loc.strip():
            unique_cities.add(loc.strip())
            
    return sorted(list(unique_cities))



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

@app.get("/api/admin/tests")
def get_admin_tests(
    page: int = 1,
    limit: int = 10,
    search: Optional[str] = None,
    profession: Optional[str] = None,
    test_type: Optional[str] = None,
    category: Optional[str] = None,
    status: Optional[str] = None,
    db: Session = Depends(get_db),
    admin: str = Depends(auth.get_current_admin)
):
    query = db.query(models.Test).filter(models.Test.is_active == True)
    
    if search:
        query = query.filter(
            models.Test.title.ilike(f"%{search}%") | 
            models.Test.description.ilike(f"%{search}%") | 
            models.Test.provider_name.ilike(f"%{search}%")
        )
        
    if profession:
        query = query.filter(models.Test.tag.ilike(f"%{profession}%"))
        
    if test_type:
        query = query.filter(models.Test.test_type == test_type)
        
    if category:
        query = query.filter(models.Test.category == category)
        
    if status:
        if status == 'draft':
            query = query.filter((models.Test.status == 'draft') | (models.Test.status == None))
        else:
            query = query.filter(models.Test.status == status)

    total = query.count()
    tests = query.order_by(models.Test.created_datetime.desc()).offset((page - 1) * limit).limit(limit).all()
    
    return {"data": tests, "total": total}

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

@app.get("/api/tests/{test_id}/questions", response_model=list[schemas.TestQuestionModel])
def get_test_questions(test_id: str, db: Session = Depends(get_db)):
    return db.query(models.TestQuestion).filter(models.TestQuestion.test_id == test_id).order_by(models.TestQuestion.order_index).all()

@app.post("/api/tests/{test_id}/questions", response_model=schemas.TestQuestionModel)
def create_test_question(test_id: str, question: schemas.TestQuestionCreate, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    data = question.model_dump()
    data["test_id"] = test_id
    db_question = models.TestQuestion(**data)
    db.add(db_question)
    db.commit()
    db.refresh(db_question)
    auth.log_admin_action(db, admin, "CREATE", "TestQuestion", str(db_question.id))
    return db_question

@app.put("/api/tests/{test_id}/questions/{question_id}", response_model=schemas.TestQuestionModel)
def update_test_question(test_id: str, question_id: str, question_update: schemas.TestQuestionUpdate, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    db_question = db.query(models.TestQuestion).filter(models.TestQuestion.id == question_id, models.TestQuestion.test_id == test_id).first()
    if not db_question:
        raise HTTPException(status_code=404, detail="Question not found")
    for key, value in question_update.model_dump(exclude_unset=True).items():
        setattr(db_question, key, value)
    db.commit()
    db.refresh(db_question)
    auth.log_admin_action(db, admin, "UPDATE", "TestQuestion", question_id)
    return db_question

@app.delete("/api/tests/{test_id}/questions/{question_id}")
def delete_test_question(test_id: str, question_id: str, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    db_question = db.query(models.TestQuestion).filter(models.TestQuestion.id == question_id, models.TestQuestion.test_id == test_id).first()
    if not db_question:
        raise HTTPException(status_code=404, detail="Question not found")
    db.delete(db_question)
    db.commit()
    auth.log_admin_action(db, admin, "DELETE", "TestQuestion", question_id)
    return {"status": "success"}

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
def get_professionals(skip: int = 0, limit: int = 50, profession: str = None, location_city: str = None, search: str = None, db: Session = Depends(get_db)):
    query = db.query(
        models.Professional,
        func.count(models.ProfessionalReview.id).label("reviews_count"),
        func.avg(models.ProfessionalReview.rating).label("avg_rating")
    ).outerjoin(
        models.ProfessionalReview, 
        models.ProfessionalReview.professional_id == models.Professional.id
    ).filter(
        models.Professional.is_active == True
    )

    if profession and profession != "All":
        query = query.filter(models.Professional.profession == profession)
    if location_city and location_city != "All":
        query = query.filter(models.Professional.location_city == location_city)
    if search:
        search_term = f"%{search}%"
        query = query.filter(
            or_(
                models.Professional.name.ilike(search_term),
                models.Professional.specialty.ilike(search_term),
                models.Professional.clinic.ilike(search_term)
            )
        )

    results = query.group_by(
        models.Professional.id
    ).order_by(
        models.Professional.is_featured.desc(),
        models.Professional.name.asc()
    ).offset(skip).limit(limit).all()
    
    professionals = []
    for prof, reviews_count, avg_rating in results:
        prof.reviews = reviews_count or 0
        prof.rating = float(avg_rating) if avg_rating is not None else prof.default_rating
        professionals.append(prof)
        
    return professionals

@app.get("/api/admin/professionals")
def get_admin_professionals(
    page: int = 1,
    limit: int = 10,
    search: Optional[str] = None,
    profession: Optional[str] = None,
    is_active: Optional[str] = None,
    db: Session = Depends(get_db),
    admin: str = Depends(auth.get_current_admin)
):
    query = db.query(models.Professional)
    
    if search:
        search_term = f"%{search}%"
        query = query.filter(
            or_(
                models.Professional.name.ilike(search_term),
                models.Professional.specialty.ilike(search_term),
                models.Professional.clinic.ilike(search_term)
            )
        )
        
    if profession and profession != "All":
        query = query.filter(models.Professional.profession == profession)
        
    if is_active and is_active != "All":
        if is_active == "Active":
            query = query.filter(models.Professional.is_active == True)
        elif is_active == "Inactive":
            query = query.filter(models.Professional.is_active == False)
            
    total = query.count()
    
    # Calculate offset
    skip = (page - 1) * limit
    professionals = query.order_by(
        models.Professional.is_featured.desc(),
        models.Professional.name.asc()
    ).offset(skip).limit(limit).all()
    
    import math
    return {
        "items": professionals,
        "total": total,
        "page": page,
        "pages": math.ceil(total / limit) if limit > 0 else 0
    }

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

@app.get("/api/professionals/{professional_id}/booked-slots", response_model=list[str])
def get_professional_booked_slots(professional_id: str, date: str, db: Session = Depends(get_db)):
    appointments = db.query(models.ProfessionalAppointment).filter(
        models.ProfessionalAppointment.professional_id == professional_id,
        models.ProfessionalAppointment.appointment_date == date,
        models.ProfessionalAppointment.status != "cancelled",
        models.ProfessionalAppointment.is_active == True
    ).all()
    
    return [appt.appointment_time.strftime("%I:%M %p") for appt in appointments]

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
@app.get("/api/users/filters/education")
def get_unique_educations(db: Session = Depends(get_db)):
    from sqlalchemy import cast, String
    profiles = db.query(models.StudentProfile.education_history).filter(models.StudentProfile.education_history != None).all()
    unique_educations = set()
    for p in profiles:
        if not p.education_history:
            continue
        for edu in p.education_history:
            degree = edu.get("degree")
            if degree and isinstance(degree, str):
                unique_educations.add(degree)
    
    return sorted(list(unique_educations))

@app.get("/api/users")
def get_users(
    city: str = None,
    goal_id: str = None,
    education: str = None,
    joined_start: str = None,
    joined_end: str = None,
    min_profile_score: int = None,
    search: str = None,
    page: int = 1,
    limit: int = 10,
    db: Session = Depends(get_db),
    admin: str = Depends(auth.get_current_admin)
):
    query = db.query(models.User).outerjoin(models.StudentProfile).filter(
        models.User.is_active == True,
        models.User.role == "student"
    )
    
    # Filters
    if city:
        city_term = f"%{city}%"
        query = query.filter(models.StudentProfile.city.ilike(city_term))
        
    if goal_id:
        query = query.filter(models.StudentProfile.goal_id == goal_id)
        
    if education:
        from sqlalchemy import cast, String
        # Cast JSON column to string to search inside the array
        query = query.filter(cast(models.StudentProfile.education_history, String).ilike(f"%{education}%"))
        
    if joined_start:
        from datetime import datetime
        try:
            start_dt = datetime.strptime(joined_start, "%Y-%m-%d")
            query = query.filter(models.User.created_datetime >= start_dt)
        except ValueError:
            pass
            
    if joined_end:
        from datetime import datetime
        try:
            end_dt = datetime.strptime(joined_end, "%Y-%m-%d").replace(hour=23, minute=59, second=59)
            query = query.filter(models.User.created_datetime <= end_dt)
        except ValueError:
            pass
            
    if min_profile_score is not None:
        query = query.filter(models.StudentProfile.profile_completion_score >= min_profile_score)
        
    # Search
    if search:
        search_term = f"%{search}%"
        from sqlalchemy import or_
        query = query.filter(
            or_(
                models.User.full_name.ilike(search_term),
                models.User.email.ilike(search_term),
                models.User.mobile_number.ilike(search_term)
            )
        )
        
    total = query.count()
    offset = (page - 1) * limit
    users = query.order_by(models.User.created_datetime.desc()).offset(offset).limit(limit).all()
    
    results = []
    for user in users:
        sp = user.student_profile
        results.append({
            "id": str(user.id),
            "full_name": user.full_name,
            "email": user.email,
            "mobile_number": user.mobile_number,
            "city": sp.city if sp else None,
            "goal": {"name": sp.goal.name} if sp and sp.goal else None,
            "experience_years": sp.years_of_experience if sp else 0,
            "profile_score": sp.profile_completion_score if sp else 0,
            "profile_image_url": sp.profile_image_url if sp else None,
            "created_datetime": user.created_datetime.isoformat() if hasattr(user, 'created_datetime') and user.created_datetime else None
        })
        
    return {
        "data": results,
        "total": total,
        "page": page,
        "limit": limit,
        "totalPages": (total + limit - 1) // limit
    }

from fastapi.encoders import jsonable_encoder

@app.get("/api/users/{user_id}/details")
def get_user_details(user_id: str, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    user = db.query(models.User).filter(models.User.id == user_id, models.User.is_active == True).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    sp = user.student_profile
    
    # Flatten user and student_profile for the frontend
    user_dict = jsonable_encoder(user)
    if sp:
        sp_dict = jsonable_encoder(sp)
        # Do not overwrite base user fields
        for field in ['id', 'created_datetime', 'is_active', 'deleted_datetime']:
            sp_dict.pop(field, None)
            
        # Add nested objects explicitly
        sp_dict['goal'] = jsonable_encoder(sp.goal) if sp.goal else None
        sp_dict['acquisition_source'] = sp.acquisition_source.name if sp.acquisition_source else None
        user_dict.update(sp_dict)
        
    job_apps = []
    test_attempts = []
    if sp:
        job_apps = db.query(models.JobApplication).filter(models.JobApplication.student_profile_id == sp.id).all()
        test_attempts = db.query(models.TestAttempt).filter(models.TestAttempt.student_profile_id == sp.id).all()
    prof_appts = db.query(models.ProfessionalAppointment).filter(models.ProfessionalAppointment.user_id == user_id).all()
    
    job_apps_enriched = []
    for app in job_apps:
        job = db.query(models.Job).filter(models.Job.id == app.job_id).first()
        app_dict = jsonable_encoder(app)
        app_dict['job'] = jsonable_encoder(job) if job else None
        job_apps_enriched.append(app_dict)
        
    test_attempts_enriched = []
    for att in test_attempts:
        test = db.query(models.Test).filter(models.Test.id == att.test_id).first()
        att_dict = jsonable_encoder(att)
        att_dict['test'] = jsonable_encoder(test) if test else None
        test_attempts_enriched.append(att_dict)
        
    prof_appts_enriched = []
    for apt in prof_appts:
        prof = db.query(models.Professional).filter(models.Professional.id == apt.professional_id).first()
        apt_dict = jsonable_encoder(apt)
        apt_dict['doctor'] = jsonable_encoder(prof) if prof else None
        prof_appts_enriched.append(apt_dict)
        
    resume_sessions = db.query(models.ResumeSession).filter(models.ResumeSession.user_id == user_id).order_by(models.ResumeSession.id.desc()).all()
    resume_sessions_encoded = [jsonable_encoder(rs) for rs in resume_sessions]
        
    return {
        "user": user_dict,
        "job_applications": job_apps_enriched,
        "test_attempts": test_attempts_enriched,
        "professional_appointments": prof_appts_enriched,
        "resume_sessions": resume_sessions_encoded
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

@app.delete("/api/users/me/appointments/{appointment_id}")
def cancel_appointment(appointment_id: str, db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_user)):
    appointment = db.query(models.ProfessionalAppointment).filter(
        models.ProfessionalAppointment.id == appointment_id,
        models.ProfessionalAppointment.user_id == current_user.id
    ).first()
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")
    if appointment.status in ["completed", "cancelled"]:
        raise HTTPException(status_code=400, detail="Cannot cancel a completed or already cancelled appointment.")
    
    appointment.status = "cancelled"
    db.commit()
    db.refresh(appointment)
    return {"status": "success", "message": "Appointment cancelled."}

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
        system_prompt = """You are an educational AI that analyses a student's test attempt and writes a personalised performance report. Always use second-person voice ('You'). Be concise, encouraging, and constructive.

Return exactly and ONLY a JSON object with this structure:
{
  "overall_insight": "string, 2-3 sentences, student voice",
  "weak_areas": [
    { "topic": "string", "subtopic": "string", "accuracy": number (0-100) }
  ],
  "strong_areas": [
    { "topic": "string", "subtopic": "string", "accuracy": number (0-100) }
  ],
  "time_management": "string, 1 sentence"
}
"""
        score = attempt_req.total_score or 0
        total_q = attempt_req.max_score or attempt_req.total_questions or 1
        pct = round((score / total_q) * 100)
        time_taken = attempt_req.time_taken_seconds or 0
        
        q_data_lines = []
        for q in attempt_req.question_responses:
            if not isinstance(q, dict): continue
            # If front-end sends question_text, use it, else generic
            q_text = q.get('question_text', 'Unknown')[:100]
            q_data_lines.append(f"- Question: {q_text}... | Correct: {q.get('is_correct', False)} | Time: {q.get('time_spent_seconds', 0)}s")
            
        user_prompt = f"""Test: {test.title}
Total Questions: {total_q}
Student Score: {score} / {total_q} ({pct}%)
Total Time Taken: {time_taken}s

Questions answered:
{chr(10).join(q_data_lines[:30])}
"""
        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(
                    "https://api.openai.com/v1/chat/completions",
                    headers={"Content-Type": "application/json", "Authorization": f"Bearer {api_key}"},
                    json={
                        "model": "gpt-4o-mini",
                        "response_format": {"type": "json_object"},
                        "messages": [
                            {"role": "system", "content": system_prompt},
                            {"role": "user", "content": user_prompt}
                        ],
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
    from sqlalchemy import extract, func
    from datetime import datetime, time, timedelta

    start_date = None
    if filter == "Today":
        start_date = datetime.combine(today, time.min)
    elif filter == "Yesterday":
        start_date = datetime.combine(today - timedelta(days=1), time.min)
    elif filter == "This Week":
        monday = today - timedelta(days=today.weekday())
        start_date = datetime.combine(monday, time.min)
    elif filter == "This Month":
        start_date = datetime.combine(today.replace(day=1), time.min)
    elif filter == "This Year":
        start_date = datetime.combine(today.replace(month=1, day=1), time.min)

    # Base queries (Only Students)
    users_q = db.query(models.User).filter(models.User.is_active == True, models.User.role == 'student')
    job_apps_q = db.query(models.JobApplication).join(models.StudentProfile).join(models.User).filter(models.JobApplication.is_active == True, models.User.role == 'student')
    tests_q = db.query(models.TestAttempt).join(models.StudentProfile).join(models.User).filter(models.User.role == 'student')
    appts_q = db.query(models.ProfessionalAppointment).join(models.User).filter(models.User.role == 'student')

    # Apply date filters
    if start_date:
        users_q = users_q.filter(models.User.created_datetime >= start_date)
        job_apps_q = job_apps_q.filter(models.JobApplication.created_datetime >= start_date)
        tests_q = tests_q.filter(models.TestAttempt.created_datetime >= start_date)
        appts_q = appts_q.filter(models.ProfessionalAppointment.created_datetime >= start_date)

    if filter == "Yesterday":
        end_date = datetime.combine(today, time.min)
        users_q = users_q.filter(models.User.created_datetime < end_date)
        job_apps_q = job_apps_q.filter(models.JobApplication.created_datetime < end_date)
        tests_q = tests_q.filter(models.TestAttempt.created_datetime < end_date)
        appts_q = appts_q.filter(models.ProfessionalAppointment.created_datetime < end_date)

    total_users = users_q.count()
    total_job_applications = job_apps_q.count()
    tests_taken = tests_q.count()
    appointments = appts_q.count()
    
    # 1. Activity Trends
    chart_data = []
    if filter in ["Today", "Yesterday"]:
        for i in range(6, -1, -1):
            target_date = today - timedelta(days=i)
            day_name = target_date.strftime("%b %d")
            users_count = db.query(models.User).filter(func.date(models.User.created_datetime) == target_date, models.User.is_active == True, models.User.role == 'student').count()
            chart_data.append({"name": day_name, "users": users_count})
            
    elif filter == "This Week":
        monday = today - timedelta(days=today.weekday())
        for i in range(7):
            target_date = monday + timedelta(days=i)
            day_name = target_date.strftime("%b %d")
            users_count = db.query(models.User).filter(func.date(models.User.created_datetime) == target_date, models.User.is_active == True, models.User.role == 'student').count()
            chart_data.append({"name": day_name, "users": users_count})
            
    elif filter == "This Month":
        for i in range(1, today.day + 1):
            target_date = today.replace(day=i)
            day_name = target_date.strftime("%b %d")
            users_count = db.query(models.User).filter(func.date(models.User.created_datetime) == target_date, models.User.is_active == True, models.User.role == 'student').count()
            chart_data.append({"name": day_name, "users": users_count})
            
    elif filter == "This Year":
        import calendar
        for m in range(1, today.month + 1):
            y = today.year
            day_name = f"{calendar.month_abbr[m]} {y}"
            users_count = db.query(models.User).filter(extract('month', models.User.created_datetime) == m, extract('year', models.User.created_datetime) == y, models.User.is_active == True, models.User.role == 'student').count()
            chart_data.append({"name": day_name, "users": users_count})
            
    elif filter == "All Time":
        for i in range(4, -1, -1):
            y = today.year - i
            day_name = str(y)
            users_count = db.query(models.User).filter(extract('year', models.User.created_datetime) == y, models.User.is_active == True, models.User.role == 'student').count()
            chart_data.append({"name": day_name, "users": users_count})

    # 2. Profile Completion Breakdown
    # Score is 0-100
    completion_data = db.query(models.StudentProfile.profile_completion_score).join(models.User).filter(models.User.role == 'student')
    if start_date:
        completion_data = completion_data.filter(models.User.created_datetime >= start_date)
    scores = [r[0] or 0 for r in completion_data.all()]
    
    completion_breakdown = [
        {"name": "0-25%", "value": len([s for s in scores if s <= 25])},
        {"name": "26-50%", "value": len([s for s in scores if 25 < s <= 50])},
        {"name": "51-75%", "value": len([s for s in scores if 50 < s <= 75])},
        {"name": "76-100%", "value": len([s for s in scores if s > 75])}
    ]

    # 3. Students by Goal
    goal_data = db.query(models.Goal.name, func.count(models.StudentProfile.id).label("count"))\
        .join(models.StudentProfile, models.Goal.id == models.StudentProfile.goal_id)\
        .join(models.User, models.User.id == models.StudentProfile.user_id)\
        .filter(models.User.role == 'student')
    if start_date:
        goal_data = goal_data.filter(models.User.created_datetime >= start_date)
    goal_data = goal_data.group_by(models.Goal.name).order_by(func.count(models.StudentProfile.id).desc()).limit(10).all()
    users_by_goal = [{"name": g[0], "value": g[1]} for g in goal_data]

    # 4. User Acquisition Sources
    acq_data = db.query(models.AcquisitionSource.name, func.count(models.StudentProfile.id).label("count"))\
        .join(models.StudentProfile, models.AcquisitionSource.id == models.StudentProfile.acquisition_source_id)\
        .join(models.User, models.User.id == models.StudentProfile.user_id)\
        .filter(models.User.role == 'student')
    if start_date:
        acq_data = acq_data.filter(models.User.created_datetime >= start_date)
    acq_data = acq_data.group_by(models.AcquisitionSource.name).all()
    acquisition_sources = [{"name": a[0], "value": a[1]} for a in acq_data]

    # 5. Experience Levels
    exp_data = db.query(models.StudentProfile.years_of_experience).join(models.User).filter(models.User.role == 'student')
    if start_date:
        exp_data = exp_data.filter(models.User.created_datetime >= start_date)
    exps = [r[0] or 0.0 for r in exp_data.all()]
    
    experience_levels = [
        {"name": "Fresher", "value": len([e for e in exps if e == 0])},
        {"name": "Junior (1-3)", "value": len([e for e in exps if 0 < e <= 3])},
        {"name": "Senior (3+)", "value": len([e for e in exps if e > 3])}
    ]

    # 6. Application Success Rate
    job_apps_data = db.query(models.JobApplication.status, func.count(models.JobApplication.id).label("count"))\
        .join(models.StudentProfile, models.StudentProfile.id == models.JobApplication.student_profile_id)\
        .join(models.User, models.User.id == models.StudentProfile.user_id)\
        .filter(models.User.role == 'student')
    if start_date:
        job_apps_data = job_apps_data.filter(models.JobApplication.created_datetime >= start_date)
    job_apps_data = job_apps_data.group_by(models.JobApplication.status).all()
    application_success = [{"name": j[0].capitalize() if j[0] else "Pending", "value": j[1]} for j in job_apps_data]

    return {
        "totals": {
            "users": total_users,
            "jobs": total_job_applications, 
            "job_applications": total_job_applications,
            "tests": tests_taken,
            "appointments": appointments
        },
        "chart_data": chart_data,
        "completion_breakdown": completion_breakdown,
        "users_by_goal": users_by_goal,
        "acquisition_sources": acquisition_sources,
        "experience_levels": experience_levels,
        "application_success": application_success
    }

# --- Admin Appointments Management ---
@app.get("/api/admin/appointments", response_model=list[schemas.ProfessionalAppointment])
def admin_get_appointments(db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    # Returns all appointments with user and doctor relations
    appointments = db.query(models.ProfessionalAppointment).filter(models.ProfessionalAppointment.is_active == True).all()
    return appointments

@app.put("/api/admin/appointments/{appointment_id}/status", response_model=schemas.ProfessionalAppointment)
def admin_update_appointment_status(appointment_id: str, status: str, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    appointment = db.query(models.ProfessionalAppointment).filter(models.ProfessionalAppointment.id == appointment_id).first()
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")
    
    appointment.status = status
    
    # Push Notification logic if assigned
    if status == "sent_to_doctor":
        from datetime import datetime
        appointment.professional_notified_at = datetime.utcnow()
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
def admin_get_all_test_attempts(
    page: int = 1,
    limit: int = 10,
    search: Optional[str] = None,
    user_type: Optional[str] = None,
    status: Optional[str] = None,
    result: Optional[str] = None,
    score_above: Optional[float] = None,
    date_from: Optional[str] = None,
    date_to: Optional[str] = None,
    db: Session = Depends(get_db),
    admin: str = Depends(auth.get_current_admin)
):
    query = db.query(models.TestAttempt).filter(models.TestAttempt.is_active == True)
    
    if status:
        query = query.filter(models.TestAttempt.status == status)
        
    if user_type == "Guest":
        query = query.filter(models.TestAttempt.user_id == None, models.TestAttempt.guest_info != None)
    elif user_type == "Registered":
        query = query.filter(models.TestAttempt.user_id != None)
        
    if result == "passed":
        query = query.filter((models.TestAttempt.total_score / models.TestAttempt.max_score * 100) >= 70)
    elif result == "failed":
        query = query.filter((models.TestAttempt.total_score / models.TestAttempt.max_score * 100) < 70)
        
    if score_above is not None:
        query = query.filter((models.TestAttempt.total_score / models.TestAttempt.max_score * 100) >= score_above)
        
    if date_from:
        from datetime import datetime
        try:
            dt_from = datetime.strptime(date_from, "%Y-%m-%d")
            query = query.filter(models.TestAttempt.created_datetime >= dt_from)
        except ValueError:
            pass
            
    if date_to:
        from datetime import datetime, timedelta
        try:
            dt_to = datetime.strptime(date_to, "%Y-%m-%d") + timedelta(days=1)
            query = query.filter(models.TestAttempt.created_datetime < dt_to)
        except ValueError:
            pass
        
    if search:
        query = query.join(models.User, models.TestAttempt.user_id == models.User.id, isouter=True) \
                     .join(models.Test, models.TestAttempt.test_id == models.Test.id) \
                     .filter(
                         models.User.full_name.ilike(f"%{search}%") | 
                         models.User.email.ilike(f"%{search}%") |
                         models.Test.title.ilike(f"%{search}%")
                     )
                     
    total = query.count()
    attempts = query.order_by(models.TestAttempt.created_datetime.desc()).offset((page - 1) * limit).limit(limit).all()
    
    result = []
    for att in attempts:
        user = db.query(models.User).filter(models.User.id == att.user_id).first() if att.user_id else None
        test = db.query(models.Test).filter(models.Test.id == att.test_id).first()
        total_questions = len(test.questions) if test and test.questions else 0
        
        user_data = None
        if user:
            user_data = {"id": str(user.id), "full_name": user.full_name, "email": user.email, "mobile_number": user.mobile_number, "city": user.student_profile.city if user.student_profile else "", "type": "Registered"}
        elif att.guest_info:
            user_data = {"id": "guest", "full_name": att.guest_info.get("name", "Guest"), "email": att.guest_info.get("email", ""), "mobile_number": att.guest_info.get("phone", ""), "city": att.guest_info.get("city", ""), "type": "Guest"}
            
        result.append({
            "id": str(att.id),
            "score": att.total_score,
            "total_questions": total_questions,
            "attempted_at": att.created_datetime.isoformat() if att.created_datetime else None,
            "status": att.status,
            "user": user_data,
            "test": {"id": str(test.id), "title": test.title, "tag": test.tag, "difficulty": test.difficulty} if test else None,
            "question_responses": att.question_responses,
            "ai_report": att.ai_report,
            "time_taken_seconds": att.time_taken_seconds
        })
    return {"data": result, "total": total}


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

# --- Settings Endpoints ---

@app.get("/api/goals", response_model=list[schemas.Goal])
def get_goals(db: Session = Depends(get_db)):
    return db.query(models.Goal).filter(models.Goal.is_active == True).all()

@app.post("/api/settings/goals", response_model=schemas.Goal)
def create_goal(goal: schemas.GoalCreate, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    db_goal = models.Goal(name=goal.name)
    db.add(db_goal)
    db.commit()
    db.refresh(db_goal)
    auth.log_admin_action(db, admin, "CREATE", "Goals", str(db_goal.id))
    return db_goal

@app.delete("/api/settings/goals/{goal_id}")
def delete_goal(goal_id: str, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    db_goal = db.query(models.Goal).filter(models.Goal.id == goal_id).first()
    if not db_goal:
        raise HTTPException(status_code=404, detail="Goal not found")
    db_goal.is_active = False
    db.commit()
    auth.log_admin_action(db, admin, "DELETE", "Goals", goal_id)
    return {"message": "Goal deleted successfully"}

@app.get("/api/test-categories", response_model=list[schemas.TestCategory])
def get_test_categories(db: Session = Depends(get_db)):
    return db.query(models.TestCategory).filter(models.TestCategory.is_active == True).all()

@app.post("/api/settings/test-categories", response_model=schemas.TestCategory)
def create_test_category(category: schemas.TestCategoryCreate, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    db_cat = models.TestCategory(name=category.name)
    db.add(db_cat)
    db.commit()
    db.refresh(db_cat)
    auth.log_admin_action(db, admin, "CREATE", "TestCategories", str(db_cat.id))
    return db_cat

@app.delete("/api/settings/test-categories/{cat_id}")
def delete_test_category(cat_id: str, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    db_cat = db.query(models.TestCategory).filter(models.TestCategory.id == cat_id).first()
    if not db_cat:
        raise HTTPException(status_code=404, detail="Category not found")
    db_cat.is_active = False
    db.commit()
    auth.log_admin_action(db, admin, "DELETE", "TestCategories", cat_id)
    return {"message": "Category deleted successfully"}

@app.get("/api/acquisition-sources", response_model=list[schemas.AcquisitionSource])
def get_acquisition_sources(db: Session = Depends(get_db)):
    return db.query(models.AcquisitionSource).filter(models.AcquisitionSource.is_active == True).all()

@app.post("/api/settings/acquisition-sources", response_model=schemas.AcquisitionSource)
def create_acquisition_source(source: schemas.AcquisitionSourceCreate, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    db_source = models.AcquisitionSource(name=source.name)
    db.add(db_source)
    db.commit()
    db.refresh(db_source)
    auth.log_admin_action(db, admin, "CREATE", "AcquisitionSources", str(db_source.id))
    return db_source

@app.delete("/api/settings/acquisition-sources/{source_id}")
def delete_acquisition_source(source_id: str, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    db_source = db.query(models.AcquisitionSource).filter(models.AcquisitionSource.id == source_id).first()
    if not db_source:
        raise HTTPException(status_code=404, detail="Acquisition Source not found")
    db_source.is_active = False
    db.commit()
    auth.log_admin_action(db, admin, "DELETE", "AcquisitionSources", source_id)
    return {"message": "Acquisition Source deleted successfully"}

@app.post("/api/settings/staff")
def create_staff(req: schemas.StaffCreateRequest, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    if req.role not in ["admin", "staff", "manager"]:
        raise HTTPException(status_code=400, detail="Invalid role")
        
    try:
        # 1. Create Firebase User
        fb_user = firebase_auth.create_user(
            email=req.email,
            password=req.password,
            display_name=req.full_name
        )
        
        # 2. Create PostgreSQL User
        db_user = models.User(
            email=req.email,
            full_name=req.full_name,
            role=req.role,
            firebase_uid=fb_user.uid
        )
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        
        auth.log_admin_action(db, admin, "CREATE", "Staff", str(db_user.id))
        return {"message": f"{req.role.capitalize()} account created successfully!"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


import requests

@app.get("/api/pincodes/{pincode}", response_model=list[schemas.PincodeDirectory])
def get_pincode_info(pincode: str, db: Session = Depends(get_db)):
    # 1. Check local DB cache
    local_data = db.query(models.PincodeDirectory).filter(models.PincodeDirectory.pincode == pincode).all()
    if local_data:
        return local_data
    
    # 2. If not found, fetch from official API and seed the DB!
    try:
        response = requests.get(f"https://api.postalpincode.in/pincode/{pincode}", headers={"User-Agent": "Mozilla/5.0"})
        if response.status_code == 200:
            data = response.json()
            if data and data[0].get("Status") == "Success":
                new_records = []
                for post_office in data[0].get("PostOffice", []):
                    record = models.PincodeDirectory(
                        pincode=pincode,
                        area=post_office.get("Name"),
                        city=post_office.get("District"),
                        state=post_office.get("State")
                    )
                    db.add(record)
                    new_records.append(record)
                db.commit()
                return new_records
    except Exception as e:
        print(f"Failed to fetch pincode {pincode}: {e}")
        
    return []

@app.get("/api/skills", response_model=list[schemas.SkillDictionary])
def search_skills(q: str = "", db: Session = Depends(get_db)):
    query = db.query(models.SkillDictionary)
    if q:
        # Case-insensitive fuzzy matching
        query = query.filter(models.SkillDictionary.name.ilike(f"%{q}%"))
    return query.order_by(models.SkillDictionary.name).limit(20).all()

@app.post("/api/skills", response_model=schemas.SkillDictionary)
def create_skill(skill: schemas.SkillDictionaryBase, db: Session = Depends(get_db)):
    # Check if exists (case insensitive)
    existing = db.query(models.SkillDictionary).filter(models.SkillDictionary.name.ilike(skill.name)).first()
    if existing:
        return existing
        
    db_skill = models.SkillDictionary(**skill.model_dump())
    db.add(db_skill)
    db.commit()
    db.refresh(db_skill)
    return db_skill

from pydantic import BaseModel
class SkillMergeRequest(BaseModel):
    source_skill_names: list[str]
    target_skill_name: str

@app.put("/api/skills/{skill_id}", response_model=schemas.SkillDictionary)
def update_skill(skill_id: str, skill_update: schemas.SkillDictionaryBase, db: Session = Depends(get_db)):
    db_skill = db.query(models.SkillDictionary).filter(models.SkillDictionary.id == skill_id).first()
    if not db_skill:
        raise HTTPException(status_code=404, detail="Skill not found")
    
    # Update properties
    db_skill.name = skill_update.name
    if hasattr(skill_update, 'is_approved'):
        db_skill.is_approved = skill_update.is_approved
    
    db.commit()
    db.refresh(db_skill)
    return db_skill

@app.post("/api/skills/merge")
def merge_skills(req: SkillMergeRequest, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    # 1. Ensure target skill exists
    target = db.query(models.SkillDictionary).filter(models.SkillDictionary.name.ilike(req.target_skill_name)).first()
    if not target:
        target = models.SkillDictionary(name=req.target_skill_name, is_approved=True)
        db.add(target)
        db.commit()

    # 2. Find all source skills and delete them from SkillDictionary
    for src in req.source_skill_names:
        db.query(models.SkillDictionary).filter(models.SkillDictionary.name.ilike(src)).delete(synchronize_session=False)
    
    # Note: A real database cascade update for JSON arrays (to replace "jva" with "Java" in jobs & profiles)
    # would go here using postgres jsonb functions or iterating records.
    db.commit()
    return {"status": "success", "message": f"Merged {len(req.source_skill_names)} skills into {req.target_skill_name}"}


@app.post("/api/users/{user_id}/suspend")
def toggle_user_suspension(user_id: str, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Toggle active status
    user.is_active = not user.is_active
    db.commit()
    return {"message": "User suspended successfully" if not user.is_active else "User activated successfully", "is_active": user.is_active}


@app.get("/api/test-taxonomy", response_model=list[schemas.QuestionTaxonomyModel])
def get_test_taxonomies(type: Optional[str] = None, db: Session = Depends(get_db)):
    query = db.query(models.QuestionTaxonomy)
    if type:
        query = query.filter(models.QuestionTaxonomy.type == type)
    return query.order_by(models.QuestionTaxonomy.name).all()

@app.post("/api/test-taxonomy", response_model=schemas.QuestionTaxonomyModel)
def create_test_taxonomy(tax: schemas.QuestionTaxonomyCreate, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    existing = db.query(models.QuestionTaxonomy).filter(models.QuestionTaxonomy.type == tax.type, models.QuestionTaxonomy.name == tax.name).first()
    if existing:
        return existing
    db_tax = models.QuestionTaxonomy(**tax.model_dump())
    db.add(db_tax)
    db.commit()
    db.refresh(db_tax)
    auth.log_admin_action(db, admin, "CREATE", "QuestionTaxonomy", str(db_tax.id))
    return db_tax

@app.put("/api/test-taxonomy/{tax_id}", response_model=schemas.QuestionTaxonomyModel)
def update_test_taxonomy(tax_id: str, tax_update: schemas.QuestionTaxonomyUpdate, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    db_tax = db.query(models.QuestionTaxonomy).filter(models.QuestionTaxonomy.id == tax_id).first()
    if not db_tax:
        raise HTTPException(status_code=404, detail="Taxonomy not found")
    db_tax.name = tax_update.name
    db.commit()
    db.refresh(db_tax)
    auth.log_admin_action(db, admin, "UPDATE", "QuestionTaxonomy", tax_id)
    return db_tax

@app.delete("/api/test-taxonomy/{tax_id}")
def delete_test_taxonomy(tax_id: str, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    db_tax = db.query(models.QuestionTaxonomy).filter(models.QuestionTaxonomy.id == tax_id).first()
    if not db_tax:
        raise HTTPException(status_code=404, detail="Taxonomy not found")
    db.delete(db_tax)
    db.commit()
    auth.log_admin_action(db, admin, "DELETE", "QuestionTaxonomy", tax_id)
    return {"status": "success"}

@app.post("/api/test-taxonomy/merge")
def merge_test_taxonomy(req: schemas.MergeTaxonomyRequest, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    # Find all questions with the old source_name
    questions = db.query(models.TestQuestion).filter(getattr(models.TestQuestion, req.type) == req.source_name).all()
    for q in questions:
        setattr(q, req.type, req.target_name)
    
    # Ensure target taxonomy exists
    target = db.query(models.QuestionTaxonomy).filter(models.QuestionTaxonomy.type == req.type, models.QuestionTaxonomy.name == req.target_name).first()
    if not target:
        target = models.QuestionTaxonomy(type=req.type, name=req.target_name)
        db.add(target)
        db.commit()
        
    # Delete the old taxonomy entry
    old_tax = db.query(models.QuestionTaxonomy).filter(models.QuestionTaxonomy.type == req.type, models.QuestionTaxonomy.name == req.source_name).first()
    if old_tax:
        db.delete(old_tax)
        
    db.commit()
    auth.log_admin_action(db, admin, "MERGE", "QuestionTaxonomy", f"Merged {req.source_name} to {req.target_name}")
    return {"status": "success", "updated_count": len(questions)}
