# JWT Authentication with RBAC - DengarTrack Backend

## Overview
This implementation provides JWT-based authentication with Role-Based Access Control (RBAC) for the DengarTrack FastAPI backend.

## Features
- **Password Hashing**: bcrypt via passlib for secure password storage
- **JWT Tokens**: token-based auth using python-jose
- **4 Roles**: screener, coordinator, hospital_admin, moh
- **Role-Based Dependency Injection**: FastAPI dependencies to enforce access control
- **Protected Routes**: Login-required and role-specific endpoints

## Architecture

### Core Files
- `auth/auth.py` - Password hashing and JWT token generation/validation
- `auth/dependencies.py` - FastAPI dependencies for protected routes and role checking
- `auth/models.py` - Pydantic models for request/response validation
- `routers/auth_router.py` - Login and protected endpoint routes
- `db/database.py` - SQLAlchemy session management

### Environment Variables (dtbackend.env)
```
DATABASE_URL=postgresql://postgres:uwais@localhost:5432/dengartrack_dev
SECRET_KEY=dengartrack001
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=480
```

### Database Schema
Users table with required columns:
- `id` (UUID) - Primary key
- `email` (VARCHAR) - Unique email
- `password_hash` (TEXT) - Bcrypt hashed password
- `role` (VARCHAR) - One of: screener, coordinator, hospital_admin, moh
- `hospital_id` (UUID) - Reference to hospital
- `full_name` (VARCHAR) - User's full name
- `is_active` (BOOLEAN) - Account status

## Setup

### 1. Install Dependencies
```bash
pip install fastapi python-jose[cryptography] passlib[bcrypt] sqlalchemy python-dotenv psycopg2-binary
```

### 2. Setup Database
Run the schema.sql to create tables:
```bash
psql -U postgres -d dengartrack_dev -f db/schema.sql
psql -U postgres -d dengartrack_dev -f db/indexes.sql
```

### 3. Seed Test Data
Create test users for all 4 roles:
```bash
python seed.py
```

This creates:
- **screener@test.com** (role: screener)
- **coordinator@test.com** (role: coordinator)
- **admin@test.com** (role: hospital_admin)
- **moh@test.com** (role: moh)

All with password: `password123`

### 4. Start the Server
```bash
uvicorn main:app --reload
```

## Usage

### Login
**POST** `/auth/login`
```json
{
  "email": "screener@test.com",
  "password": "password123"
}
```

Response:
```json
{
  "access_token": "eyJhbGc...",
  "token_type": "bearer"
}
```

### Get Current User
**GET** `/auth/me`
- Requires: Valid JWT token in Authorization header
- Returns: Current user info (id, email, role, full_name, hospital_id, is_active)

### Protected Routes (Examples)

#### Screener-Only
**GET** `/auth/screener/dashboard`
- Access: screener role only
- Returns: Welcome message with user info

#### Coordinator-Only
**GET** `/auth/coordinator/dashboard`
- Access: coordinator role only
- Returns: Welcome message with user info

#### Hospital Admin-Only
**GET** `/auth/admin/dashboard`
- Access: hospital_admin role only
- Returns: Welcome message with user info

#### MOH-Only
**GET** `/auth/moh/dashboard`
- Access: moh role only
- Returns: Welcome message with user info

#### Multi-Role Access
**GET** `/auth/management/reports`
- Access: coordinator OR hospital_admin
- Returns: Management reports data

## Using in Your Routes

### Require Authentication Only
```python
from fastapi import APIRouter, Depends
from auth.dependencies import get_current_user

router = APIRouter()

@router.get("/protected")
def protected_route(current_user: dict = Depends(get_current_user)):
    """Only authenticated users can access."""
    return {"user_id": current_user["user_id"]}
```

### Require Specific Role
```python
from auth.dependencies import screener_only, coordinator_only, hospital_admin_only, moh_only

# Screeners only
@router.post("/screening/create")
def create_screening(data, current_user = Depends(screener_only)):
    """Only screeners can create screenings."""
    pass

# Coordinators only
@router.post("/followup/create")
def create_followup(data, current_user = Depends(coordinator_only)):
    """Only coordinators can create follow-ups."""
    pass

# Hospital Admins only
@router.post("/hospital/settings")
def hospital_settings(data, current_user = Depends(hospital_admin_only)):
    """Only hospital admins can modify settings."""
    pass

# MOH only
@router.get("/national/reports")
def national_reports(current_user = Depends(moh_only)):
    """Only MOH can view national reports."""
    pass
```

### Require Multiple Roles
```python
from auth.dependencies import require_role

# Multiple specific roles
@router.get("/data/export")
def export_data(current_user = Depends(require_role("hospital_admin", "moh"))):
    """Both hospital_admin and moh can access."""
    pass

# Pre-defined multi-role dependency
from auth.dependencies import coordinator_or_admin

@router.get("/reports")
def reports(current_user = Depends(coordinator_or_admin)):
    """Coordinators and Hospital Admins can access."""
    pass
```

## Authentication Flow

1. User calls **POST /auth/login** with email and password
2. Backend verifies password using bcrypt
3. Backend creates JWT token containing: user_id, role, hospital_id, exp (expiration)
4. Client stores token and includes in Authorization header: `Bearer <token>`
5. For protected routes, FastAPI extracts token from header
6. `decode_token()` validates JWT signature and expiration
7. Role dependencies check if user's role is allowed
8. Route handler executes only if all checks pass

## Token Structure
JWT payload example:
```json
{
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "role": "screener",
  "hospital_id": "550e8400-e29b-41d4-a716-446655440001",
  "exp": 1713825600
}
```

## Testing with cURL

### Login
```bash
curl -X POST "http://localhost:8000/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"screener@test.com","password":"password123"}'
```

### Get Current User
```bash
curl -X GET "http://localhost:8000/auth/me" \
  -H "Authorization: Bearer <your-access-token>"
```

### Access Role-Protected Route
```bash
curl -X GET "http://localhost:8000/auth/screener/dashboard" \
  -H "Authorization: Bearer <screener-token>"
```

## Key Implementation Details

### Password Hashing
- Uses bcrypt with passlib
- `hash_password(password)` - hashes plain text password
- `verify_password(plain, hashed)` - verifies password against hash

### JWT Token Creation
- `create_access_token(data)` - creates token with configurable expiration
- Token signed with SECRET_KEY using HS256 algorithm
- Includes user_id, role, hospital_id, and expiration time

### Token Validation
- `decode_token(token)` - verifies JWT signature and expiration
- Returns payload if valid, None if invalid/expired
- JWTError exceptions caught and handled

### Role Dependencies
- `get_current_user()` - extracts and validates token
- `require_role(*roles)` - returns dependency that checks if user has one of specified roles
- Pre-defined dependencies: screener_only, coordinator_only, hospital_admin_only, moh_only, coordinator_or_admin

## Security Considerations

1. **Secret Key**: Keep SECRET_KEY secure, never commit to version control
2. **HTTPS**: Always use HTTPS in production
3. **Token Expiration**: Tokens expire after ACCESS_TOKEN_EXPIRE_MINUTES
4. **Password Requirements**: Consider enforcing minimum password strength
5. **Rate Limiting**: Implement rate limiting on login endpoint
6. **Audit Logging**: Log all authentication events for security

## Common Patterns

### Protecting a Screening Route
```python
@router.post("/screenings")
def create_screening(
    screening_data: ScreeningCreate,
    current_user = Depends(screener_only),
    db = Depends(get_db)
):
    """Only screeners can create screenings."""
    # Log the action
    # Save screening to database
    # Return created screening
    pass
```

### Admin-Only Management Route
```python
@router.post("/users/{user_id}/deactivate")
def deactivate_user(
    user_id: str,
    current_user = Depends(hospital_admin_only),
    db = Depends(get_db)
):
    """Only hospital admins can deactivate users."""
    # Deactivate user in database
    pass
```

### Multiple Role Access with Granular Checks
```python
@router.get("/reports/{report_id}")
def get_report(
    report_id: str,
    current_user = Depends(get_current_user),
    db = Depends(get_db)
):
    """Complex access control based on role and hospital_id."""
    if current_user["role"] == "screener":
        # Screeners can only see own reports
        pass
    elif current_user["role"] in ["coordinator", "hospital_admin"]:
        # They can see all reports in their hospital
        pass
    elif current_user["role"] == "moh":
        # MOH can see all reports nationwide
        pass
```

## Troubleshooting

### "Invalid token" Error
- Verify token is included in Authorization header
- Check token expiration (use online JWT decoder)
- Verify SECRET_KEY matches

### "Access denied" Error
- Verify user role matches required role
- Check database to confirm user role is correct

### "User not found" Error on /me
- Verify user_id in token matches database

## Next Steps
1. Add password change endpoint: POST `/auth/change-password`
2. Add user creation endpoint: POST `/auth/register`
3. Add refresh token functionality
4. Add two-factor authentication
5. Implement audit logging for auth events
