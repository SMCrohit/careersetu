from fastapi import FastAPI, Depends, HTTPException, status, UploadFile, File, Request
from typing import Optional
import io
import re
import uuid
from collections import defaultdict
import openpyxl
from pypdf import PdfReader
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from sqlalchemy import func, or_
from datetime import timedelta, datetime, date
import models, schemas, auth
from database import engine, get_db
from utils import calculate_profile_score

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

def _application_resume(app: models.JobApplication):
    """The resume for an application: the copy saved when applying, else the applicant's current profile resume."""
    snapshot = app.resume_snapshot if isinstance(app.resume_snapshot, dict) else None
    if snapshot and snapshot.get("data"):
        return snapshot, "submitted"
    profile = app.student_profile
    current = profile.resume_data if profile and isinstance(profile.resume_data, dict) else None
    if current and current.get("data"):
        return current, "profile"
    return None, None

def _application_resume_info(app: models.JobApplication) -> dict:
    resume, source = _application_resume(app)
    return {
        "has_resume": resume is not None,
        "resume_filename": (resume.get("filename") or "resume.pdf") if resume else None,
        "resume_source": source,
    }

@app.get("/api/job-applications/{app_id}/resume")
def download_application_resume(app_id: str, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    import base64
    from fastapi.responses import Response
    try:
        app_uuid = uuid.UUID(app_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="Application not found")
    application = db.query(models.JobApplication).filter(models.JobApplication.id == app_uuid).first()
    if not application:
        raise HTTPException(status_code=404, detail="Application not found")
    resume, source = _application_resume(application)
    if not resume:
        raise HTTPException(status_code=404, detail="No resume attached to this application")
    try:
        pdf_bytes = base64.b64decode(resume["data"])
    except Exception:
        raise HTTPException(status_code=422, detail="The stored resume file is corrupted")
    filename = re.sub(r'[^A-Za-z0-9._ -]', '_', resume.get("filename") or "resume.pdf")
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={
            "Content-Disposition": f'inline; filename="{filename}"',
            "X-Resume-Source": source,
            "Access-Control-Expose-Headers": "Content-Disposition, X-Resume-Source",
        },
    )

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
            **_application_resume_info(app),
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

# --- Student job feed ---

EXPERIENCE_RANGES = {
    "Fresher (0 yrs)": (None, 0),
    "1-3 Years": (0, 3),
    "3-5 Years": (3, 5),
    "5+ Years": (5, None),
}

def _published_jobs(db: Session):
    return db.query(models.Job).filter(models.Job.is_active == True, models.Job.status == "published")

def _applied_job_ids(db: Session, user) -> set:
    if not user or not user.student_profile:
        return set()
    rows = db.query(models.JobApplication.job_id).filter(
        models.JobApplication.student_profile_id == user.student_profile.id,
        models.JobApplication.is_active == True,
    ).all()
    return {r[0] for r in rows}

def _jobs_out(db: Session, jobs: list, user) -> list:
    """Serializes jobs with applicants_count and has_applied for the current user."""
    ids = [j.id for j in jobs]
    counts = dict(
        db.query(models.JobApplication.job_id, func.count(models.JobApplication.id))
        .filter(models.JobApplication.job_id.in_(ids))
        .group_by(models.JobApplication.job_id).all()
    ) if ids else {}
    applied = _applied_job_ids(db, user)
    out = []
    for j in jobs:
        d = {c.name: getattr(j, c.name) for c in j.__table__.columns}
        d["applicants_count"] = counts.get(j.id, 0)
        d["has_applied"] = j.id in applied
        out.append(d)
    return out

@app.get("/api/jobs")
def get_jobs(
    page: int = 1,
    limit: int = 10,
    search: Optional[str] = None,
    type: Optional[str] = None,
    work_model: Optional[str] = None,
    city: Optional[str] = None,
    experience: Optional[str] = None,
    min_salary: Optional[int] = None,
    max_salary: Optional[int] = None,
    posted_within_days: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: Optional[models.User] = Depends(auth.get_current_user_optional),
):
    """Published jobs for students, with search, filters and pagination."""
    from sqlalchemy import cast, String
    query = _published_jobs(db)

    if search and search.strip():
        term = f"%{search.strip()}%"
        query = query.filter(
            models.Job.title.ilike(term)
            | models.Job.company_name.ilike(term)
            | cast(models.Job.location, String).ilike(term)
            | cast(models.Job.skills_required, String).ilike(term)
        )
    if type:
        query = query.filter(models.Job.job_type == type)
    if work_model:
        query = query.filter(models.Job.work_model == work_model)
    if city:
        query = query.filter(cast(models.Job.location, String).ilike(f"%{city}%"))
    if experience in EXPERIENCE_RANGES:
        low, high = EXPERIENCE_RANGES[experience]
        if low is None:
            query = query.filter(func.coalesce(models.Job.experience_required_years, 0) == 0)
        else:
            query = query.filter(models.Job.experience_required_years > low)
            if high is not None:
                query = query.filter(models.Job.experience_required_years <= high)
    if min_salary is not None:
        query = query.filter(models.Job.salary_max >= min_salary)
    if max_salary is not None:
        query = query.filter(models.Job.salary_min <= max_salary)
    if posted_within_days:
        query = query.filter(models.Job.created_datetime >= datetime.utcnow() - timedelta(days=posted_within_days))

    page = max(page, 1)
    limit = min(max(limit, 1), 50)
    total = query.count()
    jobs = query.order_by(models.Job.is_featured.desc(), models.Job.created_datetime.desc()) \
                .offset((page - 1) * limit).limit(limit).all()
    return {"data": _jobs_out(db, jobs, current_user), "total": total, "page": page, "limit": limit}

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
            models.Job.company_name.ilike(f"%{search}%") |
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

@app.get("/api/jobs/filters")
def get_job_filter_options(db: Session = Depends(get_db)):
    """Values for the app's job filters, taken from published jobs."""
    rows = _published_jobs(db).with_entities(models.Job.location, models.Job.job_type, models.Job.work_model).all()
    cities, types, models_ = set(), set(), set()
    for loc, job_type, work_model in rows:
        if isinstance(loc, dict) and loc.get("city"):
            cities.add(str(loc["city"]).strip())
        elif isinstance(loc, str) and loc.strip():
            cities.add(loc.strip())
        if job_type:
            types.add(job_type)
        if work_model:
            models_.add(work_model)
    return {"cities": sorted(cities), "job_types": sorted(types), "work_models": sorted(models_)}

@app.get("/api/jobs/{job_id}")
def get_job(job_id: str, db: Session = Depends(get_db),
            current_user: Optional[models.User] = Depends(auth.get_current_user_optional)):
    try:
        job_uuid = uuid.UUID(job_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="Job not found")
    job = _published_jobs(db).filter(models.Job.id == job_uuid).first()
    if not job:
        raise HTTPException(status_code=404, detail="This job is no longer available")
    return _jobs_out(db, [job], current_user)[0]



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

# --- Student tests ---

def _user_attempts_query(db: Session, user: models.User):
    """Attempts by this user, matched on user_id or their student profile."""
    conds = [models.TestAttempt.user_id == user.id]
    if user.student_profile:
        conds.append(models.TestAttempt.student_profile_id == user.student_profile.id)
    return db.query(models.TestAttempt).filter(or_(*conds), models.TestAttempt.is_active == True)

def _live_tests_query(db: Session):
    """Published tests inside their schedule window."""
    now = datetime.utcnow()
    return db.query(models.Test).filter(
        models.Test.is_active == True,
        models.Test.status == "published",
        or_(models.Test.scheduled_start_at == None, models.Test.scheduled_start_at <= now),
        or_(models.Test.scheduled_end_at == None, models.Test.scheduled_end_at >= now),
    )

def _attempt_percentage(a: models.TestAttempt) -> float:
    if a.percentage is not None:
        return round(a.percentage, 1)
    return round((a.total_score or 0) / a.max_score * 100, 1) if a.max_score else 0.0

def _test_summary(test: models.Test, attempts: list) -> dict:
    import test_engine
    questions = test_engine.ordered_questions(test)
    used = len(attempts)
    best = max(attempts, key=_attempt_percentage) if attempts else None
    latest = max(attempts, key=lambda x: x.completed_at or x.created_datetime) if attempts else None
    return {
        "id": test.id, "title": test.title, "description": test.description, "tag": test.tag,
        "category": test.category, "test_type": test.test_type, "difficulty": test.difficulty,
        "provider_name": test.provider_name, "provider_logo_url": test.provider_logo_url,
        "duration_mins": test.duration_mins, "test_mode": test.test_mode,
        "question_count": len(questions), "total_marks": sum(float(q.marks or 1) for q in questions),
        "pass_percentage": test.pass_percentage, "negative_marking": test.negative_marking,
        "max_discount_percentage": test.max_discount_percentage or 0,
        "instructions": test.instructions, "created_datetime": test.created_datetime,
        "scheduled_end_at": test.scheduled_end_at,
        "attempts_used": used,
        "attempts_left": None if not test.max_attempts else max(test.max_attempts - used, 0),
        "best_attempt": {
            "id": best.id, "total_score": best.total_score, "max_score": best.max_score,
            "percentage": _attempt_percentage(best), "is_passed": best.is_passed,
            "completed_at": best.completed_at,
        } if best else None,
        "last_attempted_at": (latest.completed_at or latest.created_datetime) if latest else None,
    }

@app.get("/api/tests")
def get_tests(
    status: Optional[str] = "available",
    page: int = 1,
    limit: int = 20,
    db: Session = Depends(get_db),
    current_user: Optional[models.User] = Depends(auth.get_current_user_optional),
):
    """Student test list. available = live tests not yet attempted; attempted = tests the user has taken."""
    if status == "attempted" and not current_user:
        raise HTTPException(status_code=401, detail="Please log in to see your tests.")

    by_test = defaultdict(list)
    if current_user:
        for attempt in _user_attempts_query(db, current_user).all():
            by_test[attempt.test_id].append(attempt)

    if status == "attempted":
        tests = db.query(models.Test).filter(models.Test.id.in_(list(by_test.keys())), models.Test.is_active == True).all()
        tests.sort(key=lambda t: max((a.completed_at or a.created_datetime) for a in by_test[t.id]), reverse=True)
    else:
        tests = [t for t in _live_tests_query(db).order_by(models.Test.created_datetime.desc()).all()
                 if t.id not in by_test and any(q.is_active for q in t.questions)]

    page, limit = max(page, 1), min(max(limit, 1), 50)
    window = tests[(page - 1) * limit: page * limit]
    return {"data": [_test_summary(t, by_test.get(t.id, [])) for t in window], "total": len(tests)}

@app.post("/api/tests/{test_id}/start")
def start_test(test_id: str, db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_user)):
    """Questions for taking a test, without answers."""
    import test_engine
    try:
        test_uuid = uuid.UUID(test_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="Test not found")
    test = _live_tests_query(db).filter(models.Test.id == test_uuid).first()
    if not test:
        raise HTTPException(status_code=404, detail="This test is no longer available.")
    used = _user_attempts_query(db, current_user).filter(models.TestAttempt.test_id == test.id).count()
    if test.max_attempts and used >= test.max_attempts:
        raise HTTPException(status_code=403, detail="You've used all attempts for this test.")
    questions = test_engine.student_questions(test)
    if not questions:
        raise HTTPException(status_code=400, detail="This test has no questions yet.")
    return {
        **_test_summary(test, []),
        "attempts_used": used,
        "is_retake": used > 0,
        "default_per_question_seconds": test.default_per_question_seconds or 60,
        "questions": questions,
    }

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
# --- Professionals (student) ---

EXPERIENCE_BANDS = {"0-5": (0, 5), "5-10": (5, 10), "10+": (10, None)}

def _rating_subquery(db: Session):
    return db.query(
        models.ProfessionalReview.professional_id.label("pid"),
        func.count(models.ProfessionalReview.id).label("reviews"),
        func.avg(models.ProfessionalReview.rating).label("avg_rating"),
    ).filter(models.ProfessionalReview.is_active == True).group_by(models.ProfessionalReview.professional_id).subquery()

def _professional_out(db: Session, p: models.Professional, reviews: int, avg_rating, with_next: bool = True) -> dict:
    import booking
    d = {c.name: getattr(p, c.name) for c in p.__table__.columns}
    d["consultation_fee"] = float(p.consultation_fee or 0)
    d["reviews"] = int(reviews or 0)
    d["rating"] = round(float(avg_rating), 1) if avg_rating is not None else float(p.default_rating or 0)
    d["time_slots"] = [booking.format_time(t) for t in booking.slot_times(p)]
    d["available_days"] = [day for day in booking.WEEKDAYS if day in booking.available_weekdays(p)]
    if with_next:
        d["next_available"] = booking.next_available(db, models, p)
    return d

@app.get("/api/professionals")
def get_professionals(
    page: int = 1,
    limit: int = 10,
    search: Optional[str] = None,
    profession: Optional[str] = None,
    group: Optional[str] = None,
    city: Optional[str] = None,
    location_city: Optional[str] = None,
    consultation_mode: Optional[str] = None,
    min_fee: Optional[float] = None,
    max_fee: Optional[float] = None,
    experience: Optional[str] = None,
    language: Optional[str] = None,
    available_day: Optional[str] = None,
    min_rating: Optional[float] = None,
    featured: Optional[bool] = None,
    skip: Optional[int] = None,
    db: Session = Depends(get_db),
):
    """Active professionals for students, with filters. group = doctor | non_doctor."""
    import booking
    from sqlalchemy import cast, String
    ratings = _rating_subquery(db)
    rating_expr = func.coalesce(ratings.c.avg_rating, models.Professional.default_rating, 0)
    query = db.query(models.Professional, ratings.c.reviews, ratings.c.avg_rating) \
        .outerjoin(ratings, ratings.c.pid == models.Professional.id) \
        .filter(models.Professional.is_active == True)

    if search and search.strip():
        term = f"%{search.strip()}%"
        query = query.filter(or_(
            models.Professional.name.ilike(term), models.Professional.specialty.ilike(term),
            models.Professional.clinic.ilike(term), models.Professional.qualification.ilike(term),
            models.Professional.profession.ilike(term),
        ))
    if profession and profession != "All":
        query = query.filter(models.Professional.profession == profession)
    if group == "doctor":
        query = query.filter(func.lower(models.Professional.profession) == "doctor")
    elif group == "non_doctor":
        query = query.filter(func.lower(func.coalesce(models.Professional.profession, "")) != "doctor")
    city = city or location_city
    if city and city != "All":
        query = query.filter(models.Professional.location_city == city)
    if consultation_mode:
        query = query.filter(cast(models.Professional.consultation_mode, String).ilike(f'%"{consultation_mode}"%'))
    if language:
        query = query.filter(cast(models.Professional.languages_spoken, String).ilike(f'%"{language}"%'))
    if available_day:
        day = booking.normalize_day(available_day)
        if day:
            query = query.filter(cast(models.Professional.available_days, String).ilike(f"%{day}%"))
    if min_fee is not None:
        query = query.filter(models.Professional.consultation_fee >= min_fee)
    if max_fee is not None:
        query = query.filter(models.Professional.consultation_fee <= max_fee)
    if experience in EXPERIENCE_BANDS:
        low, high = EXPERIENCE_BANDS[experience]
        years = func.coalesce(models.Professional.years_experience_numeric, 0)
        query = query.filter(years >= low)
        if high is not None:
            query = query.filter(years < high)
    if min_rating:
        query = query.filter(rating_expr >= min_rating)
    if featured:
        query = query.filter(models.Professional.is_featured == True)

    total = query.count()
    limit = min(max(limit, 1), 50)
    offset = skip if skip is not None else (max(page, 1) - 1) * limit
    rows = query.order_by(models.Professional.is_featured.desc(), rating_expr.desc(), models.Professional.name.asc()) \
        .offset(offset).limit(limit).all()
    return {"data": [_professional_out(db, p, r, avg) for p, r, avg in rows], "total": total}

@app.get("/api/professionals/filters")
def get_professional_filter_options(db: Session = Depends(get_db)):
    pros = db.query(models.Professional).filter(models.Professional.is_active == True).all()
    def values(attr):
        out = set()
        for p in pros:
            v = getattr(p, attr)
            for item in (v if isinstance(v, list) else [v]):
                if item and str(item).strip():
                    out.add(str(item).strip())
        return sorted(out)
    fees = [float(p.consultation_fee) for p in pros if p.consultation_fee is not None]
    return {
        "professions": values("profession"),
        "cities": values("location_city"),
        "languages": values("languages_spoken"),
        "consultation_modes": values("consultation_mode"),
        "fee_min": min(fees) if fees else 0,
        "fee_max": max(fees) if fees else 0,
    }

def _get_active_professional(db: Session, professional_id: str) -> models.Professional:
    try:
        pid = uuid.UUID(professional_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="Professional not found")
    p = db.query(models.Professional).filter(models.Professional.id == pid, models.Professional.is_active == True).first()
    if not p:
        raise HTTPException(status_code=404, detail="This professional is no longer available.")
    return p

@app.get("/api/professionals/{professional_id}/availability")
def get_professional_availability(professional_id: str, days: int = 30, db: Session = Depends(get_db),
                                  current_user: Optional[models.User] = Depends(auth.get_current_user_optional)):
    """Bookable dates and slots for the next `days` days. Slot status: available, full, past,
    or booked (already held by the logged-in user)."""
    import booking
    p = _get_active_professional(db, professional_id)
    user_id = current_user.id if current_user else None
    return {"dates": booking.availability(db, models, p, days, user_id=user_id), "timezone": booking.TIMEZONE}

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

@app.get("/api/professionals/{professional_id}")
def get_professional(professional_id: str, db: Session = Depends(get_db)):
    p = _get_active_professional(db, professional_id)
    ratings = _rating_subquery(db)
    row = db.query(ratings.c.reviews, ratings.c.avg_rating).filter(ratings.c.pid == p.id).first()
    return _professional_out(db, p, row[0] if row else 0, row[1] if row else None)

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
    """Kept for older app builds; new builds use /availability. Returns slots that are full."""
    import booking
    p = _get_active_professional(db, professional_id)
    try:
        day = booking.parse_date(date)
    except ValueError:
        return []
    capacity = max(p.max_bookings_per_slot or 1, 1)
    counts = booking.booking_counts(db, models, p.id, day, day)
    return [booking.format_time(t) for (d, t), n in sorted(counts.items()) if n >= capacity]

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
        app_dict = jsonable_encoder(app, exclude={"resume_snapshot"})
        app_dict.update(_application_resume_info(app))
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
    if user_update.mobile_number is not None:
        # Check if mobile number is already in use
        existing_user = db.query(models.User).filter(models.User.mobile_number == user_update.mobile_number).first()
        if existing_user and existing_user.id != current_user.id:
            raise HTTPException(status_code=400, detail="Mobile number already in use by another account.")
        current_user.mobile_number = user_update.mobile_number
    if user_update.full_name is not None:
        current_user.full_name = user_update.full_name

    # Handle StudentProfile fields
    profile_fields = [
        'city', 'state', 'pincode', 'country', 'address', 'dob', 'gender', 'marital_status',
        'portfolio_url', 'linkedin_url', 'github_url', 'summary', 'years_of_experience',
        'preferred_job_location', 'willing_to_relocate', 'expected_salary', 'current_salary',
        'notice_period_days', 'skills', 'languages', 'education_history', 'work_experience',
        'projects', 'certifications', 'achievements', 'hobbies', 'references',
        'resume_data', 'whatsapp_number', 'email', 'profile_image_url'
    ]
    
    if any(getattr(user_update, field) is not None for field in profile_fields) or user_update.goal is not None or user_update.acquisition_source is not None:
        if not current_user.student_profile:
            new_profile = models.StudentProfile(user_id=current_user.id)
            db.add(new_profile)
            db.flush()
            current_user.student_profile = new_profile
            
        for field in profile_fields:
            if getattr(user_update, field) is not None:
                setattr(current_user.student_profile, field, getattr(user_update, field))
                
        # Sync skills with SkillDictionary
        if user_update.skills is not None:
            for skill_name in user_update.skills:
                # Case-insensitive check
                existing_skill = db.query(models.SkillDictionary).filter(models.SkillDictionary.name.ilike(skill_name)).first()
                if not existing_skill:
                    new_skill = models.SkillDictionary(name=skill_name, category="Other")
                    db.add(new_skill)
            db.flush()
                
        if user_update.goal is not None:
            # Find or create goal
            goal = db.query(models.Goal).filter(models.Goal.name.ilike(user_update.goal)).first()
            if not goal:
                goal = models.Goal(name=user_update.goal)
                db.add(goal)
                db.flush()
            current_user.student_profile.goal_id = goal.id
            
        if user_update.acquisition_source is not None:
            # Find or create source
            src = db.query(models.AcquisitionSource).filter(models.AcquisitionSource.name.ilike(user_update.acquisition_source)).first()
            if not src:
                src = models.AcquisitionSource(name=user_update.acquisition_source)
                db.add(src)
                db.flush()
            current_user.student_profile.acquisition_source_id = src.id

    if current_user.student_profile:
        current_user.student_profile.profile_completion_score = calculate_profile_score(current_user, current_user.student_profile)
    
    db.commit()
    db.refresh(current_user)
    db.refresh(current_user)
    return current_user

# --- User Appointments ---
def _appointment_out(db: Session, a: models.ProfessionalAppointment, reviewed: set) -> dict:
    import booking
    shown = booking.display_status(a)
    prof = None
    if a.professional:
        ratings = _rating_subquery(db)
        row = db.query(ratings.c.reviews, ratings.c.avg_rating).filter(ratings.c.pid == a.professional.id).first()
        prof = _professional_out(db, a.professional, row[0] if row else 0, row[1] if row else None, with_next=False)
    return {
        "id": a.id,
        "professional_id": a.professional_id,
        "professional": prof,
        "appointment_date": a.appointment_date.isoformat() if a.appointment_date else None,
        "appointment_time": booking.format_time(a.appointment_time) if a.appointment_time else None,
        "status": a.status,
        "display_status": shown,
        "is_upcoming": shown in ("pending", "confirmed"),
        "can_cancel": shown in ("pending", "confirmed"),
        "can_review": shown in ("completed", "missed") and a.professional_id not in reviewed,
        "consultation_mode": a.consultation_mode,
        "notes_by_student": a.notes_by_student,
        "cancellation_reason": a.cancellation_reason,
        "cancelled_by": a.cancelled_by,
        "created_datetime": a.created_datetime,
    }

@app.get("/api/users/me/appointments")
def get_my_appointments(skip: int = 0, limit: int = 100, db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_user)):
    import booking
    appointments = db.query(models.ProfessionalAppointment).filter(
        models.ProfessionalAppointment.user_id == current_user.id,
        models.ProfessionalAppointment.is_active == True,
    ).all()
    reviewed = {r[0] for r in db.query(models.ProfessionalReview.professional_id).filter(
        models.ProfessionalReview.user_id == current_user.id, models.ProfessionalReview.is_active == True).all()}

    def key(a):
        when = datetime.combine(a.appointment_date or date.min, a.appointment_time or datetime.min.time())
        # Upcoming first (soonest first), then the rest (most recent first).
        return (0, when) if booking.is_upcoming(a) else (1, -when.timestamp() if a.appointment_date else 0)
    appointments.sort(key=key)
    return [_appointment_out(db, a, reviewed) for a in appointments[skip: skip + limit]]

@app.post("/api/users/me/appointments")
def create_appointment(app_req: schemas.ProfessionalAppointmentCreate, db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_user)):
    """Books an available slot. Rejects unavailable days, unknown slots, past times and full slots."""
    import booking
    professional = _get_active_professional(db, str(app_req.professional_id))
    try:
        day, slot, mode = booking.validate_booking(
            db, models, professional, current_user.id,
            app_req.appointment_date, app_req.appointment_time, app_req.consultation_mode,
        )
    except booking.BookingError as e:
        raise HTTPException(status_code=e.status_code, detail=e.detail)

    appointment = models.ProfessionalAppointment(
        user_id=current_user.id,
        professional_id=professional.id,
        appointment_date=day,
        appointment_time=slot,
        status="pending",
        consultation_mode=mode,
        notes_by_student=(app_req.notes_by_student or "").strip() or None,
    )
    db.add(appointment)
    db.commit()
    db.refresh(appointment)
    return _appointment_out(db, appointment, set())

@app.delete("/api/users/me/appointments/{appointment_id}")
def cancel_appointment(appointment_id: str, reason: Optional[str] = None, db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_user)):
    import booking
    try:
        appt_uuid = uuid.UUID(appointment_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="Appointment not found")
    appointment = db.query(models.ProfessionalAppointment).filter(
        models.ProfessionalAppointment.id == appt_uuid,
        models.ProfessionalAppointment.user_id == current_user.id,
    ).first()
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")
    if not booking.is_upcoming(appointment):
        raise HTTPException(status_code=400, detail="Only upcoming appointments can be cancelled.")

    appointment.status = "cancelled"
    appointment.cancelled_by = "student"
    appointment.cancellation_reason = (reason or "").strip() or None
    db.commit()
    return {"status": "success", "message": "Appointment cancelled."}

# --- User Job Applications ---
def _student_profile_for(db: Session, user: models.User) -> models.StudentProfile:
    if not user.student_profile:
        profile = models.StudentProfile(user_id=user.id)
        db.add(profile)
        db.flush()
        user.student_profile = profile
    return user.student_profile

def _application_out(db: Session, application: models.JobApplication, user) -> dict:
    return {
        "id": application.id,
        "job_id": application.job_id,
        "status": application.status,
        "applied_datetime": application.created_datetime,
        "cover_letter": application.cover_letter,
        "screening_responses": application.screening_responses or {},
        "interview_datetime": application.interview_datetime,
        "employer_feedback": application.employer_feedback,
        "job": _jobs_out(db, [application.job], user)[0] if application.job else None,
    }

@app.get("/api/users/me/applications")
def get_my_applications(db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_user)):
    if not current_user.student_profile:
        return []
    applications = db.query(models.JobApplication).filter(
        models.JobApplication.student_profile_id == current_user.student_profile.id,
        models.JobApplication.is_active == True,
    ).order_by(models.JobApplication.created_datetime.desc()).all()
    return [_application_out(db, a, current_user) for a in applications]

@app.post("/api/users/me/applications")
def apply_for_job(app_req: schemas.JobApplicationCreate, db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_user)):
    job = _published_jobs(db).filter(models.Job.id == app_req.job_id).first()
    if not job:
        raise HTTPException(status_code=400, detail="This job is no longer accepting applications.")

    profile = _student_profile_for(db, current_user)
    existing = db.query(models.JobApplication).filter(
        models.JobApplication.student_profile_id == profile.id,
        models.JobApplication.job_id == job.id,
        models.JobApplication.is_active == True,
    ).first()
    if existing:
        raise HTTPException(status_code=409, detail="You've already applied to this job.")

    cover_letter = (app_req.cover_letter or "").strip() or None
    if job.is_cover_letter_required and job.application_routing_mode != "external_link" and not cover_letter:
        raise HTTPException(status_code=400, detail="A cover letter is required for this job.")

    resume = profile.resume_data if isinstance(profile.resume_data, dict) else {}
    application = models.JobApplication(
        student_profile_id=profile.id,
        job_id=job.id,
        status="applied",
        cover_letter=cover_letter,
        screening_responses=app_req.screening_responses or {},
        # Keep the resume as it was when applying, even if the profile resume changes later.
        resume_snapshot={"filename": resume.get("filename") or "resume.pdf", "data": resume["data"]} if resume.get("data") else None,
    )
    db.add(application)
    db.commit()
    db.refresh(application)
    return _application_out(db, application, current_user)

# --- User Test Attempts ---
def _review_allowed(test: models.Test) -> bool:
    mode = (test.show_answer_after or "after_submit") if test else "after_submit"
    if mode == "never":
        return False
    if mode == "after_test_ends" and test.scheduled_end_at and datetime.utcnow() < test.scheduled_end_at:
        return False
    return True

def _attempt_result(attempt: models.TestAttempt) -> dict:
    import test_engine
    test = attempt.test
    responses = [dict(r) for r in (attempt.question_responses or []) if isinstance(r, dict)]
    review = _review_allowed(test)
    if not review:
        for r in responses:
            for key in ("correct_option_ids", "correct_option", "explanation"):
                r.pop(key, None)
    percentage = _attempt_percentage(attempt)
    discount = 0
    if test and test.max_discount_percentage and attempt.attempt_number == 1:
        if percentage >= 80:
            discount = test.max_discount_percentage
        elif percentage >= 50:
            discount = test.max_discount_percentage // 2
    return {
        "id": attempt.id,
        "test_id": attempt.test_id,
        "test_title": test.title if test else "Test",
        "test_mode": test.test_mode if test else "overall",
        "attempt_number": attempt.attempt_number or 1,
        "total_score": attempt.total_score or 0,
        "max_score": attempt.max_score,
        "percentage": percentage,
        "is_passed": attempt.is_passed if attempt.is_passed is not None else (test is not None and percentage >= (test.pass_percentage or 0)),
        "pass_percentage": test.pass_percentage if test else None,
        "time_taken_seconds": attempt.time_taken_seconds or 0,
        "completed_at": attempt.completed_at or attempt.created_datetime,
        "section_scores": attempt.section_scores or [],
        "discount_unlocked": discount,
        "ai_report": attempt.ai_report,
        "review_available": review,
        "question_responses": responses,
        "topic_scores": test_engine.topic_scores(responses),
        **test_engine.counts(responses),
    }

@app.get("/api/users/me/test-attempts")
def get_my_test_attempts(db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_user)):
    attempts = _user_attempts_query(db, current_user).order_by(models.TestAttempt.created_datetime.desc()).all()
    return [
        {k: v for k, v in _attempt_result(a).items() if k not in ("question_responses", "ai_report", "topic_scores")}
        for a in attempts
    ]

@app.get("/api/users/me/test-attempts/{attempt_id}")
def get_my_test_attempt(attempt_id: str, db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_user)):
    try:
        attempt_uuid = uuid.UUID(attempt_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="Result not found")
    attempt = _user_attempts_query(db, current_user).filter(models.TestAttempt.id == attempt_uuid).first()
    if not attempt:
        raise HTTPException(status_code=404, detail="Result not found")
    return _attempt_result(attempt)

@app.post("/api/users/me/test-attempts")
async def submit_test_attempt(req: schemas.AttemptSubmit, db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_user)):
    """Grades a submitted test on the server and adds an AI summary."""
    import test_engine
    test = db.query(models.Test).filter(models.Test.id == req.test_id, models.Test.is_active == True).first()
    if not test:
        raise HTTPException(status_code=404, detail="Test not found")

    previous = _user_attempts_query(db, current_user).filter(models.TestAttempt.test_id == test.id).count()
    if test.max_attempts and previous >= test.max_attempts:
        raise HTTPException(status_code=403, detail="You've used all attempts for this test.")

    result = test_engine.grade(test, [a.model_dump() for a in req.answers])
    time_taken = req.time_taken_seconds or sum(a.time_spent_seconds or 0 for a in req.answers)
    profile = current_user.student_profile
    if not profile:
        profile = models.StudentProfile(user_id=current_user.id)
        db.add(profile)
        db.flush()

    now = datetime.utcnow()
    attempt = models.TestAttempt(
        user_id=current_user.id,
        student_profile_id=profile.id,
        test_id=test.id,
        attempt_number=previous + 1,
        status="completed",
        total_score=result["total_score"],
        max_score=result["max_score"],
        percentage=result["percentage"],
        is_passed=result["is_passed"],
        time_taken_seconds=time_taken,
        started_at=now - timedelta(seconds=time_taken),
        completed_at=now,
        question_responses=result["question_responses"],
        section_scores=result["section_scores"],
    )
    db.add(attempt)
    db.commit()
    db.refresh(attempt)

    report = await test_engine.ai_report(test, result, time_taken)
    if report:
        attempt.ai_report = report
        db.commit()
        db.refresh(attempt)
    return _attempt_result(attempt)

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

@app.post("/api/resume/analyze", response_model=schemas.ResumeAnalyzeResponse)
async def analyze_resume(
    req: schemas.ResumeAnalyzeRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    """Reads an uploaded resume with AI and checks it belongs to the current user. Saves nothing."""
    import base64
    import resume_ai

    try:
        pdf_bytes = base64.b64decode(req.data, validate=False)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid file data.")
    if len(pdf_bytes) > 5 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="Resume must be 5MB or smaller.")
    if not pdf_bytes.startswith(b"%PDF"):
        raise HTTPException(status_code=400, detail="Please upload a PDF file.")

    try:
        text = resume_ai.extract_pdf_text(pdf_bytes)
    except Exception:
        raise HTTPException(status_code=422, detail="Couldn't open this PDF. Please upload a different file.")
    if len(text) < 50:
        raise HTTPException(status_code=422, detail="Couldn't read text from this PDF. Please upload a text-based (not scanned) resume.")

    try:
        extracted = await resume_ai.parse_resume_with_ai(text)
    except resume_ai.ResumeAIError as e:
        raise HTTPException(status_code=e.status_code, detail=e.detail)

    profile = db.query(models.StudentProfile).filter(models.StudentProfile.user_id == current_user.id).first()
    result = resume_ai.compare_identity(current_user, profile, extracted)
    return {**result, "extracted": extracted}

# --- AI Resume Builder (chat) ---

def _active_resume_session(db: Session, user: models.User, create: bool = True):
    session = db.query(models.ResumeSession).filter(
        models.ResumeSession.user_id == user.id, models.ResumeSession.is_active == True
    ).order_by(models.ResumeSession.created_datetime.desc()).first()
    if not session and create:
        session = models.ResumeSession(user_id=user.id, chat_history=[], extracted_data={},
                                       uploaded_resume_info={}, current_step="new")
        db.add(session)
        db.flush()
    return session

def _builder_session_out(session) -> dict:
    return {
        "messages": session.chat_history or [] if session else [],
        "draft": (session.extracted_data or {}) if session else {},
        "stage": (session.current_step or "new") if session else "new",
    }

@app.get("/api/resume/session", response_model=schemas.ResumeBuilderSession)
def get_resume_session(db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_user)):
    return _builder_session_out(_active_resume_session(db, current_user, create=False))

@app.post("/api/resume/session/reset", response_model=schemas.ResumeBuilderSession)
def reset_resume_session(db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_user)):
    session = _active_resume_session(db, current_user, create=False)
    if session:
        session.is_active = False
        session.deleted_datetime = datetime.utcnow()
        db.commit()
    return _builder_session_out(None)

@app.post("/api/resume/chat", response_model=schemas.ResumeChatResponse)
async def resume_chat(req: schemas.ResumeChatEvent, db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_user)):
    import copy
    import resume_builder

    session = _active_resume_session(db, current_user)
    profile = current_user.student_profile
    if req.event == "init" and session.chat_history:
        return _builder_session_out(session) | {"messages": []}

    turn = await resume_builder.handle_event(
        session.current_step or "new", session.extracted_data or {},
        copy.deepcopy(session.uploaded_resume_info or {}), current_user, profile, req.model_dump()
    )

    if turn.sync_profile:
        update_user_profile(schemas.UserProfileUpdate(**resume_builder.draft_to_profile_update(turn.draft)),
                            db, current_user)

    user_turn = []
    if req.event == "message" and req.text:
        user_turn = [{"role": "user", "type": "text", "text": req.text}]
    elif req.event == "upload" and req.file:
        user_turn = [{"role": "user", "type": "file", "text": req.file.filename}]
    elif req.event == "choice" and req.text:
        user_turn = [{"role": "user", "type": "text", "text": req.text}]

    session.chat_history = (session.chat_history or []) + user_turn + turn.messages
    session.extracted_data = turn.draft
    session.uploaded_resume_info = turn.info
    session.current_step = turn.stage
    session.status = "completed" if turn.stage == "ready" else "in_progress"
    db.commit()
    return {"messages": turn.messages, "draft": turn.draft, "stage": turn.stage}

@app.put("/api/resume/draft", response_model=schemas.ResumeBuilderSession)
def save_resume_draft(req: schemas.ResumeDraftUpdate, db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_user)):
    import resume_builder
    session = _active_resume_session(db, current_user)
    session.extracted_data = resume_builder.apply_identity(req.draft, current_user, current_user.student_profile)
    db.commit()
    return _builder_session_out(session)

@app.post("/api/resume/improve")
async def improve_resume_text(req: schemas.ResumeImproveRequest, current_user: models.User = Depends(auth.get_current_user)):
    import resume_builder
    from resume_ai import ResumeAIError
    if not req.text.strip():
        raise HTTPException(status_code=400, detail="Nothing to improve yet.")
    try:
        return await resume_builder.improve_text(req.kind, req.text, req.context or "")
    except ResumeAIError as e:
        raise HTTPException(status_code=e.status_code, detail=e.detail)

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
