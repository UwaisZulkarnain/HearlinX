import json
import uuid

from sqlalchemy import text
from sqlalchemy.orm import Session


def ensure_follow_up_events_table(db: Session) -> None:
    db.execute(
        text(
            """
            CREATE TABLE IF NOT EXISTS follow_up_events (
                id UUID PRIMARY KEY,
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


def write_follow_up_event(
    db: Session,
    followup_id: str,
    user_id: str,
    action: str,
    from_status: str | None,
    to_status: str | None,
    notes: str | None,
    metadata: dict | None = None,
) -> None:
    ensure_follow_up_events_table(db)
    db.connection().exec_driver_sql(
        """
        INSERT INTO follow_up_events (
            id, follow_up_id, user_id, action, from_status, to_status, notes, metadata, created_at
        )
        VALUES (
            %(id)s, %(follow_up_id)s, %(user_id)s, %(action)s,
            %(from_status)s, %(to_status)s, %(notes)s, CAST(%(metadata)s AS jsonb), NOW()
        )
        """,
        {
            "id": str(uuid.uuid4()),
            "follow_up_id": followup_id,
            "user_id": user_id,
            "action": action,
            "from_status": from_status,
            "to_status": to_status,
            "notes": notes,
            "metadata": json.dumps(metadata or {}),
        },
    )
