"""Make password_hash column nullable."""
from sqlalchemy import text
from db.database import SessionLocal

def make_password_hash_nullable():
    """Make password_hash column nullable in users table."""
    db = SessionLocal()
    try:
        db.execute(text("""
            ALTER TABLE users 
            ALTER COLUMN password_hash DROP NOT NULL;
        """))
        db.commit()
        print("✓ password_hash column is now nullable")
        return True
    except Exception as e:
        db.rollback()
        print(f"✗ Failed: {e}")
        return False
    finally:
        db.close()

if __name__ == "__main__":
    make_password_hash_nullable()
