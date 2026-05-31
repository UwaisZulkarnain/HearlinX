"""Smoke test the RUJUK-to-LTFU backend workflow.

This uses the local database configured in dtbackend.env and calls the same
route functions used by the API. It avoids FastAPI TestClient because the
current local starlette/httpx versions are incompatible.
"""
from datetime import date
import sys
import uuid

from sqlalchemy import text

from auth.models import BabyCreate, FollowUpUpdate, ScreeningCreate
from db.database import SessionLocal
from routers.babies import create_baby
from routers.followups import list_followups, update_followup
from routers.reports import monthly_report, national_summary
from routers.screenings import create_screening


TEST_WARD = "LTFU Smoke Test"
TEST_SCREENING_NOTES = "LTFU smoke test RUJUK screening"


def cleanup_smoke_data(db):
    db.execute(
        text(
            """
            DELETE FROM follow_ups f
            USING screenings s
            WHERE f.screening_id = s.id
              AND s.notes = :notes
            """
        ),
        {"notes": TEST_SCREENING_NOTES},
    )
    db.execute(
        text("DELETE FROM screenings WHERE notes = :notes"),
        {"notes": TEST_SCREENING_NOTES},
    )
    db.execute(
        text("DELETE FROM babies WHERE ward = :ward AND full_name_enc = :name"),
        {"ward": TEST_WARD, "name": "LTFU Smoke Test Baby"},
    )
    db.commit()


def get_user(db, staff_id: str) -> dict:
    user = db.execute(
        text("SELECT id, role, hospital_id FROM users WHERE staff_id = :staff_id"),
        {"staff_id": staff_id},
    ).fetchone()
    if not user:
        raise RuntimeError(f"Seed user not found: {staff_id}. Run python seed.py first.")
    return {
        "user_id": str(user.id),
        "role": user.role,
        "hospital_id": str(user.hospital_id) if user.hospital_id else None,
    }


def main():
    db = SessionLocal()
    try:
        cleanup_smoke_data(db)
        coordinator = get_user(db, "COO001HKL")
        screener = get_user(db, "SCR001HKL")
        moh = get_user(db, "MOH001")

        baby = create_baby(
            BabyCreate(
                ward="LTFU Smoke Test",
                date_of_birth=date.today(),
                gestational_age=39,
                birth_weight=3100,
                gender="F",
                full_name_enc="LTFU Smoke Test Baby",
                ic_number_enc="TEST-LTFU",
            ),
            current_user=coordinator,
            db=db,
        )

        screening = create_screening(
            ScreeningCreate(
                baby_id=baby.id,
                screening_type="TEOAE",
                ear_left="pass",
                ear_right="refer",
                attempt_number=1,
                notes=TEST_SCREENING_NOTES,
            ),
            current_user=screener,
            db=db,
        )

        followups = list_followups(current_user=coordinator, db=db)
        followup = next(
            (
                item
                for item in followups
                if str(item.screening_id) == str(screening.id)
                and str(item.baby_id) == str(baby.id)
            ),
            None,
        )
        if followup is None:
            raise AssertionError("RUJUK screening did not create a follow-up task")
        if followup.status != "pending":
            raise AssertionError(f"Expected pending follow-up, got {followup.status}")

        updated = update_followup(
            uuid.UUID(str(followup.id)),
            FollowUpUpdate(status="lost_to_followup", notes="Smoke test LTFU closeout"),
            current_user=coordinator,
            db=db,
        )
        if updated.status != "lost_to_followup" or updated.urgency != "ltfu":
            raise AssertionError(f"LTFU update did not return expected state: {updated}")

        today = date.today()
        monthly = monthly_report(year=today.year, month=today.month, current_user=coordinator, db=db)
        if monthly.total_ltfu < 1:
            raise AssertionError(f"Monthly report did not count LTFU: {monthly}")

        national = national_summary(year=today.year, month=today.month, current_user=moh, db=db)
        if national.total_ltfu < 1:
            raise AssertionError(f"National report did not count LTFU: {national}")

        print("LTFU workflow smoke test passed")
        print(f"Baby: {baby.system_id}")
        print(f"Screening: {screening.id}")
        print(f"Follow-up: {followup.id} -> lost_to_followup")
        print(f"Monthly LTFU count: {monthly.total_ltfu}")
        print(f"National LTFU count: {national.total_ltfu}")
    finally:
        cleanup_smoke_data(db)
        db.close()


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"LTFU workflow smoke test failed: {exc}")
        sys.exit(1)
