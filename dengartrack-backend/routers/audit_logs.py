from fastapi import APIRouter, Depends, Query
from sqlalchemy import text
from sqlalchemy.orm import Session

from auth.dependencies import unhs_coordinator_only
from auth.models import AuditLogEntry
from db.database import get_db

router = APIRouter(prefix="/audit-logs", tags=["audit_logs"])


@router.get("/recent", response_model=list[AuditLogEntry])
def recent_hospital_activity(
    limit: int = Query(default=20, ge=1, le=50),
    current_user: dict = Depends(unhs_coordinator_only),
    db: Session = Depends(get_db),
):
    rows = db.execute(
        text(
            """
            SELECT
                a.id,
                a.action,
                a.table_name,
                a.created_at,
                u.full_name AS actor_name
            FROM audit_logs a
            JOIN users u ON u.id = a.user_id
            ORDER BY a.created_at DESC
            LIMIT :limit
            """
        ),
        {"limit": limit},
    ).fetchall()
    return rows
