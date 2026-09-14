import uuid
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, Float, Integer, Text, ForeignKey, JSON
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from database import Base

class BaseModel(Base):
    __abstract__ = True
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    created_datetime = Column(DateTime, default=datetime.utcnow)
    is_active = Column(Boolean, default=True)
    deleted_datetime = Column(DateTime, nullable=True)

class User(BaseModel):
    __tablename__ = "users"
    mobile_number = Column(String, unique=True, index=True)
    full_name = Column(String)
    email = Column(String)
    city = Column(String)
    goal = Column(String)
    resume_data = Column(JSON, nullable=True)

class Job(BaseModel):
    __tablename__ = "jobs"
    title = Column(String, index=True)
    company = Column(String)
    location = Column(String)
    salary = Column(String)
    type = Column(String)
    level = Column(String)
    description = Column(Text)
    requirements = Column(JSON, default=[])
    posted_time = Column(String)
    applicants = Column(String)

class Test(BaseModel):
    __tablename__ = "tests"
    title = Column(String, index=True)
    tag = Column(String)
    description = Column(Text)
    duration_mins = Column(Integer)
    difficulty = Column(String)
    provider_name = Column(String)
    max_discount_percentage = Column(Integer)
    questions = Column(JSON, default=[])

class Doctor(BaseModel):
    __tablename__ = "doctors"
    name = Column(String, index=True)
    specialty = Column(String)
    clinic = Column(String)
    experience = Column(String)
    consultation_fee = Column(Float)

class Offer(BaseModel):
    __tablename__ = "offers"
    title = Column(String, index=True)
    subtitle = Column(String)
    description = Column(Text)
    action = Column(String)
    type = Column(String)

class Notification(BaseModel):
    __tablename__ = "notifications"
    title = Column(String)
    message = Column(Text)
    target_user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    is_read = Column(Boolean, default=False)

class ActivityLog(BaseModel):
    __tablename__ = "activity_logs"
    admin_id = Column(String)
    action = Column(String)
    module_name = Column(String)
    record_id = Column(String)
    details = Column(JSON, default={})

class JobApplication(BaseModel):
    __tablename__ = "job_applications"
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    job_id = Column(UUID(as_uuid=True), ForeignKey("jobs.id"))
    status = Column(String)

class TestAttempt(BaseModel):
    __tablename__ = "test_attempts"
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    test_id = Column(UUID(as_uuid=True), ForeignKey("tests.id"))
    score = Column(Float)

class DoctorAppointment(BaseModel):
    __tablename__ = "doctor_appointments"
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    doctor_id = Column(UUID(as_uuid=True), ForeignKey("doctors.id"))
    appointment_date = Column(String)
    appointment_time = Column(String)
    status = Column(String)

class GameSession(BaseModel):
    __tablename__ = "game_sessions"
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    game_type = Column(String)
    score = Column(Integer)
