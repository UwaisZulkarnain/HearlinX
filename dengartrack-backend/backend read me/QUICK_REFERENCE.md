# Quick Reference & Setup Checklist

## Implementation Complete

This checklist confirms all requirements have been implemented.

### Core Requirements
- [x] **4 Roles**: screener, coordinator, hospital_admin, moh
- [x] **Password Hashing**: bcrypt via passlib
- [x] **JWT Tokens**: python-jose for generation and validation
- [x] **Login Endpoint**: POST /auth/login returns access_token
- [x] **Protected Route Dependency**: OAuth2PasswordBearer + JWT validation
- [x] **Role-Based Dependency**: require_role() with pre-defined helpers
- [x] **Database Integration**: Uses existing users table schema
- [x] **Environment Variables**: SECRET_KEY, ALGORITHM, ACCESS_TOKEN_EXPIRE_MINUTES
- [x] **File Structure**: auth/auth.py, auth/dependencies.py, auth/models.py
- [x] **Seed Script**: Creates 1 user per role with test data

## Setup Steps

### Step 1: Install Dependencies
```bash
cd dengartrack-backend
pip install -r requirements.txt
```
Installs:
- fastapi
- uvicorn
- sqlalchemy
- psycopg2-binary
- python-jose[cryptography]
- passlib[bcrypt]
- python-dotenv
- pydantic

### Step 2: Setup Database
```bash
# Connect to PostgreSQL
psql -U postgres

# Create database if not exists
CREATE DATABASE dengartrack_dev;

# Load schema
psql -U postgres -d dengartrack_dev -f db/schema.sql

# Load indexes
psql -U postgres -d dengartrack_dev -f db/indexes.sql
```

### Step 3: Verify Environment Variables
File: `dtbackend.env`
```
DATABASE_URL=postgresql://postgres:uwais@localhost:5432/dengartrack_dev
SECRET_KEY=dengartrack001
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=480
```

### Step 4: Seed Test Data
```bash
python seed.py
```

Expected output:
```
✓ Seed complete: 1 hospital + 4 test users created
  - screener@test.com (role: screener)
  - coordinator@test.com (role: coordinator)
  - admin@test.com (role: hospital_admin)
  - moh@test.com (role: moh)
  All with password: password123
```

### Step 5: Start the Server
```bash
uvicorn main:app --reload
```

Expected output:
```
INFO:     Uvicorn running on http://127.0.0.1:8000
INFO:     Application startup complete
```

### Step 6: Test the API
See TEST_AUTH.md for detailed testing instructions

## 🗂️ File Structure Created

```
dengartrack-backend/
├── auth/
│   ├── __init__.py                  # Package marker (empty)
│   ├── auth.py                      # Password + JWT functions
│   ├── dependencies.py              # FastAPI dependencies
│   └── models.py                    # Pydantic models
├── db/
│   ├── __init__.py                  # NEW - Package marker
│   ├── database.py                  # NEW - SQLAlchemy setup
│   ├── schema.sql                   # Existing schema
│   └── indexes.sql                  # Existing indexes
├── routers/
│   └── auth_router.py               # Login + protected routes
├── main.py                          # FastAPI app (UPDATED)
├── seed.py                          # Test data (UPDATED)
├── dtbackend.env                    # Existing config
├── requirements.txt                 # NEW - Python dependencies
├── AUTH_SETUP.md                    # NEW - Complete guide
├── TEST_AUTH.md                     # NEW - Testing guide
├── IMPLEMENTATION_SUMMARY.md        # NEW - Summary
└── ARCHITECTURE.md                  # NEW - Diagrams
```

## 🔑 Quick API Examples

### Login
```bash
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"screener@test.com","password":"password123"}'
```

### Get Current User
```bash
curl -X GET http://localhost:8000/auth/me \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Access Role-Protected Route
```bash
curl -X GET http://localhost:8000/auth/screener/dashboard \
  -H "Authorization: Bearer YOUR_SCREENER_TOKEN"
```

## 📝 Using Auth in Your Routes

### Simple Protected Route
```python
from fastapi import APIRouter, Depends
from auth.dependencies import get_current_user

@router.get("/data")
def get_data(current_user: dict = Depends(get_current_user)):
    return {"user_id": current_user["user_id"]}
```

### Role-Specific Route
```python
from auth.dependencies import screener_only

@router.post("/screening")
def create_screening(current_user = Depends(screener_only)):
    return {"created_by": current_user["user_id"]}
```

### Multi-Role Route
```python
from auth.dependencies import require_role

@router.get("/reports")
def reports(current_user = Depends(require_role("hospital_admin", "moh"))):
    return {"report": "data"}
```

## 🧪 Test Credentials

All test users have password: **password123**

| Email | Role | Use Case |
|-------|------|----------|
| screener@test.com | screener | Test screening endpoints |
| coordinator@test.com | coordinator | Test follow-up endpoints |
| admin@test.com | hospital_admin | Test admin endpoints |
| moh@test.com | moh | Test national reporting |

## 🔒 Security Checklist

- [x] Passwords hashed with bcrypt (not stored in plain text)
- [x] JWT signature validation
- [x] Token expiration checking
- [x] Role-based access control
- [x] User active status verification
- [ ] TODO: HTTPS in production (configure reverse proxy)
- [ ] TODO: Rate limiting on login
- [ ] TODO: Password complexity requirements
- [ ] TODO: Audit logging
- [ ] TODO: Session timeout handling

## 🐛 Troubleshooting

### Database Connection Error
```
Error: could not connect to server: Connection refused
```
**Solution**: 
1. Check PostgreSQL is running: `psql --version`
2. Verify DATABASE_URL in dtbackend.env
3. Verify database exists: `psql -U postgres -l | grep dengartrack_dev`

### ModuleNotFoundError
```
ModuleNotFoundError: No module named 'fastapi'
```
**Solution**: 
```bash
pip install -r requirements.txt
```

### Invalid Token Error
```
"detail": "Invalid token"
```
**Solutions**:
1. Token might be expired (check expiration)
2. Token format wrong (use `Bearer <token>`)
3. SECRET_KEY doesn't match (check .env)

### Access Denied Error
```
"detail": "Access denied"
```
**Solutions**:
1. Verify user role matches requirement
2. Check database for correct user role
3. Decode token at jwt.io to verify role

### No Users Found
```
Invalid email or password
```
**Solution**: Run seed script
```bash
python seed.py
```

## 📚 Documentation Files

| File | Purpose |
|------|---------|
| AUTH_SETUP.md | Complete implementation guide |
| TEST_AUTH.md | Testing procedures and examples |
| ARCHITECTURE.md | Visual diagrams and flows |
| IMPLEMENTATION_SUMMARY.md | What was built summary |
| requirements.txt | Python dependencies |
| seed.py | Create test data |

## 🚀 Next Steps (Optional Enhancements)

1. **User Registration**
   - Implement POST /auth/register
   - Validate email format
   - Enforce password requirements

2. **Token Refresh**
   - Implement refresh token endpoint
   - Short-lived access tokens
   - Long-lived refresh tokens

3. **Password Management**
   - POST /auth/change-password
   - POST /auth/forgot-password
   - Email verification

4. **Multi-Factor Authentication**
   - TOTP support
   - SMS verification
   - Email confirmation

5. **Audit Logging**
   - Log all auth events
   - Track failed login attempts
   - Monitor role changes

6. **Security Hardening**
   - Rate limiting on login
   - Account lockout after failed attempts
   - IP whitelist/blacklist
   - Session management

7. **Testing**
   - Unit tests for auth functions
   - Integration tests for routes
   - End-to-end test scenarios

## ✨ Key Features Implemented

### Authentication
- JWT-based stateless authentication
- Bcrypt password hashing with salt
- Token expiration (480 minutes default)
- OAuth2 with Bearer schema

### Authorization
- Role-Based Access Control (RBAC)
- 4 predefined roles
- Flexible role composition
- Granular permission control

### Developer Experience
- Dependency injection via FastAPI
- Type hints with Pydantic
- Clear error messages
- Comprehensive documentation

### Testing
- Seed script for test data
- Example endpoints for all roles
- Multi-role access examples
- Testing guide with curl/Python/Postman examples

## 📞 Support Resources

1. **FastAPI Docs**: http://localhost:8000/docs (when running)
2. **Swagger UI**: http://localhost:8000/swagger/ui
3. **Documentation**: 
   - AUTH_SETUP.md (implementation)
   - TEST_AUTH.md (testing)
   - ARCHITECTURE.md (diagrams)

## ⚡ Quick Commands Reference

```bash
# Setup
pip install -r requirements.txt
psql -U postgres -d dengartrack_dev -f db/schema.sql
python seed.py

# Run
uvicorn main:app --reload

# Test
curl http://localhost:8000/
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"screener@test.com","password":"password123"}'

# Database
psql -U postgres -d dengartrack_dev
SELECT email, role FROM users;
```

---

**Status**: ✅ All requirements implemented and ready for use!
