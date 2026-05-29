import json
import uuid

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import text
from sqlalchemy.orm import Session

from auth.dependencies import coordinator_only
from auth.models import FollowUpOut, FollowUpUpdate
from db.database import get_db

router = APIRouter(prefix="/followups", tags=["followups"])


def write_audit_log(
    db: Session,
    user_id: str,
    action: str,
    table_name: str,
    record_id: str,
    old_values: dict | None,
    new_values: dict | None,
):
    db.connection().exec_driver_sql(
        """
        INSERT INTO audit_logs (user_id, action, table_name, record_id, old_values, new_values, created_at)
        VALUES (
            %(user_id)s, %(action)s, %(table_name)s, %(record_id)s,
            CAST(%(old_values)s AS jsonb), CAST(%(new_values)s AS jsonb), NOW()
        )
        """,
        {
            "user_id": user_id,
            "action": action,
            "table_name": table_name,
            "record_id": record_id,
            "old_values": json.dumps(old_values) if old_values is not None else None,
            "new_values": json.dumps(new_values) if new_values is not None else None,
        },
    )


@router.get("/", response_model=list[FollowUpOut], tags=["followups"])
def list_followups(
    current_user: dict = Depends(coordinator_only),
    db: Session = Depends(get_db),
):
    rows = db.execute(
        text(
            """
            SELECT
                f.*,
                b.system_id AS baby_system_id
            FROM follow_ups f
            JOIN babies b ON b.id = f.baby_id
            WHERE f.hospital_id = :hospital_id
              AND f.status IN ('pending', 'contacted', 'appointment_booked')
            ORDER BY f.created_at ASC
            """
        ),
        {"hospital_id": current_user["hospital_id"]},
    ).fetchall()
    return rows


@router.patch("/{followup_id}", response_model=FollowUpOut, tags=["followups"])
def update_followup(
    followup_id: uuid.UUID,
    payload: FollowUpUpdate,
    current_user: dict = Depends(coordinator_only),
    db: Session = Depends(get_db),
):
    existing = db.execute(
        text("SELECT * FROM follow_ups WHERE id = :id"),
        {"id": str(followup_id)},
    ).fetchone()

    if not existing:
        raise HTTPException(status_code=404, detail="Follow-up not found")

    if str(existing.hospital_id) != current_user["hospital_id"]:
        raise HTTPException(status_code=403, detail="Cannot update follow-up from another hospital")

    old_values = {
        "status": existing.status,
        "notes": existing.notes,
        "due_date": str(existing.due_date) if existing.due_date else None,
        "assigned_to": str(existing.assigned_to) if existing.assigned_to else None,
    }

    db.execute(
        text(
            """
            UPDATE follow_ups
            SET status = :status,
                notes = :notes,
                due_date = :due_date,
                assigned_to = :assigned_to,
                updated_at = NOW()
            WHERE id = :id
            """
        ),
        {
            "id": str(followup_id),
            "status": payload.status.value,
            "notes": payload.notes,
            "due_date": payload.due_date,
            "assigned_to": current_user["user_id"],
        },
    )

    new_values = {
        "status": payload.status.value,
        "notes": payload.notes,
        "due_date": str(payload.due_date) if payload.due_date else None,
        "assigned_to": current_user["user_id"],
    }
    write_audit_log(
        db,
        current_user["user_id"],
        "UPDATE",
        "follow_ups",
        str(followup_id),
        old_values,
        new_values,
    )
    db.commit()

    updated = db.execute(
        text("SELECT * FROM follow_ups WHERE id = :id"),
        {"id": str(followup_id)},
    ).fetchone()
    return updated
