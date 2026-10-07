# Job Board Architecture Plan

Building a professional job board requires capturing the right metadata so students can search and filter effectively (like on LinkedIn or Indeed), while giving you (the Admin) strict control over how applications are handled.

Here is the plan for the robust **Jobs Module**.

## 1. Application Routing Modes
When an Admin creates a job, they must select an `application_routing_mode`. This solves your requirement for how applications are delivered to companies:
- **`manual_review`**: Applications go to the CareerSetu Admin portal. The admin reviews them, clicks "Confirm/Forward", and manually sends the best candidates to the company.
- **`direct_to_employer`**: When a student applies, an automated email is instantly sent to the company's specific `employer_contact_email` with the student's profile/resume attached.

## 2. The `Job` Database Model
Based on industry leaders like LinkedIn, Glassdoor, and Indeed, here are the extensive fields we need to capture when adding a Job.

### **System & Metadata Fields**
- **`status`**: (String) `draft`, `published`, `closed`. Allows Admin to save jobs before showing them.
- **`is_featured`**: (Boolean) If true, the job is pinned to the top of the app with a "Hot Job" badge.

### **Compulsory Fields (Required)**
These fields are essential for students to quickly understand if they want to apply:
- **`title`**: (String) e.g., "Senior Software Engineer".
- **`company_name`**: (String) Name of the hiring company.
- **`job_type`**: (String) e.g., "Full-time", "Part-time", "Contract", "Internship".
- **`work_model`**: (String) e.g., "On-Site", "Remote", "Hybrid".
- **`location`**: (String) The city/state (can be null if Remote).
- **`description`**: (Text) The full job description.
- **`application_routing_mode`**: (Enum) `manual_review`, `direct_to_employer`, or `external_link`.
- **`employer_contact_email`**: (String) Required if mode is `direct_to_employer`.
- **`external_apply_url`**: (String) Required if mode is `external_link` (Redirects student to company's career page).

### **Highly Recommended Fields (Company & Role specifics)**
These fields make the job posting look premium and allow for advanced filtering in the app:
- **`company_logo_url`**: (String) Makes the UI look beautiful.
- **`company_website`**: (String) Link to the company's homepage.
- **`vacancies_count`**: (Integer) Number of open positions (creates urgency).
- **`shift_timing`**: (String) e.g., "Day Shift", "Night Shift", "Flexible".
- **`salary_min` & `salary_max`**: (Integer) e.g., 500,000 to 800,000. 
- **`salary_type`**: (String) e.g., "Per Year", "Per Month", "Hourly".
- **`currency`**: (String) Defaults to "INR".
- **`benefits`**: (JSON Array) e.g., `["Health Insurance", "Work from Home"]`.
- **`deadline_date`**: (Date) When the listing expires and disappears from the app.

### **Candidate Requirements (For Auto-Matching)**
By capturing these, the platform can automatically tell a student "You are a 90% match for this job!" based on their resume:
- **`experience_required_years`**: (Float) Minimum experience required (e.g. 0 for freshers, 2.5 for mid-level).
- **`education_required`**: (String) e.g., "B.Tech", "Any Graduate", "12th Pass".
- **`skills_required`**: (JSON Array) e.g., `["React", "Python", "SQL"]`. 
- **`languages_required`**: (JSON Array) e.g., `["English", "Hindi"]`.

## 3. The `JobApplication` Database Model
When a student clicks "Apply", we create a record linking their `StudentProfile` to the `Job`. To make this function like a true Applicant Tracking System (ATS), we must capture the state of the application perfectly at the moment they apply.

### **Core Identifiers**
- **`job_id`** (Foreign Key)
- **`student_profile_id`** (Foreign Key)

### **Application State & Workflow**
- **`status`**: (String) Expanded pipeline: `applied`, `shortlisted`, `interview_scheduled`, `offered`, `hired`, `rejected`.
- **`applied_datetime`**: (DateTime) Timestamp of application.

### **Candidate Submission Data**
- **`resume_snapshot_url`**: (String - Highly Important) The specific PDF resume they submitted. If the student updates their global profile a month later, the company should still see the exact resume they used to apply.
- **`cover_letter`**: (Text - Optional) If the student wrote a specific message.
- **`screening_responses`**: (JSON) If the admin/company asked screening questions (e.g., "Why do you want this job?"), the student's answers are stored here.

### **Admin & Employer Evaluation**
- **`ai_match_score`**: (Integer) A score from 0-100 calculated at the time of application, showing how well the student's skills matched the job requirements.
- **`notes_by_admin`**: (Text) Private internal notes left by the CareerSetu Admin.
- **`employer_feedback`**: (Text) Feedback returned by the company after reviewing or interviewing the candidate.
- **`interview_datetime`**: (DateTime - Optional) If the status is `interview_scheduled`, this tracks exactly when the interview is happening.

---

**Status:** Ready for feedback. If this architecture perfectly captures how you want the Jobs and Applications to function, let me know and we will proceed to code Phase 1 (updating the Database Models)!
