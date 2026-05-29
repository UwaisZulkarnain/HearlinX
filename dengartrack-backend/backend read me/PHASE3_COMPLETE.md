# Phase 3 — Screening API ✓ COMPLETE

## What Was Built

**Screening Entry API** for DengarTrack with 4 endpoints:

1. **POST /screenings/** - Create new screening (screener only)
2. **GET /screenings/** - List screenings (role-based filtering)
3. **GET /screenings/{id}** - Get single screening (access controlled)
4. **GET /screenings/shift-summary/today** - Today's totals (screener only)

## Files Created/Modified

### Created
- `routers/screenings.py` - Full screening endpoints + access control
- `SCREENING_API.md` - Complete API documentation
- `test_screening_api.py` - Python test script

### Modified
- `auth/models.py` - Added screening Pydantic models
- `main.py` - Registered screenings router
- `seed.py` - Enhanced to create test babies + sample screening

## Key Features

### 1. Authentication & Authorization
- All endpoints protected by JWT (HTTPBearer)
- Role-based access control enforced at API level
- 4 roles with distinct permissions:
  - **Screener**: create screenings, see own screenings
  - **Coordinator/Hospital Admin**: see hospital screenings
  - **MOH**: see national screenings

### 2. Role-Based Filtering
```
Screener → sees only own screenings
Coordinator → sees hospital screenings
Hospital Admin → sees hospital screenings
MOH → sees all screenings nationally
```

### 3. Audit Logging
- Every screening creation automatically logged
- Immutable audit_logs table (append-only)
- Fields: user_id, action, table_name, record_id, new_values, created_at
- Query: `SELECT * FROM audit_logs WHERE table_name='screenings';`

### 4. Data Validation
- Baby must exist in database
- Screener's hospital must match baby's hospital
- Valid ear values: pass, refer, not_tested
- Valid screening types: TEOAE, AABR, ABR
- Attempt number defaults to 1

### 5. Shift Summary
- Calculates today's totals for screener
- Total screened: count of all screenings
- LULUS (pass): babies passing in at least one ear
- RUJUK (refer): babies referring in at least one ear
- Not tested: babies with both ears marked not_tested

## API Endpoints

### Create Screening
```bash
POST /screenings/
Authorization: Bearer SCREENER_TOKEN
Content-Type: application/json

{
  "baby_id": "uuid",
  "screening_type": "TEOAE",
  "ear_left": "pass",
  "ear_right": "refer",
  "attempt_number": 1,
  "notes": "optional"
}

Response: 201 Created + screening object
```

### List Screenings
```bash
GET /screenings/
Authorization: Bearer TOKEN

Response: 200 OK + array of screenings
(filtered by role)
```

### Get Single Screening
```bash
GET /screenings/{screening_id}
Authorization: Bearer TOKEN

Response: 200 OK + screening object
```

### Shift Summary
```bash
GET /screenings/shift-summary/today
Authorization: Bearer SCREENER_TOKEN

Response: 200 OK + summary object
{
  "screener_id": "uuid",
  "screener_name": "Test Screener",
  "screening_date": "2024-04-23",
  "total_screened": 5,
  "total_pass": 2,
  "total_refer": 2,
  "total_not_tested": 1
}
```

## Testing

### Quick Test
```bash
# Run test script
python test_screening_api.py

# Or manual cURL test
SCREENER_TOKEN=$(curl -s -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"screener@test.com","password":"password123"}' | jq -r '.access_token')

curl -X GET http://localhost:8000/screenings/ \
  -H "Authorization: Bearer $SCREENER_TOKEN"
```

### Database Verification
```sql
-- Check screenings created
SELECT id, baby_id, screener_id, screening_type, ear_left, ear_right 
FROM screenings;

-- Check audit logs
SELECT user_id, action, table_name, record_id, new_values, created_at 
FROM audit_logs 
WHERE table_name='screenings' 
ORDER BY created_at DESC;
```

## Security Implementation

✓ JWT token validation on all endpoints
✓ Role-based access control at API level
✓ Data isolation by hospital
✓ Screener data isolation
✓ Audit trail for all creates
✓ Input validation (enum values, required fields)
✓ Hospital affiliation checking

## Database Schema Used

### screenings table
```sql
id, baby_id, screener_id, hospital_id
screening_type (TEOAE|AABR|ABR)
ear_left (pass|refer|not_tested)
ear_right (pass|refer|not_tested)
attempt_number, notes
screening_date, created_at
```

### audit_logs table
```sql
id, user_id, action, table_name, record_id
new_values (JSONB), created_at
```

## Pydantic Models Added

```python
class EarResult(Enum)
class ScreeningType(Enum)
class ScreeningCreate(BaseModel) - request
class ScreeningOut(BaseModel) - response
class ShiftSummary(BaseModel) - summary response
```

## Error Handling

- **401**: Invalid/expired JWT
- **403**: Role doesn't have permission
- **404**: Screening or baby not found
- **422**: Invalid enum values or missing fields

## Code Quality

- Type hints throughout
- Clear docstrings on endpoints
- Input validation with Pydantic
- SQL injection prevention (parameterized queries)
- Comprehensive error messages
- Helper functions (write_audit_log)

## Integration Points

### With Phase 2 (Auth)
- Uses JWT tokens from login endpoint
- Uses HTTPBearer security
- Uses role-based dependencies
- Uses hospital_id from token payload

### With Database
- Queries screenings, babies, users, audit_logs tables
- Enforces foreign key relationships
- Immutable audit logging

### With Swagger/OpenAPI
- Auto-generates documentation
- Shows required/optional parameters
- Bearer token input in Swagger UI

## Next Steps (Phase 3B / Phase 4)

### Phase 3B Enhancements
- PATCH /screenings/{id} - update screening (with audit)
- DELETE /screenings/{id} - soft delete (with audit)
- GET /screenings/?screening_type=TEOAE - filter by type
- GET /screenings/?from_date=2024-01-01 - date range filtering
- Pagination support

### Phase 4 (Patient Records API)
- Baby record creation with anonymization
- Mother/father identifiers encrypted
- Referral status tracking
- Baby metadata (weight, DOB, gestational age)

## Files Summary

| File | Purpose |
|------|---------|
| routers/screenings.py | 4 endpoints + logic |
| auth/models.py | Pydantic screening models |
| main.py | Router registration |
| seed.py | Test data + babies |
| SCREENING_API.md | Full API docs |
| test_screening_api.py | Python test script |

## Status
✅ **COMPLETE** - All Phase 3 requirements met

- [x] POST /screenings/ (screener only)
- [x] GET /screenings/ (role-filtered)
- [x] GET /screenings/{id} (access controlled)
- [x] GET /screenings/shift-summary (screener only)
- [x] JWT protected
- [x] Role-based access at API level
- [x] Audit logging on create
- [x] Data validation
- [x] Documentation
- [x] Test script

Ready for Phase 4: Patient Records API
