"""Migrate follow-up constraints for the LTFU workflow."""
from pathlib import Path
import sys

from sqlalchemy import text

sys.path.append(str(Path(__file__).resolve().parents[1]))

from db.database import SessionLocal


def migrate_ltfu_followups():
    """Allow all app follow-up statuses and prevent duplicate screening tasks."""
    db = SessionLocal()
    try:
        db.execute(text("ALTER TABLE follow_ups DROP CONSTRAINT IF EXISTS follow_ups_status_check"))
        db.execute(
            text(
                """
                ALTER TABLE follow_ups
                ADD CONSTRAINT follow_ups_status_check
                CHECK (status IN (
                    'pending',
                    'contacted',
                    'scheduled',
                    'appointment_booked',
                    'escalated',
                    'completed',
                    'closed',
                    'lost_to_followup'
                ))
                """
            )
        )

        duplicates = db.execute(
            text(
                """
                SELECT screening_id, COUNT(*) AS count
                FROM follow_ups
                GROUP BY screening_id
                HAVING COUNT(*) > 1
                """
            )
        ).fetchall()
        if duplicates:
            duplicate_ids = ", ".join(str(row.screening_id) for row in duplicates)
            raise RuntimeError(
                "Duplicate follow-up rows exist for screening_id: "
                f"{duplicate_ids}. Clean these before adding the unique constraint."
            )

        db.execute(
            text(
                """
                ALTER TABLE follow_ups
                ADD COLUMN IF NOT EXISTS last_contacted_at TIMESTAMPTZ,
                ADD COLUMN IF NOT EXISTS appointment_date TIMESTAMPTZ,
                ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ,
                ADD COLUMN IF NOT EXISTS ltfu_reason VARCHAR(100),
                ADD COLUMN IF NOT EXISTS contact_attempts INTEGER DEFAULT 0
                """
            )
        )
        db.execute(
            text(
                """
                UPDATE follow_ups
                SET contact_attempts = 0
                WHERE contact_attempts IS NULL
                """
            )
        )

        db.execute(
            text(
                """
                ALTER TABLE follow_ups
                DROP CONSTRAINT IF EXISTS uq_follow_ups_screening
                """
            )
        )
        db.execute(
            text(
                """
                ALTER TABLE follow_ups
                ADD CONSTRAINT uq_follow_ups_screening UNIQUE (screening_id)
                """
            )
        )
        db.execute(
            text(
                """
                CREATE TABLE IF NOT EXISTS follow_up_events (
                    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                    follow_up_id UUID NOT NULL REFERENCES follow_ups(id) ON DELETE CASCADE,
                    user_id UUID REFERENCES users(id),
                    action VARCHAR(100) NOT NULL,
                    from_status VARCHAR(50),
                    to_status VARCHAR(50),
                    notes TEXT,
                    metadata JSONB,
                    created_at TIMESTAMPTZ DEFAULT NOW()
                )
                """
            )
        )
        db.execute(
            text(
                """
                CREATE INDEX IF NOT EXISTS idx_follow_up_events_follow_up
                ON follow_up_events(follow_up_id, created_at)
                """
            )
        )

        db.commit()
        print("Migration successful: LTFU follow-up statuses and uniqueness are ready")
        return True
    except Exception as e:
        db.rollback()
        print(f"Migration failed: {e}")
        return False
    finally:
        db.close()


if __name__ == "__main__":
    success = migrate_ltfu_followups()
    sys.exit(0 if success else 1)
