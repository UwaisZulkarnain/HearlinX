"""Migrate hospital_admin role values to unhs_coordinator."""
from pathlib import Path
import sys

from sqlalchemy import text

sys.path.append(str(Path(__file__).resolve().parents[1]))

from db.database import SessionLocal


def migrate_unhs_role():
    """Update existing roles and replace the users.role check constraint."""
    db = SessionLocal()
    try:
        db.execute(text("ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check"))
        result = db.execute(
            text("UPDATE users SET role = 'unhs_coordinator' WHERE role = 'hospital_admin'")
        )
        updated_count = result.rowcount or 0

        db.execute(
            text(
                """
                ALTER TABLE users
                ADD CONSTRAINT users_role_check
                CHECK (role IN ('screener', 'coordinator', 'unhs_coordinator', 'moh'))
                """
            )
        )
        db.commit()

        print(f"Updated users: {updated_count}")
        print("Migration successful: hospital_admin role migrated to unhs_coordinator")
        return True
    except Exception as e:
        db.rollback()
        print(f"Migration failed: {e}")
        return False
    finally:
        db.close()


if __name__ == "__main__":
    success = migrate_unhs_role()
    sys.exit(0 if success else 1)
