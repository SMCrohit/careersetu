import difflib
import io
import json
import os
import re

import httpx
from pypdf import PdfReader

MAX_RESUME_TEXT_CHARS = 15000

LIST_FIELDS = ["skills", "languages", "hobbies", "work_experience", "education_history",
               "projects", "certifications", "achievements"]


class ResumeAIError(Exception):
    def __init__(self, status_code: int, detail: str):
        self.status_code = status_code
        self.detail = detail


def extract_pdf_text(pdf_bytes: bytes) -> str:
    reader = PdfReader(io.BytesIO(pdf_bytes))
    text = "\n".join((page.extract_text() or "") for page in reader.pages)
    return text.strip()[:MAX_RESUME_TEXT_CHARS]


RESUME_PARSE_PROMPT = """
You extract structured data from a resume. Return ONLY a JSON object with exactly these keys.
Use null for any value not present in the resume. Never invent data.

{
  "full_name": string|null,
  "email": string|null,
  "mobile_number": string|null,
  "whatsapp_number": string|null,
  "city": string|null,
  "state": string|null,
  "pincode": string|null,
  "address": string|null,
  "dob": string|null (YYYY-MM-DD),
  "gender": string|null ("Male", "Female" or "Other"),
  "summary": string|null (2-4 sentences),
  "years_of_experience": number|null,
  "linkedin_url": string|null,
  "github_url": string|null,
  "portfolio_url": string|null,
  "skills": [string],
  "languages": [string],
  "hobbies": [string],
  "headline": string|null (current or target job title, e.g. "Flutter Developer"),
  "work_experience": [{"title": string, "company": string, "duration": string, "bullets": [string]}],
  "education_history": [{"degree": string, "institution": string, "year": string}],
  "projects": [{"title": string, "role": string, "duration": string, "description": string}],
  "certifications": [{"title": string, "organization": string, "year": string}],
  "achievements": [{"title": string, "event": string, "year": string}]
}

For "duration" use the format "MMM YYYY - MMM YYYY" or "MMM YYYY - Present" when dates are available.
Copy each job's responsibility/achievement lines into "bullets" as written. For projects, "description" is one line on what was built.
"""


async def openai_json(messages: list, temperature: float = 0.3, timeout: float = 45.0) -> dict:
    """Calls gpt-4o-mini in JSON mode and returns the parsed object. Raises ResumeAIError on failure."""
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        raise ResumeAIError(503, "AI service is not configured on the server.")

    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                "https://api.openai.com/v1/chat/completions",
                headers={
                    "Content-Type": "application/json",
                    "Authorization": f"Bearer {api_key}"
                },
                json={
                    "model": "gpt-4o-mini",
                    "response_format": {"type": "json_object"},
                    "messages": messages,
                    "temperature": temperature
                },
                timeout=timeout
            )
            response.raise_for_status()
            content = response.json()["choices"][0]["message"]["content"]
            data = json.loads(content)
        except httpx.TimeoutException:
            raise ResumeAIError(502, "AI took too long to respond. Please try again.")
        except (httpx.HTTPError, KeyError, ValueError) as e:
            print(f"OpenAI call failed: {e}")
            raise ResumeAIError(502, "AI couldn't respond right now. Please try again.")

    if not isinstance(data, dict):
        raise ResumeAIError(502, "AI couldn't respond right now. Please try again.")
    return data


async def parse_resume_with_ai(text: str) -> dict:
    data = await openai_json(
        [
            {"role": "system", "content": RESUME_PARSE_PROMPT},
            {"role": "user", "content": f"Resume text:\n\n{text}"},
        ],
        temperature=0,
    )
    for key in LIST_FIELDS:
        if not isinstance(data.get(key), list):
            data[key] = []
    return data


_NAME_TITLES = {"mr", "mrs", "ms", "miss", "dr", "er", "prof", "shri", "smt"}


def _normalize_name(name) -> list:
    tokens = re.sub(r"[^a-z\s]", " ", str(name or "").lower()).split()
    return [t for t in tokens if t not in _NAME_TITLES]


def _last10_digits(phone) -> str:
    return re.sub(r"\D", "", str(phone or ""))[-10:]


def _names_match(profile_name, resume_name) -> bool:
    p, r = _normalize_name(profile_name), _normalize_name(resume_name)
    if not p or not r:
        return False
    if all(t in r for t in p) or all(t in p for t in r):
        return True
    return difflib.SequenceMatcher(None, " ".join(p), " ".join(r)).ratio() >= 0.8


def _check(profile_value, resume_value, matched: bool) -> dict:
    if not profile_value or not resume_value:
        status = "missing"
    else:
        status = "match" if matched else "mismatch"
    return {"status": status, "profile": profile_value or None, "resume": resume_value or None}


def compare_identity(user, profile, extracted: dict) -> dict:
    profile_email = (profile.email if profile and profile.email else None) or user.email
    profile_whatsapp = profile.whatsapp_number if profile else None

    resume_name = extracted.get("full_name")
    resume_email = extracted.get("email")
    resume_phone = extracted.get("mobile_number") or extracted.get("whatsapp_number")

    name_ok = _names_match(user.full_name, resume_name)
    email_ok = bool(profile_email and resume_email
                    and profile_email.strip().lower() == resume_email.strip().lower())
    resume_digits = _last10_digits(resume_phone)
    phone_ok = bool(resume_digits) and resume_digits in {
        _last10_digits(user.mobile_number), _last10_digits(profile_whatsapp)
    }

    checks = {
        "name": _check(user.full_name, resume_name, name_ok),
        "email": _check(profile_email, resume_email, email_ok),
        "phone": _check(user.mobile_number, resume_phone, phone_ok),
    }
    statuses = [c["status"] for c in checks.values()]
    is_match = "mismatch" not in statuses and "match" in statuses
    return {"is_match": is_match, "checks": checks}
