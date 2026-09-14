from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import timedelta, datetime, date
import models, schemas, auth
from database import engine, get_db

try:
    models.Base.metadata.create_all(bind=engine)
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
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends()):
    # Hardcoded for now based on requirements
    if form_data.username != "admin" or form_data.password != "password123":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires = timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = auth.create_access_token(
        data={"sub": form_data.username, "role": "admin"}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

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

# Dashboard Stats
@app.get("/api/dashboard/stats")
def get_dashboard_stats(db: Session = Depends(get_db), admin: str = Depends(auth.get_current_admin)):
    total_users = db.query(models.User).filter(models.User.is_active == True).count()
    active_jobs = db.query(models.Job).filter(models.Job.is_active == True).count()
    tests_taken = db.query(models.TestAttempt).count()
    appointments = db.query(models.DoctorAppointment).count()
    
    # Generate simple last 7 days chart data
    chart_data = []
    today = date.today()
    for i in range(6, -1, -1):
        target_date = today - timedelta(days=i)
        day_name = target_date.strftime("%a") # Mon, Tue, etc.
        
        # Count users created on this date
        users_count = db.query(models.User).filter(
            func.date(models.User.created_datetime) == target_date
        ).count()
        
        # Count jobs created on this date
        jobs_count = db.query(models.Job).filter(
            func.date(models.Job.created_datetime) == target_date
        ).count()
        
        chart_data.append({
            "name": day_name,
            "users": users_count,
            "jobs": jobs_count
        })

    return {
        "totals": {
            "users": total_users,
            "jobs": active_jobs,
            "tests": tests_taken,
            "appointments": appointments
        },
        "chart_data": chart_data
    }

