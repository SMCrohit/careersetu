# 🧪 CareerSetu — Test Module: Full Design Plan

## What is the Test Module?

Tests on CareerSetu are **assessments published by Companies / Organizations** (via Admin) that students can discover and attempt inside the app. Think of it like a marketplace for exams — Aptitude tests, Subject tests, Company-specific hiring assessments, Competitive exam mocks (IAS, GATE, etc.).

---

## 1. 📋 Test Types

| Type | Description |
|---|---|
| **Open Test** | No login required. Link opens app directly → test starts. If app not installed → redirects to Play Store. |
| **Registered Test** | Requires student account. Supports tracking, leaderboard, reattempts. |
| **Company Test** | Conducted by a company for hiring. Admin lists it on behalf of company. |
| **Mock / Practice Test** | Aptitude, Subject, Competitive (IAS, GATE, etc.) |

---

## 2. 🗃️ Data Model Design

### `Test` (Updated)

| Field | Type | Notes |
|---|---|---|
| `id` | UUID | Primary key |
| `title` | String | e.g. "TCS NQT 2025 Mock" |
| `description` | Text | About the test |
| `test_type` | Enum | `open`, `registered`, `company_hiring`, `practice` |
| `category` | Enum | `aptitude`, `subject`, `competitive`, `coding`, `language`, `psychometric`, `custom` |
| `tag` | String | Profession tags (existing) |
| `difficulty` | Enum | `Easy`, `Medium`, `Hard` |
| `duration_mins` | Integer | Overall time limit |
| `test_mode` | Enum | `overall`, `per_question` |
| `provider_name` | String | Company/Org name |
| `provider_logo_url` | String | Company logo |
| `is_open` | Boolean | Open (no login) vs Registered |
| `open_link_token` | String | Unique token for deep link |
| `max_attempts` | Integer | 0 = unlimited |
| `show_result_mode` | Enum | `first_attempt`, `last_attempt`, `best_score` |
| `pass_percentage` | Integer | e.g. 60 (%) |
| `negative_marking` | Boolean | |
| `negative_marks_per_wrong` | Float | e.g. 0.25 |
| `shuffle_questions` | Boolean | |
| `shuffle_options` | Boolean | |
| `show_answer_after` | Enum | `immediately`, `after_submit`, `never` |
| `instructions` | Text | Shown before starting |
| `status` | Enum | `draft`, `published`, `archived` |
| `scheduled_start_at` | DateTime | Optional scheduled publish |
| `scheduled_end_at` | DateTime | Optional expiry |
| `certificate_on_pass` | Boolean | |
| `sections` | JSON | Section names with time limits |
| `created_by_admin_id` | UUID | FK to Users |

---

### `TestQuestion` (Updated)

| Field | Type | Notes |
|---|---|---|
| `id` | UUID | |
| `test_id` | UUID FK | |
| `question_type` | Enum | `mcq`, `true_false`, `multi_select` |
| `question_text` | Text | The question |
| `question_image_url` | String | Optional diagram/image |
| `question_note` | Text | Note shown above question |
| `options` | JSON | Array of option objects (see below) |
| `correct_answer` | String or JSON | Single or multiple correct |
| `marks` | Float | Default: 1 |
| `negative_marks` | Float | Per-question override |
| `time_limit_seconds` | Integer | 0 = no limit |
| `section` | String | Section name |
| `topic` | String | e.g. Mathematics |
| `subtopic` | String | e.g. Algebra |
| `difficulty` | Enum | Easy / Medium / Hard |
| `explanation` | Text | Shown after answer |
| `explanation_image_url` | String | Optional explanation diagram |
| `order_index` | Integer | Display order |

#### Option Object Structure:
```json
{
  "id": "opt_a",
  "text": "Option text here",
  "image_url": null
}
```

---

### `TestAttempt` (Updated)

| Field | Type | Notes |
|---|---|---|
| `id` | UUID | |
| `student_profile_id` | UUID FK | |
| `test_id` | UUID FK | |
| `attempt_number` | Integer | 1, 2, 3... |
| `status` | Enum | `in_progress`, `completed`, `abandoned` |
| `total_score` | Float | Calculated score |
| `max_score` | Float | Max possible |
| `percentage` | Float | |
| `is_passed` | Boolean | |
| `time_taken_seconds` | Integer | |
| `started_at` | DateTime | |
| `completed_at` | DateTime | |
| `question_responses` | JSON | Per-question answers |
| `section_scores` | JSON | Score breakdown by section |
| `ai_report` | JSON | AI-generated insights |
| `certificate_url` | String | If passed + cert enabled |

#### `question_responses` JSON structure:
```json
[
  {
    "question_id": "uuid",
    "selected_answer": "opt_b",
    "is_correct": true,
    "time_spent_seconds": 45,
    "marks_awarded": 1.0
  }
]
```

---

## 3. 🔢 Question Types Supported

| Type | Options Count | Notes |
|---|---|---|
| **MCQ (4-option)** | 4 | Standard multiple choice |
| **MCQ (5-option)** | 5 | Extra option variant |
| **True / False** | 2 | Only 2 options |
| **Multi-Select** | 4–5 | Multiple correct answers (checkbox) |
| **With Image** | Any | Question has `question_image_url` |
| **With Note** | Any | Question has `question_note` shown above |

---

## 4. 🎯 Which Result to Show: First or Last?

**Decision: Admin configures `show_result_mode` per test:**

| Mode | Behavior |
|---|---|
| `first_attempt` | Only 1st attempt result shown; re-attempts for practice only |
| `last_attempt` | Latest attempt always replaces shown result |
| `best_score` | **(Recommended default)** Show highest score across all attempts |

> **Recommended: `best_score`** — fairest for students, motivates reattempts.

---

## 5. 🔗 Open Test Flow (No Login Required)

```
Admin creates test → is_open = true
  ↓
System generates unique open_link_token
  ↓
Deep link:       careersetu://open-test/{token}
Universal link:  https://careersetu.in/t/{token}
  ↓
Android Intent handler:
  → App installed      → Opens test directly
  → App not installed  → Redirect to Play Store (with referral)
  ↓
Student completes test (anonymous session)
Result shown immediately — no account needed
Optionally prompt: "Save your result? Create account →"
```

---

## 6. 📄 Sample Question Paper — All Fields

```json
{
  "test": {
    "title": "TCS NQT 2025 — Full Mock Test",
    "description": "Complete mock test matching TCS NQT pattern with 3 sections.",
    "test_type": "company_hiring",
    "category": "aptitude",
    "difficulty": "Medium",
    "duration_mins": 90,
    "test_mode": "overall",
    "provider_name": "CareerSetu",
    "is_open": false,
    "max_attempts": 3,
    "show_result_mode": "best_score",
    "pass_percentage": 60,
    "negative_marking": true,
    "negative_marks_per_wrong": 0.25,
    "shuffle_questions": true,
    "shuffle_options": true,
    "show_answer_after": "after_submit",
    "instructions": "Read each question carefully. 1/4 marks deducted for wrong answers.",
    "sections": [
      { "name": "Quantitative Aptitude", "questions_count": 20, "time_mins": 30 },
      { "name": "Verbal Ability",        "questions_count": 15, "time_mins": 25 },
      { "name": "Reasoning",             "questions_count": 15, "time_mins": 35 }
    ]
  },
  "questions": [
    {
      "question_type": "mcq",
      "question_text": "A train travels 360 km in 4 hours. What is its speed?",
      "question_image_url": null,
      "question_note": "Use: Speed = Distance / Time",
      "options": [
        { "id": "opt_a", "text": "80 km/h",  "image_url": null },
        { "id": "opt_b", "text": "90 km/h",  "image_url": null },
        { "id": "opt_c", "text": "100 km/h", "image_url": null },
        { "id": "opt_d", "text": "120 km/h", "image_url": null }
      ],
      "correct_answer": "opt_b",
      "marks": 1,
      "negative_marks": 0.25,
      "section": "Quantitative Aptitude",
      "topic": "Speed and Distance",
      "subtopic": "Basic Speed Calculation",
      "difficulty": "Easy",
      "explanation": "Speed = Distance / Time = 360 / 4 = 90 km/h",
      "explanation_image_url": null,
      "time_limit_seconds": 0
    },
    {
      "question_type": "true_false",
      "question_text": "The Earth revolves around the Sun.",
      "options": [
        { "id": "opt_a", "text": "True",  "image_url": null },
        { "id": "opt_b", "text": "False", "image_url": null }
      ],
      "correct_answer": "opt_a",
      "marks": 1,
      "section": "General Knowledge",
      "topic": "Science",
      "difficulty": "Easy",
      "explanation": "Earth revolves around the Sun in approximately 365 days."
    },
    {
      "question_type": "mcq",
      "question_text": "Identify the shape shown in the figure.",
      "question_image_url": "https://cdn.careersetu.in/questions/shape_001.png",
      "question_note": "Look at the diagram carefully before answering.",
      "options": [
        { "id": "opt_a", "text": "Triangle",     "image_url": null },
        { "id": "opt_b", "text": "Quadrilateral", "image_url": null },
        { "id": "opt_c", "text": "Pentagon",      "image_url": null },
        { "id": "opt_d", "text": "Hexagon",       "image_url": null },
        { "id": "opt_e", "text": "Circle",        "image_url": null }
      ],
      "correct_answer": "opt_c",
      "marks": 2,
      "section": "Reasoning",
      "topic": "Spatial Reasoning",
      "difficulty": "Medium"
    },
    {
      "question_type": "multi_select",
      "question_text": "Which of the following are prime numbers?",
      "options": [
        { "id": "opt_a", "text": "2",  "image_url": null },
        { "id": "opt_b", "text": "4",  "image_url": null },
        { "id": "opt_c", "text": "7",  "image_url": null },
        { "id": "opt_d", "text": "11", "image_url": null }
      ],
      "correct_answer": ["opt_a", "opt_c", "opt_d"],
      "marks": 2,
      "negative_marks": 0,
      "section": "Quantitative Aptitude",
      "topic": "Number Theory",
      "difficulty": "Easy",
      "explanation": "2, 7, and 11 are prime numbers. 4 is divisible by 2."
    }
  ]
}
```

---

## 7. 📤 Bulk Upload — Excel Template Columns

| Column | Required | Notes |
|---|---|---|
| `question_text` | ✅ | The question text |
| `question_type` | ✅ | `mcq` / `true_false` / `multi_select` |
| `question_note` | ❌ | Note shown above question |
| `question_image_url` | ❌ | URL to question image/diagram |
| `option_a` | ✅ | First option text |
| `option_b` | ✅ | Second option text |
| `option_c` | ❌ | Third option (omit for True/False) |
| `option_d` | ❌ | Fourth option |
| `option_e` | ❌ | Fifth option |
| `option_a_image` | ❌ | Image URL for option A |
| `option_b_image` | ❌ | Image URL for option B |
| `correct_answer` | ✅ | `A`, `B`, `C`, `D`, `E` or `A,C` for multi-select |
| `marks` | ❌ | Default: 1 |
| `negative_marks` | ❌ | Default: 0 |
| `section` | ❌ | Section name |
| `topic` | ❌ | Topic |
| `subtopic` | ❌ | Subtopic |
| `difficulty` | ❌ | Easy / Medium / Hard |
| `explanation` | ❌ | Explanation text |
| `explanation_image_url` | ❌ | Explanation image URL |
| `time_limit_seconds` | ❌ | Per-question time (0 = no limit) |

---

## 8. 🛠️ Admin Panel — Feature Roadmap

### Tests List Page
- [x] List, Search, Filter by tag
- [ ] Filter by `test_type`, `category`, `status`
- [ ] Stats cards: Total / Published / Drafts / Open
- [ ] Duplicate test
- [ ] Schedule publish/expire dates

### Create/Edit Test Form
- [x] Title, Tags, Description, Duration, Difficulty, Provider, Test Mode
- [ ] `test_type` — Open / Registered / Company / Practice
- [ ] `category` — Aptitude / Subject / Competitive / etc.
- [ ] `is_open` toggle + generated deep link display
- [ ] `max_attempts` (0 = unlimited)
- [ ] `show_result_mode` — First / Last / Best
- [ ] `pass_percentage`
- [ ] Negative marking toggle + per-wrong value
- [ ] Shuffle questions / options toggles
- [ ] Show answer after: Immediately / After Submit / Never
- [ ] Instructions text area
- [ ] Section manager (name, question count, time)
- [ ] Provider logo upload
- [ ] Status: Draft → Published → Archived

### Test Questions Editor
- [x] Add / Edit / Delete questions manually
- [x] Bulk upload via Excel/PDF
- [x] Section, Topic, Subtopic, Difficulty, Explanation
- [ ] Question type selector (MCQ / True-False / Multi-Select)
- [ ] Question image upload
- [ ] Question note field
- [ ] Explanation image upload
- [ ] Option image upload
- [ ] Marks and negative marks per question
- [ ] Drag-to-reorder questions
- [ ] Filter/group by section
- [ ] Preview mode (see test as student)
- [ ] Question bank (import from reusable pool)

---

## 9. 📱 Student App — Test Flow

```
1. Discover
   → Home feed / Search / Category / Deep link / Company page

2. Test Detail Screen
   → Title, Provider logo, Duration, Difficulty
   → Section breakdown, Number of questions
   → Marking scheme (negative marking info)
   → Previous attempts summary (best / last score)
   → [Start Test] button

3. Pre-Test Instructions
   → Full instructions text
   → Rules: timing, negative marking, shuffle
   → [I'm Ready — Start] button

4. Test-Taking Screen
   → Top: Timer + Progress bar (Q n of N)
   → Question with optional note + image
   → Options (radio = MCQ/TF, checkbox = Multi-select)
   → Option images if present
   → Section tabs (if multiple sections)
   → [Flag] button for review later
   → [Previous] / [Next] navigation
   → Question palette: jump to any question
   → [Submit Test] button

5. Result Screen
   → Score: XX / YY (ZZ%)
   → Pass / Fail badge
   → Time taken
   → Section-wise score breakdown
   → Correct / Wrong / Skipped counts
   → AI Insights card
   → Rank (if competitive/leaderboard enabled)
   → [Download Certificate] (if passed + enabled)
   → [Review Answers] button
   → [Reattempt] button (if max_attempts not reached)

6. Answer Review Screen
   → Each question listed
   → Student's answer + correct answer highlighted
   → Explanation text shown
   → Explanation image if present
```

---

## 10. 🏗️ Implementation Plan

### Phase 1 — Core Model Upgrades
1. Alembic migration: add new fields to `Test`, `TestQuestion`, `TestAttempt`
2. Update backend API: create/edit test with all new fields
3. Update Admin: expanded Create/Edit Test form
4. Update Admin: questions editor with `question_type`, image upload, marks
5. Generate `open_link_token` on test creation (if `is_open=true`)

### Phase 2 — Upload & Question Bank
6. Updated Excel bulk upload template with all columns
7. PDF AI-parsing for question extraction
8. Question Bank table (`question_pool`) for reuse across tests
9. Admin preview mode

### Phase 3 — Student App
10. Test discovery UI (feed, search, category browse)
11. Deep link handler for open tests (Android intent filter)
12. Test-taking screen (timer, navigation, question palette)
13. Attempt save/resume (in-progress support)
14. Result + review screens
15. AI report generation (per section weak areas)

### Phase 4 — Advanced Features
16. Certificate PDF generation on pass
17. Leaderboard + rank system
18. Scheduled publish / auto-expire
19. Per-test analytics dashboard (admin)
20. Anti-cheat / proctoring (optional)

---

## 11. 🤔 Key Design Decisions

| Question | Decision | Reason |
|---|---|---|
| Which score to show? | **Best score** (default) | Fairest; motivates reattempts |
| Student sees answers during test? | Configurable (`show_answer_after`) | Some hiring tests must hide answers |
| Open test = fully anonymous? | Yes, prompt account creation after result | Better conversion |
| Image storage | Firebase Storage / S3 with CDN | Scalable delivery |
| Negative marking granularity | Per-test default, overridable per question | Matches real exam patterns |
| Multi-correct scoring | Full marks only if all correct selected | Strict grading default |
