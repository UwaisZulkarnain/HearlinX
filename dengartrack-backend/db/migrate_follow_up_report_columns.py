"""Add follow-up report columns required by dashboard report queries."""
from pathlib import Path
import sys

from sqlalchemy import text

sys.path.append(str(Path(__file__).resolve().parents[1]))

from db.database import SessionLocal


def migrate_follow_up_report_columns():
    """Add report-facing follow-up columns if they are missing."""
    db = SessionLocal()
    try:
        db.execute(
            text(
                """
                ALTER TABLE follow_ups
                ADD COLUMN IF NOT EXISTS last_contacted_at TIMESTAMP,
                ADD COLUMN IF NOT EXISTS appointment_date DATE,
                ADD COLUMN IF NOT EXISTS completed_at TIMESTAMP,
                ADD COLUMN IF NOT EXISTS ltfu_reason TEXT,
                ADD COLUMN IF NOT EXISTS contact_attempts INTEGER
                """
            )
        )
        db.commit()
        print("Migration successful: follow-up report columns are ready")
        return True
    except Exception as e:
        db.rollback()
        print(f"Migration failed: {e}")
        return False
    finally:
        db.close()


if __name__ == "__main__":
    success = migrate_follow_up_report_columns()
    sys.exit(0 if success else 1)
