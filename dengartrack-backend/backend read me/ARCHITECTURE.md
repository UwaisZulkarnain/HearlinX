# JWT Authentication Architecture Diagram

## Authentication Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│  CLIENT (Browser/Mobile/API Client)                                       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     │
                    ┌────────────────▼───────────────┐
                    │   1. POST /auth/login          │
                    │   {                             │
                    │     email: "user@test.com",    │
                    │     password: "password123"    │
                    │   }                             │
                    └────────────────┬────────────────┘
                                     │
                    ┌────────────────▼───────────────┐
                    │  auth_router.py                │
                    │  login() endpoint              │
                    └────────────────┬────────────────┘
                                     │
            ┌────────────────────────┼────────────────────────┐
            │                        │                        │
    ┌───────▼────────┐      ┌───────▼────────┐     ┌────────▼────────┐
    │ Get user from  │      │ Verify password│     │ Create JWT      │
    │ database       │      │ with bcrypt    │     │ token           │
    │ (is_active?)   │      │ (constant time)│     │ (sign with      │
    └────────────────┘      └────────────────┘     │  SECRET_KEY)    │
                                                     └────────┬────────┘
                                                              │
                    ┌─────────────────────────────────────────▼──┐
                    │  2. Return Token Response                  │
                    │  {                                        │
                    │    "access_token": "eyJhbGc...",          │
                    │    "token_type": "bearer"                 │
                    │  }                                        │
                    └─────────────────────────────────────────┬──┘
                                                              │
                    ┌─────────────────────────────────────────▼──┐
                    │  CLIENT STORES TOKEN                       │
                    │  (in localStorage/memory)                  │
                    └──────────────────────────────────────────┬─┘
                                                              │
                                     ┌────────────────────────▼────────────────┐
                                     │  3. Access Protected Route              │
                                     │  GET /auth/screener/dashboard           │
                                     │  Header: Authorization: Bearer <token>  │
                                     └────────────────────────┬─────────────────┘
                                                              │
                    ┌─────────────────────────────────────────▼──────┐
                    │  auth_router.py                                │
                    │  screener_dashboard() endpoint                │
                    │  Dependency: screener_only                    │
                    └────────────────┬─────────────────────────────┬┘
                                     │                             │
                    ┌────────────────▼──────────┐    ┌────────────▼─────────┐
                    │ dependencies.py            │    │ Verify role matches │
                    │ get_current_user()         │    │ required role       │
                    │ 1. Extract token          │    │ (screener_only)     │
                    │ 2. Decode JWT             │    └────────────────────┘
                    │ 3. Validate signature     │
                    │ 4. Check expiration       │
                    │ 5. Return user info       │
                    └────────────────┬──────────┘
                                     │
            ┌────────────────────────┼────────────────────────┐
            │                        │                        │
        ✅ VALID                 ❌ INVALID              ❌ EXPIRED
        ✅ CORRECT ROLE          ✅ VALID TOKEN          ✅ WRONG ROLE
            │                        │                        │
    ┌───────▼────────┐      ┌───────▼────────┐     ┌────────▼────────┐
    │ 4. Execute     │      │ 401            │     │ 403             │
    │ endpoint logic │      │ Unauthorized   │     │ Access Denied   │
    │ Return data    │      │ "Invalid token"│     │ "Access denied" │
    └────────────────┘      └────────────────┘     └─────────────────┘
            │                                               │
            └──────────────────────┬──────────────────────┘
                                   │
                    ┌──────────────▼──────────────┐
                    │ RESPONSE TO CLIENT          │
                    │ 200 OK / 401 / 403          │
                    │ + response body             │
                    └─────────────────────────────┘
```

## Component Interaction Diagram

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                              DENGARTRACK BACKEND                            │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                         main.py                                      │  │
│  │                  FastAPI Application Entry Point                    │  │
│  └──────────────────┬───────────────────────────────────────────────────┘  │
│                     │                                                       │
│        ┌────────────┴────────────────────────────────────────┐             │
│        │                                                    │              │
│        │                                                    │              │
│  ┌─────▼───────────────────┐               ┌──────────────▼───────────┐  │
│  │   routers/              │               │  db/                      │  │
│  │   auth_router.py        │               │  ├─ database.py          │  │
│  │                         │               │  ├─ schema.sql           │  │
│  │  ├─ POST /login         │               │  └─ indexes.sql          │  │
│  │  ├─ GET /me             │               │                           │  │
│  │  ├─ GET /screener/...   │───┬──────────│─ SessionLocal            │  │
│  │  ├─ GET /coordinator/...│   │          │─ engine                  │  │
│  │  ├─ GET /admin/...      │   │          │─ get_db()                │  │
│  │  ├─ GET /moh/...        │   │          │                           │  │
│  │  └─ GET /management/... │   │          └─────┬─────────────────────┘  │
│  │                         │   │                │                         │
│  └─────┬───────────────────┘   │                │                         │
│        │                        │                │                         │
│  ┌─────▼──────────────────────────────────┐     │                         │
│  │   auth/                                │     │                         │
│  │                                        │     │                         │
│  │  ├─ auth.py                           │     │                         │
│  │  │  ├─ hash_password()         ◄──────┼─────┼─────┐                   │
│  │  │  ├─ verify_password()       ◄──────┼─────┼─────┤                   │
│  │  │  ├─ create_access_token()   ◄──────┼─────┼─────┤                   │
│  │  │  └─ decode_token()          ◄──────┼─────┼─────┤                   │
│  │  │                             │       │     │     │                   │
│  │  ├─ dependencies.py            │       │     │     │                   │
│  │  │  ├─ get_current_user()      ◄──────┼─────┼─────┤                   │
│  │  │  ├─ require_role()          ◄──────┼─────┼─────┤                   │
│  │  │  ├─ screener_only          ◄──────┼─────┼─────┤                   │
│  │  │  ├─ coordinator_only       ◄──────┼─────┼─────┤                   │
│  │  │  ├─ hospital_admin_only    ◄──────┼─────┼─────┤                   │
│  │  │  ├─ moh_only               ◄──────┼─────┼─────┤                   │
│  │  │  └─ coordinator_or_admin   ◄──────┼─────┼─────┤                   │
│  │  │                             │       │     │     │                   │
│  │  └─ models.py                  │       │     │     │                   │
│  │     ├─ Token                   ◄──────┼─────┼─────┤                   │
│  │     ├─ TokenData               ◄──────┼─────┼─────┤                   │
│  │     ├─ UserLogin               ◄──────┼─────┼─────┤                   │
│  │     └─ UserOut                 ◄──────┼─────┼─────┤                   │
│  │                                         │     │     │                   │
│  └─────┬──────────────────────────────────┘     │     │                   │
│        │                                         │     │                   │
└────────┼─────────────────────────────────────────┼─────┼───────────────────┘
         │                                         │     │
    ┌────▼─────────────────────────────────┐      │     │
    │  PostgreSQL Database                  │      │     │
    │                                       │      │     │
    │  ├─ users table                       │◄─────┘     │
    │  │  ├─ id (UUID)                      │            │
    │  │  ├─ email                          │            │
    │  │  ├─ password_hash                  │            │
    │  │  ├─ role                           │            │
    │  │  ├─ hospital_id                    │            │
    │  │  ├─ full_name                      │            │
    │  │  └─ is_active                      │            │
    │  │                                    │            │
    │  └─ hospitals table                   │◄───────────┘
    │     ├─ id (UUID)                      │
    │     ├─ name                           │
    │     ├─ code                           │
    │     └─ state                          │
    │                                       │
    └───────────────────────────────────────┘
```

## Request/Response Flow for Different Scenarios

### Scenario 1: Successful Login
```
REQUEST:
┌─────────────────────────────────────────┐
│ POST /auth/login                        │
│ Content-Type: application/json          │
│                                         │
│ {                                       │
│   "email": "screener@test.com",         │
│   "password": "password123"             │
│ }                                       │
└─────────────────────────────────────────┘
                   │
                   ▼
           [Verify user exists]
           [Verify is_active = true]
           [Hash and verify password]
           [Create JWT token]
                   │
                   ▼
RESPONSE (200 OK):
┌─────────────────────────────────────────┐
│ {                                       │
│   "access_token":                       │
│   "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9│
│   .eyJ1c2VyX2lkIjoiNTUwZTg0MDAtZTI5Yy..│
│   .9yM...",                             │
│   "token_type": "bearer"                │
│ }                                       │
└─────────────────────────────────────────┘
```

### Scenario 2: Access Protected Route (Success)
```
REQUEST:
┌─────────────────────────────────────────┐
│ GET /auth/screener/dashboard            │
│ Authorization: Bearer eyJhbGc...        │
└─────────────────────────────────────────┘
                   │
                   ▼
         [Extract token from header]
         [Decode JWT]
         [Validate signature]
         [Check expiration]
         [Check role == "screener"]
                   │
                   ▼
RESPONSE (200 OK):
┌─────────────────────────────────────────┐
│ {                                       │
│   "message": "Welcome Screener",        │
│   "user_id": "550e8400-e29b...",        │
│   "role": "screener"                    │
│ }                                       │
└─────────────────────────────────────────┘
```

### Scenario 3: Access Protected Route (Wrong Role)
```
REQUEST:
┌─────────────────────────────────────────┐
│ GET /auth/coordinator/dashboard         │
│ Authorization: Bearer <screener-token>  │
└─────────────────────────────────────────┘
                   │
                   ▼
         [Extract token from header]
         [Decode JWT]
         [Validate signature]
         [Check expiration]
         [Check role == "coordinator"]
                   │
              ❌ FAILS
                   │
                   ▼
RESPONSE (403 Forbidden):
┌─────────────────────────────────────────┐
│ {                                       │
│   "detail": "Access denied"             │
│ }                                       │
└─────────────────────────────────────────┘
```

### Scenario 4: Invalid/Expired Token
```
REQUEST:
┌─────────────────────────────────────────┐
│ GET /auth/me                            │
│ Authorization: Bearer invalid_token     │
└─────────────────────────────────────────┘
                   │
                   ▼
         [Extract token from header]
         [Try to decode JWT]
                   │
              ❌ Signature invalid or expired
                   │
                   ▼
RESPONSE (401 Unauthorized):
┌─────────────────────────────────────────┐
│ {                                       │
│   "detail": "Invalid token"             │
│ }                                       │
└─────────────────────────────────────────┘
```

## JWT Token Payload Structure

```
Header:
┌────────────────────────────────────┐
│ {                                  │
│   "alg": "HS256",                  │
│   "typ": "JWT"                     │
│ }                                  │
└────────────────────────────────────┘

Payload:
┌────────────────────────────────────┐
│ {                                  │
│   "user_id": "550e8400-e29b...",   │
│   "role": "screener",              │
│   "hospital_id": "550e8400-e29c...",│
│   "exp": 1713825600                │
│ }                                  │
└────────────────────────────────────┘

Signature:
┌────────────────────────────────────┐
│ HMACSHA256(                        │
│   header + payload,                │
│   "dengartrack001"                 │
│ )                                  │
└────────────────────────────────────┘
```

## Role Hierarchy & Permissions

```
┌─────────────────────────────────────────────────┐
│           ROLE-BASED ACCESS MATRIX              │
├─────────────────────────────────────────────────┤
│ Role             │ Endpoint Category            │
├──────────────────┼──────────────────────────────┤
│ screener         │ ✓ /auth/screener/dashboard   │
│                  │ ✗ Other role dashboards      │
│                  │ ✓ /auth/me                   │
├──────────────────┼──────────────────────────────┤
│ coordinator      │ ✓ /auth/coordinator/...      │
│                  │ ✓ /auth/management/reports   │
│                  │ ✗ /auth/screener/...         │
│                  │ ✓ /auth/me                   │
├──────────────────┼──────────────────────────────┤
│ hospital_admin   │ ✓ /auth/admin/dashboard      │
│                  │ ✓ /auth/management/reports   │
│                  │ ✗ /auth/screener/...         │
│                  │ ✓ /auth/me                   │
├──────────────────┼──────────────────────────────┤
│ moh              │ ✓ /auth/moh/dashboard        │
│                  │ ✗ Other role dashboards      │
│                  │ ✓ /auth/me                   │
└──────────────────┴──────────────────────────────┘
```

## Data Flow Summary

```
1. USER INITIATES LOGIN
   └─→ POST /auth/login (email, password)

2. BACKEND VERIFIES
   ├─→ Check user exists in database
   ├─→ Check user is_active = true
   ├─→ Verify password (bcrypt)
   └─→ Return 401 if any check fails

3. TOKEN GENERATION
   ├─→ Create JWT payload with user_id, role, hospital_id
   ├─→ Add expiration time (now + 480 minutes)
   ├─→ Sign with SECRET_KEY using HS256
   └─→ Return access_token + token_type

4. CLIENT STORES TOKEN
   └─→ Store in localStorage, memory, or cookies

5. CLIENT ACCESSES PROTECTED ROUTE
   └─→ Include token in Authorization header

6. BACKEND VALIDATES TOKEN
   ├─→ Extract token from header
   ├─→ Decode JWT and verify signature
   ├─→ Check expiration time
   ├─→ Return 401 if validation fails

7. BACKEND CHECKS ROLE
   ├─→ Extract role from token payload
   ├─→ Compare with required role(s)
   ├─→ Return 403 if role doesn't match

8. ENDPOINT EXECUTES
   └─→ User has access, execute endpoint logic

9. RESPONSE RETURNED
   └─→ Return endpoint response or error
```
