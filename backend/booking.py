"""Professional availability and booking rules.

A professional lists weekdays (`available_days`, e.g. ["Mon", "Wed"]) and slot times
(`time_slots`, e.g. ["02:00 PM"]). Each slot takes up to `max_bookings_per_slot` bookings.
Times are compared in IST, the timezone users book in.
"""
from collections import Counter
from datetime import date, datetime, time, timedelta
from zoneinfo import ZoneInfo

TIMEZONE = "Asia/Kolkata"
BOOKING_WINDOW_DAYS = 30
SAME_DAY_BUFFER_MINUTES = 30
WEEKDAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
INACTIVE_STATUSES = {"cancelled"}


class BookingError(Exception):
    def __init__(self, status_code: int, detail: str):
        self.status_code = status_code
        self.detail = detail


def now_local() -> datetime:
    return datetime.now(ZoneInfo(TIMEZONE)).replace(tzinfo=None)


def normalize_day(value) -> str:
    """'Mon', 'monday', 'MON' -> 'Mon'. Returns '' if not a weekday."""
    key = str(value or "").strip()[:3].lower()
    return next((d for d in WEEKDAYS if d.lower() == key), "")


def available_weekdays(professional) -> set:
    return {d for d in (normalize_day(x) for x in (professional.available_days or [])) if d}


def parse_time(value) -> time:
    """Parses '02:00 PM', '2:00 pm', '14:00' or '14:00:00'."""
    if isinstance(value, time):
        return value.replace(second=0, microsecond=0)
    text = str(value or "").strip().upper()
    for fmt in ("%I:%M %p", "%I:%M%p", "%I %p", "%H:%M", "%H:%M:%S"):
        try:
            return datetime.strptime(text, fmt).time()
        except ValueError:
            continue
    raise ValueError(f"Unrecognised time: {value}")


def format_time(value: time) -> str:
    return value.strftime("%I:%M %p")


def slot_times(professional) -> list:
    """The professional's slots as sorted, de-duplicated `time` values."""
    out = set()
    for raw in professional.time_slots or []:
        try:
            out.add(parse_time(raw))
        except ValueError:
            continue
    return sorted(out)


def parse_date(value) -> date:
    """Parses 'YYYY-MM-DD' plus the older 'Today' and 'Oct 9, 2026' formats."""
    if isinstance(value, date):
        return value
    text = str(value or "").strip()
    if text.lower() == "today":
        return now_local().date()
    if text.lower() == "tomorrow":
        return now_local().date() + timedelta(days=1)
    for fmt in ("%Y-%m-%d", "%b %d, %Y", "%B %d, %Y", "%d-%m-%Y", "%d/%m/%Y"):
        try:
            return datetime.strptime(text, fmt).date()
        except ValueError:
            continue
    raise ValueError(f"Unrecognised date: {value}")


def booking_counts(db, models, professional_id, start: date, end: date) -> Counter:
    """Active bookings per (date, time) in a date range."""
    rows = db.query(models.ProfessionalAppointment.appointment_date, models.ProfessionalAppointment.appointment_time).filter(
        models.ProfessionalAppointment.professional_id == professional_id,
        models.ProfessionalAppointment.is_active == True,
        ~models.ProfessionalAppointment.status.in_(INACTIVE_STATUSES),
        models.ProfessionalAppointment.appointment_date >= start,
        models.ProfessionalAppointment.appointment_date <= end,
    ).all()
    return Counter((d, t.replace(second=0, microsecond=0)) for d, t in rows if d and t)


def user_bookings(db, models, professional_id, user_id, start: date, end: date) -> set:
    """(date, time) slots this user already holds with the professional."""
    if not user_id:
        return set()
    rows = db.query(models.ProfessionalAppointment.appointment_date, models.ProfessionalAppointment.appointment_time).filter(
        models.ProfessionalAppointment.professional_id == professional_id,
        models.ProfessionalAppointment.user_id == user_id,
        models.ProfessionalAppointment.is_active == True,
        ~models.ProfessionalAppointment.status.in_(INACTIVE_STATUSES),
        models.ProfessionalAppointment.appointment_date >= start,
        models.ProfessionalAppointment.appointment_date <= end,
    ).all()
    return {(d, t.replace(second=0, microsecond=0)) for d, t in rows if d and t}


def availability(db, models, professional, days: int = BOOKING_WINDOW_DAYS, user_id=None) -> list:
    """Bookable dates in the window, each with its slots and their status."""
    days = max(1, min(days, BOOKING_WINDOW_DAYS))
    weekdays = available_weekdays(professional)
    slots = slot_times(professional)
    if not weekdays or not slots:
        return []

    now = now_local()
    today = now.date()
    end = today + timedelta(days=days - 1)
    counts = booking_counts(db, models, professional.id, today, end)
    mine = user_bookings(db, models, professional.id, user_id, today, end)
    capacity = max(professional.max_bookings_per_slot or 1, 1)
    cutoff = now + timedelta(minutes=SAME_DAY_BUFFER_MINUTES)

    out = []
    for offset in range(days):
        day = today + timedelta(days=offset)
        weekday = WEEKDAYS[day.weekday()]
        if weekday not in weekdays:
            continue
        day_slots = []
        for t in slots:
            if (day, t) in mine:
                status = "booked"  # held by this user
            elif datetime.combine(day, t) <= cutoff:
                status = "past"
            elif counts[(day, t)] >= capacity:
                status = "full"
            else:
                status = "available"
            day_slots.append({"time": format_time(t), "status": status})
        if any(s["status"] in ("available", "booked") for s in day_slots):
            out.append({"date": day.isoformat(), "weekday": weekday, "slots": day_slots})
    return out


def next_available(db, models, professional):
    for day in availability(db, models, professional):
        for slot in day["slots"]:
            if slot["status"] == "available":
                return {"date": day["date"], "weekday": day["weekday"], "time": slot["time"]}
    return None


def validate_booking(db, models, professional, user_id, raw_date, raw_time, mode):
    """Checks a requested booking. Returns (date, time, mode) or raises BookingError."""
    try:
        day = parse_date(raw_date)
    except ValueError:
        raise BookingError(400, "Please pick a valid date.")
    try:
        slot = parse_time(raw_time)
    except ValueError:
        raise BookingError(400, "Please pick a valid time slot.")

    now = now_local()
    if day < now.date() or datetime.combine(day, slot) <= now + timedelta(minutes=SAME_DAY_BUFFER_MINUTES):
        raise BookingError(400, "That time has already passed. Please pick a later slot.")
    if day > now.date() + timedelta(days=BOOKING_WINDOW_DAYS - 1):
        raise BookingError(400, f"Bookings open only {BOOKING_WINDOW_DAYS} days ahead.")
    if WEEKDAYS[day.weekday()] not in available_weekdays(professional):
        raise BookingError(400, f"{professional.name} isn't available on {day.strftime('%A')}s.")
    if slot not in slot_times(professional):
        raise BookingError(400, "That time isn't one of their available slots.")

    modes = [str(m) for m in (professional.consultation_mode or [])]
    mode = (mode or "").strip() or (modes[0] if modes else "In-Person")
    if modes and mode.lower() not in {m.lower() for m in modes}:
        raise BookingError(400, f"{professional.name} offers only {', '.join(modes)} consultations.")

    # The same student may book other slots (same day or another day), but not the same slot twice.
    if (day, slot) in user_bookings(db, models, professional.id, user_id, day, day):
        raise BookingError(409, "You've already booked this slot. Pick another time or day.")

    capacity = max(professional.max_bookings_per_slot or 1, 1)
    if booking_counts(db, models, professional.id, day, day)[(day, slot)] >= capacity:
        raise BookingError(409, "Sorry, that slot was just booked. Please choose another time.")
    return day, slot, mode


def display_status(appointment) -> str:
    """What the student should see: pending, confirmed, completed, cancelled, missed or expired."""
    status = (appointment.status or "pending").lower()
    if status in ("cancelled", "completed"):
        return status
    starts = datetime.combine(appointment.appointment_date, appointment.appointment_time) \
        if appointment.appointment_date and appointment.appointment_time else None
    is_past = starts is not None and starts < now_local()
    if status in ("sent_to_doctor", "confirmed", "upcoming"):
        return "missed" if is_past else "confirmed"
    return "expired" if is_past else "pending"


def is_upcoming(appointment) -> bool:
    return display_status(appointment) in ("pending", "confirmed")
