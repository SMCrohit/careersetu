import io
import re
import uuid
import base64
import database
import models
from applicant_resume_generator import generate_applicant_resume_pdf

def backfill(db=None):
    close_db_at_end = False
    if db is None:
        db = database.SessionLocal()
        close_db_at_end = True

    try:
        apps = db.query(models.JobApplication).all()
        print(f"Total applications found: {len(apps)}")
        count = 0
        for app in apps:
            prof = app.student_profile
            user = prof.user if prof else None
            cand_name = (user.full_name if user and user.full_name else "applicant").strip()
            safe_name = re.sub(r'[^A-Za-z0-9_ -]', '', cand_name).replace(' ', '_')
            filename = f"{safe_name}_resume.pdf"

            # If profile already has an uploaded resume file, snapshot that
            if prof and prof.resume_data and isinstance(prof.resume_data, dict) and prof.resume_data.get("data"):
                if not app.resume_snapshot or not isinstance(app.resume_snapshot, dict) or not app.resume_snapshot.get("data"):
                    app.resume_snapshot = {
                        "filename": prof.resume_data.get("filename") or filename,
                        "data": prof.resume_data["data"]
                    }
                    app.resume_snapshot_url = None
                    count += 1
                continue

            # If snapshot is missing or empty, generate one
            if not app.resume_snapshot or not isinstance(app.resume_snapshot, dict) or not app.resume_snapshot.get("data"):
                try:
                    pdf_bytes = generate_applicant_resume_pdf(app)
                    app.resume_snapshot = {
                        "filename": filename,
                        "data": base64.b64encode(pdf_bytes).decode("utf-8")
                    }
                    app.resume_snapshot_url = None
                    count += 1
                except Exception as e:
                    print(f"Error generating for app {app.id}: {e}")

        if count > 0:
            db.commit()
            print(f"Successfully backfilled {count} applications with valid resume snapshots!")
        else:
            print("All job applications already have valid resume snapshots. Nothing to backfill.")
        return count

    except Exception as e:
        db.rollback()
        print(f"Error during resume backfill: {e}")
        return 0
    finally:
        if close_db_at_end:
            db.close()

def backfill_if_needed():
    """Backfills resume snapshots for any job applications that lack them."""
    db = database.SessionLocal()
    try:
        apps = db.query(models.JobApplication).all()
        needs_backfill = any(
            not a.resume_snapshot or not isinstance(a.resume_snapshot, dict) or not a.resume_snapshot.get("data")
            for a in apps
        )
        if not needs_backfill:
            print(f"All {len(apps)} job applications have resume snapshots. No backfill needed.")
            return False
        print(f"Found applications without resume snapshots. Running backfill...")
        count = backfill(db=db)
        return count > 0
    except Exception as e:
        print(f"backfill_if_needed notice: {e}")
        return False
    finally:
        db.close()

if __name__ == "__main__":
    backfill()
