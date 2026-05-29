from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session

from db.database import get_db

router = APIRouter(tags=["hospitals"])


@router.get("/")
def list_hospitals(db: Session = Depends(get_db)):
    rows = db.execute(
        text(
            """
            SELECT
                id,
                name,
                code,
                state,
                TRUE AS is_active
            FROM hospitals
            ORDER BY name ASC
            """
        )
    ).fetchall()

    return [dict(row._mapping) for row in rows]
