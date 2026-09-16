from pydantic import BaseModel, ConfigDict
from typing import List, Optional, Any
from datetime import datetime
from uuid import UUID

class ORMBase(BaseModel):
    id: UUID
    created_datetime: datetime
    is_active: bool
    deleted_datetime: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)

class UserBase(BaseModel):
    mobile_number: str
    full_name: str
    email: str
    city: str
    goal: str
    resume_data: Optional[Any] = None

class User(UserBase, ORMBase):
    pass

class AdminUserBase(BaseModel):
    username: str
    email: Optional[str] = None
    role: str = "admin"

class AdminUserCreate(AdminUserBase):
    password: str

class AdminUserOut(AdminUserBase, ORMBase):
    pass

class JobBase(BaseModel):
    title: str
    company: str
    location: str
    salary: str
    type: str
    level: str
    description: str
    requirements: List[str] = []
    posted_time: str
    applicants: str

class Job(JobBase, ORMBase):
    pass

class TestBase(BaseModel):
    title: str
    tag: str
    description: str
    duration_mins: int
    difficulty: str
    provider_name: str
    max_discount_percentage: int
    questions: List[Any] = []

class TestModel(TestBase, ORMBase):
    pass

class DoctorBase(BaseModel):
    name: str
    specialty: str
    clinic: str
    experience: str
    consultation_fee: float

class Doctor(DoctorBase, ORMBase):
    pass

class OfferBase(BaseModel):
    title: str
    subtitle: str
    description: str
    action: str
    type: str

class Offer(OfferBase, ORMBase):
    pass

class NotificationBase(BaseModel):
    title: str
    message: str
    target_user_id: Optional[UUID] = None
    is_read: bool = False

class Notification(NotificationBase, ORMBase):
    pass

class ActivityLogBase(BaseModel):
    admin_id: str
    action: str
    module_name: str
    record_id: str
    details: dict = {}

class ActivityLog(ActivityLogBase, ORMBase):
    pass

class JobApplicationBase(BaseModel):
    user_id: UUID
    job_id: UUID
    status: str

class JobApplication(JobApplicationBase, ORMBase):
    job: Optional[Job] = None

class TestAttemptBase(BaseModel):
    user_id: UUID
    test_id: UUID
    score: float

class TestAttempt(TestAttemptBase, ORMBase):
    test: Optional[TestModel] = None

class DoctorAppointmentBase(BaseModel):
    user_id: UUID
    doctor_id: UUID
    appointment_date: str
    appointment_time: str
    status: str

class DoctorAppointment(DoctorAppointmentBase, ORMBase):
    doctor: Optional[Doctor] = None

class UserProfileDetails(BaseModel):
    user: User
    job_applications: List[JobApplication] = []
    test_attempts: List[TestAttempt] = []
    doctor_appointments: List[DoctorAppointment] = []

class OTPRequest(BaseModel):
    mobile_number: str

class OTPVerify(BaseModel):
    mobile_number: str
    otp: str

class FirebaseLoginRequest(BaseModel):
    id_token: str

class FirebaseSignupRequest(BaseModel):
    id_token: str
    user_details: UserBase

class TokenResponse(BaseModel):
    access_token: str
    token_type: str
    user: User

class BannerBase(BaseModel):
    image_url: str
    link_url: str

class BannerCreate(BannerBase):
    pass

class Banner(BannerBase, ORMBase):
    pass
