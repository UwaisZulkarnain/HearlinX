"""Clear old test data."""
from sqlalchemy import text
from db.database import SessionLocal

db = SessionLocal()
try:
    db.execute(text('DELETE FROM screenings'))
    db.execute(text("DELETE FROM babies WHERE system_id IN ('BABY001','BABY002','BABY003')"))
    db.commit()
    print('✓ Cleared old test data (screenings and babies)')
finally:
    db.close()
