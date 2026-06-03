import json
import uuid
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import text
from sqlalchemy.orm import Session

from auth.dependencies import coordinator_only
from auth.models import FollowUpEventOut, FollowUpOut, FollowUpUpdate
from db.database import get_db
from routers.followup_events import ensure_follow_up_events_table, write_follow_up_event

router = APIRouter(prefix="/followups", tags=["followups"])


def payload_fields(payload: FollowUpUpdate) -> set[str]:
    return set(
        getattr(payload, "model_fields_set", getattr(payload, "__fields_set__", set()))
    )


def followup_select_sql(where_clause: str) -> str:
    return f"""
            SELECT
                f.*,
                b.system_id AS baby_system_id,
                COALESCE(GREATEST((CURRENT_DATE - f.due_date), 0), 0) AS days_overdue,
                CASE
                    WHEN f.status = 'lost_to_followup' THEN 'ltfu'
                    WHEN f.due_date IS NULL THEN 'new'
                    WHEN f.due_date < CURRENT_DATE - INTERVAL '14 days' THEN 'red'
                    WHEN f.due_date < CURRENT_DATE THEN 'amber'
                    ELSE 'new'
                END AS urgency
            FROM follow_ups f
            JOIN babies b ON b.id = f.baby_id
            {where_clause}
            """


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
            followup_select_sql(
                """
            WHERE f.hospital_id = :hospital_id
              AND f.status IN ('pending', 'contacted', 'appointment_booked', 'escalated', 'lost_to_followup')
                """
            )
            + """
            ORDER BY
                CASE
                    WHEN f.status = 'lost_to_followup' THEN 0
                    WHEN f.due_date < CURRENT_DATE - INTERVAL '14 days' THEN 1
                    WHEN f.due_date < CURRENT_DATE THEN 2
                    ELSE 3
                END,
                f.due_date ASC NULLS LAST,
                f.created_at ASC
            """
        ),
        {"hospital_id": current_user["hospital_id"]},
    ).fetchall()
    return rows


@router.get("/{followup_id}/events", response_model=list[FollowUpEventOut], tags=["followups"])
def list_followup_events(
    followup_id: uuid.UUID,
    current_user: dict = Depends(coordinator_only),
    db: Session = Depends(get_db),
):
    followup = db.execute(
        text("SELECT hospital_id FROM follow_ups WHERE id = :id"),
        {"id": str(followup_id)},
    ).fetchone()
    if not followup:
        raise HTTPException(status_code=404, detail="Follow-up not found")
    if str(followup.hospital_id) != current_user["hospital_id"]:
        raise HTTPException(status_code=403, detail="Cannot view follow-up from another hospital")

    ensure_follow_up_events_table(db)
    return db.execute(
        text(
            """
            SELECT
                e.*,
                u.full_name AS actor_name
            FROM follow_up_events e
            LEFT JOIN users u ON u.id = e.user_id
            WHERE e.follow_up_id = :followup_id
            ORDER BY e.created_at ASC
            """
        ),
        {"followup_id": str(followup_id)},
    ).fetchall()


@router.patch("/{followup_id}", response_model=FollowUpOut, tags=["followups"])
def update_followup(
    followup_id: uuid.UUID,
    payload: FollowUpUpdate,
    current_user: dict = Depends(coordinator_only),
    db: Session = Depends(get_db),
):
    existing = db.execute(
        text(followup_select_sql("WHERE f.id = :id")),
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
        "last_contacted_at": existing.last_contacted_at.isoformat() if existing.last_contacted_at else None,
        "appointment_date": existing.appointment_date.isoformat() if existing.appointment_date else None,
        "completed_at": existing.completed_at.isoformat() if existing.completed_at else None,
        "ltfu_reason": existing.ltfu_reason,
        "contact_attempts": existing.contact_attempts or 0,
        "assigned_to": str(existing.assigned_to) if existing.assigned_to else None,
    }
    fields = payload_fields(payload)
    new_status = payload.status.value if "status" in fields and payload.status else existing.status
    notes = payload.notes if "notes" in fields else existing.notes
    due_date = payload.due_date if "due_date" in fields else existing.due_date
    last_contacted_at = (
        payload.last_contacted_at
        if "last_contacted_at" in fields
        else existing.last_contacted_at
    )
    appointment_date = (
        payload.appointment_date
        if "appointment_date" in fields
        else existing.appointment_date
    )
    completed_at = (
        payload.completed_at if "completed_at" in fields else existing.completed_at
    )
    ltfu_reason = payload.ltfu_reason if "ltfu_reason" in fields else existing.ltfu_reason
    contact_attempts = (
        payload.contact_attempts
        if "contact_attempts" in fields and payload.contact_attempts is not None
        else (existing.contact_attempts or 0)
    )

    status_changed = "status" in fields and new_status != existing.status
    if status_changed and new_status == "contacted" and "last_contacted_at" not in fields:
        last_contacted_at = datetime.utcnow()
        contact_attempts += 1
    if status_changed and new_status == "completed" and "completed_at" not in fields:
        completed_at = datetime.utcnow()

    db.execute(
        text(
            """
            UPDATE follow_ups
            SET status = :status,
                notes = :notes,
                due_date = :due_date,
                last_contacted_at = :last_contacted_at,
                appointment_date = :appointment_date,
                completed_at = :completed_at,
                ltfu_reason = :ltfu_reason,
                contact_attempts = :contact_attempts,
                assigned_to = :assigned_to,
                updated_at = NOW()
            WHERE id = :id
            """
        ),
        {
            "id": str(followup_id),
            "status": new_status,
            "notes": notes,
            "due_date": due_date,
            "last_contacted_at": last_contacted_at,
            "appointment_date": appointment_date,
            "completed_at": completed_at,
            "ltfu_reason": ltfu_reason,
            "contact_attempts": contact_attempts,
            "assigned_to": current_user["user_id"],
        },
    )

    new_values = {
        "status": new_status,
        "notes": notes,
        "due_date": str(due_date) if due_date else None,
        "last_contacted_at": str(last_contacted_at) if last_contacted_at else None,
        "appointment_date": str(appointment_date) if appointment_date else None,
        "completed_at": str(completed_at) if completed_at else None,
        "ltfu_reason": ltfu_reason,
        "contact_attempts": contact_attempts,
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
    event_action = "status_changed" if status_changed else "follow_up_updated"
    write_follow_up_event(
        db,
        str(followup_id),
        current_user["user_id"],
        event_action,
        existing.status,
        new_status,
        notes,
        {
            "due_date": str(due_date) if due_date else None,
            "appointment_date": str(appointment_date) if appointment_date else None,
            "completed_at": str(completed_at) if completed_at else None,
            "last_contacted_at": str(last_contacted_at) if last_contacted_at else None,
            "ltfu_reason": ltfu_reason,
            "contact_attempts": contact_attempts,
        },
    )
    db.commit()

    updated = db.execute(
        text(followup_select_sql("WHERE f.id = :id")),
        {"id": str(followup_id)},
    ).fetchone()
    return updated
