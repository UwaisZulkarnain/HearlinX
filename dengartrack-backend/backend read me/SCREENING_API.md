# Phase 3 — Screening API Documentation

## Endpoints

### 1. Create Screening
**POST** `/screenings/`

**Access**: Screener role only (role enforced at API level)

**Request Body**:
```json
{
  "baby_id": "550e8400-e29b-41d4-a716-446655440000",
  "screening_type": "TEOAE",
  "ear_left": "pass",
  "ear_right": "refer",
  "attempt_number": 1,
  "notes": "Sample screening note"
}
```

**Valid Values**:
- `screening_type`: TEOAE, AABR, ABR
- `ear_left`/`ear_right`: pass, refer, not_tested
- `attempt_number`: integer (default: 1)
- `notes`: optional string

**Response** (201 Created):
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440001",
  "baby_id": "550e8400-e29b-41d4-a716-446655440000",
  "screener_id": "screener-uuid",
  "hospital_id": "hospital-uuid",
  "screening_type": "TEOAE",
  "ear_left": "pass",
  "ear_right": "refer",
  "screening_date": "2024-04-23T10:30:00",
  "attempt_number": 1,
  "notes": "Sample screening note",
  "created_at": "2024-04-23T10:30:00"
}
```

**Security**:
- Requires valid JWT token
- Screener must belong to same hospital as baby
- Automatically writes to audit_logs table with user_id, action, record details

**Example cURL**:
```bash
curl -X POST http://localhost:8000/screenings/ \
  -H "Authorization: Bearer YOUR_SCREENER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "baby_id": "550e8400-e29b-41d4-a716-446655440000",
    "screening_type": "TEOAE",
    "ear_left": "pass",
    "ear_right": "refer",
    "attempt_number": 1,
    "notes": "Testing screening creation"
  }'
```

---

### 2. List Screenings
**GET** `/screenings/`

**Access**: All authenticated users (screener, coordinator, hospital_admin, moh)

**Role-Based Filtering**:
- **Screener**: sees only their own screenings
- **Coordinator/Hospital Admin**: sees all screenings from their hospital
- **MOH**: sees all screenings nationally

**Response** (200 OK):
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440001",
    "baby_id": "550e8400-e29b-41d4-a716-446655440000",
    "screener_id": "screener-uuid",
    "hospital_id": "hospital-uuid",
    "screening_type": "TEOAE",
    "ear_left": "pass",
    "ear_right": "refer",
    "screening_date": "2024-04-23T10:30:00",
    "attempt_number": 1,
    "notes": "Test note",
    "created_at": "2024-04-23T10:30:00"
  }
]
```

**Example cURL**:
```bash
# Screener sees only their screenings
curl -X GET http://localhost:8000/screenings/ \
  -H "Authorization: Bearer YOUR_SCREENER_TOKEN"

# Coordinator sees hospital screenings
curl -X GET http://localhost:8000/screenings/ \
  -H "Authorization: Bearer YOUR_COORDINATOR_TOKEN"

# MOH sees national screenings
curl -X GET http://localhost:8000/screenings/ \
  -H "Authorization: Bearer YOUR_MOH_TOKEN"
```

---

### 3. Get Single Screening
**GET** `/screenings/{screening_id}`

**Access**: All authenticated users (with role-based filtering)

**Role-Based Access**:
- **Screener**: can only access their own screenings
- **Coordinator/Hospital Admin**: can access hospital screenings
- **MOH**: can access all screenings

**Response** (200 OK):
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440001",
  "baby_id": "550e8400-e29b-41d4-a716-446655440000",
  "screener_id": "screener-uuid",
  "hospital_id": "hospital-uuid",
  "screening_type": "TEOAE",
  "ear_left": "pass",
  "ear_right": "refer",
  "screening_date": "2024-04-23T10:30:00",
  "attempt_number": 1,
  "notes": "Test note",
  "created_at": "2024-04-23T10:30:00"
}
```

**Error Responses**:
- 404 Not Found: screening doesn't exist
- 403 Forbidden: user doesn't have access to screening

**Example cURL**:
```bash
curl -X GET http://localhost:8000/screenings/550e8400-e29b-41d4-a716-446655440001 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

### 4. Get Shift Summary
**GET** `/screenings/shift-summary/today`

**Access**: Screener role only

**Response** (200 OK):
```json
{
  "screener_id": "screener-uuid",
  "screener_name": "Test Screener",
  "screening_date": "2024-04-23",
  "total_screened": 5,
  "total_pass": 2,
  "total_refer": 2,
  "total_not_tested": 1
}
```

**Summary Meanings**:
- `total_screened`: Total babies screened today
- `total_pass`: LULUS - passed in at least one ear
- `total_refer`: RUJUK - referred in at least one ear
- `total_not_tested`: Babies with both ears marked as not_tested

**Example cURL**:
```bash
curl -X GET http://localhost:8000/screenings/shift-summary/today \
  -H "Authorization: Bearer YOUR_SCREENER_TOKEN"
```

---

## Testing Workflow

### 1. Get Tokens
```bash
# Login as screener
SCREENER_TOKEN=$(curl -s -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"screener@test.com","password":"password123"}' | jq -r '.access_token')

# Login as coordinator
COORD_TOKEN=$(curl -s -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"coordinator@test.com","password":"password123"}' | jq -r '.access_token')
```

### 2. Get Test Baby ID
```bash
# Query database to get a baby ID
psql -U postgres -d dengartrack_dev -c "SELECT id FROM babies LIMIT 1;"
```

### 3. Create Screening (as Screener)
```bash
curl -X POST http://localhost:8000/screenings/ \
  -H "Authorization: Bearer $SCREENER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "baby_id": "YOUR_BABY_UUID",
    "screening_type": "TEOAE",
    "ear_left": "pass",
    "ear_right": "refer"
  }'
```

### 4. List Own Screenings (as Screener)
```bash
curl -X GET http://localhost:8000/screenings/ \
  -H "Authorization: Bearer $SCREENER_TOKEN"
```

### 5. List Hospital Screenings (as Coordinator)
```bash
curl -X GET http://localhost:8000/screenings/ \
  -H "Authorization: Bearer $COORD_TOKEN"
```

### 6. Get Shift Summary (as Screener)
```bash
curl -X GET http://localhost:8000/screenings/shift-summary/today \
  -H "Authorization: Bearer $SCREENER_TOKEN"
```

---

## Key Implementation Details

### Role-Based Access Control
- **API Level**: All access control enforced at API level, not just frontend
- **Screener Isolation**: Screeners cannot access other screeners' screenings
- **Hospital Isolation**: Hospital staff cannot access other hospitals' data
- **MOH Access**: MOH can see all national data
- **Audit Trail**: Every create action logged to immutable audit_logs table

### Audit Logging
When a screening is created, an audit log entry is automatically written:

**Audit Log Fields**:
- `user_id`: UUID of screener who created it
- `action`: "CREATE"
- `table_name`: "screenings"
- `record_id`: UUID of screening
- `new_values`: JSON of all screening data
- `created_at`: Timestamp (immutable)

**Query Audit Logs**:
```sql
SELECT * FROM audit_logs WHERE table_name = 'screenings' ORDER BY created_at DESC;
```

### Data Validation
- Baby must exist in database
- Screener's hospital must match baby's hospital
- ear_left/ear_right must be: pass, refer, or not_tested
- screening_type must be: TEOAE, AABR, or ABR

---

## Error Handling

### 401 Unauthorized
- Invalid or expired JWT token
- Missing Authorization header

### 403 Forbidden
- Role doesn't have permission (e.g., screener creating screening for different hospital)
- Access denied to screening from different hospital/screener

### 404 Not Found
- Baby doesn't exist
- Screening doesn't exist

### 422 Unprocessable Entity
- Invalid enum values for screening_type or ear_left/ear_right
- Missing required fields

---

## Integration with Phase 2 (Auth)

Uses existing authentication from Phase 2:
- HTTPBearer security scheme
- JWT token validation
- Role-based dependencies
- User hospital affiliation tracking

---

## Next Steps (Phase 3B)

- Add PATCH `/screenings/{id}` - update screening (audit trail)
- Add DELETE `/screenings/{id}` - soft delete (audit trail)
- Add filtering by screening_type, date range, outcome
- Add pagination to list endpoints
- Add search by baby system_id
