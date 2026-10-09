import uuid
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, Date, Time, Numeric, Float, Integer, Text, ForeignKey, JSON
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
    mobile_number = Column(String, unique=True, index=True, nullable=True)
    email = Column(String, unique=True, index=True, nullable=True)
    full_name = Column(String)
    role = Column(String, default="student")
    firebase_uid = Column(String, unique=True, index=True, nullable=True)
    
    student_profile = relationship("StudentProfile", back_populates="user", uselist=False)

class StudentProfile(BaseModel):
    __tablename__ = "student_profiles"
    user_id = Column(UUID(as_uuid=True), ForeignKey('users.id'), unique=True, nullable=False)
    
    # Location fields
    city = Column(String)
    state = Column(String, nullable=True)
    pincode = Column(String, nullable=True)
    country = Column(String, default="India")
    location_data = Column(JSON, nullable=True)
    goal_id = Column(UUID(as_uuid=True), ForeignKey('goals.id'), nullable=True)
    resume_data = Column(JSON, nullable=True)
    profile_image_url = Column(Text, nullable=True)
    
    # Personal Info
    email = Column(String, nullable=True)
    whatsapp_number = Column(String, nullable=True)
    address = Column(Text, nullable=True)
    dob = Column(Date, nullable=True)
    gender = Column(String, nullable=True)
    marital_status = Column(String, nullable=True)
    
    # Professional Links
    portfolio_url = Column(String, nullable=True)
    linkedin_url = Column(String, nullable=True)
    github_url = Column(String, nullable=True)
    
    # Professional Overview & Logistics
    summary = Column(Text, nullable=True)
    years_of_experience = Column(Float, default=0.0)
    preferred_job_location = Column(JSON, nullable=True)
    willing_to_relocate = Column(Boolean, default=False)
    expected_salary = Column(Integer, nullable=True)
    current_salary = Column(Integer, nullable=True)
    notice_period_days = Column(Integer, nullable=True)
    
    # Structured Data
    skills = Column(JSON, nullable=True)
    languages = Column(JSON, nullable=True)
    education_history = Column(JSON, nullable=True)
    work_experience = Column(JSON, nullable=True)
    projects = Column(JSON, nullable=True)
    certifications = Column(JSON, nullable=True)
    achievements = Column(JSON, nullable=True)
    hobbies = Column(JSON, nullable=True)
    references = Column(JSON, nullable=True)
    
    # Acquisition tracking
    acquisition_source_id = Column(UUID(as_uuid=True), ForeignKey('acquisition_sources.id'), nullable=True)
    
    # System Fields
    profile_completion_score = Column(Integer, default=0)
    
    user = relationship("User", back_populates="student_profile")
    goal = relationship("Goal")
    acquisition_source = relationship("AcquisitionSource")
    applications = relationship("JobApplication", back_populates="student_profile")
    test_attempts = relationship("TestAttempt", back_populates="student_profile")

class Goal(BaseModel):
    __tablename__ = "goals"
    name = Column(String, unique=True, index=True, nullable=False)

class TestCategory(BaseModel):
    __tablename__ = "test_categories"
    name = Column(String, unique=True, index=True, nullable=False)

class AcquisitionSource(BaseModel):
    __tablename__ = "acquisition_sources"
    name = Column(String, unique=True, index=True, nullable=False)


class SkillDictionary(BaseModel):
    __tablename__ = "skill_dictionary"
    name = Column(String, unique=True, index=True, nullable=False)
    category = Column(String, default="General")
    is_approved = Column(Boolean, default=True)

class PincodeDirectory(BaseModel):
    __tablename__ = "pincode_directory"
    pincode = Column(String, index=True, nullable=False)
    area = Column(String)
    city = Column(String)
    state = Column(String)

class Job(BaseModel):
    __tablename__ = "jobs"
    # Core
    title = Column(String, index=True)
    company_name = Column(String)
    job_type = Column(String, default="Full-time")
    work_model = Column(String, default="On-Site")
    location = Column(JSON, nullable=True)
    description = Column(Text)
    
    # Metadata & Settings
    status = Column(String, default="published")
    is_featured = Column(Boolean, default=False)
    application_routing_mode = Column(String, default="manual_review")
    employer_contact_email = Column(String, nullable=True)
    external_apply_url = Column(String, nullable=True)
    company_website = Column(String, nullable=True)
    
    # Compensation & Details
    vacancies_count = Column(Integer, default=1)
    shift_timing = Column(String, nullable=True)
    is_cover_letter_required = Column(Boolean, default=False)
    screening_questions = Column(JSON, default=list)
    salary_min = Column(Integer, nullable=True)
    salary_max = Column(Integer, nullable=True)
    salary_type = Column(String, default="Per Year")
    currency = Column(String, default="INR")
    
    # AI Matching / Requirements
    experience_required_years = Column(Float, default=0.0)
    education_required = Column(String, nullable=True)
    skills_required = Column(JSON, default=[])
    languages_required = Column(JSON, default=[])
    
    applications = relationship("JobApplication", back_populates="job")

class Test(BaseModel):
    __tablename__ = "tests"
    title = Column(String, index=True)
    description = Column(Text)
    test_type = Column(String, default="practice")
    category = Column(String, default="aptitude")
    tag = Column(String)
    difficulty = Column(String, default="Medium")
    duration_mins = Column(Integer)
    test_mode = Column(String, default="overall")
    default_per_question_seconds = Column(Integer, default=60)
    provider_name = Column(String)
    provider_logo_url = Column(String, nullable=True)
    is_open = Column(Boolean, default=False)
    open_link_token = Column(String, unique=True, index=True, nullable=True)
    max_attempts = Column(Integer, default=0)
    show_result_mode = Column(String, default="best_score")
    pass_percentage = Column(Integer, default=60)
    negative_marking = Column(Boolean, default=False)
    negative_marks_per_wrong = Column(Float, default=0.25)
    shuffle_questions = Column(Boolean, default=False)
    shuffle_options = Column(Boolean, default=False)
    show_answer_after = Column(String, default="after_submit")
    instructions = Column(Text, nullable=True)
    status = Column(String, default="draft")
    scheduled_start_at = Column(DateTime, nullable=True)
    scheduled_end_at = Column(DateTime, nullable=True)
    certificate_on_pass = Column(Boolean, default=False)
    sections = Column(JSON, default=[])
    created_by_admin_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    max_discount_percentage = Column(Integer, default=0)
    
    questions = relationship("TestQuestion", back_populates="test")
    attempts = relationship("TestAttempt", back_populates="test")
    creator = relationship("User", foreign_keys=[created_by_admin_id])

class TestQuestion(BaseModel):
    __tablename__ = "test_questions"
    test_id = Column(UUID(as_uuid=True), ForeignKey("tests.id"))
    question_type = Column(String, default="mcq")
    question_text = Column(Text)
    question_image_url = Column(String, nullable=True)
    question_note = Column(Text, nullable=True)
    options = Column(JSON, default=[])
    correct_answer = Column(String)
    marks = Column(Float, default=1.0)
    negative_marks = Column(Float, nullable=True)
    time_limit_seconds = Column(Integer, default=0)
    section = Column(String, nullable=True)
    topic = Column(String, nullable=True)
    subtopic = Column(String, nullable=True)
    difficulty = Column(String, default="Medium")
    explanation = Column(Text, nullable=True)
    explanation_image_url = Column(String, nullable=True)
    order_index = Column(Integer, default=0)
    
    test = relationship("Test", back_populates="questions")

class Professional(BaseModel):
    __tablename__ = "professionals"
    name = Column(String, index=True)
    profession = Column(String, default="Doctor")
    specialty = Column(String)
    qualification = Column(String, nullable=True) # e.g. "MBBS, MD"
    clinic = Column(String)
    experience = Column(String)
    years_experience_numeric = Column(Integer, default=0)
    consultation_fee = Column(Numeric)
    image_url = Column(Text, nullable=True)
    description = Column(Text, nullable=True)
    default_rating = Column(Float, default=0.0)
    
    # Availability
    available_days = Column(JSON, default=list) # e.g. ["Monday", "Wednesday"]
    time_slots = Column(JSON, default=list) # e.g. ["10:00 AM", "02:00 PM"]
    max_bookings_per_slot = Column(Integer, default=1)
    
    # New fields for Phase 2
    is_featured = Column(Boolean, default=False)
    consultation_mode = Column(JSON, default=list) # e.g. ["In-Person", "Online"]
    languages_spoken = Column(JSON, default=list) # e.g. ["English", "Hindi"]
    location_city = Column(String, nullable=True)
    is_active = Column(Boolean, default=True)

class ProfessionalReview(BaseModel):
    __tablename__ = "professional_reviews"
    professional_id = Column(UUID(as_uuid=True), ForeignKey("professionals.id"))
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    rating = Column(Float)
    comment = Column(Text, nullable=True)
    
    professional = relationship("Professional")
    user = relationship("User")

class Offer(BaseModel):
    __tablename__ = "offers"
    title = Column(String, index=True)
    subtitle = Column(String)
    description = Column(Text)
    action = Column(String)
    type = Column(String)
    city = Column(String, nullable=True, index=True)
    discount_code = Column(String, nullable=True)
    valid_until = Column(DateTime, nullable=True)

class ClaimedOffer(BaseModel):
    __tablename__ = "claimed_offers"
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    offer_id = Column(UUID(as_uuid=True), ForeignKey("offers.id"))
    
    user = relationship("User")
    offer = relationship("Offer")

class ResumeSession(BaseModel):
    __tablename__ = "resume_sessions"
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    chat_history = Column(JSON, default=[])
    extracted_data = Column(JSON, default={})
    uploaded_resume_info = Column(JSON, nullable=True)
    status = Column(String, default="in_progress")
    current_step = Column(String, default="summary")

    user = relationship("User")

class Notification(BaseModel):
    __tablename__ = "notifications"
    title = Column(String)
    message = Column(Text)
    target_user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    is_read = Column(Boolean, default=False)
    
    user = relationship("User")

class ActivityLog(BaseModel):
    __tablename__ = "activity_logs"
    admin_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    action = Column(String)
    module_name = Column(String)
    record_id = Column(String)
    details = Column(JSON, default={})
    
    admin = relationship("User")

class JobApplication(BaseModel):
    __tablename__ = "job_applications"
    student_profile_id = Column(UUID(as_uuid=True), ForeignKey("student_profiles.id"))
    job_id = Column(UUID(as_uuid=True), ForeignKey("jobs.id"))
    
    status = Column(String, default="applied")
    resume_snapshot_url = Column(Text, nullable=True)
    # Copy of the profile resume at the time of applying: {"filename", "data" (base64 PDF)}
    resume_snapshot = Column(JSON, nullable=True)
    cover_letter = Column(Text, nullable=True)
    screening_responses = Column(JSON, default={})
    
    ai_match_score = Column(Integer, nullable=True)
    notes_by_admin = Column(Text, nullable=True)
    employer_feedback = Column(Text, nullable=True)
    interview_datetime = Column(DateTime, nullable=True)
    
    job = relationship("Job", back_populates="applications")
    student_profile = relationship("StudentProfile", back_populates="applications")

class TestAttempt(BaseModel):
    __tablename__ = "test_attempts"
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    student_profile_id = Column(UUID(as_uuid=True), ForeignKey("student_profiles.id"), nullable=True)
    guest_info = Column(JSON, nullable=True)
    test_id = Column(UUID(as_uuid=True), ForeignKey("tests.id"))
    attempt_number = Column(Integer, default=1)
    status = Column(String, default="completed")
    total_score = Column(Float)
    max_score = Column(Float, nullable=True)
    percentage = Column(Float, nullable=True)
    is_passed = Column(Boolean, nullable=True)
    time_taken_seconds = Column(Integer)
    started_at = Column(DateTime, default=datetime.utcnow)
    completed_at = Column(DateTime, default=datetime.utcnow)
    question_responses = Column(JSON, default=[])
    section_scores = Column(JSON, nullable=True)
    ai_report = Column(JSON, nullable=True)
    certificate_url = Column(String, nullable=True)
    
    test = relationship("Test", back_populates="attempts")
    student_profile = relationship("StudentProfile", back_populates="test_attempts")

class ProfessionalAppointment(BaseModel):
    __tablename__ = "professional_appointments"
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    professional_id = Column(UUID(as_uuid=True), ForeignKey("professionals.id"))
    appointment_date = Column(Date)
    appointment_time = Column(Time)
    status = Column(String)
    
    # New fields for Phase 2
    consultation_mode = Column(String, default="In-Person")
    notes_by_student = Column(Text, nullable=True)
    notes_by_admin = Column(Text, nullable=True)
    professional_notified_at = Column(DateTime, nullable=True)
    student_contact_shared_at = Column(DateTime, nullable=True)
    cancellation_reason = Column(Text, nullable=True)
    cancelled_by = Column(String, nullable=True)

    user = relationship("User")
    professional = relationship("Professional")

class GameSession(BaseModel):
    __tablename__ = "game_sessions"
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    game_type = Column(String)
    score = Column(Integer)
    
    user = relationship("User")

class Banner(BaseModel):
    __tablename__ = "banners"
    image_url = Column(String)
    link_url = Column(String)

class QuestionTaxonomy(BaseModel):
    __tablename__ = "question_taxonomies"
    type = Column(String, index=True) # 'section', 'topic', 'subtopic'
    name = Column(String, index=True)
