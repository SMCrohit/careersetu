"""Conversation engine for the in-app AI resume builder.

The conversation is a stage machine. Stage changes, uploads and merges are plain code; OpenAI is
only used to understand free text, fill gaps and improve wording. Everything works on one
canonical resume "draft" shape that the app's preview, PDF templates and editor also use.
"""
import base64
import copy
import json
import re

import resume_ai
from resume_ai import ResumeAIError

# ---------------------------------------------------------------------------
# Draft shape
# ---------------------------------------------------------------------------

EMPTY_DRAFT = {
    "full_name": "", "email": "", "phone": "", "city": "",
    "headline": "", "summary": "",
    "experience": [],      # {title, company, location, start, end, bullets[]}
    "education": [],       # {degree, school, start, end, score}
    "skills": [],
    "projects": [],        # {title, description, bullets[]}
    "certifications": [],  # {title, organization, year}
    "languages": [],
    "links": {"linkedin": "", "github": "", "portfolio": ""},
}

LIST_KEYS = ["experience", "education", "skills", "projects", "certifications", "languages"]
ITEM_FIELDS = {
    "experience": {"title": "", "company": "", "location": "", "start": "", "end": "", "bullets": []},
    "education": {"degree": "", "school": "", "start": "", "end": "", "score": ""},
    "projects": {"title": "", "description": "", "bullets": []},
    "certifications": {"title": "", "organization": "", "year": ""},
}


def _s(value) -> str:
    return str(value).strip() if value is not None else ""


def _str_list(value) -> list:
    if isinstance(value, str):
        value = re.split(r"[,\n]", value)
    if not isinstance(value, list):
        return []
    return [_s(v) for v in value if _s(v)]


def _normalize_item(kind: str, item) -> dict:
    template = ITEM_FIELDS[kind]
    item = item if isinstance(item, dict) else {}
    out = {}
    for key, default in template.items():
        out[key] = _str_list(item.get(key)) if isinstance(default, list) else _s(item.get(key))
    return out


def normalize_draft(draft) -> dict:
    """Coerces any dict into the canonical draft shape."""
    draft = draft if isinstance(draft, dict) else {}
    out = copy.deepcopy(EMPTY_DRAFT)
    for key in ["full_name", "email", "phone", "city", "headline", "summary"]:
        out[key] = _s(draft.get(key))
    for key in ["skills", "languages"]:
        out[key] = list(dict.fromkeys(_str_list(draft.get(key))))
    for kind in ITEM_FIELDS:
        items = draft.get(kind) if isinstance(draft.get(kind), list) else []
        out[kind] = [i for i in (_normalize_item(kind, x) for x in items) if any(v for v in i.values())]
    links = draft.get("links") if isinstance(draft.get("links"), dict) else {}
    out["links"] = {k: _s(links.get(k)) for k in EMPTY_DRAFT["links"]}
    return out


def _split_range(value) -> tuple:
    parts = re.split(r"\s+(?:-|–|to)\s+", _s(value), maxsplit=1)
    if len(parts) == 2:
        return _s(parts[0]), _s(parts[1])
    return "", _s(parts[0])


def _from_profile_shapes(src: dict) -> dict:
    """Maps profile-shaped data (profile JSON columns or resume_ai output) into the draft."""
    experience = []
    for w in src.get("work_experience") or []:
        if isinstance(w, dict):
            start, end = _split_range(w.get("duration"))
            experience.append({"title": w.get("title"), "company": w.get("company"),
                               "start": start, "end": end, "bullets": w.get("bullets") or []})
    education = []
    for e in src.get("education_history") or []:
        if isinstance(e, dict):
            start, end = _split_range(e.get("year"))
            education.append({"degree": e.get("degree"), "school": e.get("institution"), "start": start, "end": end})
    projects = []
    for p in src.get("projects") or []:
        if isinstance(p, dict):
            projects.append({"title": p.get("title"),
                             "description": p.get("description") or p.get("role"),
                             "bullets": p.get("bullets") or []})
    return normalize_draft({
        "full_name": src.get("full_name"),
        "email": src.get("email"),
        "phone": src.get("mobile_number"),
        "city": (_s(src.get("city")).split(", ")[-1]) if src.get("city") else "",
        "headline": src.get("headline"),
        "summary": src.get("summary"),
        "experience": experience,
        "education": education,
        "skills": src.get("skills"),
        "projects": projects,
        "certifications": src.get("certifications"),
        "languages": src.get("languages"),
        "links": {"linkedin": src.get("linkedin_url"), "github": src.get("github_url"),
                  "portfolio": src.get("portfolio_url")},
    })


def profile_to_draft(user, profile) -> dict:
    p = profile
    src = {
        "full_name": user.full_name,
        "email": (p.email if p and p.email else None) or user.email,
        "mobile_number": user.mobile_number,
    }
    if p:
        for key in ["city", "summary", "skills", "languages", "work_experience", "education_history",
                    "projects", "certifications", "linkedin_url", "github_url", "portfolio_url"]:
            src[key] = getattr(p, key, None)
    return _from_profile_shapes(src)


def resume_to_draft(extracted: dict) -> dict:
    return _from_profile_shapes(extracted or {})


def apply_identity(draft: dict, user, profile) -> dict:
    """Name, email and phone always come from the profile."""
    identity = profile_to_draft(user, profile)
    draft = normalize_draft(draft)
    for key in ["full_name", "email", "phone"]:
        draft[key] = identity[key]
    return draft


def merge(profile_draft: dict, resume_draft: dict) -> dict:
    """Resume data wins; anything the resume lacks is filled from the profile."""
    out = normalize_draft(resume_draft)
    base = normalize_draft(profile_draft)
    for key, value in out.items():
        if key == "links":
            out[key] = {k: v or base["links"][k] for k, v in value.items()}
        elif not value:
            out[key] = base[key]
    return out


def apply_patch(draft: dict, patch) -> dict:
    """A patch replaces whole top-level sections, e.g. {"skills": [...]}. Identity keys are ignored."""
    if not isinstance(patch, dict):
        return draft
    out = copy.deepcopy(draft)
    for key, value in patch.items():
        if key in ("full_name", "email", "phone") or key not in EMPTY_DRAFT:
            continue
        if key == "links" and isinstance(value, dict):
            out["links"] = {**out["links"], **value}
        else:
            out[key] = value
    return normalize_draft(out)


def has_content(draft: dict) -> bool:
    d = normalize_draft(draft)
    return bool(d["summary"] or d["experience"] or d["education"] or d["skills"] or d["projects"])


# ---------------------------------------------------------------------------
# Gaps
# ---------------------------------------------------------------------------

def find_gaps(draft: dict, skipped: list) -> list:
    """Ordered list of missing or weak sections, as gap keys."""
    d = normalize_draft(draft)
    gaps = []
    if not d["headline"]:
        gaps.append("headline")
    if len(d["summary"]) < 120:
        gaps.append("summary")
    if not d["experience"]:
        gaps.append("experience")
    for i, job in enumerate(d["experience"][:3]):
        if not job["bullets"]:
            gaps.append(f"bullets:{i}")
    if len(d["skills"]) < 3:
        gaps.append("skills")
    if not d["education"]:
        gaps.append("education")
    if not d["projects"]:
        gaps.append("projects")
    return [g for g in gaps if g not in skipped]


def _gap_question(gap: str, draft: dict) -> tuple:
    """Returns (question, chips) for a gap."""
    d = normalize_draft(draft)
    write = chip("write_for_me", "✨ Write it for me")
    skip = chip("skip", "Skip")
    if gap == "headline":
        suggestions = [j["title"] for j in d["experience"][:2] if j["title"]]
        return ("First, what role are you aiming for? This becomes the headline under your name "
                "(e.g. \"Flutter Developer\" or \"Sales Executive\").",
                [chip_say(s) for s in dict.fromkeys(suggestions)] + [write])
    if gap == "summary":
        return ("Next, your professional summary: 2–3 lines on who you are and what you're great at. "
                "Tell me a little about yourself, or I can write one from your experience.", [write, skip])
    if gap == "experience":
        return ("Do you have any work experience or internships? Share the role, company and dates "
                "(e.g. \"Intern at TCS, Jun–Aug 2023\").", [chip_say("I'm a fresher, no experience yet"), skip])
    if gap.startswith("bullets:"):
        job = d["experience"][int(gap.split(":")[1])]
        role = " at ".join(x for x in [job["title"], job["company"]] if x)
        return (f"For your role as *{role}*, what were your main responsibilities or achievements? "
                "Numbers make it stronger (e.g. \"cut app load time by 40%\").", [write, skip])
    if gap == "skills":
        return ("Which skills should we highlight? List them separated by commas, "
                "or I can suggest some based on your experience.", [write, skip])
    if gap == "education":
        return "What's your highest qualification? Share the degree, college and year.", [skip]
    if gap == "projects":
        tip = "Projects really help freshers stand out." if not d["experience"] else "Projects help you stand out."
        return ("Any projects you're proud of? Give me a title and a line about what you built. " + tip, [write, skip])
    return "Tell me more.", [skip]


# ---------------------------------------------------------------------------
# Messages
# ---------------------------------------------------------------------------

def chip(cid: str, label: str, kind: str = "choice") -> dict:
    """kind: choice (sent to server), message (label sent as text), upload / preview (handled in app)."""
    return {"id": cid, "label": label, "kind": kind}


def chip_say(label: str) -> dict:
    return chip(f"say:{label}", label, "message")


def text_msg(text: str, options: list = None) -> dict:
    return {"role": "assistant", "type": "text", "text": text, "options": options or []}


def card_msg(kind: str, text: str = "", data=None, options: list = None) -> dict:
    return {"role": "assistant", "type": kind, "text": text, "data": data, "options": options or []}


UPLOAD_CHIP = chip("upload", "📄 Upload resume", "upload")
REVIEW_CHIPS = [chip("confirm", "Yes, all correct"), chip("change", "Change something")]


# ---------------------------------------------------------------------------
# AI calls
# ---------------------------------------------------------------------------

DRAFT_SCHEMA_TEXT = """Resume draft JSON shape:
{"headline": str, "summary": str, "city": str,
 "experience": [{"title","company","location","start","end","bullets":[str]}],
 "education": [{"degree","school","start","end","score"}],
 "skills": [str], "projects": [{"title","description","bullets":[str]}],
 "certifications": [{"title","organization","year"}], "languages": [str],
 "links": {"linkedin","github","portfolio"}}
Dates look like "Jan 2022"; use "Present" for a current role. full_name, email and phone are fixed and must never be changed."""

WRITING_RULES = """Writing rules: professional, concise, ATS-friendly. Bullets start with a strong action verb,
show impact and include numbers only when the user gave them (never invent facts, companies or metrics),
max ~2 lines each, 3-5 bullets per role. Summary: 2-3 sentences, no "I"."""


async def interpret(stage: str, options: list, draft: dict, text: str, gap: str = None) -> dict:
    """Understands a free-text message. Returns {option, draft_patch, reply, done}."""
    option_text = ", ".join(f'"{o["id"]}" ({o["label"]})' for o in options if o["kind"] == "choice") or "none"
    system = f"""You are CareerSetu's friendly, professional resume assistant chatting with a job seeker in India.
Current stage: {stage}. {f'Current question is about: {gap}.' if gap else ''}
Quick-reply options the user can pick: {option_text}.

{DRAFT_SCHEMA_TEXT}
{WRITING_RULES}

Read the user's message and return ONLY a JSON object:
{{"option": one option id if the message clearly means that option, else null,
  "draft_patch": an object with ONLY the top-level draft sections that should change (send the full new value of each changed section), or {{}},
  "done": true if the current question is answered or the user doesn't want to answer it, else false,
  "reply": a short, warm reply (1-3 sentences; use *bold* only for a few key words, never a whole sentence). If something is unclear, ask one specific follow-up question. If the message is off-topic, politely bring them back to the resume.}}

Guidance:
- At stage "mismatch": "style", "design", "look", "format" means option "style"; "data", "content", "details", "information" means "use_content".
- At stage "review": if the user describes corrections, apply them in draft_patch and set option null.
- At stage "interview": extract the answer into draft_patch (professionally reworded per the writing rules) and set done=true when the question is answered. If the user says they are a fresher or have none, set done=true with an empty patch.
- At stage "ready": apply any requested change to the resume in draft_patch.
"""
    user = f"Current draft:\n{json.dumps(normalize_draft(draft))}\n\nUser message: {text}"
    data = await resume_ai.openai_json([{"role": "system", "content": system},
                                        {"role": "user", "content": user}])
    valid_ids = {o["id"] for o in options if o["kind"] == "choice"}
    return {
        "option": data.get("option") if data.get("option") in valid_ids else None,
        "draft_patch": data.get("draft_patch") if isinstance(data.get("draft_patch"), dict) else {},
        "done": bool(data.get("done")),
        "reply": _s(data.get("reply")),
    }


async def write_for_gap(gap: str, draft: dict) -> dict:
    """Drafts content for a gap from what the resume already contains. Returns a draft patch."""
    d = normalize_draft(draft)
    if gap.startswith("bullets:"):
        idx = int(gap.split(":")[1])
        task = (f'Write 3-4 bullets for experience[{idx}] ({d["experience"][idx]["title"]} at '
                f'{d["experience"][idx]["company"]}) using typical responsibilities for that role. '
                'Return {"experience": [the full experience list with those bullets filled]}.')
    else:
        task = {
            "headline": 'Write a headline (target job title, max 5 words). Return {"headline": str}.',
            "summary": 'Write a professional summary. Return {"summary": str}.',
            "skills": 'Suggest 6-10 relevant skills, keeping existing ones first. Return {"skills": [str]}.',
            "projects": 'Suggest one realistic project entry based on their skills, clearly generic so they can edit it. Return {"projects": [...]}.',
        }.get(gap, 'Return {}.')
    system = f"You write resume content.\n{DRAFT_SCHEMA_TEXT}\n{WRITING_RULES}\nReturn ONLY JSON."
    data = await resume_ai.openai_json([{"role": "system", "content": system},
                                        {"role": "user", "content": f"Draft:\n{json.dumps(d)}\n\nTask: {task}"}],
                                       temperature=0.6)
    return data if isinstance(data, dict) else {}


async def polish(draft: dict) -> dict:
    """Rewrites the summary and experience bullets. Returns a patch with summary and experience."""
    d = normalize_draft(draft)
    payload = {"summary": d["summary"],
               "experience": [{"title": j["title"], "company": j["company"], "bullets": j["bullets"]} for j in d["experience"]]}
    system = (f"You improve resume wording.\n{WRITING_RULES}\nKeep the same number of roles in the same order. "
              'Return ONLY JSON: {"summary": str, "experience": [{"bullets": [str]}]}')
    data = await resume_ai.openai_json([{"role": "system", "content": system},
                                        {"role": "user", "content": json.dumps(payload)}])
    improved = data.get("experience") if isinstance(data.get("experience"), list) else []
    experience = copy.deepcopy(d["experience"])
    for job, new in zip(experience, improved):
        bullets = _str_list(new.get("bullets")) if isinstance(new, dict) else []
        if bullets:
            job["bullets"] = bullets
    return {"summary": _s(data.get("summary")) or d["summary"], "experience": experience}


async def improve_text(kind: str, text: str, context: str = "") -> dict:
    """'Improve with AI' for the editor. kind is 'summary' or 'bullets' (text = one bullet per line)."""
    if kind == "bullets":
        shape = '{"bullets": [str]}'
    else:
        shape = '{"text": str}'
    system = f"You improve resume wording.\n{WRITING_RULES}\nReturn ONLY JSON: {shape}"
    user = f"Context: {context}\n\n{'Bullets' if kind == 'bullets' else 'Summary'}:\n{text}"
    data = await resume_ai.openai_json([{"role": "system", "content": system},
                                        {"role": "user", "content": user}])
    if kind == "bullets":
        return {"bullets": _str_list(data.get("bullets"))}
    return {"text": _s(data.get("text"))}


# ---------------------------------------------------------------------------
# Stage machine
# ---------------------------------------------------------------------------

STAGE_OPTIONS = {
    "source_confirm": [chip("continue", "Looks good, continue"), UPLOAD_CHIP],
    "source_upload": [UPLOAD_CHIP, chip("scratch", "Start from scratch")],
    "mismatch": [chip("use_content", "Use its content"), chip("style", "Use its design/style"), UPLOAD_CHIP],
    "review": REVIEW_CHIPS,
    "polish": [chip("apply_polish", "Apply improvements"), chip("keep_mine", "Keep mine")],
    "profile_sync": [chip("sync_yes", "Yes, update profile"), chip("sync_no", "No thanks")],
    "ready": [chip("preview", "👀 Preview resume", "preview")],
}


class Turn:
    """Mutable state for one event: the session's stage/draft/info plus the reply being built."""

    def __init__(self, stage: str, draft: dict, info: dict, user, profile):
        self.stage = stage
        self.draft = normalize_draft(draft)
        self.info = info if isinstance(info, dict) else {}
        self.user = user
        self.profile = profile
        self.messages = []
        self.sync_profile = False

    def say(self, text: str, options: list = None):
        self.messages.append(text_msg(text, options))

    def card(self, kind: str, text: str = "", data=None, options: list = None):
        self.messages.append(card_msg(kind, text, data, options))

    @property
    def skipped(self) -> list:
        return self.info.setdefault("skipped", [])


def _first_name(user) -> str:
    return (_s(user.full_name).split(" ") or ["there"])[0] or "there"


def _decode_pdf(data: str) -> bytes:
    try:
        return base64.b64decode(data, validate=False)
    except Exception:
        return b""


async def _read_resume(pdf_bytes: bytes) -> dict:
    """Returns resume_ai output for a PDF. Raises ResumeAIError with a user-facing message."""
    if not pdf_bytes.startswith(b"%PDF"):
        raise ResumeAIError(400, "That doesn't look like a PDF. Please upload your resume as a PDF file.")
    if len(pdf_bytes) > 5 * 1024 * 1024:
        raise ResumeAIError(413, "That file is over 5MB. Please upload a smaller PDF.")
    try:
        text = resume_ai.extract_pdf_text(pdf_bytes)
    except Exception:
        raise ResumeAIError(422, "I couldn't open that PDF. Could you try a different file?")
    if len(text) < 50:
        raise ResumeAIError(422, "I couldn't read any text in that PDF. It may be a scanned image. "
                                 "Please upload a text-based PDF.")
    return await resume_ai.parse_resume_with_ai(text)


def _show_review(t: Turn, intro: str):
    t.stage = "review"
    t.card("data_card", intro, t.draft)
    t.say("Is all of this correct for you, or would you like to change something?", REVIEW_CHIPS)


async def _ask_next_gap(t: Turn, lead: str = ""):
    gaps = find_gaps(t.draft, t.skipped)
    if not gaps:
        await _start_polish(t, lead)
        return
    t.stage = "interview"
    t.info["gap"] = gaps[0]
    question, options = _gap_question(gaps[0], t.draft)
    t.say(f"{lead}\n\n{question}".strip(), options)


async def _start_polish(t: Turn, lead: str = ""):
    d = t.draft
    if not d["summary"] and not any(j["bullets"] for j in d["experience"]):
        _start_profile_sync(t, lead)
        return
    improved = await polish(d)
    t.info["polish"] = improved
    t.stage = "polish"
    preview = ""
    first = next((j for j in improved["experience"] if j["bullets"]), None)
    if first:
        bullets = "\n".join(f"• {b}" for b in first["bullets"][:3])
        preview = f"\n\nFor example, *{first['title']}*:\n{bullets}"
    t.say(f"{lead}\n\nGreat, that covers everything! ✍️ I've polished your summary and bullet points "
          f"with strong action verbs.{preview}\n\nShall I apply these improvements?".strip(),
          STAGE_OPTIONS["polish"])


def _start_profile_sync(t: Turn, lead: str = ""):
    t.stage = "profile_sync"
    t.say(f"{lead}\n\nOne last thing: should I also add these skills, jobs and education to your "
          "CareerSetu profile? It helps recruiters find you. Your name, email and phone stay as they are.".strip(),
          STAGE_OPTIONS["profile_sync"])


def _finish(t: Turn, lead: str = ""):
    t.stage = "ready"
    t.card("ready_card", f"{lead}\n\nYour resume is ready 🎉 Open the preview to pick from 10 templates, "
                         "download it, or edit anything. You can also ask me for changes here anytime.".strip(),
           None, STAGE_OPTIONS["ready"])


async def _handle_upload(t: Turn, filename: str, pdf_bytes: bytes, from_profile: bool = False):
    try:
        extracted = await _read_resume(pdf_bytes)
    except ResumeAIError as e:
        if from_profile:
            raise
        t.say(e.detail, STAGE_OPTIONS["source_upload"])
        return

    check = resume_ai.compare_identity(t.user, t.profile, extracted)
    resume_draft = resume_to_draft(extracted)
    profile_draft = profile_to_draft(t.user, t.profile)

    if check["is_match"]:
        t.draft = apply_identity(merge(profile_draft, resume_draft), t.user, t.profile)
        intro = (f"I've pulled your details from your profile and *{filename}*. Here's what I found:"
                 if from_profile else f"Thanks! I've read *{filename}*. Here's everything I found:")
        if from_profile:
            t.stage = "source_confirm"
            t.card("data_card", intro, t.draft)
            t.say("Shall we continue with this, or would you like to upload a different resume?",
                  STAGE_OPTIONS["source_confirm"])
        else:
            _show_review(t, intro)
        return

    t.info["pending"] = resume_draft
    t.stage = "mismatch"
    found = extracted.get("full_name") or extracted.get("email") or "someone else"
    t.say(f"Hmm, it seems *{filename}* isn't your resume. The name/email on it belongs to *{found}*, "
          "not your profile. 🤔\n\nWhat would you like to use from it?", STAGE_OPTIONS["mismatch"])


async def _start(t: Turn):
    t.draft = profile_to_draft(t.user, t.profile)
    t.say(f"Hi {_first_name(t.user)} 👋 I'm your CareerSetu resume assistant. Together we'll build a "
          "polished, ATS-friendly resume in just a few minutes. I'll use what's already in your profile, "
          "so you only need to fill the gaps.")

    resume_file = t.profile.resume_data if t.profile and isinstance(t.profile.resume_data, dict) else None
    if resume_file and resume_file.get("data"):
        try:
            await _handle_upload(t, resume_file.get("filename") or "your resume",
                                 _decode_pdf(resume_file["data"]), from_profile=True)
            if t.stage != "mismatch":
                return
            # The profile's resume belongs to someone else: fall back to asking for an upload.
            t.messages.pop()
            t.info.pop("pending", None)
        except ResumeAIError:
            pass

    if len(find_gaps(t.draft, [])) <= 3:
        t.stage = "source_confirm"
        t.card("data_card", "I've pulled your details from your profile. Here's what I found:", t.draft)
        t.say("Shall we continue with this, or would you like to upload a resume as well?",
              STAGE_OPTIONS["source_confirm"])
        return

    t.stage = "source_upload"
    t.card("upload_card", "Have a resume already? Upload it and I'll read it for you, "
                          "or we can build one from scratch together.", None, STAGE_OPTIONS["source_upload"])


async def _handle_choice(t: Turn, option: str):
    if option == "continue" or option == "scratch":
        await _ask_next_gap(t, "Perfect, let's go! 🚀" if option == "scratch" else "Great! Let's fill in the gaps.")
    elif option == "use_content":
        pending = t.info.pop("pending", None) or {}
        profile_draft = profile_to_draft(t.user, t.profile)
        t.draft = apply_identity(merge(profile_draft, pending), t.user, t.profile)
        # The resume belongs to someone else, so their location isn't the user's.
        t.draft["city"] = profile_draft["city"]
        _show_review(t, "Sure! I'll use the content from that resume, keeping *your* name, email and phone "
                        "from your profile. Here's the combined data:")
    elif option == "style":
        t.say("Sorry, I can't copy a resume's design or style yet. 🙏 But you can choose from 10 professional "
              "templates in the preview. Would you like to use its content instead?",
              [chip("use_content", "Use its content"), UPLOAD_CHIP, chip("scratch", "Start from scratch")])
    elif option == "confirm":
        await _ask_next_gap(t, "Awesome! ✅")
    elif option == "change":
        t.stage = "review"
        t.say("Sure, tell me what to change. For example: \"I left Infosys in March 2024\" or "
              "\"remove Java from my skills\".")
    elif option == "write_for_me" and t.stage == "interview":
        gap = t.info.get("gap", "")
        patch = await write_for_gap(gap, t.draft)
        t.draft = apply_patch(t.draft, patch)
        if gap in find_gaps(t.draft, []):
            t.skipped.append(gap)
        await _ask_next_gap(t, "Here's what I wrote. You can tweak it later in the editor. ✍️")
    elif option == "skip" and t.stage == "interview":
        t.skipped.append(t.info.get("gap", ""))
        await _ask_next_gap(t, "No problem, skipping that.")
    elif option == "apply_polish":
        t.draft = apply_patch(t.draft, t.info.pop("polish", {}))
        _start_profile_sync(t, "Done, improvements applied! ✨")
    elif option == "keep_mine":
        t.info.pop("polish", None)
        _start_profile_sync(t, "Sure, keeping your original wording.")
    elif option == "sync_yes":
        t.sync_profile = True
        _finish(t, "Done, your profile is updated too. ✅")
    elif option == "sync_no":
        _finish(t, "No problem, your profile stays as it is.")
    else:
        t.say("Sorry, I didn't get that. Could you say it another way?", STAGE_OPTIONS.get(t.stage))


async def _handle_message(t: Turn, text: str):
    options = STAGE_OPTIONS.get(t.stage, [])
    if t.stage == "interview":
        options = [chip("write_for_me", "Write it for me"), chip("skip", "Skip")]
    result = await interpret(t.stage, options, t.draft, text, t.info.get("gap"))

    if result["option"]:
        await _handle_choice(t, result["option"])
        return

    if result["draft_patch"]:
        t.draft = apply_patch(t.draft, result["draft_patch"])

    if t.stage == "review":
        if result["draft_patch"]:
            _show_review(t, result["reply"] or "Updated! Here's the latest:")
        else:
            t.say(result["reply"] or "Could you tell me exactly what to change?", REVIEW_CHIPS)
    elif t.stage == "interview":
        gap = t.info.get("gap", "")
        if result["done"]:
            if gap in find_gaps(t.draft, []):
                t.skipped.append(gap)
            await _ask_next_gap(t, result["reply"])
        else:
            t.say(result["reply"], [chip("write_for_me", "✨ Write it for me"), chip("skip", "Skip")])
    elif t.stage == "ready":
        if result["draft_patch"]:
            t.card("ready_card", result["reply"] or "Updated your resume!", None, STAGE_OPTIONS["ready"])
        else:
            t.say(result["reply"], STAGE_OPTIONS["ready"])
    else:
        t.say(result["reply"] or "Please pick one of the options below.", options)


async def handle_event(stage: str, draft: dict, info: dict, user, profile, event: dict) -> Turn:
    """Runs one user event through the stage machine. Never raises for AI failures."""
    t = Turn(stage, draft, info, user, profile)
    kind = event.get("event")
    try:
        if kind == "init":
            await _start(t)
        elif kind == "upload":
            file = event.get("file") or {}
            await _handle_upload(t, file.get("filename") or "resume.pdf", _decode_pdf(file.get("data") or ""))
        elif kind == "choice":
            choice = event.get("choice") or ""
            offered = t.info.get("offered", [])
            if choice in [o["id"] for o in offered if o["kind"] == "choice"]:
                await _handle_choice(t, choice)
            else:
                t.say("Let's continue from where we are.", offered)
        else:
            await _handle_message(t, _s(event.get("text")))
    except ResumeAIError as e:
        t.say(f"Sorry, I'm having trouble right now. {e.detail}", STAGE_OPTIONS.get(t.stage))
    t.draft = apply_identity(t.draft, user, profile)
    # Remember which chips are on screen so stale taps on older messages are ignored.
    offered = next((m["options"] for m in reversed(t.messages) if m["options"]), None)
    if offered is not None:
        t.info["offered"] = offered
    return t


def draft_to_profile_update(draft: dict) -> dict:
    """Maps the draft back to PUT /api/users/profile fields. Never includes name, email or phone."""
    d = normalize_draft(draft)

    def rng(a, b):
        return " - ".join(x for x in [a, b] if x)

    update = {
        "skills": d["skills"] or None,
        "languages": d["languages"] or None,
        "work_experience": [{"title": j["title"], "company": j["company"], "duration": rng(j["start"], j["end"]),
                             "bullets": j["bullets"]} for j in d["experience"]] or None,
        "education_history": [{"degree": e["degree"], "institution": e["school"], "year": rng(e["start"], e["end"])}
                              for e in d["education"]] or None,
        "projects": [{"title": p["title"], "role": p["description"], "duration": ""} for p in d["projects"]] or None,
        "certifications": d["certifications"] or None,
        "summary": d["summary"] or None,
        "linkedin_url": d["links"]["linkedin"] or None,
        "github_url": d["links"]["github"] or None,
        "portfolio_url": d["links"]["portfolio"] or None,
    }
    return {k: v for k, v in update.items() if v is not None}
