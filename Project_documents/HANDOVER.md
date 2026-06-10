# DengarTrack Comprehensive Handover

## Project Identity & Mission

**DengarTrack** is a digital replacement for Universal Newborn Hearing Screening (UNHS) workflows: screeners enter results at cot side, and the data auto-flows to the coordinator dashboard, follow-up queue, and MOH reports, replacing paper cards, Excel, and WhatsApp groups.

- **Client/user:** Mak Uda / Dr. Siti Aminah Kamaludin.
- **Problem solved:** replacement for paper-based UNHS workflow: paper cards, Excel, WhatsApp groups, and manual MoH reporting.
- **Tech stack:** Flutter mobile app, FastAPI backend, PostgreSQL database.
- **Current status from `misc/CLAUDE_CONTEXT_CURRENT.md`:**
  - Backend: marked **DONE** / FastAPI running at `0.0.0.0:8000`.
  - Flutter Mobile: marked **READY**.
  - Web React: marked **NOT STARTED - empty folder**.

Source evidence:

```md
# misc/CLAUDE_CONTEXT_CURRENT.md
4 | **DengarTrack** is a digital replacement for Universal Newborn Hearing Screening (UNHS) workflows. Screeners enter results at cot side → auto-flows to coordinator dashboard, follow-up queue, and MOH reports. Replaces paper cards, Excel, WhatsApp groups.
17 | ## Current Implementation Status
19 | ### Backend ✅ DONE
20 | - FastAPI running at 0.0.0.0:8000
32 | ### Flutter Mobile ✅ READY
38 | ### Web React 🚧 NOT STARTED
39 | - Empty folder
```

Project README-style context in `misc/DengarTrack_README_MAIN.txt`:

```txt
3 | Exec Summary of the project (DengarTrack) 
4 | 					- a Digital Newborn Hearing Screening Management platform.
5 | :DengarTrack is a purpose built mobile digital workflow platform designed to replaced fragmented paper-based management system currently used in Universal Newborn hearing Screening(UNHS) programmes across Malaysian public hospitals. No equivalent MOH-sanctioned platform currently exists.
8 | What it does: DengarTrack replaces the current UNHS workflow -- Paper cards, Excel, Whatsapp groups, and manual MoH reports -- with a single Intergrated mobile platform. Every screener action at the cot side, flows automatically into the coordinator dashboard, follow-up queue and national reporting system.
10 | *Concept - Design priciples: Speed first(any screener action <60 seconds) offline-Capable (works without WiFi) | Bahasa Melayu/English bilingual | PDPA 2010 compliant | Android 9+ | One entry, many uses
```

---

## Backend Architecture

### `dengartrack-backend/main.py`

File path: `dengartrack-backend/main.py`.

Key facts:

- FastAPI app title: `"DengarTrack API"`.
- Version: `"1.0.0"`.
- Loads `.env` from `dengartrack-backend/dtbackend.env`.
- CORS allows all origins and all methods/headers.
- Startup event fixes null `contact_attempts` in `follow_ups`.
- Includes routers:
  - `auth_router`
  - `audit_logs_router`
  - `babies_router`
  - `followups_router`
  - `hospitals_router` with prefix `/hospitals`
  - `reports_router`
  - `screenings_router`
  - `users_router` with prefix `/users`

Exact code:

```python
# dengartrack-backend/main.py
1 | from fastapi import FastAPI
2 | from fastapi.middleware.cors import CORSMiddleware
3 | from dotenv import load_dotenv
4 | from sqlalchemy import text
5 | import os
6 | 
7 | # Load environment variables
8 | load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), 'dtbackend.env'))
9 | 
10 | from routers.auth_router import router as auth_router
11 | from routers.audit_logs import router as audit_logs_router
12 | from routers.babies import router as babies_router
13 | from routers.followups import router as followups_router
14 | from routers.hospitals import router as hospitals_router
15 | from routers.reports import router as reports_router
16 | from routers.screenings import router as screenings_router
17 | from routers.users import router as users_router
18 | 
19 | from db.database import engine as db_engine
20 | 
21 | app = FastAPI(
22 |     title="DengarTrack API", 
23 |     version="1.0.0",
24 |     generate_unique_id_function=lambda route: route.name
25 | )
26 | 
27 | 
28 | @app.on_event("startup")
29 | def fix_followups_null_data():
30 |     """Set contact_attempts = 0 where NULL to prevent Pydantic validation errors."""
31 |     try:
32 |         with db_engine.begin() as conn:
33 |             conn.execute(text("""
34 |                 UPDATE follow_ups 
35 |                 SET contact_attempts = 0 
36 |                 WHERE contact_attempts IS NULL
37 |             """))
38 |     except Exception:
39 |         pass  # Table may not exist yet on fresh DB
40 | 
41 | # Add CORS middleware
42 | app.add_middleware(
43 |     CORSMiddleware,
44 |     allow_origins=["*"],
45 |     allow_credentials=True,
46 |     allow_methods=["*"],
47 |     allow_headers=["*"],
48 | )
49 | 
50 | # Include routers
51 | app.include_router(auth_router)
52 | app.include_router(audit_logs_router)
53 | app.include_router(babies_router)
54 | app.include_router(followups_router)
55 | app.include_router(hospitals_router, prefix="/hospitals")
56 | app.include_router(reports_router)
57 | app.include_router(screenings_router)
58 | app.include_router(users_router, prefix="/users")
59 | 
60 | @app.get("/")
61 | def root():
62 |     return {"message": "DengarTrack API running", "version": "1.0.0"}
```

### `dengartrack-backend/db/schema.sql`

File path: `dengartrack-backend/db/schema.sql`.

Tables:

1. `users`
2. `hospitals`
3. `babies`
4. `screenings`
5. `follow_ups`
6. `follow_up_events`
7. `audit_logs`

Important constraints:

- `users.role` CHECK: `('screener','coordinator','unhs_coordinator','moh')`.
- `babies.gender` CHECK: `('M','F')`.
- `screenings.screening_type` CHECK: `('TEOAE','AABR','ABR')`.
- `screenings.ear_left` / `ear_right` CHECK: `('pass','refer','not_tested')`.
- `follow_ups.status` CHECK includes:
  - `pending`
  - `contacted`
  - `scheduled`
  - `appointment_booked`
  - `escalated`
  - `completed`
  - `closed`
  - `lost_to_followup`
- `follow_ups.screening_id` has unique constraint.
- `audit_logs` has immutable rules preventing update/delete.

Exact SQL:

```sql
-- dengartrack-backend/db/schema.sql
1 | -- Enable UUID generation
2 | CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
3 | 
4 | -- ─────────────────────────────────────────
5 | -- USERS (all roles live here)
6 | -- ─────────────────────────────────────────
7 | CREATE TABLE users (
8 |     id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
9 |     full_name       VARCHAR(255) NOT NULL,
10 |     email           VARCHAR(255) UNIQUE NOT NULL,
11 |     password_hash   TEXT NOT NULL,
12 |     role            VARCHAR(50) NOT NULL 
13 |                     CHECK (role IN ('screener','coordinator','unhs_coordinator','moh')),
14 |     hospital_id     UUID,
15 |     is_active       BOOLEAN DEFAULT TRUE,
16 |     created_at      TIMESTAMPTZ DEFAULT NOW(),
17 |     updated_at      TIMESTAMPTZ DEFAULT NOW()
18 | );
19 | 
20 | -- ─────────────────────────────────────────
21 | -- HOSPITALS
22 | -- ─────────────────────────────────────────
23 | CREATE TABLE hospitals (
24 |     id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
25 |     name            VARCHAR(255) NOT NULL,
26 |     code            VARCHAR(50) UNIQUE NOT NULL,
27 |     state           VARCHAR(100) NOT NULL,
28 |     created_at      TIMESTAMPTZ DEFAULT NOW()
29 | );
30 | 
31 | -- Add FK after both tables exist
32 | ALTER TABLE users 
33 |     ADD CONSTRAINT fk_users_hospital 
34 |     FOREIGN KEY (hospital_id) REFERENCES hospitals(id);
35 | 
36 | -- ─────────────────────────────────────────
37 | -- BABIES (anonymised)
38 | -- ─────────────────────────────────────────
39 | CREATE TABLE babies (
40 |     id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
41 |     system_id       VARCHAR(50) UNIQUE NOT NULL, -- only ID used externally
42 |     hospital_id     UUID NOT NULL REFERENCES hospitals(id),
43 |     ward            VARCHAR(100),
44 |     date_of_birth   DATE NOT NULL,
45 |     gestational_age INTEGER, -- in weeks
46 |     birth_weight    INTEGER, -- in grams
47 |     gender          CHAR(1) CHECK (gender IN ('M','F')),
48 |     -- Sensitive fields encrypted at application level
49 |     full_name_enc   TEXT,  -- AES-256 encrypted
50 |     ic_number_enc   TEXT,  -- AES-256 encrypted
51 |     created_at      TIMESTAMPTZ DEFAULT NOW()
52 | );
53 | 
54 | -- ─────────────────────────────────────────
55 | -- SCREENINGS
56 | -- ─────────────────────────────────────────
57 | CREATE TABLE screenings (
58 |     id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
59 |     baby_id         UUID NOT NULL REFERENCES babies(id),
60 |     screener_id     UUID NOT NULL REFERENCES users(id),
61 |     hospital_id     UUID NOT NULL REFERENCES hospitals(id),
62 |     screening_type  VARCHAR(50) NOT NULL 
63 |                     CHECK (screening_type IN ('TEOAE','AABR','ABR')),
64 |     ear_left        VARCHAR(20) CHECK (ear_left IN ('pass','refer','not_tested')),
65 |     ear_right       VARCHAR(20) CHECK (ear_right IN ('pass','refer','not_tested')),
66 |     screening_date  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
67 |     attempt_number  INTEGER DEFAULT 1,
68 |     notes           TEXT,
69 |     created_at      TIMESTAMPTZ DEFAULT NOW()
70 | );
71 | 
72 | -- ─────────────────────────────────────────
73 | -- FOLLOW UPS
74 | -- ─────────────────────────────────────────
75 | CREATE TABLE follow_ups (
76 |     id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
77 |     baby_id         UUID NOT NULL REFERENCES babies(id),
78 |     screening_id    UUID NOT NULL REFERENCES screenings(id),
79 |     hospital_id     UUID NOT NULL REFERENCES hospitals(id),
80 |     assigned_to     UUID REFERENCES users(id), -- coordinator
81 |     status          VARCHAR(50) DEFAULT 'pending'
82 |                     CHECK (status IN ('pending','contacted','scheduled','appointment_booked','escalated','completed','closed','lost_to_followup')),
83 |     due_date        DATE,
84 |     last_contacted_at TIMESTAMPTZ,
85 |     appointment_date  TIMESTAMPTZ,
86 |     completed_at      TIMESTAMPTZ,
87 |     ltfu_reason       VARCHAR(100),
88 |     contact_attempts  INTEGER DEFAULT 0,
89 |     notes           TEXT,
90 |     created_at      TIMESTAMPTZ DEFAULT NOW(),
91 |     updated_at      TIMESTAMPTZ DEFAULT NOW()
92 | );
93 | 
94 | ALTER TABLE follow_ups
95 |     ADD CONSTRAINT uq_follow_ups_screening UNIQUE (screening_id);
96 | 
97 | CREATE TABLE follow_up_events (
98 |     id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
99 |     follow_up_id    UUID NOT NULL REFERENCES follow_ups(id) ON DELETE CASCADE,
100|     user_id         UUID REFERENCES users(id),
101|     action          VARCHAR(100) NOT NULL,
102|     from_status     VARCHAR(50),
103|     to_status       VARCHAR(50),
104|     notes           TEXT,
105|     metadata        JSONB,
106|     created_at      TIMESTAMPTZ DEFAULT NOW()
107| );
108| 
109| -- ─────────────────────────────────────────
110| -- AUDIT LOG (immutable — no updates/deletes ever)
111| -- ─────────────────────────────────────────
112| CREATE TABLE audit_logs (
113|     id              BIGSERIAL PRIMARY KEY,
114|     user_id         UUID NOT NULL REFERENCES users(id),
115|     action          VARCHAR(100) NOT NULL,
116|     table_name      VARCHAR(100),
117|     record_id       UUID,
118|     old_values      JSONB,
119|     new_values      JSONB,
120|     ip_address      INET,
121|     created_at      TIMESTAMPTZ DEFAULT NOW()
122| );
123| 
124| -- Prevent any updates or deletes on audit_logs
125| CREATE RULE no_update_audit AS ON UPDATE TO audit_logs DO INSTEAD NOTHING;
126| CREATE RULE no_delete_audit AS ON DELETE TO audit_logs DO INSTEAD NOTHING;
```

### `dengartrack-backend/routers/followups.py`

File path: `dengartrack-backend/routers/followups.py`.

Router:

```python
router = APIRouter(prefix="/followups", tags=["followups"])
```

Endpoints:

| Method | Path | Response model | Dependency |
|---|---|---|---|
| GET | `/followups/` | `list[FollowUpOut]` | `coordinator_only` |
| GET | `/followups/{followup_id}/events` | `list[FollowUpEventOut]` | `coordinator_only` |
| PATCH | `/followups/{followup_id}` | `FollowUpOut` | `coordinator_only` |

Key helper functions:

```python
# dengartrack-backend/routers/followups.py
17 | def payload_fields(payload: FollowUpUpdate) -> set[str]:
18 |     return set(
19 |         getattr(payload, "model_fields_set", getattr(payload, "__fields_set__", set()))
20 |     )
```

```python
# dengartrack-backend/routers/followups.py
23 | def followup_select_sql(where_clause: str) -> str:
24 |     return f"""
25 |             SELECT
26 |                 f.*,
27 |                 b.system_id AS baby_system_id,
28 |                 COALESCE(GREATEST((CURRENT_DATE - f.due_date), 0), 0) AS days_overdue,
29 |                 CASE
30 |                     WHEN f.status = 'lost_to_followup' THEN 'ltfu'
31 |                     WHEN f.due_date IS NULL THEN 'new'
32 |                     WHEN f.due_date < CURRENT_DATE - INTERVAL '14 days' THEN 'red'
33 |                     WHEN f.due_date < CURRENT_DATE THEN 'amber'
34 |                     ELSE 'new'
35 |                 END AS urgency
36 |             FROM follow_ups f
37 |             JOIN babies b ON b.id = f.baby_id
38 |             {where_clause}
39 |             """
```

```python
# dengartrack-backend/routers/followups.py
42 | def write_audit_log(
43 |     db: Session,
44 |     user_id: str,
45 |     action: str,
46 |     table_name: str,
47 |     record_id: str,
48 |     old_values: dict | None,
49 |     new_values: dict | None,
50 | ):
```

`GET /followups/` exact logic:

```python
# dengartrack-backend/routers/followups.py
70 | @router.get("/", response_model=list[FollowUpOut], tags=["followups"])
71 | def list_followups(
72 |     current_user: dict = Depends(coordinator_only),
73 |     db: Session = Depends(get_db),
74 | ):
75 |     rows = db.execute(
76 |         text(
77 |             followup_select_sql(
78 |                 """
79 |             WHERE f.hospital_id = :hospital_id
80 |               AND f.status IN ('pending', 'contacted', 'appointment_booked', 'escalated', 'lost_to_followup')
81 |                 """
82 |             )
83 |             + """
84 |             ORDER BY
85 |                 CASE
86 |                     WHEN f.status = 'lost_to_followup' THEN 0
87 |                     WHEN f.due_date < CURRENT_DATE - INTERVAL '14 days' THEN 1
88 |                     WHEN f.due_date < CURRENT_DATE THEN 2
89 |                     ELSE 3
90 |                 END,
91 |                 f.due_date ASC NULLS LAST,
92 |                 f.created_at ASC
93 |             """
94 |         ),
95 |         {"hospital_id": current_user["hospital_id"]},
96 |     ).fetchall()
97 |     return rows
```

`GET /followups/{followup_id}/events` exact logic:

```python
# dengartrack-backend/routers/followups.py
100| @router.get("/{followup_id}/events", response_model=list[FollowUpEventOut], tags=["followups"])
101| def list_followup_events(
102|     followup_id: uuid.UUID,
103|     current_user: dict = Depends(coordinator_only),
104|     db: Session = Depends(get_db),
105| ):
106|     followup = db.execute(
107|         text("SELECT hospital_id FROM follow_ups WHERE id = :id"),
108|         {"id": str(followup_id)},
109|     ).fetchone()
110|     if not followup:
111|         raise HTTPException(status_code=404, detail="Follow-up not found")
112|     if str(followup.hospital_id) != current_user["hospital_id"]:
113|         raise HTTPException(status_code=403, detail="Cannot view follow-up from another hospital")
114| 
115|     ensure_follow_up_events_table(db)
116|     return db.execute(
117|         text(
118|             """
119|             SELECT
120|                 e.*,
121|                 u.full_name AS actor_name
122|             FROM follow_up_events e
123|             LEFT JOIN users u ON u.id = e.user_id
124|             WHERE e.follow_up_id = :followup_id
125|             ORDER BY e.created_at ASC
126|             """
127|         ),
128|         {"followup_id": str(followup_id)},
129|     ).fetchall()
```

`PATCH /followups/{followup_id}` exact logic:

```python
# dengartrack-backend/routers/followups.py
132| @router.patch("/{followup_id}", response_model=FollowUpOut, tags=["followups"])
133| def update_followup(
134|     followup_id: uuid.UUID,
135|     payload: FollowUpUpdate,
136|     current_user: dict = Depends(coordinator_only),
137|     db: Session = Depends(get_db),
138| ):
```

Important update behavior:

- Validates follow-up exists.
- Validates same hospital.
- Captures `old_values`.
- Uses Pydantic `model_fields_set` / `__fields_set__` to update only provided fields.
- If status changes to `contacted` and `last_contacted_at` is not supplied, backend sets `last_contacted_at = datetime.utcnow()` and increments `contact_attempts`.
- If status changes to `completed` and `completed_at` is not supplied, backend sets `completed_at = datetime.utcnow()`.
- Writes audit log.
- Writes follow-up event.
- Commits.
- Returns updated row.

Exact status auto-update snippet:

```python
# dengartrack-backend/routers/followups.py
185|     status_changed = "status" in fields and new_status != existing.status
186|     if status_changed and new_status == "contacted" and "last_contacted_at" not in fields:
187|         last_contacted_at = datetime.utcnow()
188|         contact_attempts += 1
189|     if status_changed and new_status == "completed" and "completed_at" not in fields:
190|         completed_at = datetime.utcnow()
```

Auto-LTFU logic:

- No backend scheduler/cron job was found in the specified follow-up router.
- `list_followups()` returns `urgency = 'ltfu'` only when `f.status = 'lost_to_followup'` at line 30.
- There is no automatic appointment-day-plus-one LTFU job in `followups.py`.
- This remains a pending feature.

### `dengartrack-backend/auth/models.py`

File path: `dengartrack-backend/auth/models.py`.

Pydantic models:

```python
# dengartrack-backend/auth/models.py
7  | RoleName = Literal["screener", "coordinator", "unhs_coordinator", "moh"]
9  | class Token(BaseModel):
10 |     access_token: str
11 |     token_type: str
13 | class TokenData(BaseModel):
14 |     user_id: Optional[str] = None
15 |     role: Optional[RoleName] = None
16 |     hospital_id: Optional[str] = None
18 | class UserLogin(BaseModel):
19 |     staff_id: str
20 |     pin: str
21 |     hospital_code: Optional[str] = None
23 | class UserOut(BaseModel):
24 |     id: uuid.UUID
25 |     full_name: str
26 |     email: str
27 |     staff_id: Optional[str] = None
28 |     role: RoleName
29 |     hospital_id: Optional[uuid.UUID]
30 |     is_active: bool
```

Screening models:

```python
# dengartrack-backend/auth/models.py
39 | class EarResult(str, Enum):
40 |     """Valid ear screening results."""
41 |     pass_result = "pass"
42 |     refer = "refer"
43 |     not_tested = "not_tested"
45 | class ScreeningType(str, Enum):
46 |     """Valid screening types."""
47 |     TEOAE = "TEOAE"
48 |     AABR = "AABR"
49 |     ABR = "ABR"
51 | class ScreeningCreate(BaseModel):
52 |     """Request model for creating a screening."""
53 |     baby_id: uuid.UUID
54 |     screening_type: ScreeningType
55 |     ear_left: EarResult
56 |     ear_right: EarResult
57 |     attempt_number: Optional[int] = 1
58 |     notes: Optional[str] = None
59 |     screening_date: Optional[datetime] = None
61 | class ScreeningOut(BaseModel):
62 |     """Response model for screening record."""
63 |     id: uuid.UUID
64 |     baby_id: uuid.UUID
65 |     baby_system_id: Optional[str] = None
66 |     screener_id: uuid.UUID
67 |     hospital_id: uuid.UUID
68 |     screening_type: str
69 |     ear_left: str
70 |     ear_right: str
71 |     screening_date: datetime
72 |     attempt_number: int
73 |     notes: Optional[str]
74 |     created_at: datetime
79 | class ShiftSummary(BaseModel):
80 |     """Today's shift summary for screener."""
81 |     screener_id: uuid.UUID
82 |     screener_name: str
83 |     screening_date: str
84 |     total_screened: int
85 |     total_pass: int
86 |     total_refer: int
87 |     total_not_tested: int
```

Baby models:

```python
# dengartrack-backend/auth/models.py
90 | class BabyCreate(BaseModel):
91 |     ward: Optional[str] = None
92 |     date_of_birth: date
93 |     gestational_age: Optional[int] = None
94 |     birth_weight: Optional[int] = None
95 |     gender: Optional[str] = None
96 |     full_name_enc: Optional[str] = None
97 |     ic_number_enc: Optional[str] = None
99 | class BabyOut(BaseModel):
100|     id: uuid.UUID
101|     system_id: str
102|     hospital_id: uuid.UUID
103|     ward: Optional[str]
104|     date_of_birth: date
105|     gestational_age: Optional[int]
106|     birth_weight: Optional[int]
107|     gender: Optional[str]
108|     full_name_enc: Optional[str]
109|     ic_number_enc: Optional[str]
110|     created_at: datetime
```

Follow-up models:

```python
# dengartrack-backend/auth/models.py
117| class FollowUpStatus(str, Enum):
118|     pending = "pending"
119|     contacted = "contacted"
120|     appointment_booked = "appointment_booked"
121|     escalated = "escalated"
122|     closed = "closed"
123|     scheduled = "scheduled"
124|     completed = "completed"
125|     lost_to_followup = "lost_to_followup"
126| 
127| 
128| class FollowUpOut(BaseModel):
129|     id: uuid.UUID
130|     baby_id: uuid.UUID
131|     baby_system_id: Optional[str] = None
132|     screening_id: uuid.UUID
133|     hospital_id: uuid.UUID
134|     assigned_to: Optional[uuid.UUID]
135|     status: str
136|     due_date: Optional[date]
137|     last_contacted_at: Optional[datetime] = None
138|     appointment_date: Optional[datetime] = None
139|     completed_at: Optional[datetime] = None
140|     ltfu_reason: Optional[str] = None
141|     contact_attempts: Optional[int] = None
142|     notes: Optional[str]
143|     urgency: Optional[str] = None
144|     days_overdue: int = 0
145|     created_at: datetime
146|     updated_at: datetime
```

Critical follow-up update schema:

```python
# dengartrack-backend/auth/models.py
152| class FollowUpUpdate(BaseModel):
153|     status: Optional[FollowUpStatus] = None
154|     notes: Optional[str] = None
155|     due_date: Optional[date] = None
156|     last_contacted_at: Optional[datetime] = None
157|     appointment_date: Optional[datetime] = None
158|     completed_at: Optional[datetime] = None
159|     ltfu_reason: Optional[str] = None
160|     contact_attempts: Optional[int] = None
```

Other models:

```python
# dengartrack-backend/auth/models.py
163| class FollowUpEventOut(BaseModel):
164|     id: uuid.UUID
165|     follow_up_id: uuid.UUID
166|     user_id: Optional[uuid.UUID] = None
167|     actor_name: Optional[str] = None
168|     action: str
169|     from_status: Optional[str] = None
170|     to_status: Optional[str] = None
171|     notes: Optional[str] = None
172|     metadata: Optional[dict] = None
173|     created_at: datetime
179| class MonthlyReportSummary(BaseModel):
191| class NationalHospitalSummary(BaseModel):
201| class NationalSummaryOut(BaseModel):
213| class AuditLogEntry(BaseModel):
221| class BenchmarkReport(BaseModel):
230| class CoverageReport(BaseModel):
237| class WardBreakdownItem(BaseModel):
245| class WardBreakdownReport(BaseModel):
```

### `dengartrack-backend/db/migrations/`

Directory path: `dengartrack-backend/db/migrations/`.

Only migration file currently listed:

- `dengartrack-backend/db/migrations/002_fix_followup_status_constraint.sql`

Exact content:

```sql
-- dengartrack-backend/db/migrations/002_fix_followup_status_constraint.sql
1 | -- Migration: Fix follow_ups status CHECK constraint
2 | -- Date: 2026-06-06
3 | -- Issue: appointment_booked and escalated were missing from CHECK constraint
4 | -- on the deployed database (schema.sql is already correct).
5 | 
6 | -- Drop the old constraint (safe, no data loss)
7 | ALTER TABLE follow_ups DROP CONSTRAINT IF EXISTS follow_ups_status_check;
8 | 
9 | -- Add the corrected constraint with all valid statuses
10 | ALTER TABLE follow_ups ADD CONSTRAINT follow_ups_status_check
11 |     CHECK (status IN (
12 |         'pending',
13 |         'contacted', 
14 |         'scheduled',
15 |         'appointment_booked',
16 |         'escalated',
17 |         'completed',
18 |         'closed',
19 |         'lost_to_followup'
20 |     ));
```

Other migration-style scripts exist outside `db/migrations/`:

- `dengartrack-backend/db/migrate_follow_up_report_columns.py`
- `dengartrack-backend/db/migrate_ltfu_followups.py`
- `dengartrack-backend/db/migrate_unhs_role.py`

### `dengartrack-backend/seed.py`

File path: `dengartrack-backend/seed.py`.

Purpose: seed hospitals, users, babies, and one sample screening.

Hospitals:

```python
# dengartrack-backend/seed.py
204|         hospitals = [
205|             {
206|                 "code": "HKL001",
207|                 "name": "Hospital Kuala Lumpur",
208|                 "state": "Kuala Lumpur",
209|             },
210|             {
211|                 "code": "HPJ001",
212|                 "name": "Hospital Putrajaya",
213|                 "state": "Putrajaya",
214|             },
215|             {
216|                 "code": "HSB001",
217|                 "name": "Hospital Sungai Buloh",
218|                 "state": "Selangor",
219|             },
220|         ]
```

Users:

```python
# dengartrack-backend/seed.py
228|         users = [
229|             {"role": "screener", "staff_id": "SCR001HKL", "pin": "1234", "name": "Nur Aina Binti Rahman", "hospital_code": "HKL001"},
230|             {"role": "screener", "staff_id": "SCR002HKL", "pin": "1234", "name": "Muhammad Fahmi Bin Azlan", "hospital_code": "HKL001"},
231|             {"role": "screener", "staff_id": "SCR003HKL", "pin": "1234", "name": "Siti Hajar Binti Osman", "hospital_code": "HKL001"},
232|             {"role": "coordinator", "staff_id": "COO001HKL", "pin": "1234", "name": "Dr Nurul Izzah Binti Hamid", "hospital_code": "HKL001"},
233|             {"role": "coordinator", "staff_id": "COO002HKL", "pin": "1234", "name": "Ahmad Syafiq Bin Omar", "hospital_code": "HKL001"},
234|             {"role": "screener", "staff_id": "SCR001HPJ", "pin": "1234", "name": "Farah Nabila Binti Yusof", "hospital_code": "HPJ001"},
235|             {"role": "screener", "staff_id": "SCR002HPJ", "pin": "1234", "name": "Muhammad Hakim Bin Rosli", "hospital_code": "HPJ001"},
236|             {"role": "screener", "staff_id": "SCR003HPJ", "pin": "1234", "name": "Nor Idayu Binti Zainal", "hospital_code": "HPJ001"},
237|             {"role": "coordinator", "staff_id": "COO001HPJ", "pin": "1234", "name": "Dr Afiqah Binti Jalil", "hospital_code": "HPJ001"},
238|             {"role": "coordinator", "staff_id": "COO002HPJ", "pin": "1234", "name": "Mohd Rizal Bin Kamarudin", "hospital_code": "HPJ001"},
239|             {"role": "screener", "staff_id": "SCR001HSB", "pin": "1234", "name": "Amira Balqis Binti Salleh", "hospital_code": "HSB001"},
240|             {"role": "screener", "staff_id": "SCR002HSB", "pin": "1234", "name": "Ikhwan Danish Bin Mahmud", "hospital_code": "HSB001"},
241|             {"role": "screener", "staff_id": "SCR003HSB", "pin": "1234", "name": "Nadia Sofea Binti Ismail", "hospital_code": "HSB001"},
242|             {"role": "coordinator", "staff_id": "COO001HSB", "pin": "1234", "name": "Dr Liyana Binti Razak", "hospital_code": "HSB001"},
243|             {"role": "coordinator", "staff_id": "COO002HSB", "pin": "1234", "name": "Khairul Anwar Bin Saad", "hospital_code": "HSB001"},
244|             {"role": "unhs_coordinator", "staff_id": "ADM001", "pin": "1234", "name": "Test UNHS Coordinator"},
245|             {"role": "moh", "staff_id": "MOH001", "pin": "1234", "name": "Test MOH"},
246|         ]
```

Babies:

```python
# dengartrack-backend/seed.py
253|         legacy_babies = [
254|             {
255|                 **baby,
256|                 "system_id": f"BABY{index:03d}",
257|                 "hospital_code": "HKL001",
258|             }
259|             for index, baby in enumerate(make_babies("HKL001", "LEGACY", 20), start=1)
260|         ]
261| 
262|         babies = [
263|             *legacy_babies,
264|             *make_babies("HKL001", "HKL", 20),
265|             *make_babies("HPJ001", "HPJ", 10),
266|             *make_babies("HSB001", "HSB", 10),
267|         ]
```

Sample screening:

```python
# dengartrack-backend/seed.py
274|         if "BABY001" in baby_ids and "SCR001HKL" in user_ids:
275|             existing_screening = db.execute(
276|                 text(
277|                     """
278|                     SELECT id
279|                     FROM screenings
280|                     WHERE baby_id = :baby_id
281|                       AND screener_id = :screener_id
282|                       AND notes = :notes
283|                     LIMIT 1
284|                     """
285|                 ),
286|                 {
287|                     "baby_id": baby_ids["BABY001"],
288|                     "screener_id": user_ids["SCR001HKL"],
289|                     "notes": "Sample screening for testing",
290|                 },
291|             ).fetchone()
...
297|                         INSERT INTO screenings (
298|                             id, baby_id, screener_id, hospital_id, screening_type,
299|                             ear_left, ear_right, attempt_number, notes
300|                         )
301|                         VALUES (
302|                             :id, :baby_id, :screener_id, :hospital_id, :screening_type,
303|                             :ear_left, :ear_right, :attempt_number, :notes
304|                         )
305|                         """
306|                     ),
307|                     {
308|                         "id": str(uuid.uuid4()),
309|                         "baby_id": baby_ids["BABY001"],
310|                         "screener_id": user_ids["SCR001HKL"],
311|                         "hospital_id": hospital_ids["HKL001"],
312|                         "screening_type": "TEOAE",
313|                         "ear_left": "pass",
314|                         "ear_right": "refer",
315|                         "attempt_number": 1,
316|                         "notes": "Sample screening for testing",
317|                     },
```

Seed output:

```python
# dengartrack-backend/seed.py
321|         print("✓ Seed complete:")
322|         print("  Hospitals: HKL001, HPJ001, HSB001")
323|         print("  Users (with hospital suffixes):")
324|         print("    HKL: SCR001HKL, SCR002HKL, SCR003HKL, COO001HKL, COO002HKL")
325|         print("    HPJ: SCR001HPJ, SCR002HPJ, SCR003HPJ, COO001HPJ, COO002HPJ")
326|         print("    HSB: SCR001HSB, SCR002HSB, SCR003HSB, COO001HSB, COO002HSB")
327|         print("    Admin: ADM001, MOH001 (unchanged)")
328|         print("  PIN for all demo users: 1234")
329|         print("  Babies: BABY001-020, HKL-BABY001-020, HPJ-BABY001-010, HSB-BABY001-010")
330|         print("  Screenings: sample screening preserved/created for BABY001")
```

Important auth mismatch:

- `dengartrack-backend/routers/auth_router.py` expects `staff_id` and `pin`, not email/password:
  - Lines 18-20: `@router.post("/login", response_model=Token)` and docstring says `"Login endpoint: accepts staff_id and PIN, returns JWT access token."`
  - Line 26: `if not user or not verify_password(credentials.pin, user.pin_hash):`
- `misc/CLAUDE_CONTEXT_CURRENT.md` lists email/password demo credentials with `password123`, but current `seed.py` creates staff IDs/PINs with `1234`.
- Therefore, mobile login and actual backend seed use staff ID/PIN.

---

## Flutter Mobile Architecture

### `mobile_flutter_app/hearlinx/pubspec.yaml`

File path: `mobile_flutter_app/hearlinx/pubspec.yaml`.

Exact version:

```yaml
19 | version: 1.0.0+1
```

SDK:

```yaml
21 | environment:
22 |   sdk: ^3.11.5
```

Dependencies:

| Dependency | Version |
|---|---|
| `flutter` | `sdk: flutter` |
| `flutter_localizations` | `sdk: flutter` |
| `cupertino_icons` | `^1.0.8` |
| `http` | `^1.5.0` |
| `flutter_secure_storage` | `^9.2.4` |
| `sqflite` | `^2.4.2` |
| `path_provider` | `^2.1.5` |
| `provider` | `^6.1.5` |
| `mobile_scanner` | `^7.0.1` |
| `intl` | `^0.20.2` |
| `shared_preferences` | `^2.3.5` |
| `google_fonts` | `^6.1.0` |
| `shorebird_code_push` | `^1.1.0` |

Dev dependencies:

| Dependency | Version |
|---|---|
| `flutter_test` | `sdk: flutter` |
| `flutter_lints` | `^6.0.0` |
| `flutter_launcher_icons` | `^0.14.1` |

Assets:

```yaml
71 |   assets:
72 |     - assests/
73 |     - shorebird.yaml
```

Note exact spelling: `assests/` not `assets/`.

### `mobile_flutter_app/hearlinx/lib/main.dart`

File path: `mobile_flutter_app/hearlinx/lib/main.dart`.

Initialization logic:

- Calls `WidgetsFlutterBinding.ensureInitialized()`.
- Initializes `ApiConfig`.
- Creates `LanguageProvider`.
- Loads saved locale before `runApp`.
- Checks Shorebird patch availability on startup.
- Stores `last_seen_patch` and `patch_just_applied` in `SharedPreferences`.

Exact startup code:

```dart
// mobile_flutter_app/hearlinx/lib/main.dart
21 | void main() async {
22 |   WidgetsFlutterBinding.ensureInitialized();
23 | 
24 |   // Initialize API config with smart URL detection
25 |   await ApiConfig.initialize();
26 | 
27 |   // Pre-load language before runApp to ensure Malay is set on cold start
28 |   final languageProvider = LanguageProvider();
29 |   await languageProvider.loadSavedLocale();
30 | 
31 |   // Shorebird: silently check for and download patches on startup
32 |   try {
33 |     final shorebird = ShorebirdCodePush();
34 |     final isUpdateAvailable = await shorebird.isNewPatchAvailableForDownload();
35 |     if (isUpdateAvailable) {
36 |       await shorebird.downloadUpdateIfAvailable();
37 | 
38 |       // Track patch application for login screen banner
39 |       final prefs = await SharedPreferences.getInstance();
40 |       final currentPatch = await shorebird.currentPatchNumber();
41 |       final previousPatch = prefs.getInt('last_seen_patch');
42 | 
43 |       if (currentPatch != null && currentPatch != previousPatch) {
44 |         await prefs.setInt('last_seen_patch', currentPatch);
45 |         await prefs.setBool('patch_just_applied', true);
46 |       }
47 |     }
48 |   } catch (_) {
49 |     // Shorebird not available in debug mode or on first install — ignore silently
50 |   }
51 | 
52 |   runApp(HearLinxApp(languageProvider: languageProvider));
53 | }
```

Providers:

```dart
// mobile_flutter_app/hearlinx/lib/main.dart
62 |       providers: [
63 |         ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
64 |         ChangeNotifierProvider<LanguageProvider>.value(value: languageProvider),
65 |       ],
```

Routes:

```dart
// mobile_flutter_app/hearlinx/lib/main.dart
85 |             routes: {
86 |               '/login': (_) => const LoginScreen(),
87 |               '/home': (_) => const HomeScreen(),
88 |               '/coordinator-dashboard': (_) =>
89 |                   const CoordinatorDashboardScreen(),
90 |               '/coordinator/followups': (_) => const FollowUpListScreen(),
91 |               '/unhs-dashboard': (_) => const UnhsDashboardScreen(),
92 |               '/moh-dashboard': (_) => const MohDashboardScreen(),
93 |               '/screening-entry': (_) => const ScreeningEntryScreen(),
94 |               '/shift-summary': (_) => const ShiftSummaryScreen(),
95 |             },
96 |             home: const LoginScreen(),
```

### `mobile_flutter_app/hearlinx/lib/config/api_config.dart`

File path: `mobile_flutter_app/hearlinx/lib/config/api_config.dart`.

Exact base URLs:

```dart
// mobile_flutter_app/hearlinx/lib/config/api_config.dart
8  |   static const String _productionUrl =
9  |       'https://hearlinx-production.up.railway.app';
10 |   static const String _localUrl = 'http://10.20.88.90:8000';
```

Initialization logic:

```dart
// mobile_flutter_app/hearlinx/lib/config/api_config.dart
23 |   /// Initialize API config on app startup
24 |   /// Attempts production first, falls back to local if timeout
25 |   static Future<void> initialize() async {
26 |     if (_initialized) return;
27 | 
28 |     _log('Initializing ApiConfig...');
29 | 
30 |     if (_useDebugOverride) {
31 |       _activeUrl = _localUrl;
32 |       _log('DEBUG OVERRIDE: Using local URL', force: true);
33 |       _initialized = true;
34 |       return;
35 |     }
36 | 
37 |     // Try production first
38 |     final prodConnected = await checkConnectivity(url: _productionUrl);
39 |     if (prodConnected) {
40 |       _activeUrl = _productionUrl;
41 |       _log('✓ Production URL is reachable');
42 |     } else {
43 |       // Fallback to local
44 |       final localConnected = await checkConnectivity(url: _localUrl);
45 |       if (localConnected) {
46 |         _activeUrl = _localUrl;
47 |         _log('⚠ Production unreachable, switched to local URL', force: true);
48 |       } else {
49 |         // Default to production if both fail
50 |         _activeUrl = _productionUrl;
51 |         _log('✗ Both URLs unreachable, defaulting to production', force: true);
52 |       }
53 |     }
54 | 
55 |     _initialized = true;
56 |     _log('ApiConfig initialized: $_activeUrl');
57 |   }
```

Public getters:

```dart
// mobile_flutter_app/hearlinx/lib/config/api_config.dart
59 |   /// Get current active base URL
60 |   static String get baseUrl => _activeUrl;
61 | 
62 |   /// Get last measured latency in milliseconds
63 |   static int get latency => _latencyMs;
64 | 
65 |   /// Check if using production URL
66 |   static bool get isProduction => _activeUrl == _productionUrl;
```

Health check:

```dart
// mobile_flutter_app/hearlinx/lib/config/api_config.dart
88 |   static Future<bool> checkConnectivity({String? url}) async {
89 |     final checkUrl = url ?? _activeUrl;
90 |     final stopwatch = Stopwatch()..start();
91 | 
92 |     try {
93 |       final response = await _httpClient
94 |           .get(Uri.parse('$checkUrl/'), headers: {'Connection': 'keep-alive'})
95 |           .timeout(_healthCheckTimeout);
96 | 
97 |       stopwatch.stop();
98 |       _latencyMs = stopwatch.elapsedMilliseconds;
99 | 
100|       final isHealthy = response.statusCode >= 200 && response.statusCode < 300;
```

### `mobile_flutter_app/hearlinx/lib/l10n/app_text.dart`

File path: `mobile_flutter_app/hearlinx/lib/l10n/app_text.dart`.

Class:

```dart
// mobile_flutter_app/hearlinx/lib/l10n/app_text.dart
1 | class AppText {
2 |   const AppText(this.lang);
3 | 
4 |   final String lang;
5 | 
6 |   bool get isMs => lang == 'ms';
```

All current translation keys with BM / EN values:

| Key | BM | EN | Lines |
|---|---|---|---|
| `welcome` | `Selamat kembali` | `Welcome back` | 8 |
| `subtitle` | `Log masuk ke akaun anda` | `Sign in to your account` | 9-10 |
| `staffId` | `ID Staf` | `Staff ID` | 11 |
| `pin` | `PIN` | `PIN` | 12 |
| `signIn` | `Log Masuk` | `Sign In` | 13 |
| `invalidCreds` | `ID Staf atau PIN tidak sah` | `Invalid Staff ID or PIN` | 14-15 |
| `hospital` | `Hospital` | `Hospital` | 16 |
| `selectHospital` | `Pilih Hospital` | `Select Hospital` | 17 |
| `enterStaffId` | `Masukkan ID Staf` | `Enter Staff ID` | 18 |
| `enterPin` | `Masukkan PIN` | `Enter PIN` | 19 |
| `forgotPin` | `Lupa PIN?\nHubungi Penyelaras` | `Forgot PIN?\nContact Coordinator` | 20-22 |
| `contactCoordinator` | `Hubungi Penyelaras` | `Contact Coordinator` | 23-24 |
| `forgotPinContactName` | `Dr. Siti Aminah Kamaludin` | `Dr. Siti Aminah Kamaludin` | 25-26 |
| `forgotPinContactPhone` | `Tel: +60 12-204 8848` | `Tel: +60 12-204 8848` | 27-28 |
| `forgotPinContactEmail` | `Emel: sitiaminah@email.com` | `Email: sitiaminah@email.com` | 29-30 |
| `forgotPinContactOffice` | `Pejabat: Unit Audiologi, Hospital Kuala Lumpur` | `Office: Audiology Unit, Hospital Kuala Lumpur` | 31-33 |
| `appSubtitle` | `Sistem Pengurusan Saringan Pendengaran Bayi` | `Newborn Hearing Screening Management System` | 34-36 |
| `newScreening` | `Saringan Baharu` | `New Screening` | 38 |
| `scanQR` | `Imbas Kod QR` | `Scan QR Code` | 39 |
| `manualEntry` | `Masukkan secara manual` | `Enter manually` | 40 |
| `babyId` | `ID Bayi` | `Baby ID` | 41 |
| `ward` | `Wad` | `Ward` | 42 |
| `device` | `Peranti Digunakan` | `Device Used` | 43 |
| `leftEar` | `Telinga Kiri` | `Left Ear` | 44 |
| `rightEar` | `Telinga Kanan` | `Right Ear` | 45 |
| `screeningDate` | `Tarikh Saringan` | `Screening Date` | 46 |
| `selectDate` | `Pilih Tarikh` | `Select Date` | 47 |
| `pass` | `LULUS` | `PASS` | 48 |
| `refer` | `RUJUK` | `REFER` | 49 |
| `notes` | `Nota (pilihan)` | `Notes (optional)` | 50 |
| `submit` | `Hantar` | `Submit` | 51 |
| `shiftSummary` | `Ringkasan Syif` | `Shift Summary` | 52 |
| `myShiftSummary` | `Ringkasan Syif` | `Shift Summary` | 53 |
| `allSaved` | `Semua Tersimpan` | `All Saved` | 54 |
| `pendingSync` | `rekod belum disinkron` | `records pending sync` | 55-56 |
| `continueText` | `Teruskan` | `Continue` | 57 |
| `typeBabyId` | `Taip ID Bayi` | `Enter Baby ID` | 58 |
| `enterBabyToContinue` | `Masukkan ID bayi untuk meneruskan saringan` | `Enter baby ID to continue screening` | 59-61 |
| `babyInfo` | `Maklumat Bayi` | `Baby Information` | 62 |
| `pointCameraQr` | `Arahkan kamera ke kod QR` | `Point camera at QR code` | 63-64 |
| `todayScreenings` | `Saringan Hari Ini` | `Today's Screenings` | 65-66 |
| `today` | `Hari Ini` | `Today` | 67 |
| `allHistory` | `Semua Sejarah` | `All History` | 68 |
| `allScreenings` | `Semua Saringan` | `All Screenings` | 69 |
| `noAllScreenings` | `Tiada saringan direkodkan.` | `No screenings recorded.` | 70-71 |
| `noTodayScreenings` | `Tiada saringan hari ini` | `No screenings today` | 72-73 |
| `totalScreenedToday` | `Jumlah disaring hari ini` | `Total screened today` | 74-75 |
| `totalPass` | `Jumlah LULUS` | `Total PASS` | 76 |
| `totalRefer` | `Jumlah RUJUK` | `Total REFER` | 77-78 |
| `dashboard` | `Papan Pemuka` | `Dashboard` | 79 |
| `hospitalDashboard` | `Papan Pemuka Hospital` | `Hospital Dashboard` | 80-81 |
| `nationalDashboard` | `Dashboard Nasional` | `National Dashboard` | 82-83 |
| `unhsDashboard` | `Dashboard UNHS` | `UNHS Dashboard` | 84 |
| `followupQueue` | `Antrian Susulan` | `Follow-up Queue` | 85 |
| `ltfu` | `LTFU` | `LTFU` | 86 |
| `ltfuRate` | `Kadar LTFU` | `LTFU Rate` | 87 |
| `overdue` | `Lewat` | `Overdue` | 88 |
| `newFollowup` | `Baharu` | `New` | 89 |
| `redRisk` | `Risiko Tinggi` | `High Risk` | 90 |
| `markContacted` | `Tandakan Dihubungi` | `Mark Contacted` | 91 |
| `bookAppointment` | `Buat Temujanji` | `Book Appointment` | 92 |
| `escalate` | `Eskalasi` | `Escalate` | 93 |
| `complete` | `Selesai` | `Complete` | 94 |
| `markLtfu` | `Tanda LTFU` | `Mark LTFU` | 95 |
| `followupDetails` | `Butiran Susulan` | `Follow-up Details` | 96 |
| `timeline` | `Garis Masa` | `Timeline` | 97 |
| `status` | `Status` | `Status` | 98 |
| `statusLabel` | `Status` | `Status` | 99 |
| `wardLabel` | `Wad` | `Ward` | 100 |
| `totalCount` | `Jumlah` | `Total` | 101 |
| `referCount` | `Rujukan` | `Referrals` | 102 |
| `ratePercentage` | `Kadar %` | `Rate %` | 103 |
| `dateLabel` | `Tarikh` | `Date` | 104 |
| `appointmentDate` | `Tarikh Temujanji` | `Appointment Date` | 105 |
| `ltfuReason` | `Sebab LTFU` | `LTFU Reason` | 106 |
| `contactAttempts` | `Cubaan Hubungan` | `Contact Attempts` | 107 |
| `connectionError` | `Ralat Sambungan` | `Connection Error` | 108 |
| `checkInternet` | `Sila pastikan anda mempunyai sambungan internet dan cuba semula.` | `Please ensure you have an internet connection and try again.` | 109-111 |
| `close` | `Tutup` | `Close` | 112 |
| `monthlyReport` | `Laporan Bulanan` | `Monthly Report` | 113 |
| `export` | `Eksport` | `Export` | 114 |
| `monthlySummary` | `Ringkasan Bulanan` | `Monthly Summary` | 115 |
| `noPendingFollowups` | `Tiada susulan tertunda.` | `No pending follow-ups.` | 116-117 |
| `todayScreeningRecorded` | `Tiada saringan direkodkan hari ini.` | `No screenings recorded today.` | 118-120 |
| `logout` | `Log Keluar` | `Logout` | 122 |
| `loading` | `Memuatkan...` | `Loading...` | 123 |
| `error` | `Sesuatu telah berlaku` | `Something went wrong` | 124 |
| `sessionExpired` | `Sesi telah tamat. Sila log masuk semula.` | `Session expired. Please sign in again.` | 125-127 |
| `serverDataError` | `Ralat data dari pelayan.` | `Server data error.` | 128-129 |
| `slowConnection` | `Sambungan lambat. Sila cuba semula.` | `Connection is slow. Please try again.` | 130-132 |
| `noInternet` | `Sambungan internet tiada. Sila cuba semula.` | `No internet connection. Please try again.` | 133-135 |
| `unknownError` | `Ralat tidak diketahui` | `Unknown error` | 136 |
| `retry` | `Cuba Semula` | `Retry` | 137 |
| `cancel` | `Batal` | `Cancel` | 138 |
| `confirm` | `Sahkan` | `Confirm` | 139 |
| `save` | `Simpan` | `Save` | 140 |
| `back` | `Kembali` | `Back` | 141 |
| `welcomeHome` | `Selamat datang` | `Welcome` | 142 |
| `userLoadError` | `Tidak dapat memuatkan profil pengguna.` | `Unable to load user profile.` | 143-145 |
| `screener` | `Penyaring` | `Screener` | 146 |
| `coordinator` | `Audiologis Hospital` | `Hospital Audiologist` | 147-148 |
| `unhsCoordinator` | `Penyelaras UNHS Nasional` | `National UNHS Coordinator` | 149-150 |
| `user` | `Pengguna` | `User` | 151 |
| `totalScreenings` | `Total Saringan` | `Total Screenings` | 152 |
| `notTested` | `Tidak diuji` | `Not tested` | 153 |
| `recentAudit` | `Aktiviti Audit Terkini` | `Recent Audit Activity` | 154-155 |
| `noAudit` | `Tiada aktiviti audit direkodkan.` | `No audit activity recorded.` | 156-157 |
| `hospitalPerformance` | `Prestasi Mengikut Hospital` | `Performance by Hospital` | 158-159 |
| `noNationalData` | `Tiada data kebangsaan tersedia.` | `No national data available.` | 160-161 |
| `screening` | `Saringan` | `Screenings` | 162 |
| `monthlyReportLabel` | `laporan bulanan` | `monthly report` | 165 |
| `followupListLabel` | `senarai susulan` | `follow-up list` | 166 |
| `todayScreeningsLabel` | `saringan hari ini` | `today screenings` | 167-168 |
| `benchmarkLabel` | `benchmark` | `benchmark` | 169 |
| `coverageRateLabel` | `kadar liputan` | `coverage rate` | 170 |
| `wardBreakdownLabel` | `pecahan wad` | `ward breakdown` | 171 |
| `dashboardNoDataMessage` | `Tiada data dashboard tersedia selepas dimuatkan. Cuba semula atau semak sambungan pelayan.` | `No dashboard data is available after loading. Try again or check the server connection.` | 172-174 |
| `followupStatusUpdated` | `Status susulan berjaya dikemas kini` | `Follow-up status updated successfully` | 175-177 |
| `noDueDate` | `Tiada tarikh` | `No date` | 178 |
| `noTimelineEvents` | `Tiada peristiwa garis masa lagi.` | `No timeline events yet.` | 179-180 |
| `welcomeGreeting(String name)` | `Selamat datang, $name! Semoga hari anda produktif. 🌟` | `Welcome, $name! Have a productive day. 🌟` | 183-185 |
| `lastScreening` | `Saringan Terakhir` | `Last Screening` | 186 |
| `activeScreeners` | `Penyaring Aktif` | `Active Screeners` | 187 |
| `screeningType` | `Jenis Saringan` | `Screening Type` | 188 |
| `coverageRateTitle` | `Kadar Liputan Saringan` | `Screening Coverage Rate` | 189-190 |
| `benchmarkTitle` | `Penanda Aras 1-3-6 KKM` | `1-3-6 KKM Benchmark` | 191-192 |
| `screenedBy1Month` | `Disaring dalam 1 bulan` | `Screened within 1 month` | 193-194 |
| `diagnosedBy3Months` | `Diagnosis dalam 3 bulan` | `Diagnosed within 3 months` | 195-196 |
| `kkmTarget` | `Sasaran KKM: ≥90%` | `KKM Target: ≥90%` | 197 |
| `wardBreakdown` | `Pecahan Mengikut Wad` | `Ward Breakdown` | 198 |
| `noWardData` | `Tiada data wad` | `No ward data` | 199 |
| `screenedToday` | `Disaring Hari Ini` | `Screened Today` | 200 |
| `restMessage` | `Beristirahat dan nikmati hari anda!` | `Rest and enjoy your day!` | 201-202 |
| `coverageRate` | `Kadar Liputan` | `Coverage Rate` | 203 |
| `totalBabiesRegistered` | `Jumlah Bayi Terdaftar` | `Total Babies Registered` | 204-205 |
| `lastUpdated` | `Dikemas kini terakhir` | `Last updated` | 206 |
| `viewAll` | `Lihat Semua` | `View All` | 207 |
| `more` | `lagi` | `more` | 208 |
| `versionUpToDate` | `Versi terkini` | `Up to date` | 209 |
| `updateApplied` | `Aplikasi telah dikemaskini` | `Update applied` | 210-211 |
| `patchLabel` | `Kemaskini Perisian` | `Software Update` | 212 |
| `appVersion` | `v1.0.1` | `v1.0.1` | 213 |
| `statusPending` | `Belum Selesai` | `Pending` | 216 |
| `statusContacted` | `Dihubungi` | `Contacted` | 217 |
| `statusAppointmentBooked` | `Temujanji Ditetapkan` | `Appointment Booked` | 218-219 |
| `statusEscalated` | `Dinaik Taraf` | `Escalated` | 220 |
| `statusCompleted` | `Selesai` | `Completed` | 221 |
| `statusLostToFollowup` | `Hilang Susulan` | `Lost to Follow-up` | 222-223 |
| `statusClosed` | `Ditutup` | `Closed` | 224 |
| `actionCreatedFromRujuk` | `Dicipta dari saringan RUJUK` | `Created from RUJUK screening` | 227-228 |
| `actionStatusChanged` | `Status ditukar` | `Status changed` | 229 |
| `actionContactAttempt` | `Cubaan hubungan` | `Contact attempt` | 230-231 |
| `actionNoteAdded` | `Nota ditambah` | `Note added` | 232 |
| `actionAppointmentBooked` | `Temujanji ditetapkan` | `Appointment booked` | 233-234 |
| `actionEscalated` | `Kes dinaik taraf` | `Case escalated` | 235 |
| `actionMarkedLtfu` | `Tanda hilang susulan` | `Marked LTFU` | 236 |
| `actionCompleted` | `Kes selesai` | `Case completed` | 237 |
| `statusTo` | `kepada` | `to` | 240 |
| `followUpDetailTitle` | `Butiran Susulan` | `Follow-up Details` | 243-244 |
| `babyIdLabel` | `ID Bayi` | `Baby ID` | 245 |
| `appointmentDateHint` | `Pilih tarikh & masa` | `Select date & time` | 246-247 |
| `ltfuReasonLabel` | `Sebab Hilang Susulan` | `LTFU Reason` | 248 |
| `ltfuReasonHint` | `Nyatakan sebab...` | `Enter reason...` | 249 |
| `notesOptionalLabel` | `Nota (pilihan)` | `Notes (optional)` | 250 |
| `notesHint` | `Tambah nota...` | `Add notes...` | 251 |
| `contactAttemptsLabel` | `Cubaan Hubungan` | `Contact Attempts` | 252-253 |
| `timelineTitle` | `Garis Masa` | `Timeline` | 254 |
| `timelineCount` | `aktiviti` | `events` | 255 |
| `saveChanges` | `Simpan Perubahan` | `Save Changes` | 256 |
| `tapToViewDetails` | `Ketik untuk butiran` | `Tap for details` | 257-258 |
| `allFollowUpsTitle` | `Senarai Susulan` | `Follow-up List` | 261 |
| `searchByBabyId` | `Cari ID Bayi...` | `Search baby ID...` | 262 |
| `filterAll` | `Semua` | `All` | 263 |
| `filterLtfu` | `LTFU` | `LTFU` | 264 |
| `filterRed` | `Merah` | `Red` | 265 |
| `filterAmber` | `Oren` | `Amber` | 266 |
| `filterNew` | `Baharu` | `New` | 267 |
| `noFollowUpsFound` | `Tiada susulan dijumpai` | `No follow-ups found` | 268-269 |
| `dueDateLabel` | `Tarikh Akhir` | `Due Date` | 270 |
| `daysOverdueText` | `hari lewat` | `days overdue` | 271 |
| `confirmAction` | `Sahkan Tindakan` | `Confirm Action` | 274 |
| `confirmMarkLtfu` | `Tanda bayi ini sebagai Hilang Susulan (LTFU)?` | `Mark this baby as Lost to Follow-up (LTFU)?` | 275-277 |
| `confirmComplete` | `Tanda kes ini sebagai Selesai?` | `Mark this case as Completed?` | 278-279 |
| `confirmEscalate` | `Naik taraf kes ini kepada penyelia?` | `Escalate this case to supervisor?` | 280-282 |
| `yes` | `Ya` | `Yes` | 283 |
| `no` | `Tidak` | `No` | 284 |
| `markedAsContacted` | `Dihubungi` | `Marked as Contacted` | 287 |
| `appointmentBooked` | `Temujanji Ditetapkan` | `Appointment Booked` | 288-289 |
| `caseEscalated` | `Kes Dinaik Taraf` | `Case Escalated` | 290 |
| `caseCompleted` | `Kes Selesai` | `Case Completed` | 291 |
| `caseMarkedLtfu` | `Hilang Susulan` | `Lost to Follow-up` | 292 |
| `actionQuickContacted` | `Dihubungi secara pantas` | `Quick contacted` | 295-296 |
| `actionQuickAppointment` | `Temujanji pantas` | `Quick appointment` | 297-298 |
| `actionQuickEscalated` | `Naik taraf pantas` | `Quick escalated` | 299-300 |
| `actionQuickCompleted` | `Selesai pantas` | `Quick completed` | 301-302 |
| `actionQuickLtfu` | `LTFU pantas` | `Quick LTFU` | 303 |
| `bookAppointmentTitle` | `Tetapkan Temujanji` | `Book Appointment` | 306-307 |
| `appointmentDateLabel` | `Tarikh & Masa Temujanji` | `Appointment Date & Time` | 308-309 |
| `confirmAppointment` | `Sahkan Temujanji` | `Confirm Appointment` | 310-311 |
| `invalidDateFormat` | `Format tarikh tidak sah` | `Invalid date format` | 312-313 |
| `escalateTitle` | `Naik Taraf Kes` | `Escalate Case` | 316 |
| `escalationReasonLabel` | `Sebab Pennaikan Taraf` | `Escalation Reason` | 317-318 |
| `escalationReasonHint` | `Nyatakan sebab...` | `Enter reason...` | 319-320 |
| `confirmEscalation` | `Sahkan Eskalasi` | `Confirm Escalation` | 321-322 |
| `daysOverduePrefix` | `Lewat` | `Overdue` | 325 |
| `daysOverdueSuffix` | `hari` | `days` | 326 |
| `daysRemainingSuffix` | `hari lagi` | `days left` | 327 |
| `appointmentLabel` | `Temujanji` | `Appointment` | 328 |
| `dueLabel` | `Tarikh akhir` | `Due` | 329 |
| `urgent` | `Segera` | `Urgent` | 332 |
| `severalDays` | `beberapa hari` | `several days` | 333 |
| `upcoming` | `Akan Datang` | `Upcoming` | 334 |
| `warning` | `Amaran` | `Warning` | 335 |
| `screenedOn` | `Saringan` | `Screened` | 338 |

Recently added / recently important keys specifically:

```dart
// mobile_flutter_app/hearlinx/lib/l10n/app_text.dart
325|   String get daysOverduePrefix => isMs ? 'Lewat' : 'Overdue';
326|   String get daysOverdueSuffix => isMs ? 'hari' : 'days';
327|   String get daysRemainingSuffix => isMs ? 'hari lagi' : 'days left';
328|   String get appointmentLabel => isMs ? 'Temujanji' : 'Appointment';
329|   String get dueLabel => isMs ? 'Tarikh akhir' : 'Due';
330| 
331|   // Urgency context
332|   String get urgent => isMs ? 'Segera' : 'Urgent';
333|   String get severalDays => isMs ? 'beberapa hari' : 'several days';
334|   String get upcoming => isMs ? 'Akan Datang' : 'Upcoming';
335|   String get warning => isMs ? 'Amaran' : 'Warning';
336| 
337|   // Screening context
338|   String get screenedOn => isMs ? 'Saringan' : 'Screened';
```

### `mobile_flutter_app/hearlinx/lib/ui/app_styles.dart`

File path: `mobile_flutter_app/hearlinx/lib/ui/app_styles.dart`.

Colors/constants:

```dart
// mobile_flutter_app/hearlinx/lib/ui/app_styles.dart
3  | class AppStyles {
4  |   static const brand = Color(0xFF0D6E63);
5  |   static const accent = Color(0xFF17B8A1);
6  |   static const background = Color(0xFFF6FAF9);
7  |   static const surface = Colors.white;
8  |   static const textPrimary = Color(0xFF20323B);
9  |   static const textSecondary = Color(0xFF5B6B73);
10 |   static const success = Color(0xFF26D07C);
11 |   static const danger = Color(0xFFE85D75);
12 |   static const warning = Color(0xFFF59E0B);
13 |   static const pagePadding = EdgeInsets.fromLTRB(20, 20, 20, 28);
14 |   static const formPagePadding = EdgeInsets.symmetric(horizontal: 28, vertical: 20);
15 |   static const buttonHeight = 60.0;
16 |   static const buttonRadius = 14.0;
17 |   static const cardRadius = 14.0;
```

Text styles:

```dart
// mobile_flutter_app/hearlinx/lib/ui/app_styles.dart
19 |   static const headingStyle = TextStyle(
20 |     fontSize: 22,
21 |     fontWeight: FontWeight.w800,
22 |     color: textPrimary,
23 |   );
24 |   static const sectionTitleStyle = TextStyle(
25 |     fontSize: 18,
26 |     fontWeight: FontWeight.w800,
27 |     color: textPrimary,
28 |   );
29 |   static const bodyStyle = TextStyle(
30 |     fontSize: 14,
31 |     fontWeight: FontWeight.w500,
32 |     color: textSecondary,
33 |     height: 1.4,
34 |   );
35 |   static const labelStyle = TextStyle(
36 |     fontSize: 13,
37 |     fontWeight: FontWeight.w600,
38 |     color: textSecondary,
39 |     height: 1.35,
40 |   );
```

Methods:

```dart
// mobile_flutter_app/hearlinx/lib/ui/app_styles.dart
42 |   static BoxDecoration surfaceCard({Color color = surface}) {
...
56 |   static ButtonStyle primaryButtonStyle() {
...
70 |   static ButtonStyle outlineButtonStyle() {
```

### `mobile_flutter_app/hearlinx/lib/providers/language_provider.dart`

File path: `mobile_flutter_app/hearlinx/lib/providers/language_provider.dart`.

Language switching logic:

- Storage key: `'hearlinx_lang'`.
- Default locale: Malay `Locale('ms')`.
- Loads saved locale from `SharedPreferences`.
- Accepts only `en` or `ms`.
- `toggleLang()` toggles between `en` and `ms`.

Exact code:

```dart
// mobile_flutter_app/hearlinx/lib/providers/language_provider.dart
6  | class LanguageProvider extends ChangeNotifier {
7  |   static const _storageKey = 'hearlinx_lang';
8  | 
9  |   Locale _locale = const Locale('ms');
10 | 
11 |   Locale get locale => _locale;
12 |   String get lang => _locale.languageCode;
13 |   AppText get text => AppText(lang);
14 | 
15 |   Future<void> loadSavedLocale() async {
16 |     final prefs = await SharedPreferences.getInstance();
17 |     final savedLang = prefs.getString(_storageKey) ?? 'ms';
18 | 
19 |     if (savedLang == 'en' || savedLang == 'ms') {
20 |       _locale = Locale(savedLang);
21 |       notifyListeners();
22 |     }
23 |   }
24 | 
25 |   Future<void> setLang(String lang) async {
26 |     if (lang != 'en' && lang != 'ms') {
27 |       return;
28 |     }
29 | 
30 |     if (_locale.languageCode == lang) {
31 |       return;
32 |     }
33 | 
34 |     _locale = Locale(lang);
35 |     final prefs = await SharedPreferences.getInstance();
36 |     await prefs.setString(_storageKey, lang);
37 |     notifyListeners();
38 |   }
39 | 
40 |   Future<void> toggleLang() async {
41 |     await setLang(lang == 'en' ? 'ms' : 'en');
42 |   }
43 | }
```

### `mobile_flutter_app/hearlinx/lib/services/auth_service.dart`

File path: `mobile_flutter_app/hearlinx/lib/services/auth_service.dart`.

JWT storage:

```dart
// mobile_flutter_app/hearlinx/lib/services/auth_service.dart
20 |   Future<String?> getToken() {
21 |     return _storage.read(key: 'jwt_token');
22 |   }
```

Logout:

```dart
// mobile_flutter_app/hearlinx/lib/services/auth_service.dart
24 |   Future<void> logout() async {
25 |     await _storage.delete(key: 'jwt_token');
26 |     await _storage.delete(key: 'selected_hospital');
27 |     await _storage.delete(key: 'staff_id');
28 |   }
```

Login storage:

```dart
// mobile_flutter_app/hearlinx/lib/services/auth_service.dart
135|       await _storage.write(key: 'jwt_token', value: token);
136|       await _storage.write(key: 'selected_hospital', value: hospitalCode);
137|       await _storage.write(key: 'staff_id', value: staffId);
```

Login endpoint:

```dart
// mobile_flutter_app/hearlinx/lib/services/auth_service.dart
109|   Future<bool> login({
110|     required String hospitalCode,
111|     required String staffId,
112|     required String pin,
113|   }) async {
114|     final response = await _client.post(
115|       Uri.parse('${ApiConfig.baseUrl}/auth/login'),
116|       headers: const {'Content-Type': 'application/json'},
117|       body: jsonEncode({
118|         'staff_id': staffId,
119|         'pin': pin,
120|         'hospital_code': hospitalCode,
121|       }),
122|     );
```

### `mobile_flutter_app/hearlinx/lib/services/offline_service.dart`

File path: `mobile_flutter_app/hearlinx/lib/services/offline_service.dart`.

SQLite schema:

```dart
// mobile_flutter_app/hearlinx/lib/services/offline_service.dart
15 |   static const _databaseName = 'hearlinx_offline.db';
16 |   static const _databaseVersion = 2;
17 |   static const _pendingScreeningsTable = 'pending_screenings';
```

```dart
// mobile_flutter_app/hearlinx/lib/services/offline_service.dart
38 |         await db.execute('''
39 |           CREATE TABLE $_pendingScreeningsTable (
40 |             id INTEGER PRIMARY KEY AUTOINCREMENT,
41 |             baby_id TEXT NOT NULL,
42 |             screening_type TEXT NOT NULL,
43 |             ear_left TEXT NOT NULL,
44 |             ear_right TEXT NOT NULL,
45 |             notes TEXT,
46 |             screening_date TEXT,
47 |             created_at TEXT NOT NULL
48 |           )
49 |         ''');
```

Upgrade:

```dart
// mobile_flutter_app/hearlinx/lib/services/offline_service.dart
51 |       onUpgrade: (db, oldVersion, newVersion) async {
52 |         if (oldVersion < 2) {
53 |           await db.execute(
54 |             'ALTER TABLE $_pendingScreeningsTable ADD COLUMN screening_date TEXT',
55 |           );
56 |         }
57 |       },
```

Methods:

```dart
// mobile_flutter_app/hearlinx/lib/services/offline_service.dart
64 |   Future<void> savePendingScreening(Screening screening) async {
...
77 |   Future<int> getPendingScreeningCount() async {
...
85 |   Future<int> syncPendingScreenings(String token) async {
```

Sync endpoint:

```dart
// mobile_flutter_app/hearlinx/lib/services/offline_service.dart
102|         final response = await _apiService.client.post(
103|           Uri.parse('${_apiService.baseEndpoint}/screenings/'),
104|           headers: {
105|             'Content-Type': 'application/json',
106|             'Authorization': 'Bearer $token',
107|           },
108|           body: jsonEncode({
109|             'baby_id': screening.babyId,
110|             'screening_type': screening.screeningType,
111|             'ear_left': screening.earLeft,
112|             'ear_right': screening.earRight,
113|             'notes': screening.notes,
114|             if (screening.screeningDate != null)
115|               'screening_date': screening.screeningDate,
116|           }),
117|         );
```

Current offline status: implemented for pending screenings only; follow-up cache/sync queue/connectivity banner are not fully wired.

### `mobile_flutter_app/hearlinx/lib/screens/login_screen.dart`

File path: `mobile_flutter_app/hearlinx/lib/screens/login_screen.dart`.

Key UI elements:

- Hospital dropdown fetched from `${ApiConfig.baseUrl}/hospitals/`.
- Staff ID field.
- PIN field with numeric input formatter.
- BM/EN language toggle.
- Login button.
- Forgot PIN dialog.
- Version / Shorebird patch badge.

Hospital short names:

```dart
// mobile_flutter_app/hearlinx/lib/screens/login_screen.dart
16 | class _HospitalOption {
17 |   static final Map<String, String> _hospitalShortNames = {
18 |     'HKL001': 'Hospital KL',
19 |     'HPJ001': 'Hospital Putrajaya',
20 |     'HSB001': 'Hospital Sungai Buloh',
21 |   };
```

Shorebird patch banner logic:

```dart
// mobile_flutter_app/hearlinx/lib/screens/login_screen.dart
80 |   Future<void> _checkPatchStatus() async {
81 |     try {
82 |       final shorebird = ShorebirdCodePush();
83 |       final patch = await shorebird.currentPatchNumber();
84 |       final prefs = await SharedPreferences.getInstance();
85 |       final justApplied = prefs.getBool('patch_just_applied') ?? false;
86 | 
87 |       if (mounted) {
88 |         setState(() {
89 |           _currentPatch = patch;
90 |           _showPatchBanner = justApplied;
91 |         });
92 |       }
93 | 
94 |       if (justApplied) {
95 |         await prefs.setBool('patch_just_applied', false);
96 |       }
97 |     } catch (_) {
98 |       // Shorebird not available in debug mode — ignore
99 |     }
100|   }
```

Version display:

```dart
// mobile_flutter_app/hearlinx/lib/screens/login_screen.dart
697|                                                 '${t.appVersion} · ${t.patchLabel} ${_currentPatch ?? 0} · ${t.versionUpToDate}',
```

### `mobile_flutter_app/hearlinx/lib/screens/coordinator_dashboard_screen.dart`

File path: `mobile_flutter_app/hearlinx/lib/screens/coordinator_dashboard_screen.dart`.

#### `_FollowUpItem` model

Exact constructor:

```dart
// mobile_flutter_app/hearlinx/lib/screens/coordinator_dashboard_screen.dart
2341| class _FollowUpItem {
2342|   const _FollowUpItem({
2343|     required this.id,
2344|     required this.babySystemId,
2345|     required this.dueDate,
2346|     required this.status,
2347|     required this.urgency,
2348|     required this.daysOverdue,
2349|     required this.notes,
2350|     required this.appointmentDate,
2351|     required this.ltfuReason,
2352|     required this.contactAttempts,
2353|     required this.screeningDate,
2354|   });
```

Fields:

```dart
// mobile_flutter_app/hearlinx/lib/screens/coordinator_dashboard_screen.dart
2383|   final String id;
2384|   final String babySystemId;
2385|   final DateTime? dueDate;
2386|   final String status;
2387|   final String urgency;
2388|   final int daysOverdue;
2389|   final String? notes;
2390|   final DateTime? appointmentDate;
2391|   final String? ltfuReason;
2392|   final int contactAttempts;
2393|   final DateTime? screeningDate;
```

`fromJson` parsing:

```dart
// mobile_flutter_app/hearlinx/lib/screens/coordinator_dashboard_screen.dart
2367|       id: json['id'] as String? ?? '',
2368|       babySystemId: json['baby_system_id'] as String? ?? '',
2369|       dueDate: parseDateSafe(json['due_date']),
2370|       status: json['status'] as String? ?? '',
2371|       urgency: json['urgency'] as String? ?? 'new',
2372|       daysOverdue: json['days_overdue'] as int? ?? 0,
2373|       notes: json['notes'] as String?,
2374|       appointmentDate: parseDateSafe(json['appointment_date']),
2375|       ltfuReason: json['ltfu_reason'] as String?,
2376|       contactAttempts: json['contact_attempts'] as int? ?? 0,
2377|       screeningDate: parseDateSafe(
2378|         json['created_at'] ?? json['screening_date'],
2379|       ),
```

#### `_resolveUrgency`

Exact method:

```dart
// mobile_flutter_app/hearlinx/lib/screens/coordinator_dashboard_screen.dart
2068|   /// Resolve effective urgency, label, color, and subtitle for a follow-up item.
2069|   (String urgency, String label, Color color, String subtitle) _resolveUrgency(
2070|     _FollowUpItem item,
2071|     AppText t,
2072|   ) {
2073|     final now = DateTime.now();
2074| 
2075|     if (item.appointmentDate != null) {
2076|       final hoursUntil = item.appointmentDate!.difference(now).inHours;
2077| 
2078|       if (hoursUntil <= 24 && hoursUntil > 0) {
2079|         return (
2080|           'red',
2081|           t.redRisk,
2082|           AppStyles.danger,
2083|           '${t.appointmentLabel}: ${DateFormat('d MMM yyyy, hh:mm a', 'en_US').format(item.appointmentDate!)} · ${t.urgent}',
2084|         );
2085|       }
2086|       if (hoursUntil <= 168 && hoursUntil > 0) {
2087|         return (
2088|           'amber',
2089|           t.upcoming,
2090|           const Color(0xFFEA580C),
2091|           '${t.appointmentLabel}: ${DateFormat('d MMM yyyy, hh:mm a', 'en_US').format(item.appointmentDate!)} · ${hoursUntil ~/ 24} ${t.daysRemainingSuffix}',
2092|         );
2093|       }
2094|       if (hoursUntil <= 0) {
2095|         return (
2096|           'red',
2097|           t.redRisk,
2098|           AppStyles.danger,
2099|           '${t.appointmentLabel}: ${DateFormat('d MMM yyyy, hh:mm a', 'en_US').format(item.appointmentDate!)} · ${t.overdue}',
2100|         );
2101|       }
2102|     }
2103| 
2104|     return switch (item.urgency) {
2105|       'ltfu' => (
2106|         'ltfu',
2107|         t.ltfu,
2108|         AppStyles.warning,
2109|         item.daysOverdue > 0
2110|             ? '${t.daysOverduePrefix} ${item.daysOverdue} ${t.daysOverdueSuffix}'
2111|             : '${t.daysOverduePrefix} ${t.severalDays}',
2112|       ),
2113|       'red' => (
2114|         'red',
2115|         t.redRisk,
2116|         AppStyles.danger,
2117|         item.daysOverdue > 0
2118|             ? '${t.daysOverduePrefix} ${item.daysOverdue} ${t.daysOverdueSuffix}'
2119|             : '${t.daysOverduePrefix} ${t.severalDays}',
2120|       ),
2121|       'amber' => (
2122|         'amber',
2123|         t.warning,
2124|         const Color(0xFFEA580C),
2125|         '${t.dueLabel}: ${DateFormat('d MMM').format(item.dueDate ?? now)}',
2126|       ),
2127|       _ => (
2128|         'new',
2129|         t.newFollowup,
2130|         AppStyles.accent,
2131|         item.dueDate != null
2132|             ? '${t.dueLabel}: ${DateFormat('d MMM').format(item.dueDate!)}'
2133|             : t.noDueDate,
2134|       ),
2135|     };
2136|   }
```

Logic summary:

1. Appointment date overrides backend urgency.
2. If appointment is within 24 hours and future: `red`.
3. If appointment is within 168 hours / 7 days and future: `amber`.
4. If appointment time is past or now: `red`.
5. Otherwise uses backend `item.urgency`.
6. `ltfu`/`red` use overdue or `severalDays`.
7. Backend `amber` uses `t.warning`, not `t.upcoming`.

#### `_buildCompactFollowUpRow`

Exact method starts at line 2138. It renders:

- Card container with urgency color.
- `InkWell` row to open `_showFollowUpDetails`.
- Baby system ID.
- Resolved urgency subtitle.
- Screening date text if present.
- Status chip.
- Chevron icon.
- Quick action chips:
  - Contacted
  - Book appointment
  - Escalate
  - Complete
  - Mark LTFU

Exact method:

```dart
// mobile_flutter_app/hearlinx/lib/screens/coordinator_dashboard_screen.dart
2138|   Widget _buildCompactFollowUpRow(_FollowUpItem item, AppText t) {
2139|     final (urgency, urgencyLabel, urgencyColor, subtitle) = _resolveUrgency(
2140|       item,
2141|       t,
2142|     );
2143| 
2144|     final screeningText = item.screeningDate != null
2145|         ? '${t.screenedOn}: ${DateFormat('d MMM').format(item.screeningDate!)}'
2146|         : '';
2147| 
2148|     return Container(
2149|       margin: const EdgeInsets.only(bottom: 8),
2150|       decoration: BoxDecoration(
2151|         color: urgencyColor.withValues(alpha: 0.05),
2152|         borderRadius: BorderRadius.circular(8),
2153|         border: Border.all(
2154|           color: urgencyColor.withValues(alpha: 0.15),
2155|           width: 1,
2156|         ),
2157|       ),
2158|       child: Column(
2159|         crossAxisAlignment: CrossAxisAlignment.start,
2160|         children: [
2161|           InkWell(
2162|             onTap: () => _showFollowUpDetails(item),
2163|             borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
2164|             child: Padding(
2165|               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
2166|               child: Row(
2167|                 children: [
2168|                   Container(
2169|                     width: 8,
2170|                     height: 8,
2171|                     decoration: BoxDecoration(
2172|                       color: urgencyColor,
2173|                       borderRadius: BorderRadius.circular(999),
2174|                     ),
2175|                   ),
2176|                   const SizedBox(width: 12),
2177|                   Expanded(
2178|                     child: Column(
2179|                       crossAxisAlignment: CrossAxisAlignment.start,
2180|                       children: [
2181|                         Text(
2182|                           item.babySystemId,
2183|                           style: const TextStyle(
2184|                             fontWeight: FontWeight.w700,
2185|                             fontFamily: 'monospace',
2186|                             fontSize: 13,
2187|                             letterSpacing: 0.5,
2188|                           ),
2189|                         ),
2190|                         const SizedBox(height: 2),
2191|                         Text(
2192|                           subtitle,
2193|                           style: TextStyle(
2194|                             color: AppStyles.textSecondary,
2195|                             fontSize: 11,
2196|                           ),
2197|                         ),
2198|                         if (screeningText.isNotEmpty)
2199|                           Text(
2200|                             screeningText,
2201|                             style: TextStyle(
2202|                               color: AppStyles.textSecondary.withValues(
2203|                                 alpha: 0.7,
2204|                               ),
2205|                               fontSize: 10,
2206|                             ),
2207|                           ),
2208|                       ],
2209|                     ),
2210|                   ),
2211|                   Container(
2212|                     padding: const EdgeInsets.symmetric(
2213|                       horizontal: 8,
2214|                       vertical: 4,
2215|                     ),
2216|                     decoration: BoxDecoration(
2217|                       color: urgencyColor.withValues(alpha: 0.1),
2218|                       borderRadius: BorderRadius.circular(6),
2219|                     ),
2220|                     child: Text(
2221|                       _translateStatus(item.status, t),
2222|                       style: TextStyle(
2223|                         color: urgencyColor,
2224|                         fontSize: 11,
2225|                         fontWeight: FontWeight.w700,
2226|                       ),
2227|                     ),
2228|                   ),
2229|                   const SizedBox(width: 8),
2230|                   const Icon(
2231|                     Icons.chevron_right_rounded,
2232|                     color: AppStyles.textSecondary,
2233|                     size: 20,
2234|                   ),
2235|                 ],
2236|               ),
2237|             ),
2238|           ),
2239|           Padding(
2240|             padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
2241|             child: Wrap(
2242|               spacing: 6,
2243|               runSpacing: 6,
2244|               children: [
2245|                 _miniActionButton(
2246|                   t.markContacted,
2247|                   () => _quickAction(item.id, 'contacted', t.markedAsContacted),
2248|                   Colors.green,
2249|                 ),
2250|                 _miniActionButton(
2251|                   t.bookAppointment,
2252|                   () => _showAppointmentDialog(item.id),
2253|                   Colors.blue,
2254|                 ),
2255|                 _miniActionButton(
2256|                   t.escalate,
2257|                   () => _showEscalationDialog(item.id),
2258|                   Colors.orange,
2259|                 ),
2260|                 _miniActionButton(
2261|                   t.complete,
2262|                   () => _confirmAndQuickAction(
2263|                     item.id,
2264|                     'completed',
2265|                     t.confirmComplete,
2266|                     t.caseCompleted,
2267|                   ),
2268|                   AppStyles.success,
2269|                 ),
2270|                 _miniActionButton(
2271|                   t.markLtfu,
2272|                   () => _confirmAndQuickAction(
2273|                     item.id,
2274|                     'lost_to_followup',
2275|                     t.confirmMarkLtfu,
2276|                     t.caseMarkedLtfu,
2277|                   ),
2278|                   AppStyles.warning,
2279|                 ),
2280|               ],
2281|             ),
2282|           ),
2283|         ],
2284|       ),
2285|     );
2286|   }
```

#### `_showAppointmentDialog`

Exact method starts at line 1226. It uses:

- `showDatePicker` with `initialDate: DateTime.now()`, `firstDate: DateTime.now()`, `lastDate: DateTime.now().add(const Duration(days: 365))`.
- Date button displays `d MMM yyyy`.
- Time picker is enabled only after date is selected.
- Time picker uses `Localizations.override(locale: const Locale('en', 'US'))`.
- Time display uses `_formatTimeOfDay`.
- Confirm button disabled until both date and time selected.
- On confirm, sends PATCH payload:

```dart
// mobile_flutter_app/hearlinx/lib/screens/coordinator_dashboard_screen.dart
1418|       await _patchFollowUp(id, {
1419|         'status': 'appointment_booked',
1420|         'appointment_date': dateTime.toIso8601String(),
1421|       });
```

#### `_showEscalationDialog`

Exact method starts at line 1425. It uses:

- `TextEditingController`.
- `TextField` with `minLines: 2`, `maxLines: 4`.
- On confirm, sends status `escalated`.
- Notes are null when empty to prevent sending blank notes:

```dart
// mobile_flutter_app/hearlinx/lib/screens/coordinator_dashboard_screen.dart
1466|       await _patchFollowUp(id, {
1467|         'status': 'escalated',
1468|         'notes': controller.text.trim().isEmpty ? null : controller.text.trim(),
1469|       });
1470|     }
1471|     controller.dispose();
```

#### `_showFollowUpDetails`

Exact method starts at line 1474. Modal content:

- Fetches timeline events via `_fetchFollowUpEvents(item.id)`.
- Uses `showModalBottomSheet`.
- Uses `DraggableScrollableSheet`.
- Shows baby ID.
- Status dropdown with:
  - `pending`
  - `contacted`
  - `appointment_booked`
  - `escalated`
  - `completed`
  - `lost_to_followup`
  - `closed`
- Appointment text field with default `yyyy-MM-dd HH:mm`.
- LTFU reason field.
- Notes field.
- Contact attempts display.
- Timeline events display.
- Save button builds payload:

```dart
// mobile_flutter_app/hearlinx/lib/screens/coordinator_dashboard_screen.dart
1945|                               final payload = <String, dynamic>{
1946|                                 'status': selectedStatus,
1947|                                 'notes': notesController.text.trim().isEmpty
1948|                                     ? null
1949|                                     : notesController.text.trim(),
1950|                                 'ltfu_reason':
1951|                                     reasonController.text.trim().isEmpty
1952|                                     ? null
1953|                                     : reasonController.text.trim(),
1954|                               };
1955|                               final appointmentText = appointmentController.text
1956|                                   .trim();
1957|                               if (appointmentText.isNotEmpty) {
1958|                                 payload['appointment_date'] = DateTime.parse(
1959|                                   appointmentText,
1960|                                 ).toIso8601String();
1961|                               }
1962|                               Navigator.of(context).pop();
1963|                               await _patchFollowUp(item.id, payload);
```

#### `_quickAction` and `_confirmAndQuickAction`

`_quickAction` starts at line 1154. It PATCHes only `{'status': status}`.

```dart
// mobile_flutter_app/hearlinx/lib/screens/coordinator_dashboard_screen.dart
1163|       final response = await http
1164|           .patch(
1165|             Uri.parse('${ApiConfig.baseUrl}/followups/$id'),
1166|             headers: {
1167|               'Authorization': 'Bearer $token',
1168|               'Content-Type': 'application/json',
1169|             },
1170|             body: jsonEncode({'status': status}),
1171|           )
```

`_confirmAndQuickAction` starts at line 1195. It shows confirmation dialog and calls `_quickAction` if confirmed.

#### `_patchFollowUp`

Exact method starts at line 294. It PATCHes:

```dart
// mobile_flutter_app/hearlinx/lib/screens/coordinator_dashboard_screen.dart
301|       final response = await _apiService.client
302|           .patch(
303|             Uri.parse('${_apiService.baseEndpoint}/followups/$id'),
304|             headers: {
305|               'Authorization': 'Bearer $token',
306|               'Content-Type': 'application/json',
307|             },
308|             body: jsonEncode(payload),
309|           )
310|           .timeout(const Duration(seconds: 15));
```

### `mobile_flutter_app/hearlinx/lib/screens/followup_list_screen.dart`

File path: `mobile_flutter_app/hearlinx/lib/screens/followup_list_screen.dart`.

#### `_FollowUpListItem` model

Exact constructor:

```dart
// mobile_flutter_app/hearlinx/lib/screens/followup_list_screen.dart
1056| class _FollowUpListItem {
1057|   const _FollowUpListItem({
1058|     required this.id,
1059|     required this.babySystemId,
1060|     required this.dueDate,
1061|     required this.status,
1062|     required this.urgency,
1063|     required this.daysOverdue,
1064|     required this.contactAttempts,
1065|     required this.appointmentDate,
1066|     required this.screeningDate,
1067|   });
```

Fields:

```dart
// mobile_flutter_app/hearlinx/lib/screens/followup_list_screen.dart
1094|   final String id;
1095|   final String babySystemId;
1096|   final DateTime? dueDate;
1097|   final String status;
1098|   final String urgency;
1099|   final int daysOverdue;
1100|   final int contactAttempts;
1101|   final DateTime? appointmentDate;
1102|   final DateTime? screeningDate;
```

`fromJson`:

```dart
// mobile_flutter_app/hearlinx/lib/screens/followup_list_screen.dart
1080|       id: json['id'] as String? ?? '',
1081|       babySystemId: json['baby_system_id'] as String? ?? '',
1082|       dueDate: parseDateSafe(json['due_date']),
1083|       status: json['status'] as String? ?? '',
1084|       urgency: json['urgency'] as String? ?? 'new',
1085|       daysOverdue: json['days_overdue'] as int? ?? 0,
1086|       contactAttempts: json['contact_attempts'] as int? ?? 0,
1087|       appointmentDate: parseDateSafe(json['appointment_date']),
1088|       screeningDate: parseDateSafe(
1089|         json['created_at'] ?? json['screening_date'],
1090|       ),
```

#### `_resolveUrgency`

Exact method starts at line 166. It is the same appointment-overrides-backend logic as coordinator dashboard, with exact lines:

```dart
// mobile_flutter_app/hearlinx/lib/screens/followup_list_screen.dart
166|   /// Resolve effective urgency, label, color, and subtitle for a follow-up item.
167|   /// Considers appointment proximity, backend urgency, and overdue status.
168|   (String urgency, String label, Color color, String subtitle) _resolveUrgency(
169|     _FollowUpListItem item,
170|     AppText t,
171|   ) {
172|     final now = DateTime.now();
173| 
174|     // 1. Appointment-based override (most important)
175|     if (item.appointmentDate != null) {
176|       final hoursUntil = item.appointmentDate!.difference(now).inHours;
177| 
178|       if (hoursUntil <= 24 && hoursUntil > 0) {
179|         return (
180|           'red',
181|           t.redRisk,
182|           AppStyles.danger,
183|           '${t.appointmentLabel}: ${DateFormat('d MMM yyyy, hh:mm a', 'en_US').format(item.appointmentDate!)} · ${t.urgent}',
184|         );
185|       }
186|       if (hoursUntil <= 168 && hoursUntil > 0) {
187|         return (
188|           'amber',
189|           t.upcoming,
190|           const Color(0xFFEA580C),
191|           '${t.appointmentLabel}: ${DateFormat('d MMM yyyy, hh:mm a', 'en_US').format(item.appointmentDate!)} · ${hoursUntil ~/ 24} ${t.daysRemainingSuffix}',
192|         );
193|       }
194|       if (hoursUntil <= 0) {
195|         return (
196|           'red',
197|           t.redRisk,
198|           AppStyles.danger,
199|           '${t.appointmentLabel}: ${DateFormat('d MMM yyyy, hh:mm a', 'en_US').format(item.appointmentDate!)} · ${t.overdue}',
200|         );
201|       }
202|     }
203| 
204|     // 2. Backend urgency fallback
205|     return switch (item.urgency) {
206|       'ltfu' => (
207|         'ltfu',
208|         t.ltfu,
209|         AppStyles.warning,
210|         item.daysOverdue > 0
211|             ? '${t.daysOverduePrefix} ${item.daysOverdue} ${t.daysOverdueSuffix}'
212|             : '${t.daysOverduePrefix} ${t.severalDays}',
213|       ),
214|       'red' => (
215|         'red',
216|         t.redRisk,
217|         AppStyles.danger,
218|         item.daysOverdue > 0
219|             ? '${t.daysOverduePrefix} ${item.daysOverdue} ${t.daysOverdueSuffix}'
220|             : '${t.daysOverduePrefix} ${t.severalDays}',
221|       ),
222|       'amber' => (
223|         'amber',
224|         t.warning,
225|         const Color(0xFFEA580C),
226|         '${t.dueLabel}: ${DateFormat('d MMM').format(item.dueDate ?? now)}',
227|       ),
228|       _ => (
229|         'new',
230|         t.newFollowup,
231|         AppStyles.accent,
232|         item.dueDate != null
233|             ? '${t.dueLabel}: ${DateFormat('d MMM').format(item.dueDate!)}'
234|             : t.noDueDate,
235|       ),
236|     };
237|   }
```

#### `_applyFilter`

Exact method:

```dart
// mobile_flutter_app/hearlinx/lib/screens/followup_list_screen.dart
96 |   void _applyFilter() {
97 |     var filtered = _allFollowUps;
98 | 
99 |     if (_searchQuery.isNotEmpty) {
100|       filtered = filtered
101|           .where(
102|             (item) => item.babySystemId.toLowerCase().contains(
103|               _searchQuery.toLowerCase(),
104|             ),
105|           )
106|           .toList();
107|     }
108| 
109|     // Filter by RESOLVED urgency, not raw backend urgency
110|     if (_filterUrgency != 'all') {
111|       filtered = filtered.where((item) {
112|         final (effectiveUrgency, _, _, _) = _resolveUrgency(
113|           item,
114|           _allFollowUps.isEmpty
115|               ? AppText('en')
116|               : context.read<LanguageProvider>().text,
117|         );
118|         return effectiveUrgency == _filterUrgency;
119|       }).toList();
120|     }
121| 
122|     setState(() {
123|       _filteredFollowUps = filtered;
124|     });
125|   }
```

#### `_buildFollowUpCard`

Exact method starts at line 820. It renders:

- Card with urgency color.
- Header with baby system ID.
- Urgency badge.
- Days overdue badge if applicable.
- Card subtitle from `_resolveUrgency`.
- Screening context from `screeningDate`.
- Status and date on right.
- Quick action buttons.
- Tap hint.

Important exact lines:

```dart
// mobile_flutter_app/hearlinx/lib/screens/followup_list_screen.dart
820|   Widget _buildFollowUpCard(_FollowUpListItem item, AppText t) {
821|     final (effectiveUrgency, urgencyLabel, urgencyColor, cardSubtitle) =
822|         _resolveUrgency(item, t);
823| 
824|     final screeningText = item.screeningDate != null
825|         ? '${t.screenedOn}: ${DateFormat('d MMM').format(item.screeningDate!)}'
826|         : '';
```

#### Navigation/back button logic

Back button:

```dart
// mobile_flutter_app/hearlinx/lib/screens/followup_list_screen.dart
626|         leading: IconButton(
627|           icon: const Icon(Icons.arrow_back),
628|           onPressed: () => Navigator.of(context).pop(),
629|         ),
```

Logout in this screen still uses stack reset:

```dart
// mobile_flutter_app/hearlinx/lib/screens/followup_list_screen.dart
655|             onPressed: () async {
656|               await AuthService().logout();
657|               if (!context.mounted) return;
658|               Navigator.of(
659|                 context,
660|               ).pushNamedAndRemoveUntil('/login', (route) => false);
661|             }
```

#### `_quickActionWithPayload`

Exact method:

```dart
// mobile_flutter_app/hearlinx/lib/screens/followup_list_screen.dart
316|   Future<void> _quickActionWithPayload(
317|     String id,
318|     Map<String, dynamic> payload,
319|   ) async {
320|     final t = context.read<LanguageProvider>().text;
321|     try {
322|       final token = await _authService.getToken();
323|       if (token == null || token.isEmpty) throw Exception(t.sessionExpired);
324| 
325|       final response = await http
326|           .patch(
327|             Uri.parse('${ApiConfig.baseUrl}/followups/$id'),
328|             headers: {
329|               'Authorization': 'Bearer $token',
330|               'Content-Type': 'application/json',
331|             },
332|             body: jsonEncode(payload),
333|           )
334|           .timeout(const Duration(seconds: 15));
```

Used by appointment and escalation dialogs.

### `mobile_flutter_app/hearlinx/lib/widgets/app_shell.dart`

File path: `mobile_flutter_app/hearlinx/lib/widgets/app_shell.dart`.

Purpose:

- Reusable `Scaffold` for dashboard screens.
- Shows brand-colored app bar.
- Shows title.
- Shows language toggle.
- Shows logout button.
- Optionally shows back-to-home button.
- Accepts extra actions.

Navigation:

```dart
// mobile_flutter_app/hearlinx/lib/widgets/app_shell.dart
22 |   Future<void> _logout(BuildContext context) async {
23 |     await AuthService().logout();
24 |     if (!context.mounted) {
25 |       return;
26 |     }
27 |     Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
28 |   }
```

```dart
// mobile_flutter_app/hearlinx/lib/widgets/app_shell.dart
40 |         leading: showBackToHome
41 |             ? IconButton(
42 |                 icon: const Icon(Icons.arrow_back),
43 |                 onPressed: () {
44 |                   Navigator.of(
45 |                     context,
46 |                   ).pushNamedAndRemoveUntil('/home', (route) => false);
47 |                 },
48 |               )
49 |             : null,
```

Language toggle:

```dart
// mobile_flutter_app/hearlinx/lib/widgets/app_shell.dart
62 |           TextButton(
63 |             onPressed: languageProvider.toggleLang,
64 |             child: Text(
65 |               languageProvider.lang == 'en' ? 'BM' : 'EN',
```

---

## Recent Changes & Fixes

Git history checked with:

```powershell
git log --oneline -20
```

Result:

```text
32789fca (HEAD -> main, origin/main, origin/HEAD) test: OTA patch - version label update
6cca3514 fix: date picker for appointments + escalation dialog + backend migration for status constraint
d90a88aa fix: translations, quick actions, icon corruption prevention
fabd9540 feat: redesigned follow-up modal + full follow-up list page + translations
75ce058e chore: clean repo - ignore misc, config, untracked pdfs; keep core folders
dbcbdc31 feat: patch status UI on login - version indicator + update snackbar
3ea730b9 chore: remove unnecessary project docs, keep only ICT proposal, logo, poster, concept brief
3eebe247 fix: flutter default Malay, login offline error dialog, web AM/PM dates, remove broken widget test
297273aa fix: followups contact_attempts NULL validation, web dashboard BM/EN hardcoded strings
9f9f1db2 fix: add follow_up_events table guard, fix RUJUK 500 error
77fcc2ec chore: trigger vercel redeploy
706b0a82 chore: ignore untracked dev files
e1a81f01 fix: web dashboard - screener redirect, coordinator screenings page, remove dead nav links
b07756c4 fix: minor Flutter UI and translation tweaks
f2308abb feat: backend model updates, screening logic fixes, and Flutter offline/UI refinements
33221540 fix: remove text overflow ellipsis and polish UI text display
478c1fc3 second flutter history screenings3_6_2026
2f2bb876 feat: add coverage, benchmark, and ward metrics to web coordinator dashboard
3252bac4 feat: UI polish, new app icons, web dashboard metrics, and project docs reorganization
```

### 1. Font/icon corruption prevention

Evidence:

```text
d90a88aa fix: translations, quick actions, icon corruption prevention
```

Git diff evidence:

```diff
# mobile_flutter_app/hearlinx/lib/screens/coordinator_dashboard_screen.dart
1308|                                   Icons.person,
```

The diff for `d90a88aa` shows replacement of `Icons.child_care_rounded` with `Icons.person` in the follow-up detail modal. The fix was to avoid corrupted Material icon rendering. The Shorebird release command to preserve icon/font data is:

```powershell
shorebird release android --artifact=apk -- --no-tree-shake-icons
```

### 2. Shorebird base mismatch

Current repository evidence:

- `pubspec.yaml` still says `version: 1.0.0+1`.
- `AppText.appVersion` says `v1.0.1`.
- No git tags were present from `git tag --list`.
- Shorebird CLI state is not stored in the repo.

Required build knowledge:

```powershell
shorebird release android --artifact=apk -- --no-tree-shake-icons
shorebird patch --platforms=android --release-version=1.0.0+1
```

Session note to preserve: old `1.0.0+1` base was deleted and a new base was rebuilt. Treat this as deployment history because the repo cannot verify Shorebird server state.

### 3. Appointment dialog

Commit:

```text
6cca3514 fix: date picker for appointments + escalation dialog + backend migration for status constraint
```

Implementation:

- `_showAppointmentDialog(String id)` in `coordinator_dashboard_screen.dart` line 1226 and `followup_list_screen.dart` line 359.
- Uses date picker and time picker.
- Time picker is disabled until a date is chosen.
- Sends:

```dart
'status': 'appointment_booked',
'appointment_date': dateTime.toIso8601String(),
```

### 4. Escalation dialog and null prevention

Implementation:

- `_showEscalationDialog(String id)` in `coordinator_dashboard_screen.dart` line 1425 and `followup_list_screen.dart` line 565.
- Uses `TextEditingController`.
- Sends:

```dart
'notes': controller.text.trim().isEmpty ? null : controller.text.trim(),
```

This prevents empty string notes being sent.

### 5. Database CHECK constraint

Migration:

```sql
# dengartrack-backend/db/migrations/002_fix_followup_status_constraint.sql
1 | -- Migration: Fix follow_ups status CHECK constraint
2 | -- Date: 2026-06-06
3 | -- Issue: appointment_booked and escalated were missing from CHECK constraint
4 | -- on the deployed database (schema.sql is already correct).
```

### 6. Urgency logic

Appointment override:

- 24h red.
- 168h amber.
- Past appointment red.
- Backend `amber` label uses `t.warning`.
- Appointment amber label uses `t.upcoming`.

Exact lines:

- `coordinator_dashboard_screen.dart`: 2068-2136.
- `followup_list_screen.dart`: 166-237.

### 7. Time display

Exact helper:

```dart
// mobile_flutter_app/hearlinx/lib/screens/coordinator_dashboard_screen.dart
2033|   String _formatTimeOfDay(TimeOfDay time) {
2034|     final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
2035|     final minute = time.minute.toString().padLeft(2, '0');
2036|     final period = time.hour < 12 ? 'AM' : 'PM';
2037|     return '$hour:$minute $period';
2038|   }
```

Also used in `followup_list_screen.dart` lines 159-164.

`hh:mm a` / `en_US` examples:

```dart
// coordinator_dashboard_screen.dart
473|     return DateFormat(
474|       'hh:mm a',
475|       'en_US',
476|     ).format(lastScreening.screeningDate.toLocal());
```

### 8. Amber label fix

Appointment amber uses `t.upcoming` in `_resolveUrgency`:

```dart
// coordinator_dashboard_screen.dart
2088|           t.upcoming,
```

Backend amber uses `t.warning`:

```dart
// coordinator_dashboard_screen.dart
2123|         t.warning,
```

### 9. New translation keys

New/recent keys include:

- `timelineCount`
- `confirmAction`
- `confirmMarkLtfu`
- `confirmComplete`
- `confirmEscalate`
- `yes`
- `no`
- `markedAsContacted`
- `appointmentBooked`
- `caseEscalated`
- `caseCompleted`
- `caseMarkedLtfu`
- `actionQuickContacted`
- `actionQuickAppointment`
- `actionQuickEscalated`
- `actionQuickCompleted`
- `actionQuickLtfu`
- `bookAppointmentTitle`
- `appointmentDateLabel`
- `confirmAppointment`
- `invalidDateFormat`
- `escalateTitle`
- `escalationReasonLabel`
- `escalationReasonHint`
- `confirmEscalation`
- `daysOverduePrefix`
- `daysOverdueSuffix`
- `daysRemainingSuffix`
- `appointmentLabel`
- `dueLabel`
- `urgent`
- `severalDays`
- `upcoming`
- `warning`
- `screenedOn`

### 10. Filter fix

Exact comment and logic:

```dart
// mobile_flutter_app/hearlinx/lib/screens/followup_list_screen.dart
109|     // Filter by RESOLVED urgency, not raw backend urgency
110|     if (_filterUrgency != 'all') {
111|       filtered = filtered.where((item) {
112|         final (effectiveUrgency, _, _, _) = _resolveUrgency(
```

### 11. Back navigation

Follow-up list uses `Navigator.pop()`:

```dart
// mobile_flutter_app/hearlinx/lib/screens/followup_list_screen.dart
628|           onPressed: () => Navigator.of(context).pop(),
```

Other screens still use `pushNamedAndRemoveUntil`, including `app_shell.dart` and `home_screen.dart`.

### 12. Screening context

Follow-up models parse:

```dart
screeningDate: parseDateSafe(
  json['created_at'] ?? json['screening_date'],
),
```

- `coordinator_dashboard_screen.dart`: lines 2377-2379.
- `followup_list_screen.dart`: lines 1088-1090.

---

## Shorebird / Build Configuration

File: `mobile_flutter_app/hearlinx/pubspec.yaml`.

Current version:

```yaml
19 | version: 1.0.0+1
```

Shorebird app ID:

```yaml
# mobile_flutter_app/hearlinx/shorebird.yaml
8 | app_id: 56e91c28-c9eb-4248-96e3-d3a78087b122
```

Shorebird release command used / required:

```powershell
shorebird release android --artifact=apk -- --no-tree-shake-icons
```

Shorebird patch command:

```powershell
shorebird patch --platforms=android --release-version=1.0.0+1
```

GitHub release APK URL:

```text
https://github.com/UwaisZulkarnain/HearlinX/releases/latest/download/DengarTrack.apk
```

APK output path:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Font fix flag:

```text
--no-tree-shake-icons
```

Reason: prevent icon/font corruption during release/APK build.

Current Shorebird base status:

- Repository cannot verify Shorebird server base state.
- No git tags were present.
- `pubspec.yaml` remains `1.0.0+1`.
- `app_text.dart` displays `v1.0.1`.
- Treat base mismatch status as deployment state, not repo state.

---

## Pending Features & Known Issues

1. **Notifications:** `flutter_local_notifications` plugin is NOT in `pubspec.yaml`. It must be added and baked into the next APK rebuild.
2. **End-of-day check-in screen:** Mak Uda requested it. Not implemented.
3. **Offline support:** `offline_service.dart` exists but is incomplete. It only stores/syncs pending screenings. Sync queue, connectivity banner, and offline follow-up cache are not fully wired.
4. **Dark mode:** Not implemented. There are 60+ hardcoded colors across screens.
5. **Auto-LTFU cron job:** Backend scheduler not implemented.
6. **QR scan offline:** `mobile_scanner` plugin exists, but offline logic is not wired.
7. **Web React:** Empty/not-started folder.
8. **Push notifications:** Not implemented. Firebase vs local notifications is still TBD.

---

## Mak Uda's Requirements / User Stories

1. Auto-mark missed appointments as LTFU after appointment day + 1.
2. End-of-day check-in: enter baby ID, mark status (`LTFU`, `escalated`, `completed`).
3. Appointment reminders when appointment is close.
4. Proper Malay/English — no mixing, no awkward translations.
5. Screener can work offline, sync when online.
6. Multiple screeners syncing — no ID conflicts, use UUID-based IDs.

---

## Test Credentials & Environment

Backend URLs:

- Local backend: `http://localhost:8000`
- Production/Railway: `https://hearlinx-production.up.railway.app`
- Flutter local fallback URL in `ApiConfig`: `http://10.20.88.90:8000`

How to run backend:

```powershell
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Working directory for backend:

```text
C:\Users\uwais\Desktop\DengarTrackiCaRehab\dengartrack-backend
```

Python venv:

```text
C:\Users\uwais\Desktop\DengarTrackiCaRehab\venv
```

How to run Flutter:

```powershell
flutter run
```

Working directory for Flutter:

```text
C:\Users\uwais\Desktop\DengarTrackiCaRehab\mobile_flutter_app\hearlinx
```

Documented demo credentials in `misc/CLAUDE_CONTEXT_CURRENT.md`:

```text
65 | ## Test Credentials (password: `password123`)
66 | ```
67 | screener@test.com (role: screener)
68 | coordinator@test.com (role: coordinator)
69 | admin@test.com (role: hospital_admin)
70 | moh@test.com (role: moh)
71 | ```
```

Actual seed/demo credentials in `dengartrack-backend/seed.py`:

| Role | Staff ID | PIN | Hospital |
|---|---|---:|---|
| Screener | `SCR001HKL` | `1234` | HKL001 |
| Screener | `SCR002HKL` | `1234` | HKL001 |
| Screener | `SCR003HKL` | `1234` | HKL001 |
| Coordinator | `COO001HKL` | `1234` | HKL001 |
| Coordinator | `COO002HKL` | `1234` | HKL001 |
| Screener | `SCR001HPJ` | `1234` | HPJ001 |
| Screener | `SCR002HPJ` | `1234` | HPJ001 |
| Screener | `SCR003HPJ` | `1234` | HPJ001 |
| Coordinator | `COO001HPJ` | `1234` | HPJ001 |
| Coordinator | `COO002HPJ` | `1234` | HPJ001 |
| Screener | `SCR001HSB` | `1234` | HSB001 |
| Screener | `SCR002HSB` | `1234` | HSB001 |
| Screener | `SCR003HSB` | `1234` | HSB001 |
| Coordinator | `COO001HSB` | `1234` | HSB001 |
| Coordinator | `COO002HSB` | `1234` | HSB001 |
| UNHS Coordinator | `ADM001` | `1234` | none |
| MOH | `MOH001` | `1234` | none |

Important: current auth expects `staff_id` and `pin`, not email/password.

---

## AI Development Rules

1. **Never say "probably"** — if uncertain, ask for exact code or use `grep` to find it
2. **Never mix Malay and English** — BM mode = 100% natural Malay, EN mode = 100% English
3. **Always use exact line numbers** — no "around line X", find the exact line
4. **Always provide copy-pasteable code** — no "add something like this"
5. **Always verify with `flutter analyze`** before declaring success
6. **Never modify backend without explicit permission** — Flutter-only unless asked
7. **Shorebird patches = Dart code only** — native plugins require APK rebuild
8. **Always use `--no-tree-shake-icons`** for Shorebird releases
9. **Test on device** — emulator is not enough for Shorebird/OTA testing

---

## Verification Checklist

| # | Check | Status |
|---|---|---|
| 1 | `HANDOVER.md` created in `Project_documents/` | ☑ |
| 2 | Backend architecture fully documented | ☑ |
| 3 | Flutter screens fully documented (all methods) | ☑ |
| 4 | Recent fixes documented with exact file paths | ☑ |
| 5 | Shorebird/build config documented | ☑ |
| 6 | Pending features listed | ☑ |
| 7 | Mak Uda requirements captured | ☑ |
| 8 | Test credentials included | ☑ |
| 9 | AI development rules section added | ☑ |
| 10 | File is >2000 words (comprehensive) | ☑ |

---

## Files Read for This Handover

- `misc/CLAUDE_CONTEXT_CURRENT.md`
- `misc/DengarTrack_README_MAIN.txt`
- `dengartrack-backend/main.py`
- `dengartrack-backend/db/schema.sql`
- `dengartrack-backend/routers/followups.py`
- `dengartrack-backend/auth/models.py`
- `dengartrack-backend/db/migrations/002_fix_followup_status_constraint.sql`
- `dengartrack-backend/seed.py`
- `dengartrack-backend/auth/auth.py`
- `dengartrack-backend/routers/auth_router.py`
- `mobile_flutter_app/hearlinx/pubspec.yaml`
- `mobile_flutter_app/hearlinx/pubspec.lock`
- `mobile_flutter_app/hearlinx/lib/main.dart`
- `mobile_flutter_app/hearlinx/lib/config/api_config.dart`
- `mobile_flutter_app/hearlinx/lib/l10n/app_text.dart`
- `mobile_flutter_app/hearlinx/lib/ui/app_styles.dart`
- `mobile_flutter_app/hearlinx/lib/providers/language_provider.dart`
- `mobile_flutter_app/hearlinx/lib/services/auth_service.dart`
- `mobile_flutter_app/hearlinx/lib/services/offline_service.dart`
- `mobile_flutter_app/hearlinx/lib/screens/login_screen.dart`
- `mobile_flutter_app/hearlinx/lib/screens/coordinator_dashboard_screen.dart`
- `mobile_flutter_app/hearlinx/lib/screens/followup_list_screen.dart`
- `mobile_flutter_app/hearlinx/lib/screens/home_screen.dart`
- `mobile_flutter_app/hearlinx/lib/widgets/app_shell.dart`
- `mobile_flutter_app/hearlinx/shorebird.yaml`