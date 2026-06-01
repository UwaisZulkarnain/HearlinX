# DengarTrack Project - Complete Directory Structure & GitHub Upload Guide

## PROJECT OVERVIEW
**DengarTrack** - A Digital Newborn Hearing Screening Management Platform
- Replaces paper-based UNHS workflow in Malaysian hospitals
- Bilingual (Malay/English), offline-capable mobile + web platform
- Technology: Flutter Mobile + FastAPI Backend + Next.js Web Dashboard
- PDPA 2010 compliant, JWT auth with role-based access control

---

## ROOT DIRECTORY: `/DengarTrackiCaRehab/`

### Project Structure Summary
```
DengarTrackiCaRehab/
├── dengartrack-backend/        ← BACKEND (FastAPI Python)
├── mobile_flutter_app/         ← MOBILE APP (Flutter)
├── web_react/                  ← WEB DASHBOARD (Next.js React)
├── Project_documents/          ← DOCUMENTATION & DESIGN ASSETS
├── misc/                       ← MISCELLANEOUS NOTES
├── Testings/                   ← TEST FILES
└── venv/                       ← Python virtual environment (SKIP)
```

---

## 1. BACKEND: `dengartrack-backend/`
**Technology:** FastAPI (Python 3.11+), PostgreSQL

### Key Files & Folders
```
dengartrack-backend/
├── main.py                     ← FastAPI entry point, app initialization
├── requirements.txt            ← Python dependencies
├── dtbackend.env              ← Environment variables (SKIP FOR GITHUB)
├── dtbackendcfg.json          ← Config file (REVIEW BEFORE UPLOAD)
│
├── auth/                       ← AUTHENTICATION & AUTHORIZATION
│   ├── auth.py               ← JWT token generation/validation
│   ├── dependencies.py       ← Role-based access control (RBAC)
│   ├── models.py             ← Pydantic auth models
│
├── db/                         ← DATABASE LAYER
│   ├── database.py           ← SQLAlchemy connection & session mgmt
│   ├── schema.sql            ← PostgreSQL schema (hospitals, babies, screenings, etc)
│   ├── indexes.sql           ← Database indexes for performance
│   ├── migrate_unhs_role.py  ← DB migration script
│
├── routers/                    ← API ENDPOINTS
│   ├── auth_router.py        ← Login, logout, token refresh
│   ├── babies.py             ← Baby registration (QR scan support)
│   ├── screenings.py         ← Hearing test results entry
│   ├── followups.py          ← Follow-up case tracking
│   ├── users.py              ← Staff account management
│   ├── hospitals.py          ← Hospital data
│   ├── reports.py            ← Monthly & national reporting
│   ├── audit_logs.py         ← Compliance audit trail
│
├── backend read me/            ← DOCUMENTATION
│   ├── ARCHITECTURE.md        ← System architecture overview
│   ├── AUTH_SETUP.md          ← Authentication flow & JWT
│   ├── SCREENING_API.md       ← Screening API endpoints
│   ├── IMPLEMENTATION_SUMMARY.md
│   └── TEST_AUTH.md           ← Auth testing guide
│
├── UTILITY SCRIPTS
│   ├── seed.py               ← Database seed data (hospitals, test users)
│   ├── generate_qr.py        ← QR code generation for wristbands
│   ├── clear_test_data.py    ← Clear test records
│   ├── make_password_nullable.py  ← Migration script
│
└── TEST FILES
    ├── testdtdatabase.py     ← Database connection tests
    ├── test_screening_api.py ← API endpoint tests
```

### What to Upload to GitHub:
✅ All of `auth/`, `db/`, `routers/` folders
✅ `main.py`, `requirements.txt`
✅ `backend read me/` folder with all documentation
✅ `seed.py`, `generate_qr.py` (utility scripts)
✅ Create `.env.example` from `dtbackend.env`
❌ Skip: `dtbackend.env` (contains secrets), `venv/` folder, `__pycache__/`

---

## 2. MOBILE APP: `mobile_flutter_app/hearlinx/`
**Technology:** Flutter 3.11+, Dart

### Key Files & Folders
```
mobile_flutter_app/hearlinx/
├── pubspec.yaml              ← Dependencies, app metadata
├── main.dart                 ← App entry point
│
├── lib/
│   ├── config/
│   │   ├── api_config.dart  ← API base URL, endpoints
│   │   └── [config files]
│   │
│   ├── screens/              ← UI PAGES
│   │   ├── login_screen.dart
│   │   ├── home_screen.dart
│   │   ├── screening_entry_screen.dart    ← QR scan + test entry
│   │   ├── shift_summary_screen.dart      ← Screener shift report
│   │   ├── coordinator_dashboard_screen.dart  ← Coordinator overview
│   │   ├── moh_dashboard_screen.dart      ← National MOH reporting
│   │   └── unhs_dashboard_screen.dart
│   │
│   ├── widgets/              ← REUSABLE UI COMPONENTS
│   │   ├── app_shell.dart   ← Navigation shell
│   │   └── [other widgets]
│   │
│   ├── services/             ← API & BUSINESS LOGIC
│   │   ├── api_service.dart  ← HTTP client wrapper
│   │   ├── auth_service.dart ← JWT token management
│   │   └── [other services]
│   │
│   ├── providers/            ← STATE MANAGEMENT
│   │   └── language_provider.dart  ← Localization (MS/EN)
│   │
│   ├── l10n/                 ← TRANSLATIONS
│   │   └── app_text.dart    ← Bilingual strings (Malay/English)
│   │
│   ├── models/               ← DATA MODELS
│   │   ├── user.dart
│   │   └── [other models]
│   │
│   └── ui/
│       ├── app_styles.dart  ← Theme, colors, text styles
│       └── [UI utilities]
│
├── android/                  ← Android build config
├── ios/                      ← iOS build config
└── test/                     ← Unit tests
```

### What to Upload to GitHub:
✅ All of `lib/` folder (source code)
✅ `pubspec.yaml`
✅ Create `.env.example` for API endpoints
✅ `android/` basic config (without signing keys)
❌ Skip: `build/`, `.dart_tool/`, sensitive keys
❌ Skip: iOS provisioning profiles

---

## 3. WEB DASHBOARD: `web_react/`
**Technology:** Next.js 16, React 19, TypeScript, Tailwind CSS

### Key Files & Folders
```
web_react/
├── package.json              ← Node dependencies
├── tsconfig.json             ← TypeScript config
├── next.config.ts            ← Next.js config
├── eslint.config.mjs         ← Code linting rules
│
├── src/
│   ├── app/                  ← NEXT.JS APP ROUTER
│   │   ├── layout.tsx        ← Root layout
│   │   └── [pages]
│   │
│   ├── components/           ← REUSABLE COMPONENTS
│   │   ├── [React components]
│   │   └── [UI modules]
│   │
│   ├── context/              ← CONTEXT PROVIDERS
│   │   └── [State management]
│   │
│   ├── hooks/                ← CUSTOM HOOKS
│   │   └── [useAuth, useFetch, etc]
│   │
│   ├── i18n/                 ← INTERNATIONALIZATION
│   │   └── [Translation files]
│   │
│   ├── lib/                  ← UTILITIES
│   │   ├── api.ts           ← Axios API client
│   │   └── [Helper functions]
│   │
│   ├── types/                ← TYPESCRIPT TYPES
│   │   └── [.ts interface files]
│   │
│   └── [pages & features]
│
├── public/                   ← STATIC ASSETS
│   ├── [images, logos]
│
└── testing/                  ← TEST FILES
    └── [test suites]
```

### What to Upload to GitHub:
✅ All of `src/` folder (source code)
✅ `package.json`, `package-lock.json`
✅ `tsconfig.json`, `next.config.ts`, `eslint.config.mjs`
✅ `public/` folder
✅ Create `.env.local.example`
❌ Skip: `.next/`, `node_modules/`, `.env.local`

---

## 4. DOCUMENTATION: `Project_documents/`
```
Project_documents/
├── Concept\ brief.pdf        ← Project concept & requirements
├── DengarTrack_ICT_Proposal.pdf
├── Project\ Roadmap.pdf      ← Development phases & timeline
├── future\ improvements.txt  ← Planned enhancements
├── Dengartrack\ logo.jpeg    ← Branding assets
│
├── Other_docs_and_notes/
│   ├── fastAPIdocs.txt      ← FastAPI API documentation
│   └── Xplainations/        ← Technical explanations
│
└── Photos/
    ├── figma/               ← UI/UX design mockups
    └── Progress\ Screenshots/  ← Development screenshots
```

### What to Upload to GitHub:
✅ Keep documentation PDFs & notes
✅ Keep UI design screenshots
✅ Keep roadmap & requirements
❌ Skip: Large design files or internal notes

---

## 5. MISCELLANEOUS: `misc/`
```
misc/
├── DengarTrack_README_MAIN.txt     ← Project overview (text version)
├── CLAUDE_CONTEXT_CURRENT.md       ← Development context (OPTIONAL)
├── dengratrack_dev.session.sql     ← SQL dev notes (OPTIONAL)
```

### What to Upload:
⚠️ Skip internal context files, only keep main README

---

## 6. TESTING: `Testings/`
```
Testings/
├── [test documentation]
├── [test cases]
└── [QA checklists]
```

### What to Upload:
⚠️ Include testing documentation if relevant

---

## 7. FILES TO SKIP (DO NOT UPLOAD)
```
❌ venv/                        ← Python virtual environment
❌ .venv/                       ← Alternative Python venv
❌ node_modules/                ← NPM dependencies
❌ __pycache__/                 ← Python compiled files
❌ .dart_tool/                  ← Dart build artifacts
❌ build/                       ← Build output
❌ .next/                       ← Next.js build output
❌ *.env                        ← All environment files (create .example)
❌ dtbackend.env               ← Contains secrets
❌ Android signing keys
❌ iOS provisioning profiles
❌ Local IDE settings          ← .vscode/, .idea/
```

---

## GITHUB REPOSITORY STRUCTURE (RECOMMENDED)
```
DengarTrack/
├── README.md                 ← Main project overview
├── .gitignore               ← Ignore venv, node_modules, .env
│
├── backend/                 ← FastAPI
│   ├── requirements.txt
│   ├── main.py
│   ├── auth/
│   ├── db/
│   ├── routers/
│   ├── backend_readme.md    ← Backend setup instructions
│   └── .env.example
│
├── mobile/                  ← Flutter App
│   ├── pubspec.yaml
│   ├── lib/
│   ├── android/
│   ├── ios/
│   ├── MOBILE_README.md     ← Flutter setup instructions
│   └── .env.example
│
├── web/                     ← Next.js Dashboard
│   ├── package.json
│   ├── src/
│   ├── public/
│   ├── WEB_README.md        ← Web setup instructions
│   └── .env.example
│
├── docs/                    ← Documentation
│   ├── ARCHITECTURE.md      ← System design
│   ├── API_DOCS.md         ← Backend API reference
│   ├── AUTH_FLOW.md        ← Authentication flow
│   ├── DEPLOYMENT.md       ← Deployment guide
│   └── ROADMAP.md          ← Project roadmap
│
└── design/                  ← UI/UX assets
    ├── figma_exports/
    ├── mockups/
    └── logo/
```

---

## FILES TO CREATE BEFORE UPLOAD

### 1. Main README.md (Root)
```markdown
# DengarTrack - Digital Newborn Hearing Screening Platform

## Overview
[Brief description + tech stack + features]

## Quick Start
- Backend: See `backend/BACKEND_README.md`
- Mobile: See `mobile/MOBILE_README.md`
- Web: See `web/WEB_README.md`

## Installation
[Prerequisites: Python 3.11+, Node 18+, Flutter 3.11+]

## Documentation
- [Architecture](docs/ARCHITECTURE.md)
- [API Reference](docs/API_DOCS.md)
- [Deployment](docs/DEPLOYMENT.md)
```

### 2. `.gitignore`
```
# Python
venv/
.venv/
__pycache__/
*.pyc
.env

# Node
node_modules/
.next/
.npm

# Flutter
.dart_tool/
build/

# Secrets
*.env
!.env.example

# IDE
.vscode/
.idea/
```

### 3. `.env.example` (for each component)
```
# Backend .env.example
DATABASE_URL=postgresql://user:password@localhost/dengartrack
JWT_SECRET=your_jwt_secret_here
API_PORT=8000

# Mobile & Web .env.example
REACT_APP_API_URL=http://localhost:8000
```

### 4. CONTRIBUTING.md
```markdown
# Contributing to DengarTrack

## Branch Naming
- `feature/description`
- `bugfix/description`
- `docs/description`

## Commit Messages
Follow conventional commits: `type(scope): description`

## Pull Request Process
1. Fork repo
2. Create feature branch
3. Commit changes
4. Create PR with description
```

---

## RECOMMENDED INITIAL COMMITS

1. **Initial Setup**
   - Upload backend, mobile, web source code
   - Add all README files
   - Add .gitignore, LICENSE

2. **Documentation**
   - Upload architecture docs
   - Upload API documentation
   - Upload deployment guide

3. **Configuration Examples**
   - Add .env.example files
   - Add sample configuration files

---

## UPLOAD CHECKLIST

- [ ] Remove all `.env` files (replace with `.example`)
- [ ] Remove `venv/`, `node_modules/`, `build/`, `.dart_tool/`
- [ ] Remove `__pycache__/`, `.next/`
- [ ] Create `.gitignore`
- [ ] Create main `README.md`
- [ ] Create backend setup guide
- [ ] Create mobile setup guide
- [ ] Create web setup guide
- [ ] Create architecture documentation
- [ ] Add LICENSE file
- [ ] Verify no secrets in config files
- [ ] Test `.gitignore` works correctly
- [ ] Create CONTRIBUTING.md

---

## SIZE REFERENCE
- Backend: ~200 KB (without venv)
- Mobile: ~500 KB (without build files)
- Web: ~300 KB (without node_modules)
- **Total: ~1-2 MB** (GitHub is fine with this)

---

## NEXT STEPS FOR GITHUB

1. Create GitHub repo: `DengarTrack` or `dengartrack`
2. Clone to new location
3. Copy only approved files using checklist above
4. Follow recommended folder structure
5. Initial commit with setup files
6. Add all team members as collaborators
7. Set branch protection rules for main branch
8. Add GitHub Issues for features/bugs

