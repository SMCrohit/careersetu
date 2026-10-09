import os
import sqlalchemy
from sqlalchemy import inspect
from dotenv import load_dotenv

load_dotenv('.env.production')
DATABASE_URL = os.getenv("DATABASE_URL")

engine = sqlalchemy.create_engine(DATABASE_URL)
inspector = inspect(engine)

columns = inspector.get_columns('student_profiles')
for col in columns:
    print(f"{col['name']}: nullable={col.get('nullable')}")
