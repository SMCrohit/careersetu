from fastapi import FastAPI, Depends, HTTPException, status
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
    if os.path.exists(cred_path):
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
    elif os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON"):
        import json
        cred_dict = json.loads(os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON"))
        cred = credentials.Certificate(cred_dict)
        firebase_admin.initialize_app(cred)
    else:
        print("Warning: Firebase Admin not initialized. No service account found.")

try:
    models.Base.metadata.create_all(bind=engine)
    # Initialize default admin user if none exists
    db = next(get_db())
    if db.query(models.AdminUser).count() == 0:
        admin_password = os.getenv("DEFAULT_ADMIN_PASSWORD")
        if not admin_password:
            raise ValueError("DEFAULT_ADMIN_PASSWORD environment variable is missing.")
            
        default_admin = models.AdminUser(
            username="admin",
            password_hash=auth.get_password_hash(admin_password),
            role="admin"
        )
        db.add(default_admin)
        db.commit()
    db.close()
except Exception as e:
    print(f"Warning: Failed to connect to database on startup: {e}")

app = FastAPI(title="Careersetu API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

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
@app.get("/api/tests", response_model=list[schemas.TestModel])
def get_tests(db: Session = Depends(get_db)):
    return db.query(models.Test).filter(models.Test.is_active == True).all()

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

# Doctors CRUD
@app.get("/api/doctors", response_model=list[schemas.Doctor])
def get_doctors(db: Session = Depends(get_db)):
    return db.query(models.Doctor).filter(models.Doctor.is_active == True).all()

@app.post("/api/doctors", response_model=schemas.Doctor)
def create_doctor(doctor: schemas.DoctorBase, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    db_doctor = models.Doctor(**doctor.model_dump())
    db.add(db_doctor)
    db.commit()
    db.refresh(db_doctor)
    auth.log_admin_action(db, admin, "CREATE", "Doctors", str(db_doctor.id))
    return db_doctor

@app.delete("/api/doctors/{doctor_id}")
def delete_doctor(doctor_id: str, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    db_doctor = db.query(models.Doctor).filter(models.Doctor.id == doctor_id).first()
    if not db_doctor:
        raise HTTPException(status_code=404, detail="Doctor not found")
    db_doctor.is_active = False
    from datetime import datetime
    db_doctor.deleted_datetime = datetime.utcnow()
    db.commit()
    auth.log_admin_action(db, admin, "DELETE", "Doctors", doctor_id)
    return {"status": "Doctor soft deleted"}

@app.put("/api/doctors/{doctor_id}", response_model=schemas.Doctor)
def update_doctor(doctor_id: str, doctor_update: schemas.DoctorBase, db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    db_doctor = db.query(models.Doctor).filter(models.Doctor.id == doctor_id, models.Doctor.is_active == True).first()
    if not db_doctor:
        raise HTTPException(status_code=404, detail="Doctor not found")
    for key, value in doctor_update.model_dump().items():
        setattr(db_doctor, key, value)
    db.commit()
    db.refresh(db_doctor)
    auth.log_admin_action(db, admin, "UPDATE", "Doctors", doctor_id)
    return db_doctor

# Offers CRUD
@app.get("/api/offers", response_model=list[schemas.Offer])
def get_offers(db: Session = Depends(get_db)):
    return db.query(models.Offer).filter(models.Offer.is_active == True).all()

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
    doc_appts = db.query(models.DoctorAppointment).filter(models.DoctorAppointment.user_id == user_id).all()
    
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
        
    doc_appts_enriched = []
    for apt in doc_appts:
        doc = db.query(models.Doctor).filter(models.Doctor.id == apt.doctor_id).first()
        apt_dict = apt.__dict__.copy()
        apt_dict['doctor'] = doc.__dict__ if doc else None
        doc_appts_enriched.append(apt_dict)
        
    return {
        "user": user,
        "job_applications": job_apps_enriched,
        "test_attempts": test_attempts_enriched,
        "doctor_appointments": doc_appts_enriched
    }

# Activity Logs
@app.get("/api/logs", response_model=list[schemas.ActivityLog])
def get_activity_logs(db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    return db.query(models.ActivityLog).order_by(models.ActivityLog.created_datetime.desc()).all()

# Dashboard Stats
@app.get("/api/dashboard/stats")
def get_dashboard_stats(filter: str = "This Week", db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    total_users = db.query(models.User).filter(models.User.is_active == True).count()
    active_jobs = db.query(models.Job).filter(models.Job.is_active == True).count()
    tests_taken = db.query(models.TestAttempt).count()
    appointments = db.query(models.DoctorAppointment).count()
    
    # Generate chart data based on filter
    chart_data = []
    today = date.today()
    from sqlalchemy import extract
    
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

    return {
        "totals": {
            "users": total_users,
            "jobs": active_jobs,
            "tests": tests_taken,
            "appointments": appointments
        },
        "chart_data": chart_data
    }

