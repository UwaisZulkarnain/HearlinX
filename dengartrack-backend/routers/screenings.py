from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import text
from datetime import datetime, date, timedelta
import uuid
import json

from auth.models import ScreeningCreate, ScreeningOut, ShiftSummary
from auth.dependencies import get_current_user, require_role
from db.database import get_db

router = APIRouter(prefix="/screenings", tags=["screenings"])
FOLLOW_UP_DUE_DAYS = 14

def write_audit_log(db: Session, user_id: str, action: str, table_name: str, record_id: str, new_values: dict):
    """Helper function to write to audit log."""
    db.connection().exec_driver_sql("""
        INSERT INTO audit_logs (user_id, action, table_name, record_id, new_values, created_at)
        VALUES (%(user_id)s, %(action)s, %(table_name)s, %(record_id)s, %(new_values)s, NOW())
    """, {
        "user_id": user_id,
        "action": action,
        "table_name": table_name,
        "record_id": record_id,
        "new_values": json.dumps(new_values)
    })


def create_follow_up_for_refer(
    db: Session,
    screening: ScreeningCreate,
    screening_id: str,
    hospital_id: str,
    actor_user_id: str,
):
    """Create one pending follow-up task for a RUJUK screening."""
    has_refer_result = (
        screening.ear_left.value == "refer" or screening.ear_right.value == "refer"
    )
    if not has_refer_result:
        return

    existing = db.execute(
        text("SELECT id FROM follow_ups WHERE screening_id = :screening_id"),
        {"screening_id": screening_id},
    ).fetchone()
    if existing:
        return

    follow_up_id = str(uuid.uuid4())
    due_date = date.today() + timedelta(days=FOLLOW_UP_DUE_DAYS)

    db.execute(
        text(
            """
            INSERT INTO follow_ups (
                id, baby_id, screening_id, hospital_id, status, due_date, created_at, updated_at
            )
            VALUES (
                :id, :baby_id, :screening_id, :hospital_id, 'pending', :due_date, NOW(), NOW()
            )
            """
        ),
        {
            "id": follow_up_id,
            "baby_id": str(screening.baby_id),
            "screening_id": screening_id,
            "hospital_id": hospital_id,
            "due_date": due_date,
        },
    )

    write_audit_log(
        db,
        actor_user_id,
        "CREATE",
        "follow_ups",
        follow_up_id,
        {
            "baby_id": str(screening.baby_id),
            "screening_id": screening_id,
            "hospital_id": hospital_id,
            "status": "pending",
            "due_date": str(due_date),
            "reason": "RUJUK screening result",
        },
    )
    db.connection().exec_driver_sql(
        """
        INSERT INTO follow_up_events (
            id, follow_up_id, user_id, action, from_status, to_status, notes, metadata, created_at
        )
        VALUES (
            %(id)s, %(follow_up_id)s, %(user_id)s, %(action)s,
            NULL, %(to_status)s, %(notes)s, CAST(%(metadata)s AS jsonb), NOW()
        )
        """,
        {
            "id": str(uuid.uuid4()),
            "follow_up_id": follow_up_id,
            "user_id": actor_user_id,
            "action": "created_from_rujuk",
            "to_status": "pending",
            "notes": "Follow-up created automatically from RUJUK screening",
            "metadata": json.dumps(
                {
                    "screening_id": screening_id,
                    "baby_id": str(screening.baby_id),
                    "due_date": str(due_date),
                }
            ),
        },
    )

@router.post("/", response_model=ScreeningOut, status_code=status.HTTP_201_CREATED)
def create_screening(
    screening: ScreeningCreate,
    current_user: dict = Depends(require_role("screener", "coordinator")),
    db: Session = Depends(get_db)
):
    """
    Create a new screening result.
    Screeners and coordinators can create screenings (role enforced via dependency).
    Automatically writes to audit_logs.
    """
    
    # Verify baby exists
    baby = db.execute(
        text("SELECT id, hospital_id FROM babies WHERE id = :id"),
        {"id": str(screening.baby_id)}
    ).fetchone()
    
    if not baby:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Baby not found"
        )
    
    # Verify screener's hospital matches baby's hospital
    if str(baby.hospital_id) != current_user.get("hospital_id"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot create screening for baby in different hospital"
        )
    
    # Create screening record
    screening_id = str(uuid.uuid4())
    screener_id = current_user["user_id"]
    hospital_id = current_user["hospital_id"]
    
    db.execute(text("""
        INSERT INTO screenings 
        (id, baby_id, screener_id, hospital_id, screening_type, ear_left, ear_right, attempt_number, notes, screening_date, created_at)
        VALUES (:id, :baby_id, :screener_id, :hospital_id, :screening_type, :ear_left, :ear_right, :attempt_number, :notes, COALESCE(:screening_date, NOW()), NOW())
    """), {
        "id": screening_id,
        "baby_id": str(screening.baby_id),
        "screener_id": screener_id,
        "hospital_id": hospital_id,
        "screening_type": screening.screening_type.value,
        "ear_left": screening.ear_left.value,
        "ear_right": screening.ear_right.value,
        "attempt_number": screening.attempt_number,
        "notes": screening.notes,
        "screening_date": screening.screening_date
    })
    
    # Write to audit log
    audit_data = {
        "baby_id": str(screening.baby_id),
        "screener_id": screener_id,
        "screening_type": screening.screening_type.value,
        "ear_left": screening.ear_left.value,
        "ear_right": screening.ear_right.value,
        "attempt_number": screening.attempt_number,
        "notes": screening.notes,
        "screening_date": screening.screening_date.isoformat()
        if screening.screening_date
        else None
    }
    write_audit_log(db, screener_id, "CREATE", "screenings", screening_id, audit_data)
    create_follow_up_for_refer(db, screening, screening_id, hospital_id, screener_id)
    
    db.commit()
    
    # Fetch and return created record
    result = db.execute(
        text("SELECT * FROM screenings WHERE id = :id"),
        {"id": screening_id}
    ).fetchone()
    
    return result

@router.get("/", response_model=list[ScreeningOut])
def list_screenings(
    today: bool = Query(False),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get screenings.
    - Screeners: see only their own screenings
    - Coordinators: see all screenings from their hospital
    - UNHS coordinators/MOH: no individual screening access
    """
    role = current_user.get("role")
    hospital_id = current_user.get("hospital_id")
    user_id = current_user["user_id"]
    today_filter = " AND DATE(s.screening_date) = :today" if today else ""

    base_query = """
        SELECT
            s.*,
            b.system_id AS baby_system_id
        FROM screenings s
        JOIN babies b ON b.id = s.baby_id
    """
    
    if role == "screener":
        query = f"""
            {base_query}
            WHERE s.screener_id = :user_id
            {today_filter}
            ORDER BY s.screening_date DESC
        """
        params = {"user_id": user_id}
    elif role == "coordinator":
        query = f"""
            {base_query}
            WHERE s.hospital_id = :hospital_id
            {today_filter}
            ORDER BY s.screening_date DESC
        """
        params = {"hospital_id": hospital_id}
    elif role in ["unhs_coordinator", "moh"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Summary-only role cannot access individual screenings"
        )
    else:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid role"
        )

    if today:
        params["today"] = date.today()
    
    results = db.execute(text(query), params).fetchall()
    return results

@router.get("/shift-summary/today", response_model=ShiftSummary)
def get_shift_summary(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get today's shift summary.
    Returns: total screened, total pass (LULUS), total refer (RUJUK).
    Screeners see own shift. Coordinators see own hospital.
    """
    role = current_user.get("role")
    user_id = current_user["user_id"]
    hospital_id = current_user.get("hospital_id")
    today = date.today()
    
    user = db.execute(
        text("SELECT id, full_name FROM users WHERE id = :id"),
        {"id": user_id}
    ).fetchone()

    if role == "screener":
        where_clause = "screener_id = :user_id"
        params = {"user_id": user_id, "today": today}
    elif role == "coordinator":
        where_clause = "hospital_id = :hospital_id"
        params = {"hospital_id": hospital_id, "today": today}
    elif role in ["unhs_coordinator", "moh"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Summary-only role cannot access shift summaries"
        )
    else:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid role"
        )

    result = db.execute(text(f"""
        SELECT
            COUNT(*) as total_screened,
            SUM(CASE WHEN ear_left = 'pass' AND ear_right = 'pass' THEN 1 ELSE 0 END) as total_pass,
            SUM(CASE WHEN ear_left = 'refer' OR ear_right = 'refer' THEN 1 ELSE 0 END) as total_refer,
            SUM(CASE WHEN (ear_left = 'refer' OR ear_right = 'refer') THEN 0 WHEN (ear_left = 'not_tested' OR ear_right = 'not_tested') THEN 1 ELSE 0 END) as total_not_tested
        FROM screenings
        WHERE {where_clause}
        AND DATE(screening_date) = :today
    """), params).fetchone()
    
    return ShiftSummary(
        screener_id=uuid.UUID(user_id),
        screener_name=user.full_name,
        screening_date=str(today),
        total_screened=result.total_screened or 0,
        total_pass=result.total_pass or 0,
        total_refer=result.total_refer or 0,
        total_not_tested=result.total_not_tested or 0
    )

@router.get("/{screening_id}", response_model=ScreeningOut)
def get_screening(
    screening_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get a single screening record.
    Access controlled by role and hospital affiliation.
    """
    screening = db.execute(
        text("SELECT * FROM screenings WHERE id = :id"),
        {"id": str(screening_id)}
    ).fetchone()
    
    if not screening:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Screening not found"
        )
    
    role = current_user.get("role")
    hospital_id = current_user.get("hospital_id")
    user_id = current_user["user_id"]
    
    # Access control
    if role == "screener":
        # Screeners can only view their own screenings
        if str(screening.screener_id) != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Cannot access screening from another screener"
            )
    elif role == "coordinator":
        # Coordinators can view hospital screenings
        if str(screening.hospital_id) != hospital_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Cannot access screening from another hospital"
            )
    elif role in ["unhs_coordinator", "moh"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Summary-only role cannot access individual screenings"
        )
    else:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid role"
        )
    
    return screening
