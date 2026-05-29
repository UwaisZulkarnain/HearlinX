# Testing JWT Authentication - Quick Start Guide

## Prerequisites
1. PostgreSQL running with dengartrack_dev database created
2. Backend dependencies installed: `pip install -r requirements.txt`
3. Database schema loaded: `psql -U postgres -d dengartrack_dev -f db/schema.sql`
4. Test data seeded: `python seed.py`

## Quick Test Flow

### 1. Start the Backend
```bash
uvicorn main:app --reload
```
Server will start at: http://localhost:8000

### 2. Test Login (All 4 Roles)
Use any of these credentials, all with password: `password123`

#### Via REST Client (VS Code REST Client Extension)
Create a file named `test_auth.http`:

```http
### Login as Screener
POST http://localhost:8000/auth/login
Content-Type: application/json

{
  "email": "screener@test.com",
  "password": "password123"
}

### Login as Coordinator
POST http://localhost:8000/auth/login
Content-Type: application/json

{
  "email": "coordinator@test.com",
  "password": "password123"
}

### Login as Hospital Admin
POST http://localhost:8000/auth/login
Content-Type: application/json

{
  "email": "admin@test.com",
  "password": "password123"
}

### Login as MOH
POST http://localhost:8000/auth/login
Content-Type: application/json

{
  "email": "moh@test.com",
  "password": "password123"
}

### Get Current User Info
GET http://localhost:8000/auth/me
Authorization: Bearer YOUR_TOKEN_HERE

### Test Screener Dashboard (Screener Only)
GET http://localhost:8000/auth/screener/dashboard
Authorization: Bearer YOUR_SCREENER_TOKEN

### Test Coordinator Dashboard (Coordinator Only)
GET http://localhost:8000/auth/coordinator/dashboard
Authorization: Bearer YOUR_COORDINATOR_TOKEN

### Test Admin Dashboard (Admin Only)
GET http://localhost:8000/auth/admin/dashboard
Authorization: Bearer YOUR_ADMIN_TOKEN

### Test MOH Dashboard (MOH Only)
GET http://localhost:8000/auth/moh/dashboard
Authorization: Bearer YOUR_MOH_TOKEN

### Test Multi-Role Access
GET http://localhost:8000/auth/management/reports
Authorization: Bearer YOUR_COORDINATOR_OR_ADMIN_TOKEN
```

#### Via cURL
```bash
# Login as screener
TOKEN=$(curl -s -X POST "http://localhost:8000/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"screener@test.com","password":"password123"}' | jq -r '.access_token')

echo "Token: $TOKEN"

# Get current user
curl -X GET "http://localhost:8000/auth/me" \
  -H "Authorization: Bearer $TOKEN"

# Try to access screener dashboard (should work)
curl -X GET "http://localhost:8000/auth/screener/dashboard" \
  -H "Authorization: Bearer $TOKEN"

# Try to access coordinator dashboard (should fail with 403)
curl -X GET "http://localhost:8000/auth/coordinator/dashboard" \
  -H "Authorization: Bearer $TOKEN"
```

#### Via Python
```python
import requests
import json

BASE_URL = "http://localhost:8000"

# Login
login_data = {"email": "screener@test.com", "password": "password123"}
response = requests.post(f"{BASE_URL}/auth/login", json=login_data)
token = response.json()["access_token"]
print(f"Token: {token}")

# Get current user
headers = {"Authorization": f"Bearer {token}"}
response = requests.get(f"{BASE_URL}/auth/me", headers=headers)
print(f"Current user: {response.json()}")

# Access role-protected route
response = requests.get(f"{BASE_URL}/auth/screener/dashboard", headers=headers)
print(f"Screener dashboard: {response.json()}")

# Try to access different role (should fail)
response = requests.get(f"{BASE_URL}/auth/coordinator/dashboard", headers=headers)
print(f"Status: {response.status_code}")
if response.status_code == 403:
    print("Access denied - correct behavior!")
```

## Expected Results

### Successful Login Response
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

### Get Current User Response
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "full_name": "Test Screener",
  "email": "screener@test.com",
  "role": "screener",
  "hospital_id": "550e8400-e29b-41d4-a716-446655440001",
  "is_active": true
}
```

### Authorized Route Response (Same Role)
```json
{
  "message": "Welcome Screener",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "role": "screener"
}
```

### Unauthorized Route Response (Different Role)
```json
{
  "detail": "Access denied"
}
```
HTTP Status: 403 Forbidden

## Test Scenarios

### Scenario 1: Role Isolation
1. Login as screener → Get screener token
2. Try to access `/auth/coordinator/dashboard` with screener token
3. **Expected**: 403 Forbidden with "Access denied"

### Scenario 2: Token Validation
1. Login to get valid token
2. Modify token (change any character)
3. Try to access protected route with modified token
4. **Expected**: 401 Unauthorized with "Invalid token"

### Scenario 3: Token Expiration
1. Wait for ACCESS_TOKEN_EXPIRE_MINUTES to pass (or manually set expiration)
2. Try to access protected route with expired token
3. **Expected**: 401 Unauthorized with "Invalid token"

### Scenario 4: Multi-Role Access
1. Login as coordinator → Get coordinator token
2. Access `/auth/management/reports` with coordinator token
3. **Expected**: 200 OK - access granted
4. Login as hospital_admin → Get admin token
5. Access `/auth/management/reports` with admin token
6. **Expected**: 200 OK - access granted
7. Login as screener → Get screener token
8. Access `/auth/management/reports` with screener token
9. **Expected**: 403 Forbidden - access denied

## Using Postman

1. Import as new environment variable:
   - Name: `token`
   - Initial value: (empty)
   - Current value: (empty)

2. Login request:
   - Method: POST
   - URL: http://localhost:8000/auth/login
   - Body (JSON):
     ```json
     {
       "email": "screener@test.com",
       "password": "password123"
     }
     ```
   - Tests tab:
     ```javascript
     var jsonData = pm.response.json();
     pm.environment.set("token", jsonData.access_token);
     ```

3. Protected route requests:
   - Add header: `Authorization: Bearer {{token}}`
   - Send request

## Debugging

### Check Token Contents
Use [jwt.io](https://jwt.io) to decode tokens and view payload

### View Database
```sql
SELECT id, email, role, is_active FROM users;
```

### Check Auth Logs
Look for debug prints in terminal running uvicorn

## Common Issues

### "Database connection refused"
- Ensure PostgreSQL is running
- Verify DATABASE_URL in dtbackend.env
- Confirm database and user exist

### "Relation users does not exist"
- Run `psql -U postgres -d dengartrack_dev -f db/schema.sql`
- Check for SQL errors

### "No users found when seeding"
- Verify users table exists
- Run seed script: `python seed.py`

### "Invalid token"
- Ensure token is being sent in Authorization header
- Token format should be: `Bearer <token>`
- Check token hasn't expired

### "ModuleNotFoundError"
- Install requirements: `pip install -r requirements.txt`
- Ensure venv is activated
