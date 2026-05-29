from datetime import datetime
import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import text
from sqlalchemy.orm import Session

from auth.dependencies import get_current_user, coordinator_only
from auth.models import BabyCreate, BabyOut
from db.database import get_db

router = APIRouter(prefix="/babies", tags=["babies"])


def write_audit_log(
    db: Session,
    user_id: str,
    action: str,
    table_name: str,
    record_id: str,
    new_values: dict,
):
    db.connection().exec_driver_sql(
        """
        INSERT INTO audit_logs (user_id, action, table_name, record_id, new_values, created_at)
        VALUES (%(user_id)s, %(action)s, %(table_name)s, %(record_id)s, CAST(%(new_values)s AS jsonb), NOW())
        """,
        {
            "user_id": user_id,
            "action": action,
            "table_name": table_name,
            "record_id": record_id,
            "new_values": __import__("json").dumps(new_values),
        },
    )


def generate_system_id(db: Session) -> str:
    prefix = datetime.utcnow().strftime("HLX%y%m%d")
    while True:
        candidate = f"{prefix}-{uuid.uuid4().hex[:6].upper()}"
        existing = db.execute(
            text("SELECT 1 FROM babies WHERE system_id = :system_id"),
            {"system_id": candidate},
        ).fetchone()
        if not existing:
            return candidate


@router.post("/", response_model=BabyOut, status_code=status.HTTP_201_CREATED, tags=["babies"])
def create_baby(
    payload: BabyCreate,
    current_user: dict = Depends(coordinator_only),
    db: Session = Depends(get_db),
):
    baby_id = str(uuid.uuid4())
    system_id = generate_system_id(db)
    hospital_id = current_user["hospital_id"]

    db.execute(
        text(
            """
            INSERT INTO babies (
                id, system_id, hospital_id, ward, date_of_birth, gestational_age,
                birth_weight, gender, full_name_enc, ic_number_enc, created_at
            )
            VALUES (
                :id, :system_id, :hospital_id, :ward, :date_of_birth, :gestational_age,
                :birth_weight, :gender, :full_name_enc, :ic_number_enc, NOW()
            )
            """
        ),
        {
            "id": baby_id,
            "system_id": system_id,
            "hospital_id": hospital_id,
            "ward": payload.ward,
            "date_of_birth": payload.date_of_birth,
            "gestational_age": payload.gestational_age,
            "birth_weight": payload.birth_weight,
            "gender": payload.gender,
            "full_name_enc": payload.full_name_enc,
            "ic_number_enc": payload.ic_number_enc,
        },
    )

    write_audit_log(
        db,
        current_user["user_id"],
        "CREATE",
        "babies",
        baby_id,
        {
            "system_id": system_id,
            "hospital_id": hospital_id,
            "ward": payload.ward,
            "date_of_birth": str(payload.date_of_birth),
            "gestational_age": payload.gestational_age,
            "birth_weight": payload.birth_weight,
            "gender": payload.gender,
        },
    )
    db.commit()

    baby = db.execute(
        text("SELECT * FROM babies WHERE id = :id"),
        {"id": baby_id},
    ).fetchone()
    return baby


@router.get("/{system_id}", response_model=BabyOut, tags=["babies"])
def get_baby_by_system_id(
    system_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    baby = db.execute(
        text("SELECT * FROM babies WHERE system_id = :system_id"),
        {"system_id": system_id},
    ).fetchone()

    if not baby:
        raise HTTPException(status_code=404, detail="Baby not found")

    role = current_user.get("role")
    if role in ["screener", "coordinator"]:
        if str(baby.hospital_id) != current_user.get("hospital_id"):
            raise HTTPException(status_code=403, detail="Cannot access baby from another hospital")
    elif role in ["unhs_coordinator", "moh"]:
        raise HTTPException(status_code=403, detail="Summary-only role cannot access baby records")
    else:
        raise HTTPException(status_code=403, detail="Invalid role")

    return baby
