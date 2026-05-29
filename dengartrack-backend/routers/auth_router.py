from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import text
from auth.auth import verify_password, create_access_token, hash_password
from auth.models import UserLogin, Token, UserOut
from db.database import get_db
from auth.dependencies import (
    get_current_user, 
    screener_only,
    coordinator_only,
    unhs_coordinator_only,
    moh_only,
    coordinator_or_unhs
)

router = APIRouter(prefix="/auth", tags=["auth"])

@router.post("/login", response_model=Token)
def login(credentials: UserLogin, db: Session = Depends(get_db)):
    """Login endpoint: accepts staff_id and PIN, returns JWT access token."""
    user = db.execute(
        text("SELECT * FROM users WHERE staff_id = :staff_id AND is_active = true"),
        {"staff_id": credentials.staff_id}
    ).fetchone()

    if not user or not verify_password(credentials.pin, user.pin_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid staff ID or PIN"
        )

    if credentials.hospital_code and user.hospital_id is not None:
        hospital = db.execute(
            text("SELECT id FROM hospitals WHERE code = :code"),
            {"code": credentials.hospital_code}
        ).fetchone()

        if not hospital or str(user.hospital_id) != str(hospital.id):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Hospital tidak sepadan."
            )

    token = create_access_token({
        "user_id": str(user.id),
        "role": user.role,
        "hospital_id": str(user.hospital_id) if user.hospital_id else None,
        "full_name": user.full_name,
        "staff_id": getattr(user, "staff_id", None),
    })

    return {"access_token": token, "token_type": "bearer"}

@router.get("/me", response_model=UserOut)
def get_me(current_user: dict = Depends(get_current_user), db: Session = Depends(get_db)):
    """Get current authenticated user info."""
    user = db.execute(
        text("SELECT * FROM users WHERE id = :id"),
        {"id": current_user["user_id"]}
    ).fetchone()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

# ─────────────────────────────────────────────────────────
# EXAMPLE PROTECTED ROUTES - Demonstrating RBAC
# ─────────────────────────────────────────────────────────

@router.get("/screener/dashboard")
def screener_dashboard(current_user: dict = Depends(screener_only)):
    """Example: Only screeners can access this."""
    return {
        "message": "Welcome Screener",
        "user_id": current_user["user_id"],
        "role": current_user["role"]
    }

@router.get("/coordinator/dashboard")
def coordinator_dashboard(current_user: dict = Depends(coordinator_only)):
    """Example: Only coordinators can access this."""
    return {
        "message": "Welcome Coordinator",
        "user_id": current_user["user_id"],
        "role": current_user["role"]
    }

@router.get("/unhs/dashboard")
def unhs_dashboard(current_user: dict = Depends(unhs_coordinator_only)):
    """Example: Only UNHS coordinators can access this."""
    return {
        "message": "Welcome UNHS Coordinator",
        "user_id": current_user["user_id"],
        "role": current_user["role"]
    }

@router.get("/moh/dashboard")
def moh_dashboard(current_user: dict = Depends(moh_only)):
    """Example: Only MOH users can access this."""
    return {
        "message": "Welcome MOH User",
        "user_id": current_user["user_id"],
        "role": current_user["role"]
    }

@router.get("/management/reports")
def management_reports(current_user: dict = Depends(coordinator_or_unhs)):
    """Example: Coordinators and UNHS coordinators can access this."""
    return {
        "message": "Management Reports",
        "access_by": current_user["role"],
        "user_id": current_user["user_id"]
    }
