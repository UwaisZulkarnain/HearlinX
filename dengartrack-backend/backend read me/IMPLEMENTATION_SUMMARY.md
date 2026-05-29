# JWT Authentication with RBAC - Implementation Summary

## What Was Implemented

### Core Authentication System
✅ **Password Hashing** - bcrypt via passlib
✅ **JWT Token Generation** - using python-jose
✅ **Token Validation** - signature and expiration checking
✅ **Role-Based Access Control** - 4 roles with dependency injection
✅ **Protected Routes** - authentication and authorization enforcement
✅ **Login Endpoint** - POST /auth/login returns JWT token

### Roles (4 Total)
1. `screener` - Healthcare screeners
2. `coordinator` - Follow-up coordinators
3. `hospital_admin` - Hospital administration
4. `moh` - Ministry of Health oversight

## File Structure Created/Modified

```
dengartrack-backend/
├── auth/
│   ├── __init__.py (empty, already exists)
│   ├── auth.py ✅ (password hashing + JWT)
│   ├── dependencies.py ✅ (role-based dependencies)
│   └── models.py ✅ (Pydantic request/response models)
├── db/
│   ├── __init__.py ✅ (NEW - package marker)
│   ├── database.py ✅ (NEW - SQLAlchemy setup)
│   ├── schema.sql (already exists)
│   └── indexes.sql (already exists)
├── routers/
│   └── auth_router.py ✅ (login + protected endpoints)
├── main.py ✅ (FastAPI app setup)
├── seed.py ✅ (test data creation)
├── dtbackend.env (already exists with required vars)
├── requirements.txt ✅ (NEW - dependencies)
├── AUTH_SETUP.md ✅ (NEW - comprehensive guide)
└── TEST_AUTH.md ✅ (NEW - testing guide)
```

## Key Components

### 1. Authentication Module (auth/auth.py)
- `hash_password(password)` - Hash passwords with bcrypt
- `verify_password(plain, hashed)` - Verify password matches hash
- `create_access_token(data)` - Generate JWT token
- `decode_token(token)` - Validate and decode JWT

### 2. Dependencies Module (auth/dependencies.py)
- `get_current_user()` - Extract and validate token
- `require_role(*roles)` - Create role-checking dependency
- Pre-defined dependencies:
  - `screener_only`
  - `coordinator_only`
  - `hospital_admin_only`
  - `moh_only`
  - `coordinator_or_admin`

### 3. Models (auth/models.py)
- `Token` - Access token response
- `TokenData` - Token payload structure
- `UserLogin` - Login request
- `UserOut` - User response object

### 4. Database (db/database.py)
- SQLAlchemy engine setup
- SessionLocal for database sessions
- `get_db()` - FastAPI dependency for database access

### 5. Routes (routers/auth_router.py)
- POST `/auth/login` - Login endpoint
- GET `/auth/me` - Current user info
- GET `/auth/screener/dashboard` - Example screener route
- GET `/auth/coordinator/dashboard` - Example coordinator route
- GET `/auth/admin/dashboard` - Example admin route
- GET `/auth/moh/dashboard` - Example MOH route
- GET `/auth/management/reports` - Multi-role example

### 6. Seed Script (seed.py)
Creates test data:
- 1 Hospital (Hospital KL Test)
- 4 Users (one per role)
- All users have password: `password123`
- All users are active

## Database Schema

**Users Table:**
```sql
CREATE TABLE users (
    id              UUID PRIMARY KEY,
    full_name       VARCHAR(255) NOT NULL,
    email           VARCHAR(255) UNIQUE NOT NULL,
    password_hash   TEXT NOT NULL,
    role            VARCHAR(50) NOT NULL (screener|coordinator|hospital_admin|moh),
    hospital_id     UUID REFERENCES hospitals(id),
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);
```

## Configuration

**Environment Variables (dtbackend.env):**
```
DATABASE_URL=postgresql://postgres:uwais@localhost:5432/dengartrack_dev
SECRET_KEY=dengartrack001
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=480
```

## Installation & Setup

### 1. Install Dependencies
```bash
cd dengartrack-backend
pip install -r requirements.txt
```

### 2. Create Database
```bash
psql -U postgres -d dengartrack_dev -f db/schema.sql
psql -U postgres -d dengartrack_dev -f db/indexes.sql
```

### 3. Seed Test Data
```bash
python seed.py
```

Output:
```
✓ Seed complete: 1 hospital + 4 test users created
  - screener@test.com (role: screener)
  - coordinator@test.com (role: coordinator)
  - admin@test.com (role: hospital_admin)
  - moh@test.com (role: moh)
  All with password: password123
```

### 4. Start Server
```bash
uvicorn main:app --reload
```

Server runs at: http://localhost:8000

## Quick API Test

### 1. Login
```bash
curl -X POST "http://localhost:8000/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"screener@test.com","password":"password123"}'
```

Response:
```json
{
  "access_token": "eyJhbGci...",
  "token_type": "bearer"
}
```

### 2. Access Protected Route
```bash
curl -X GET "http://localhost:8000/auth/me" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 3. Test Role Enforcement
```bash
# This works (screener accessing screener route)
curl -X GET "http://localhost:8000/auth/screener/dashboard" \
  -H "Authorization: Bearer SCREENER_TOKEN"

# This fails with 403 (screener accessing coordinator route)
curl -X GET "http://localhost:8000/auth/coordinator/dashboard" \
  -H "Authorization: Bearer SCREENER_TOKEN"
```

## Usage in Your Routes

### Simple Protected Route
```python
from fastapi import APIRouter, Depends
from auth.dependencies import get_current_user

@router.get("/screenings")
def list_screenings(current_user: dict = Depends(get_current_user)):
    # Only authenticated users can access
    return {"screener_id": current_user["user_id"]}
```

### Role-Specific Route
```python
from auth.dependencies import screener_only

@router.post("/screening/create")
def create_screening(data, current_user = Depends(screener_only)):
    # Only screeners can access
    return {"created_by": current_user["user_id"]}
```

### Multi-Role Route
```python
from auth.dependencies import require_role

@router.get("/reports")
def get_reports(current_user = Depends(require_role("hospital_admin", "moh"))):
    # Both hospital_admin and moh can access
    return {"reports": []}
```

## Documentation Files

1. **AUTH_SETUP.md** - Complete implementation guide
   - Feature overview
   - Architecture explanation
   - Detailed usage examples
   - Security considerations

2. **TEST_AUTH.md** - Testing guide
   - Setup instructions
   - Test flows for all scenarios
   - Expected results
   - Debugging tips

3. **requirements.txt** - Python dependencies
   - FastAPI & Uvicorn
   - SQLAlchemy & psycopg2
   - python-jose & passlib
   - python-dotenv & pydantic

## Security Features

✅ Bcrypt password hashing (salted)
✅ JWT signature validation
✅ Token expiration (480 minutes default)
✅ Role-based access control
✅ Secure password verification (constant-time comparison)
✅ Database connection pooling
✅ User status checking (is_active)

## Testing

### Unit Test Example
```python
def test_screener_cannot_access_coordinator_route():
    # Login as screener
    response = client.post("/auth/login", json={
        "email": "screener@test.com",
        "password": "password123"
    })
    token = response.json()["access_token"]
    
    # Try to access coordinator route
    response = client.get(
        "/auth/coordinator/dashboard",
        headers={"Authorization": f"Bearer {token}"}
    )
    
    # Should fail with 403
    assert response.status_code == 403
    assert response.json()["detail"] == "Access denied"
```

## Next Steps

1. **Add User Registration** - Create signup endpoint
2. **Add Refresh Tokens** - Implement token refresh
3. **Add Password Reset** - Email-based password recovery
4. **Add MFA** - Two-factor authentication
5. **Add Audit Logging** - Log all auth events
6. **Add Rate Limiting** - Prevent brute force
7. **Add HTTPS** - Enforce SSL/TLS in production

## Support Files

- **Authentication**: auth/auth.py
- **Authorization**: auth/dependencies.py
- **Data Models**: auth/models.py
- **API Routes**: routers/auth_router.py
- **Database**: db/database.py
- **Configuration**: dtbackend.env
- **Tests**: seed.py (for test data)

## Troubleshooting

**Issue**: "Database connection refused"
- Check PostgreSQL is running
- Verify DATABASE_URL in .env

**Issue**: "Invalid token"
- Token may be expired
- Token may be malformed
- Check SECRET_KEY matches

**Issue**: "Access denied"
- User role doesn't match required role
- Check user role in database

**Issue**: "ModuleNotFoundError"
- Run: `pip install -r requirements.txt`

## Summary

✅ Complete JWT authentication system implemented
✅ Role-Based Access Control with 4 roles
✅ Password hashing with bcrypt
✅ Token generation and validation
✅ Protected routes with dependency injection
✅ Example routes demonstrating all patterns
✅ Test data seeding script
✅ Comprehensive documentation
✅ Quick start testing guide

**Status**: Ready for production use with additional hardening
