"""Migration script to add staff_id and pin_hash columns to users table."""
from sqlalchemy import text
from db.database import SessionLocal
import sys

def migrate_database():
    """Add staff_id and pin_hash columns to users table."""
    db = SessionLocal()
    try:
        db.execute(text("""
            ALTER TABLE users 
            ADD COLUMN IF NOT EXISTS staff_id VARCHAR(50) UNIQUE,
            ADD COLUMN IF NOT EXISTS pin_hash TEXT;
        """))
        db.commit()
        print("✓ Migration successful: staff_id and pin_hash columns added to users table")
        return True
    except Exception as e:
        db.rollback()
        print(f"✗ Migration failed: {e}")
        return False
    finally:
        db.close()

if __name__ == "__main__":
    success = migrate_database()
    sys.exit(0 if success else 1)
