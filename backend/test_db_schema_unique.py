import os
import sqlalchemy
from sqlalchemy import inspect
from dotenv import load_dotenv

load_dotenv('.env.production')
DATABASE_URL = os.getenv("DATABASE_URL")

engine = sqlalchemy.create_engine(DATABASE_URL)
inspector = inspect(engine)

indexes = inspector.get_indexes('student_profiles')
for idx in indexes:
    print(f"Index: {idx['name']}, Unique: {idx['unique']}, Columns: {idx['column_names']}")
