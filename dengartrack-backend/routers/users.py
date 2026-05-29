from datetime import datetime
import json
import uuid
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import text
from sqlalchemy.orm import Session

from auth.auth import hash_password
from auth.dependencies import require_role
from db.database import get_db

router = APIRouter(tags=["users"])


class UserCreate(BaseModel):
    full_name: str
    email: str
    staff_id: str
    pin: str
    role: str
    hospital_id: Optional[uuid.UUID] = None


class UserUpdate(BaseModel):
    pin: Optional[str] = None
    is_active: Optional[bool] = None


def write_audit_log(
    db: Session,
    actor_user_id: str,
    action: str,
    target_user_id: str,
    new_values: dict,
):
    db.connection().exec_driver_sql(
        """
        INSERT INTO audit_logs (user_id, action, table_name, record_id, new_values, created_at)
        VALUES (%(user_id)s, %(action)s, %(table_name)s, %(record_id)s, CAST(%(new_values)s AS jsonb), NOW())
        """,
        {
            "user_id": actor_user_id,
            "action": action,
            "table_name": "users",
            "record_id": target_user_id,
            "new_values": json.dumps(new_values),
        },
    )


def serialize_user(row):
    return {
        "id": row.id,
        "full_name": row.full_name,
        "email": row.email,
        "staff_id": row.staff_id,
        "role": row.role,
        "hospital_id": row.hospital_id,
        "hospital_name": getattr(row, "hospital_name", None),
        "is_active": row.is_active,
        "created_at": row.created_at,
        "updated_at": row.updated_at,
    }


@router.post("/", status_code=status.HTTP_201_CREATED)
def create_user(
    payload: UserCreate,
    current_user: dict = Depends(require_role("coordinator", "unhs_coordinator")),
    db: Session = Depends(get_db),
):
    actor_role = current_user["role"]

    if payload.role in ["moh", "unhs_coordinator"]:
        raise HTTPException(status_code=403, detail="Cannot create this role via API")

    if actor_role == "coordinator":
        if payload.role != "screener":
            raise HTTPException(status_code=403, detail="Coordinator can only create screeners")
        hospital_id = current_user.get("hospital_id")
        if not hospital_id:
            raise HTTPException(status_code=403, detail="Coordinator hospital is required")
    else:
        if payload.role != "coordinator":
            raise HTTPException(status_code=403, detail="UNHS can only create coordinators")
        if payload.hospital_id is None:
            raise HTTPException(status_code=400, detail="hospital_id is required")

        hospital = db.execute(
            text("SELECT id FROM hospitals WHERE id = :id"),
            {"id": str(payload.hospital_id)},
        ).fetchone()
        if not hospital:
            raise HTTPException(status_code=400, detail="Hospital not found")
        hospital_id = str(payload.hospital_id)

    duplicate = db.execute(
        text("SELECT id FROM users WHERE staff_id = :staff_id LIMIT 1"),
        {"staff_id": payload.staff_id},
    ).fetchone()
    if duplicate:
        raise HTTPException(status_code=400, detail="staff_id already exists")

    user_id = str(uuid.uuid4())
    db.execute(
        text(
            """
            INSERT INTO users (
                id, full_name, email, role, hospital_id, is_active, staff_id, pin_hash
            )
            VALUES (
                :id, :full_name, :email, :role, :hospital_id, true, :staff_id, :pin_hash
            )
            """
        ),
        {
            "id": user_id,
            "full_name": payload.full_name,
            "email": payload.email,
            "role": payload.role,
            "hospital_id": hospital_id,
            "staff_id": payload.staff_id,
            "pin_hash": hash_password(payload.pin),
        },
    )

    write_audit_log(
        db,
        current_user["user_id"],
        "CREATE_USER",
        user_id,
        {
            "user_id": user_id,
            "created_by": current_user["user_id"],
            "role": payload.role,
            "hospital_id": hospital_id,
            "timestamp": datetime.utcnow().isoformat(),
        },
    )
    db.commit()

    created = db.execute(
        text(
            """
            SELECT u.*, h.name AS hospital_name
            FROM users u
            LEFT JOIN hospitals h ON h.id = u.hospital_id
            WHERE u.id = :id
            """
        ),
        {"id": user_id},
    ).fetchone()
    return serialize_user(created)


@router.get("/")
def list_users(
    current_user: dict = Depends(require_role("coordinator", "unhs_coordinator")),
    db: Session = Depends(get_db),
):
    if current_user["role"] == "coordinator":
        rows = db.execute(
            text(
                """
                SELECT u.*, h.name AS hospital_name
                FROM users u
                LEFT JOIN hospitals h ON h.id = u.hospital_id
                WHERE u.hospital_id = :hospital_id
                ORDER BY u.role, u.full_name
                """
            ),
            {"hospital_id": current_user["hospital_id"]},
        ).fetchall()
    else:
        rows = db.execute(
            text(
                """
                SELECT u.*, h.name AS hospital_name
                FROM users u
                LEFT JOIN hospitals h ON h.id = u.hospital_id
                ORDER BY h.name NULLS LAST, u.role, u.full_name
                """
            )
        ).fetchall()

    return [serialize_user(row) for row in rows]


@router.patch("/{user_id}")
def update_user(
    user_id: uuid.UUID,
    payload: UserUpdate,
    current_user: dict = Depends(require_role("coordinator", "unhs_coordinator")),
    db: Session = Depends(get_db),
):
    if payload.pin is None and payload.is_active is None:
        raise HTTPException(status_code=400, detail="No update fields provided")

    if payload.is_active is True:
        raise HTTPException(status_code=400, detail="Users can only be deactivated")

    target = db.execute(
        text("SELECT * FROM users WHERE id = :id"),
        {"id": str(user_id)},
    ).fetchone()
    if not target:
        raise HTTPException(status_code=404, detail="User not found")

    if current_user["role"] == "coordinator":
        if str(target.hospital_id) != current_user.get("hospital_id"):
            raise HTTPException(status_code=403, detail="Cannot update users from another hospital")
    else:
        if target.role != "coordinator":
            raise HTTPException(status_code=403, detail="UNHS can only update coordinators")

    update_values = {"id": str(user_id)}
    set_clauses = ["updated_at = NOW()"]
    audit_actions = []
    audit_values = {
        "actor": current_user["user_id"],
        "target_user_id": str(user_id),
        "timestamp": datetime.utcnow().isoformat(),
    }

    if payload.pin is not None:
        set_clauses.append("pin_hash = :pin_hash")
        update_values["pin_hash"] = hash_password(payload.pin)
        audit_actions.append("RESET_PIN")

    if payload.is_active is False:
        set_clauses.append("is_active = false")
        audit_actions.append("DEACTIVATE_USER")

    db.execute(
        text(f"UPDATE users SET {', '.join(set_clauses)} WHERE id = :id"),
        update_values,
    )

    for action in audit_actions:
        write_audit_log(
            db,
            current_user["user_id"],
            action,
            str(user_id),
            audit_values,
        )

    db.commit()

    updated = db.execute(
        text(
            """
            SELECT u.*, h.name AS hospital_name
            FROM users u
            LEFT JOIN hospitals h ON h.id = u.hospital_id
            WHERE u.id = :id
            """
        ),
        {"id": str(user_id)},
    ).fetchone()
    return serialize_user(updated)
