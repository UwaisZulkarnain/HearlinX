# DengarTrack: Complete Workspace Context

## Project Overview
**DengarTrack** is a digital replacement for Universal Newborn Hearing Screening (UNHS) workflows. Screeners enter results at cot side → auto-flows to coordinator dashboard, follow-up queue, and MOH reports. Replaces paper cards, Excel, WhatsApp groups.

## Tech Stack
- **Backend:** FastAPI (Python) on 0.0.0.0:8000
- **Mobile:** Flutter (Android primary, iOS secondary)
- **Web:** React.js (NOT STARTED - empty folder)
- **Database:** PostgreSQL
- **Auth:** JWT + RBAC (4 roles)
- **Encryption:** TLS 1.3 + AES-256

## Design Principles
Speed first (<60sec per action) | Offline-capable | Bilingual (Malay/English) | PDPA 2010 compliant | Android 9+ | One entry, many uses

## Current Implementation Status

### Backend ✅ DONE
- FastAPI running at 0.0.0.0:8000
- 6 routers implemented:
  - `auth_router.py` - Login, user info, role-based dashboards
  - `screenings.py` - Screening entry & result management
  - `babies.py` - Baby records CRUD
  - `followups.py` - Follow-up workflow
  - `reports.py` - MOH/hospital/audit reports
  - `audit_logs.py` - Audit trail queries
- JWT + RBAC with 4 roles fully implemented
- CORS enabled for all origins
- Database schema prepared (schema.sql + indexes.sql)

### Flutter Mobile ✅ READY
- Lib structure: config/, models/, providers/, screens/, services/, ui/, widgets/
- Dependencies: http, flutter_secure_storage, sqflite, path_provider
- SDK: ^3.11.5
- Android & iOS build files present

### Web React 🚧 NOT STARTED
- Empty folder
- No dependencies or structure

### Database ✅ READY
- PostgreSQL schema prepared
- Users table: id, email, password_hash, role, hospital_id, full_name, is_active
- Tables for: babies, screenings, followups, audit_logs

## Authentication & Authorization

### JWT Flow
1. POST /auth/login (email + password)
2. Server validates → creates JWT token
3. Client stores token (secure storage in Flutter, localStorage in React)
4. Protected requests: `Authorization: Bearer <token>` header
5. Server validates via `get_current_user()` dependency
6. Role check via `require_role(*roles)` dependency

### 4 Roles & Access
| Role | Access |
|------|--------|
| **Screener** | Own screening results only |
| **Coordinator** | Full hospital access (dashboard, follow-ups, reports) |
| **Hospital Admin** | Hospital-level metrics & audit logs |
| **MoH/KKM** | National aggregate dashboard |

### Test Credentials (password: `password123`)
```
screener@test.com (role: screener)
coordinator@test.com (role: coordinator)
admin@test.com (role: hospital_admin)
moh@test.com (role: moh)
```

## Key Backend Files
```
dengartrack-backend/
├── main.py                 - FastAPI app (CORS + 6 routers)
├── auth/
│   ├── auth.py            - JWT generation/validation
│   ├── dependencies.py     - Role-based dependency injection
│   ├── models.py          - Pydantic schemas
├── routers/               - 6 endpoint modules
├── db/
│   ├── schema.sql         - Database schema
│   ├── indexes.sql        - Indexes
│   ├── database.py        - DB connection
├── seed.py                - Test data seeding
├── requirements.txt       - Python deps
├── dtbackend.env          - Environment variables
└── dtbackendcfg.json      - Config file
```

## Key Flutter Files
```
mobile_flutter_app/hearlinx/
├── lib/
│   ├── main.dart          - Entry point
│   ├── config/            - App configuration
│   ├── models/            - Data models
│   ├── providers/         - State management
│   ├── screens/           - UI screens
│   ├── services/          - HTTP API client (calls backend)
│   ├── ui/                - Reusable UI components
│   └── widgets/           - Custom widgets
├── android/               - Native Android build
├── ios/                   - Native iOS build
├── pubspec.yaml           - Dependencies
└── pubspec.lock           - Locked versions
```

## API Endpoints (Main)

### Authentication
- `POST /auth/login` - Get JWT token
- `GET /auth/me` - Current user info
- `GET /auth/{role}/dashboard` - Role-specific dashboard

### Screenings
- CRUD operations for screening entries
- Role-based access control

### Babies
- Baby record management
- Links to screening results

### Follow-ups
- Follow-up workflow
- Status tracking

### Reports
- MOH report generation
- Hospital metrics
- Audit reports

### Audit Logs
- Track all user actions
- Compliance logging

## Running Services

### Backend
```
Terminal: uvicorn
Command: uvicorn main:app --host 0.0.0.0 --port 8000 --reload
Status: Running
CWD: C:\Users\uwais\Desktop\DengarTrackiCaRehab\dengartrack-backend
API Docs: http://localhost:8000/docs
```

### Python Environment
- Virtual environment: C:\Users\uwais\Desktop\DengarTrackiCaRehab\venv
- Activated via: PowerShell script

### Flutter
- Ready to run: `flutter run` from hearlinx folder
- Target: Android (primary)

## Database Setup
1. Create PostgreSQL database
2. Run schema.sql + indexes.sql
3. Run seed.py for test data
4. Credentials stored in dtbackend.env

## Key Dependencies

### Python (Backend)
- fastapi, uvicorn
- python-dotenv (env vars)
- python-jose (JWT)
- SQLAlchemy (ORM)
- pydantic (validation)
- PostgreSQL driver (psycopg2)

### Flutter
- http: Network calls to backend API
- flutter_secure_storage: Secure JWT token storage
- sqflite: Local SQLite database for offline data
- path_provider: File system access
- flutter_localizations: Bilingual support (Malay/English)

## Development Workflow

### Backend Development
1. Update code in dengartrack-backend/
2. Uvicorn auto-reloads on save
3. Check API docs: http://localhost:8000/docs
4. Test with seed.py credentials

### Flutter Development
1. Code in mobile_flutter_app/hearlinx/lib/
2. Run: `flutter run` (Android) or `flutter run -d ios` (iOS)
3. HTTP service calls backend API
4. Offline data syncs when connectivity returns

### Web Development
1. Setup React.js in web_react/ (NOT STARTED)
2. Copy API integration patterns from Flutter services/
3. Use same JWT auth flow

## Important Notes
- All user actions are audit-logged
- Encryption mandatory: TLS 1.3 + AES-256
- PDPA 2010 compliance required
- Data residency: Malaysia region
- Backend CORS: Allow all origins (*)
- Offline-first design: Mobile has local SQLite sync

## Project Documents
- ARCHITECTURE.md - System design
- AUTH_SETUP.md - Authentication details
- IMPLEMENTATION_SUMMARY.md - Progress summary
- QUICK_REFERENCE.md - Quick lookup
- SCREENING_API.md - Screening API details
- TEST_AUTH.md - Auth testing guide
