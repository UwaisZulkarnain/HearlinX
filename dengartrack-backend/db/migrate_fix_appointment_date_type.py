"""Fix appointment_date column from DATE to TIMESTAMPTZ to preserve time."""
from pathlib import Path
import sys

from sqlalchemy import text

sys.path.append(str(Path(__file__).resolve().parents[1]))

from db.database import SessionLocal


def migrate_fix_appointment_date_type():
    """Change appointment_date from DATE to TIMESTAMPTZ if needed."""
    db = SessionLocal()
    try:
        # Check if column is currently DATE type
        result = db.execute(
            text(
                """
                SELECT data_type
                FROM information_schema.columns
                WHERE table_name = 'follow_ups'
                AND column_name = 'appointment_date'
                """
            )
        ).fetchone()

        if result and result[0] == 'date':
            print(
                "appointment_date is DATE type. "
                "Casting to TIMESTAMPTZ..."
            )
            db.execute(
                text(
                    """
                    ALTER TABLE follow_ups
                    ALTER COLUMN appointment_date TYPE TIMESTAMPTZ
                    USING appointment_date::timestamptz
                    """
                )
            )
            db.commit()
            print(
                "Migration successful: "
                "appointment_date is now TIMESTAMPTZ"
            )
        else:
            print(
                f"appointment_date is already {result[0] if result else 'unknown'}, "
                "no change needed."
            )
        return True
    except Exception as e:
        db.rollback()
        print(f"Migration failed: {e}")
        return False
    finally:
        db.close()


if __name__ == "__main__":
    success = migrate_fix_appointment_date_type()
    sys.exit(0 if success else 1)