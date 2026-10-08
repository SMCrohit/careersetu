import json

def calculate_profile_score(user, student_profile):
    if not student_profile:
        return 0

    score = 0
    
    # 🔴 High (7-10%)
    if student_profile.resume_data: score += 10
    if student_profile.education_history: score += 8
    if student_profile.work_experience: score += 8
    if student_profile.skills: score += 7

    # 🟡 Medium (4-7%)
    if student_profile.profile_image_url: score += 7
    if student_profile.email: score += 7
    if user.full_name and user.full_name.strip() and user.full_name != 'null': score += 5
    if student_profile.goal_id: score += 5
    if student_profile.summary and student_profile.summary.strip(): score += 5
    if student_profile.certifications: score += 5
    
    # 🟢 Low (1-4%)
    if user.mobile_number and user.mobile_number.strip(): score += 4
    if student_profile.whatsapp_number and student_profile.whatsapp_number.strip(): score += 4
    if student_profile.city and student_profile.city.strip(): score += 4
    if student_profile.linkedin_url and student_profile.linkedin_url.strip(): score += 4
    if student_profile.gender and student_profile.gender.strip(): score += 3
    if student_profile.dob: score += 3
    if student_profile.languages: score += 3
    if student_profile.state and student_profile.state.strip(): score += 2
    if student_profile.pincode and student_profile.pincode.strip(): score += 2
    if student_profile.address and student_profile.address.strip(): score += 2
    if student_profile.country and student_profile.country.strip(): score += 1
    if student_profile.years_of_experience is not None and student_profile.years_of_experience > 0: score += 1

    return min(100, score)
