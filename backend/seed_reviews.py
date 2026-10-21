"""Seed 35 realistic reviews for various professionals by real student users in the database."""

import random
from datetime import datetime, timedelta
from database import SessionLocal
import models

DOCTOR_COMMENTS = [
    "Very patient and listened to all my concerns carefully. Prescribed effective treatment.",
    "Excellent consultation! Explained the diagnosis in simple terms and put my mind at ease.",
    "Very professional and empathetic approach. Felt heard and well-guided throughout.",
    "Dr. helped me immensely with my mental health issues. Highly recommend for counseling.",
    "Quick appointment and thorough checkup. The follow-up advice was super helpful.",
    "Great demeanor and very knowledgeable. Solved an issue I had been struggling with for months.",
    "Extremely thorough and kind. Took the time to understand my routine before suggesting lifestyle changes.",
    "One of the best doctors I have consulted. Practical advice and no unnecessary tests."
]

CA_COMMENTS = [
    "Incredible guidance for setting up our startup's compliance and taxation framework.",
    "Made tax filing and accounting seamless for a beginner founder. Highly recommended!",
    "Extremely sharp and insightful on financial structuring. Saved us a lot of potential headaches.",
    "Clear, concise, and very professional financial consultation. Worth every rupee."
]

LAWYER_COMMENTS = [
    "Clear and crisp legal advice regarding our contracts. Highly professional.",
    "Helped review our partnership deeds with utmost detail and provided great insights.",
    "Very knowledgeable in corporate law. Resolved all my queries during the call.",
    "Practical and actionable guidance on intellectual property and agreements."
]

CONSULTANT_COMMENTS = [
    "Helped me choose the right university and shortlisted countries based on my budget. So helpful!",
    "The exam prep roadmap provided was spot-on. Boosted my confidence for the entrance test.",
    "Very realistic guidance on career transitions and job market expectations.",
    "Super motivating session! Clarified all my doubts about higher studies abroad.",
    "In-depth review of my profile with practical steps to improve my chances."
]

PROFESSOR_COMMENTS = [
    "Concepts were explained with amazing clarity. Great mentoring for competitive exams.",
    "His physics problem-solving techniques are game-changers. Loved the session!",
    "Very supportive and encouraging mentor. Clarified all foundational doubts.",
    "Outstanding pedagogy and patience in answering even basic questions."
]

TECH_COMMENTS = [
    "Gave great feedback on my tech stack and system design. Truly experienced engineer.",
    "Helped me prepare for technical interviews and highlighted areas of improvement.",
    "Solid advice on building real-world projects and improving code architecture.",
    "Insightful code review and tips on modern software best practices."
]

GENERAL_COMMENTS = [
    "Very prompt, insightful, and professional consultation. Would definitely book again.",
    "Detailed guidance with clear next steps. Truly appreciated the structured approach.",
    "Polite, punctual, and very helpful throughout the appointment.",
    "Exceeded my expectations! Provided actionable takeaways from our discussion."
]

def get_comment_for_prof(prof):
    p_type = (prof.profession or "").lower()
    if "doctor" in p_type or "psych" in (prof.specialty or "").lower():
        pool = DOCTOR_COMMENTS + GENERAL_COMMENTS
    elif "ca" in p_type or "account" in p_type or "finance" in p_type:
        pool = CA_COMMENTS + GENERAL_COMMENTS
    elif "law" in p_type or "adv" in p_type:
        pool = LAWYER_COMMENTS + GENERAL_COMMENTS
    elif "professor" in p_type or "teacher" in p_type:
        pool = PROFESSOR_COMMENTS + GENERAL_COMMENTS
    elif "dev" in p_type or "tech" in p_type:
        pool = TECH_COMMENTS + GENERAL_COMMENTS
    elif "consult" in p_type:
        pool = CONSULTANT_COMMENTS + GENERAL_COMMENTS
    else:
        pool = GENERAL_COMMENTS
    return random.choice(pool)

def seed(db=None):
    close_db_at_end = False
    if db is None:
        db = SessionLocal()
        close_db_at_end = True

    try:
        professionals = db.query(models.Professional).filter(models.Professional.is_active == True).all()
        if not professionals:
            print("No active professionals found. Cannot seed reviews yet.")
            return 0

        users = db.query(models.User).filter(models.User.role == "student", models.User.is_active == True).all()
        if not users:
            users = db.query(models.User).filter(models.User.is_active == True).all()

        # If still no users exist, create standard sample student reviewers
        if not users or len(users) < 3:
            sample_reviewers = [
                {"name": "Aarav Sharma", "email": "aarav.sharma@careersetu.demo"},
                {"name": "Pooja Patel", "email": "pooja.patel@careersetu.demo"},
                {"name": "Rohan Verma", "email": "rohan.verma@careersetu.demo"},
                {"name": "Sneha Kulkarni", "email": "sneha.kulkarni@careersetu.demo"},
                {"name": "Aditya Nair", "email": "aditya.nair@careersetu.demo"},
                {"name": "Ananya Iyer", "email": "ananya.iyer@careersetu.demo"},
            ]
            for rev in sample_reviewers:
                existing = db.query(models.User).filter(models.User.email == rev["email"]).first()
                if not existing:
                    u = models.User(
                        full_name=rev["name"],
                        email=rev["email"],
                        role="student",
                        is_active=True
                    )
                    db.add(u)
            db.commit()
            users = db.query(models.User).filter(models.User.role == "student", models.User.is_active == True).all()

        print(f"Found {len(professionals)} professionals and {len(users)} users.")

        # Check existing reviews to avoid duplicates
        existing_pairs = set(
            db.query(models.ProfessionalReview.professional_id, models.ProfessionalReview.user_id).all()
        )

        candidates = []
        for p in professionals:
            for u in users:
                if (p.id, u.id) not in existing_pairs:
                    candidates.append((p, u))

        if not candidates:
            print("All available professional-user pairings already have reviews.")
            return 0

        random.seed(42)
        random.shuffle(candidates)

        target_count = min(36, len(candidates))
        selected = candidates[:target_count]

        ratings_distribution = [5.0, 5.0, 4.5, 4.5, 4.5, 4.0, 4.0, 4.8, 4.2, 3.8]

        created_reviews = []
        now = datetime.utcnow()

        for idx, (prof, user) in enumerate(selected):
            rating = random.choice(ratings_distribution)
            comment = get_comment_for_prof(prof)
            # Stagger creation dates over the last 45 days
            days_ago = random.randint(1, 45)
            hours_ago = random.randint(1, 23)
            created_at = now - timedelta(days=days_ago, hours=hours_ago)

            review = models.ProfessionalReview(
                professional_id=prof.id,
                user_id=user.id,
                rating=rating,
                comment=comment,
                created_datetime=created_at,
                is_active=True
            )
            db.add(review)
            created_reviews.append((prof.name, user.full_name or user.email, rating, comment[:40]))

        db.commit()
        print(f"Successfully seeded {len(created_reviews)} reviews!")
        for name, user_name, rating, comm in created_reviews[:6]:
            print(f" - {user_name} -> {name}: {rating}★ ({comm}...)")
        return len(created_reviews)

    except Exception as e:
        db.rollback()
        print(f"Error seeding reviews: {e}")
        return 0
    finally:
        if close_db_at_end:
            db.close()

def seed_if_needed(min_count=15):
    """Seed reviews automatically if table has fewer than min_count reviews."""
    db = SessionLocal()
    try:
        current_count = db.query(models.ProfessionalReview).count()
        if current_count >= min_count:
            print(f"Reviews already exist ({current_count} reviews in DB). No automatic seeding required.")
            return False
        print(f"Review count is {current_count} (< {min_count}). Seeding reviews...")
        count = seed(db=db)
        return count > 0
    except Exception as e:
        print(f"seed_if_needed notice: {e}")
        return False
    finally:
        db.close()

if __name__ == "__main__":
    seed()
