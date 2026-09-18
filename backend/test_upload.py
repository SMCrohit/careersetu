import requests

url = "http://localhost:8000/api/tests/c8d17df5-d7de-4df6-9654-26f41c415a6c/upload-questions"
file_path = "../admin-frontend/public/sample_questions.xlsx"

# Using a dummy admin token. Actually, we don't have the token.
# But wait, does the endpoint require an admin token?
# Yes: admin: str = Depends(auth.get_current_admin)
# Let's just create a new python script inside backend to call the function directly or let's look at the backend logs.
