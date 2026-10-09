"""Server-side grading and AI summaries for student test attempts."""
import json
import random
from collections import defaultdict
from datetime import datetime

import resume_ai
from resume_ai import ResumeAIError


# ---------------------------------------------------------------------------
# Questions
# ---------------------------------------------------------------------------

def normalize_options(options) -> list:
    """Options as [{id, text}]. Older rows may store plain strings."""
    out = []
    for i, opt in enumerate(options or []):
        if isinstance(opt, dict):
            oid = str(opt.get("id") if opt.get("id") is not None else i + 1)
            out.append({"id": oid, "text": str(opt.get("text") or "")})
        else:
            out.append({"id": str(i + 1), "text": str(opt)})
    return out


def correct_option_ids(question) -> set:
    """Correct answers as a set of option ids.

    Stored formats seen: an option id ("2"), a JSON list ('["2","3"]'),
    option text (admin form), and '||'-joined option texts for multi-select.
    """
    options = normalize_options(question.options)
    raw = (question.correct_answer or "").strip()
    if not raw:
        return set()

    tokens = None
    if raw.startswith("["):
        try:
            parsed = json.loads(raw)
            if isinstance(parsed, list):
                tokens = [str(t).strip() for t in parsed]
        except ValueError:
            pass
    if tokens is None:
        tokens = [t.strip() for t in raw.split("||")] if "||" in raw else [raw]

    by_id = {o["id"]: o["id"] for o in options}
    by_text = {o["text"].strip().lower(): o["id"] for o in options if o["text"].strip()}
    ids = set()
    for token in tokens:
        if token in by_id:
            ids.add(by_id[token])
        elif token.lower() in by_text:
            ids.add(by_text[token.lower()])
    return ids


def question_time_limit(question, test) -> int:
    return int(question.time_limit_seconds or test.default_per_question_seconds or 60)


def ordered_questions(test) -> list:
    return sorted([q for q in test.questions if q.is_active], key=lambda q: (q.order_index or 0, str(q.id)))


def student_questions(test) -> list:
    """Questions for taking the test: no answers or explanations, shuffled if the test says so."""
    questions = ordered_questions(test)
    if test.shuffle_questions:
        questions = random.sample(questions, len(questions))
    out = []
    for q in questions:
        options = normalize_options(q.options)
        if test.shuffle_options and q.question_type != "true_false":
            options = random.sample(options, len(options))
        out.append({
            "id": str(q.id),
            "question_type": q.question_type or "single_select",
            "question_text": q.question_text or "",
            "question_image_url": q.question_image_url,
            "question_note": q.question_note,
            "options": options,
            "marks": float(q.marks or 1),
            "negative_marks": _negative_marks(q, test),
            "time_limit_seconds": question_time_limit(q, test),
            "section": q.section or "General",
            "topic": q.topic or "General",
        })
    return out


def _negative_marks(question, test) -> float:
    if not test.negative_marking:
        return 0.0
    if question.negative_marks is not None:
        return float(question.negative_marks)
    return float(test.negative_marks_per_wrong or 0)


# ---------------------------------------------------------------------------
# Grading
# ---------------------------------------------------------------------------

def grade(test, answers: list) -> dict:
    """Scores an attempt. `answers` is [{question_id, selected_option_ids, time_spent_seconds}]."""
    by_question = {str(a.get("question_id")): a for a in answers if isinstance(a, dict)}
    responses = []
    total = 0.0
    max_score = 0.0
    sections = defaultdict(lambda: {"score": 0.0, "max_score": 0.0, "correct": 0, "total": 0})

    for q in ordered_questions(test):
        options = normalize_options(q.options)
        text_of = {o["id"]: o["text"] for o in options}
        answer = by_question.get(str(q.id), {})
        selected = {str(s) for s in (answer.get("selected_option_ids") or []) if str(s) in text_of}
        correct = correct_option_ids(q)
        marks = float(q.marks or 1)

        attempted = bool(selected)
        is_correct = attempted and bool(correct) and selected == correct
        if is_correct:
            awarded = marks
        elif attempted:
            awarded = -_negative_marks(q, test)
        else:
            awarded = 0.0

        total += awarded
        max_score += marks
        section = q.section or "General"
        sections[section]["score"] += awarded
        sections[section]["max_score"] += marks
        sections[section]["total"] += 1
        sections[section]["correct"] += 1 if is_correct else 0

        responses.append({
            "question_id": str(q.id),
            "question_text": q.question_text or "",
            "question_type": q.question_type or "single_select",
            "topic": q.topic or "General",
            "subtopic": q.subtopic or "",
            "section": section,
            "options": options,
            "selected_option_ids": sorted(selected),
            "correct_option_ids": sorted(correct),
            # Kept for the admin panel, which shows these fields.
            "selected_option": ", ".join(text_of[s] for s in sorted(selected)) if selected else None,
            "correct_option": ", ".join(text_of[c] for c in sorted(correct) if c in text_of),
            "is_attempted": attempted,
            "is_correct": is_correct,
            "marks": marks,
            "marks_awarded": round(awarded, 2),
            "time_spent_seconds": int(answer.get("time_spent_seconds") or 0),
            "explanation": q.explanation,
        })

    total = max(total, 0.0)
    percentage = round(total / max_score * 100, 1) if max_score else 0.0
    return {
        "total_score": round(total, 2),
        "max_score": round(max_score, 2),
        "percentage": percentage,
        "is_passed": percentage >= (test.pass_percentage or 0),
        "section_scores": [
            {"section": name, "score": round(s["score"], 2), "max_score": s["max_score"],
             "correct": s["correct"], "total": s["total"]}
            for name, s in sections.items()
        ],
        "question_responses": responses,
    }


def counts(responses: list) -> dict:
    attempted = sum(1 for r in responses if r.get("is_attempted", True))
    correct = sum(1 for r in responses if r.get("is_correct"))
    return {
        "total_questions": len(responses),
        "attempted": attempted,
        "correct": correct,
        "incorrect": attempted - correct,
        "skipped": len(responses) - attempted,
    }


STRONG_ACCURACY = 70
WEAK_ACCURACY = 50


def topic_scores(responses: list) -> list:
    """Accuracy per topic, strongest first. Computed from graded responses, so it never depends on AI."""
    topics = defaultdict(lambda: {"correct": 0, "total": 0, "subtopic": ""})
    for r in responses:
        t = topics[r.get("topic") or "General"]
        t["total"] += 1
        t["correct"] += 1 if r.get("is_correct") else 0
        t["subtopic"] = t["subtopic"] or (r.get("subtopic") or "")
    out = [
        {"topic": name, "subtopic": t["subtopic"], "correct": t["correct"], "total": t["total"],
         "accuracy": round(t["correct"] / t["total"] * 100) if t["total"] else 0}
        for name, t in topics.items()
    ]
    return sorted(out, key=lambda t: -t["accuracy"])


# ---------------------------------------------------------------------------
# AI summary
# ---------------------------------------------------------------------------

AI_REPORT_PROMPT = """You are an encouraging career-test coach for a student in India. Analyse their test attempt
and write a short, specific performance report in second person ("You"). Base it only on the data given.

Return ONLY a JSON object:
{
  "overall_insight": "2-3 sentences about how they did and what it means",
  "strong_areas": [{"topic": str, "subtopic": str, "accuracy": number 0-100}],
  "weak_areas": [{"topic": str, "subtopic": str, "accuracy": number 0-100}],
  "time_management": "1 sentence about their pacing",
  "next_steps": ["2-3 short, concrete actions to improve"]
}
Use topics exactly as given. Topics with accuracy >= 70% are strengths, below 50% need work."""


async def ai_report(test, result: dict, time_taken_seconds: int):
    """Returns the AI summary dict, or None if AI is unavailable."""
    responses = result["question_responses"]
    if not responses:
        return None

    topics = defaultdict(lambda: {"correct": 0, "total": 0, "time": 0, "subtopic": "", "sample": ""})
    for r in responses:
        t = topics[r["topic"]]
        t["total"] += 1
        t["correct"] += 1 if r["is_correct"] else 0
        t["time"] += r["time_spent_seconds"]
        t["subtopic"] = t["subtopic"] or r["subtopic"]
        t["sample"] = t["sample"] or r["question_text"][:120]

    c = counts(responses)
    lines = [
        f"- {name} ({t['subtopic'] or 'general'}): {t['correct']}/{t['total']} correct "
        f"({round(t['correct'] / t['total'] * 100)}%), {round(t['time'] / t['total'])}s avg. e.g. \"{t['sample']}\""
        for name, t in topics.items()
    ]
    summary = (
        f"Test: {test.title} ({test.category or 'general'}, {test.difficulty})\n"
        f"Score: {result['total_score']} / {result['max_score']} ({result['percentage']}%), "
        f"pass mark {test.pass_percentage}% -> {'passed' if result['is_passed'] else 'not passed'}\n"
        f"Answered {c['attempted']} of {c['total_questions']} ({c['skipped']} skipped), "
        f"{c['correct']} correct, {c['incorrect']} wrong\n"
        f"Time: {time_taken_seconds}s used of {(test.duration_mins or 0) * 60}s allowed\n"
        f"By topic:\n" + "\n".join(lines[:20])
    )
    try:
        data = await resume_ai.openai_json(
            [{"role": "system", "content": AI_REPORT_PROMPT}, {"role": "user", "content": summary}],
            temperature=0.4, timeout=25.0,
        )
    except ResumeAIError as e:
        print(f"Test AI report skipped: {e.detail}")
        return None

    # Strong/weak topics come from the graded data so they always match the scores shown.
    scores = topic_scores(responses)
    pick = lambda t: {"topic": t["topic"], "subtopic": t["subtopic"], "accuracy": t["accuracy"]}

    return {
        "overall_insight": str(data.get("overall_insight") or ""),
        "strong_areas": [pick(t) for t in scores if t["accuracy"] >= STRONG_ACCURACY],
        "weak_areas": [pick(t) for t in scores if t["accuracy"] < WEAK_ACCURACY],
        "time_management": str(data.get("time_management") or ""),
        "next_steps": [str(s) for s in (data.get("next_steps") or []) if s][:3],
        "generated_at": datetime.utcnow().isoformat(),
    }
