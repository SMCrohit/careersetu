import io
import html
import base64
from typing import Optional
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, HRFlowable, KeepTogether
from reportlab.lib.units import inch

def _escape(text) -> str:
    if text is None:
        return ""
    return html.escape(str(text).strip())

def generate_applicant_resume_pdf(app) -> bytes:
    """
    Generates a clean, professional, ATS-formatted PDF resume for an applicant's job application.
    Uses applicant profile data, contact details, education, skills, work experience,
    and application screening/cover letter details.
    """
    buf = io.BytesIO()
    doc = SimpleDocTemplate(
        buf,
        pagesize=letter,
        leftMargin=40,
        rightMargin=40,
        topMargin=40,
        bottomMargin=40,
    )

    prof = app.student_profile
    user = prof.user if prof else None
    job = app.job

    name = (user.full_name if user and user.full_name else "Applicant").strip()
    email = (user.email if user and user.email else (prof.email if prof else "")).strip()
    phone = (getattr(user, "phone_number", None) or (prof.whatsapp_number if prof else "") or "").strip()
    
    city = (prof.city if prof and prof.city else "").strip()
    country = (prof.country if prof and prof.country else "").strip()
    location_parts = [p for p in [city, country] if p]
    location = ", ".join(location_parts)

    linkedin = (prof.linkedin_url if prof and prof.linkedin_url else "").strip()
    github = (prof.github_url if prof and prof.github_url else "").strip()
    portfolio = (prof.portfolio_url if prof and prof.portfolio_url else "").strip()

    job_title = job.title if job and job.title else "Professional"
    company_name = job.company_name if job and job.company_name else "Company"

    styles = getSampleStyleSheet()

    # Custom styles
    primary_color = colors.HexColor("#1E3A8A")   # Deep navy
    secondary_color = colors.HexColor("#334155") # Slate 700
    accent_color = colors.HexColor("#2563EB")    # Blue 600
    text_muted = colors.HexColor("#64748B")      # Slate 500
    border_color = colors.HexColor("#CBD5E1")    # Slate 300
    bg_light = colors.HexColor("#F8FAFC")        # Slate 50

    name_style = ParagraphStyle(
        "CandidateName",
        parent=styles["Normal"],
        fontName="Helvetica-Bold",
        fontSize=22,
        leading=26,
        textColor=primary_color,
    )

    headline_style = ParagraphStyle(
        "CandidateHeadline",
        parent=styles["Normal"],
        fontName="Helvetica-Bold",
        fontSize=11,
        leading=15,
        textColor=accent_color,
    )

    contact_style = ParagraphStyle(
        "CandidateContact",
        parent=styles["Normal"],
        fontName="Helvetica",
        fontSize=9,
        leading=13,
        textColor=text_muted,
    )

    section_heading = ParagraphStyle(
        "SectionHeading",
        parent=styles["Normal"],
        fontName="Helvetica-Bold",
        fontSize=12,
        leading=16,
        textColor=primary_color,
        spaceBefore=10,
        spaceAfter=4,
    )

    body_style = ParagraphStyle(
        "BodyDark",
        parent=styles["Normal"],
        fontName="Helvetica",
        fontSize=9.5,
        leading=14,
        textColor=secondary_color,
    )

    bold_item_title = ParagraphStyle(
        "BoldItemTitle",
        parent=styles["Normal"],
        fontName="Helvetica-Bold",
        fontSize=10,
        leading=14,
        textColor=secondary_color,
    )

    item_subtitle = ParagraphStyle(
        "ItemSubtitle",
        parent=styles["Normal"],
        fontName="Helvetica-Oblique",
        fontSize=9,
        leading=13,
        textColor=text_muted,
    )

    q_style = ParagraphStyle(
        "QuestionStyle",
        parent=styles["Normal"],
        fontName="Helvetica-Bold",
        fontSize=9,
        leading=13,
        textColor=secondary_color,
    )

    a_style = ParagraphStyle(
        "AnswerStyle",
        parent=styles["Normal"],
        fontName="Helvetica",
        fontSize=9,
        leading=13,
        textColor=colors.HexColor("#1E293B"),
    )

    story = []

    # 1. Header: Name & Contact
    story.append(Paragraph(_escape(name), name_style))
    story.append(Spacer(1, 2))
    
    headline = f"Applicant for {job_title}"
    if company_name:
        headline += f" at {company_name}"
    story.append(Paragraph(_escape(headline), headline_style))
    story.append(Spacer(1, 4))

    contact_items = []
    if email:
        contact_items.append(f"<b>Email:</b> {_escape(email)}")
    if phone:
        contact_items.append(f"<b>Phone:</b> {_escape(phone)}")
    if location:
        contact_items.append(f"<b>Location:</b> {_escape(location)}")
    if linkedin:
        contact_items.append(f"<b>LinkedIn:</b> {_escape(linkedin)}")
    if github:
        contact_items.append(f"<b>GitHub:</b> {_escape(github)}")
    if portfolio:
        contact_items.append(f"<b>Portfolio:</b> {_escape(portfolio)}")

    story.append(Paragraph(" &nbsp;•&nbsp; ".join(contact_items), contact_style))
    story.append(Spacer(1, 8))
    story.append(HRFlowable(width="100%", thickness=1.5, color=primary_color, spaceBefore=2, spaceAfter=8))

    # 2. Professional Summary
    summary_text = (prof.summary if prof and prof.summary else "").strip()
    if not summary_text:
        # Construct an informative summary if not explicitly provided
        skills_summary = ", ".join(prof.skills[:4]) if prof and prof.skills and isinstance(prof.skills, list) else ""
        if skills_summary:
            summary_text = f"Motivated candidate seeking the {job_title} role with foundational background and expertise in {skills_summary}."
        else:
            summary_text = f"Motivated professional applying for the {job_title} position at {company_name}, bringing dedication, analytical problem-solving, and a commitment to operational excellence."

    story.append(Paragraph("PROFESSIONAL SUMMARY", section_heading))
    story.append(HRFlowable(width="100%", thickness=0.5, color=border_color, spaceBefore=1, spaceAfter=4))
    story.append(Paragraph(_escape(summary_text), body_style))
    story.append(Spacer(1, 8))

    # 3. Core Competencies / Skills
    skills = prof.skills if prof and prof.skills and isinstance(prof.skills, list) else []
    if skills:
        story.append(Paragraph("CORE SKILLS & COMPETENCIES", section_heading))
        story.append(HRFlowable(width="100%", thickness=0.5, color=border_color, spaceBefore=1, spaceAfter=4))
        skills_formatted = " &nbsp;•&nbsp; ".join([f"<b>{_escape(s)}</b>" for s in skills if str(s).strip()])
        story.append(Paragraph(skills_formatted, body_style))
        story.append(Spacer(1, 8))

    # 4. Education History
    education = prof.education_history if prof and prof.education_history and isinstance(prof.education_history, list) else []
    if education:
        story.append(Paragraph("EDUCATION", section_heading))
        story.append(HRFlowable(width="100%", thickness=0.5, color=border_color, spaceBefore=1, spaceAfter=4))
        for edu in education:
            if isinstance(edu, dict):
                deg = _escape(edu.get("degree") or "Degree")
                inst = _escape(edu.get("institution") or edu.get("school") or "")
                yr = _escape(edu.get("year") or edu.get("start", "") + (" - " + edu.get("end", "") if edu.get("end") else ""))
                score = _escape(edu.get("score") or edu.get("grade") or "")

                title_line = f"<b>{deg}</b>"
                if yr:
                    title_line = f"<table width='100%'><tr><td><b>{deg}</b></td><td align='right'>{yr}</td></tr></table>"
                story.append(Paragraph(title_line, bold_item_title))
                if inst or score:
                    inst_line = inst
                    if score:
                        inst_line += f" (Score: {score})"
                    story.append(Paragraph(inst_line, item_subtitle))
                story.append(Spacer(1, 4))
        story.append(Spacer(1, 4))

    # 5. Work Experience
    experience = prof.work_experience if prof and prof.work_experience and isinstance(prof.work_experience, list) else []
    if experience:
        story.append(Paragraph("WORK EXPERIENCE", section_heading))
        story.append(HRFlowable(width="100%", thickness=0.5, color=border_color, spaceBefore=1, spaceAfter=4))
        for exp in experience:
            if isinstance(exp, dict):
                exp_title = _escape(exp.get("title") or exp.get("role") or "Role")
                exp_co = _escape(exp.get("company") or "")
                exp_dur = _escape(exp.get("duration") or (exp.get("start", "") + " - " + exp.get("end", "") if exp.get("start") else ""))
                exp_loc = _escape(exp.get("location") or "")

                t_str = f"<b>{exp_title}</b>"
                if exp_dur:
                    t_str = f"<table width='100%'><tr><td><b>{exp_title}</b></td><td align='right'>{exp_dur}</td></tr></table>"
                story.append(Paragraph(t_str, bold_item_title))
                
                sub_parts = [p for p in [exp_co, exp_loc] if p]
                if sub_parts:
                    story.append(Paragraph(" | ".join(sub_parts), item_subtitle))

                bullets = exp.get("bullets") or exp.get("description") or []
                if isinstance(bullets, str):
                    bullets = [bullets]
                if isinstance(bullets, list):
                    for b in bullets:
                        if b:
                            story.append(Paragraph(f"• {_escape(b)}", body_style))
                story.append(Spacer(1, 6))
        story.append(Spacer(1, 4))

    # 6. Projects & Certifications
    projects = prof.projects if prof and prof.projects and isinstance(prof.projects, list) else []
    if projects:
        story.append(Paragraph("KEY PROJECTS", section_heading))
        story.append(HRFlowable(width="100%", thickness=0.5, color=border_color, spaceBefore=1, spaceAfter=4))
        for proj in projects:
            if isinstance(proj, dict):
                p_title = _escape(proj.get("title") or "Project")
                p_desc = _escape(proj.get("description") or "")
                story.append(Paragraph(f"<b>{p_title}</b>", bold_item_title))
                if p_desc:
                    story.append(Paragraph(p_desc, body_style))
                story.append(Spacer(1, 4))
        story.append(Spacer(1, 4))

    # 7. Screening Responses (Submitted when applying)
    screening = app.screening_responses if app.screening_responses and isinstance(app.screening_responses, dict) else {}
    if screening:
        story.append(Paragraph("APPLICATION SCREENING RESPONSES", section_heading))
        story.append(HRFlowable(width="100%", thickness=0.5, color=border_color, spaceBefore=1, spaceAfter=4))
        for q, a in screening.items():
            story.append(Paragraph(f"<b>Q: {_escape(q)}</b>", q_style))
            story.append(Paragraph(f"A: {_escape(a)}", a_style))
            story.append(Spacer(1, 4))
        story.append(Spacer(1, 4))

    # 8. Cover Letter (if submitted)
    cover_letter = (app.cover_letter or "").strip()
    if cover_letter:
        story.append(Paragraph("SUBMITTED COVER LETTER", section_heading))
        story.append(HRFlowable(width="100%", thickness=0.5, color=border_color, spaceBefore=1, spaceAfter=4))
        story.append(Paragraph(_escape(cover_letter), body_style))
        story.append(Spacer(1, 6))

    # Build PDF
    doc.build(story)
    return buf.getvalue()

def generate_applicant_resume_base64(app) -> str:
    pdf_bytes = generate_applicant_resume_pdf(app)
    return base64.b64encode(pdf_bytes).decode("utf-8")
