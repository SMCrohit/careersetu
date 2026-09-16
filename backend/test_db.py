import sys
import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from models import AdminUser, Base
import auth

db_url = "postgresql://postgres.npcvdrgwctuksedvetby:RAMjikinikalisawari%402026@aws-0-ap-southeast-1.pooler.supabase.com:6543/postgres"

try:
    engine = create_engine(db_url)
    Session = sessionmaker(bind=engine)
    db = Session()
    if db.query(AdminUser).count() == 0:
        print("No admin user found. Creating one...")
        admin_password = "password123"
        default_admin = AdminUser(
            username="admin",
            password_hash=auth.get_password_hash(admin_password),
            role="admin"
        )
        db.add(default_admin)
        db.commit()
    else:
        print(f"Found {db.query(AdminUser).count()} admin users.")
    db.close()
    print("Admin user check completed successfully!")
except Exception as e:
    print(f"Error: {e}")
