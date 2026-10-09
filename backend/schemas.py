from pydantic import BaseModel, ConfigDict
from typing import List, Optional, Any
from datetime import datetime, date, time
from uuid import UUID

class ORMBase(BaseModel):
    id: UUID
    created_datetime: datetime
    is_active: bool
    deleted_datetime: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)

class UserBase(BaseModel):
    mobile_number: Optional[str] = None
    full_name: str
    email: Optional[str] = None
    role: Optional[str] = "student"
    firebase_uid: Optional[str] = None
    firebase_uid: Optional[str] = None

class UserProfileUpdate(BaseModel):
    profile_image_url: Optional[str] = None
    mobile_number: Optional[str] = None
    full_name: Optional[str] = None
    email: Optional[str] = None
    whatsapp_number: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    pincode: Optional[str] = None
    country: Optional[str] = None
    address: Optional[str] = None
    dob: Optional[date] = None
    gender: Optional[str] = None
    marital_status: Optional[str] = None
    portfolio_url: Optional[str] = None
    linkedin_url: Optional[str] = None
    github_url: Optional[str] = None
    summary: Optional[str] = None
    years_of_experience: Optional[float] = None
    preferred_job_location: Optional[dict] = None
    willing_to_relocate: Optional[bool] = None
    expected_salary: Optional[int] = None
    current_salary: Optional[int] = None
    notice_period_days: Optional[int] = None
    skills: Optional[Any] = None
    languages: Optional[Any] = None
    education_history: Optional[Any] = None
    work_experience: Optional[Any] = None
    projects: Optional[Any] = None
    certifications: Optional[Any] = None
    achievements: Optional[Any] = None
    hobbies: Optional[Any] = None
    references: Optional[Any] = None
    goal: Optional[str] = None
    acquisition_source: Optional[str] = None
    resume_data: Optional[Any] = None

class GoalBase(BaseModel):
    name: str

class GoalCreate(GoalBase):
    pass

class Goal(GoalBase, ORMBase):
    pass

class TestCategoryBase(BaseModel):
    name: str

class TestCategoryCreate(TestCategoryBase):
    pass

class TestCategory(TestCategoryBase, ORMBase):
    pass

class AcquisitionSourceBase(BaseModel):
    name: str

class AcquisitionSourceCreate(AcquisitionSourceBase):
    pass

class AcquisitionSource(AcquisitionSourceBase, ORMBase):
    pass

class StudentProfileBase(BaseModel):
    city: Optional[str] = None
    state: Optional[str] = None
    pincode: Optional[str] = None
    country: Optional[str] = "India"
    goal_id: Optional[UUID] = None
    acquisition_source_id: Optional[UUID] = None
    resume_data: Optional[Any] = None
    profile_image_url: Optional[str] = None
    email: Optional[str] = None
    whatsapp_number: Optional[str] = None
    address: Optional[str] = None
    dob: Optional[date] = None
    gender: Optional[str] = None
    marital_status: Optional[str] = None
    portfolio_url: Optional[str] = None
    linkedin_url: Optional[str] = None
    github_url: Optional[str] = None
    summary: Optional[str] = None
    years_of_experience: Optional[float] = 0.0
    preferred_job_location: Optional[dict] = None
    willing_to_relocate: Optional[bool] = False
    expected_salary: Optional[int] = None
    current_salary: Optional[int] = None
    notice_period_days: Optional[int] = None
    skills: Optional[Any] = None
    languages: Optional[Any] = None
    education_history: Optional[Any] = None
    work_experience: Optional[Any] = None
    projects: Optional[Any] = None
    certifications: Optional[Any] = None
    achievements: Optional[Any] = None
    hobbies: Optional[Any] = None
    references: Optional[Any] = None
    profile_completion_score: Optional[int] = 0

class StudentProfile(StudentProfileBase, ORMBase):
    goal: Optional[Goal] = None
    acquisition_source: Optional[AcquisitionSource] = None

class StaffCreateRequest(BaseModel):
    full_name: str
    email: str
    password: str
    role: str

class User(UserBase, ORMBase):
    goal: Optional[Goal] = None
    student_profile: Optional[StudentProfile] = None



class SkillDictionaryBase(BaseModel):
    name: str
    category: str = "General"
    is_approved: bool = True

class SkillDictionary(SkillDictionaryBase, ORMBase):
    pass

class PincodeDirectoryBase(BaseModel):
    pincode: str
    area: str
    city: str
    state: str

class PincodeDirectory(PincodeDirectoryBase, ORMBase):
    pass

class JobBase(BaseModel):
    title: str
    company_name: str
    job_type: str = "Full-time"
    work_model: str = "On-Site"
    location: Optional[dict] = None
    description: str
    
    status: str = "published"
    is_featured: bool = False
    application_routing_mode: str = "manual_review"
    employer_contact_email: Optional[str] = None
    external_apply_url: Optional[str] = None
    company_website: Optional[str] = None
    
    vacancies_count: int = 1
    shift_timing: Optional[str] = None
    is_cover_letter_required: bool = False
    screening_questions: Optional[list] = []
    salary_min: Optional[int] = None
    salary_max: Optional[int] = None
    salary_type: str = "Per Year"
    currency: str = "INR"
    
    experience_required_years: float = 0.0
    education_required: Optional[str] = None
    skills_required: List[str] = []
    languages_required: List[str] = []

class Job(JobBase, ORMBase):
    pass

class TestBase(BaseModel):
    title: str
    tag: str
    description: str
    duration_mins: Optional[int] = 0
    difficulty: str
    provider_name: str
    max_discount_percentage: int = 0
    test_mode: Optional[str] = "overall"
    test_type: Optional[str] = "practice"
    category: Optional[str] = "aptitude"
    provider_logo_url: Optional[str] = None
    is_open: Optional[bool] = False
    open_link_token: Optional[str] = None
    max_attempts: Optional[int] = 0
    show_result_mode: Optional[str] = "best_score"
    pass_percentage: Optional[int] = 60
    negative_marking: Optional[bool] = False
    negative_marks_per_wrong: Optional[float] = 0.25
    shuffle_questions: Optional[bool] = False
    shuffle_options: Optional[bool] = False
    show_answer_after: Optional[str] = "after_submit"
    instructions: Optional[str] = None
    status: Optional[str] = "draft"
    scheduled_start_at: Optional[datetime] = None
    scheduled_end_at: Optional[datetime] = None
    certificate_on_pass: Optional[bool] = False
    sections: Optional[list] = []
    created_by_admin_id: Optional[UUID] = None
    default_per_question_seconds: Optional[int] = 60

class TestQuestionBase(BaseModel):
    test_id: UUID
    question_type: str = "single_select"
    question_text: str
    question_image_url: Optional[str] = None
    question_note: Optional[str] = None
    options: List[dict] = []
    correct_answer: str
    marks: float = 1.0
    negative_marks: Optional[float] = None
    time_limit_seconds: Optional[int] = None
    section: Optional[str] = None
    topic: Optional[str] = None
    subtopic: Optional[str] = None
    difficulty: str = "Medium"
    explanation: Optional[str] = None
    explanation_image_url: Optional[str] = None
    order_index: int = 0

class TestQuestionCreate(TestQuestionBase):
    pass

class TestQuestionUpdate(TestQuestionBase):
    test_id: Optional[UUID] = None
    question_text: Optional[str] = None
    correct_answer: Optional[str] = None

class TestQuestionModel(TestQuestionBase, ORMBase):
    pass

class TestModel(TestBase, ORMBase):
    questions: List[TestQuestionModel] = []

class ProfessionalBase(BaseModel):
    name: str
    profession: str = "Doctor"
    specialty: str
    qualification: Optional[str] = None
    clinic: str
    experience: str
    years_experience_numeric: Optional[int] = 0
    consultation_fee: float
    image_url: Optional[str] = None
    description: Optional[str] = None
    default_rating: float = 0.0
    reviews: Optional[int] = 0
    rating: Optional[float] = None
    
    # Availability
    available_days: Optional[list] = []
    time_slots: Optional[list] = []
    max_bookings_per_slot: Optional[int] = 1
    
    # New fields for Phase 2
    is_featured: Optional[bool] = False
    consultation_mode: Optional[list] = []
    languages_spoken: Optional[list] = []

class ProfessionalReviewBase(BaseModel):
    professional_id: UUID
    rating: float
    comment: Optional[str] = None

class AdminProfessionalReviewCreate(ProfessionalReviewBase):
    user_id: UUID

class ProfessionalReviewCreate(BaseModel):
    rating: float
    comment: Optional[str] = None

class ProfessionalReview(ProfessionalReviewBase, ORMBase):
    user_id: UUID
    user: Optional[UserBase] = None
    professional: Optional[ProfessionalBase] = None

class Professional(ProfessionalBase, ORMBase):
    pass

class OfferBase(BaseModel):
    title: str
    subtitle: str
    description: str
    action: str
    type: str
    city: Optional[str] = None
    discount_code: Optional[str] = None
    valid_until: Optional[datetime] = None

class Offer(OfferBase, ORMBase):
    pass

class ClaimedOfferBase(BaseModel):
    user_id: UUID
    offer_id: UUID

class ClaimedOfferResponse(ClaimedOfferBase, ORMBase):
    offer: Optional[Offer] = None
    user: Optional[UserBase] = None

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
    student_profile_id: UUID
    job_id: UUID
    status: str = "applied"
    resume_snapshot_url: Optional[str] = None
    cover_letter: Optional[str] = None
    screening_responses: dict = {}
    ai_match_score: Optional[int] = None
    notes_by_admin: Optional[str] = None
    employer_feedback: Optional[str] = None
    interview_datetime: Optional[datetime] = None

class JobApplicationCreate(BaseModel):
    job_id: UUID
    cover_letter: Optional[str] = None
    screening_responses: dict = {}

class JobApplication(JobApplicationBase, ORMBase):
    job: Optional[Job] = None

class TestAttemptBase(BaseModel):
    student_profile_id: Optional[UUID] = None
    test_id: UUID
    total_score: float = 0
    max_score: Optional[float] = None
    percentage: Optional[float] = None
    is_passed: Optional[bool] = None
    time_taken_seconds: Optional[int] = 0
    question_responses: List[Any] = []
    ai_report: Optional[dict] = None

class AttemptAnswer(BaseModel):
    question_id: UUID
    selected_option_ids: List[str] = []
    time_spent_seconds: int = 0

class AttemptSubmit(BaseModel):
    test_id: UUID
    time_taken_seconds: int = 0
    answers: List[AttemptAnswer] = []

class TestAttempt(TestAttemptBase, ORMBase):
    completed_at: Optional[datetime] = None
    test: Optional[TestModel] = None

class ProfessionalAppointmentBase(BaseModel):
    user_id: UUID
    professional_id: UUID
    appointment_date: Optional[date] = None
    appointment_time: Optional[time] = None
    status: str
    consultation_mode: Optional[str] = "In-Person"
    notes_by_student: Optional[str] = None
    notes_by_admin: Optional[str] = None
    cancellation_reason: Optional[str] = None
    cancelled_by: Optional[str] = None

class ProfessionalAppointmentCreate(BaseModel):
    professional_id: UUID
    appointment_date: str  # "YYYY-MM-DD" (older builds send "Today" / "Oct 9, 2026")
    appointment_time: str  # "02:00 PM"
    consultation_mode: Optional[str] = None
    notes_by_student: Optional[str] = None

class ProfessionalAppointment(ProfessionalAppointmentBase, ORMBase):
    professional: Optional[Professional] = None
    user: Optional[UserBase] = None

class UserProfileDetails(BaseModel):
    user: User
    job_applications: List[JobApplication] = []
    test_attempts: List[TestAttempt] = []
    professional_appointments: List[ProfessionalAppointment] = []

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
    message: Optional[str] = None

class BannerBase(BaseModel):
    image_url: str
    link_url: str

class BannerCreate(BannerBase):
    pass

class Banner(BannerBase, ORMBase):
    pass

class ResumeChatFile(BaseModel):
    filename: str
    data: str  # base64 encoded PDF

class ResumeChatEvent(BaseModel):
    event: str  # init | message | choice | upload
    text: Optional[str] = None
    choice: Optional[str] = None
    file: Optional[ResumeChatFile] = None

class ResumeChatResponse(BaseModel):
    messages: List[dict]
    draft: dict
    stage: str

class ResumeBuilderSession(BaseModel):
    messages: List[dict]
    draft: dict
    stage: str

class ResumeDraftUpdate(BaseModel):
    draft: dict

class ResumeImproveRequest(BaseModel):
    kind: str  # summary | bullets
    text: str
    context: Optional[str] = ""

class ResumeAnalyzeRequest(BaseModel):
    filename: str
    data: str  # base64 encoded PDF

class IdentityCheck(BaseModel):
    status: str  # match | mismatch | missing
    profile: Optional[str] = None
    resume: Optional[str] = None

class ResumeAnalyzeResponse(BaseModel):
    is_match: bool
    checks: dict[str, IdentityCheck]
    extracted: dict

class ResumeSessionBase(BaseModel):
    chat_history: List[dict] = []
    extracted_data: dict = {}
    uploaded_resume_info: Optional[dict] = None
    status: str = "in_progress"
    current_step: str = "summary"

class ResumeSessionUpdate(BaseModel):
    chat_history: Optional[List[dict]] = None
    extracted_data: Optional[dict] = None
    uploaded_resume_info: Optional[dict] = None
    status: Optional[str] = None
    current_step: Optional[str] = None

class ResumeSessionOut(ResumeSessionBase, ORMBase):
    user_id: UUID

class QuestionTaxonomyBase(BaseModel):
    type: str
    name: str

class QuestionTaxonomyCreate(QuestionTaxonomyBase):
    pass

class QuestionTaxonomyUpdate(BaseModel):
    name: str

class QuestionTaxonomyModel(QuestionTaxonomyBase, ORMBase):
    pass

class MergeTaxonomyRequest(BaseModel):
    type: str
    source_name: str
    target_name: str
