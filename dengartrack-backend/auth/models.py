from pydantic import BaseModel
from typing import Literal, Optional
import uuid
from datetime import datetime, date
from enum import Enum

RoleName = Literal["screener", "coordinator", "unhs_coordinator", "moh"]

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    user_id: Optional[str] = None
    role: Optional[RoleName] = None
    hospital_id: Optional[str] = None

class UserLogin(BaseModel):
    staff_id: str
    pin: str
    hospital_code: Optional[str] = None

class UserOut(BaseModel):
    id: uuid.UUID
    full_name: str
    email: str
    staff_id: Optional[str] = None
    role: RoleName
    hospital_id: Optional[uuid.UUID]
    is_active: bool

    class Config:
        from_attributes = True

# ─────────────────────────────────────────────────────────
# SCREENING MODELS
# ─────────────────────────────────────────────────────────

class EarResult(str, Enum):
    """Valid ear screening results."""
    pass_result = "pass"
    refer = "refer"
    not_tested = "not_tested"

class ScreeningType(str, Enum):
    """Valid screening types."""
    TEOAE = "TEOAE"
    AABR = "AABR"
    ABR = "ABR"

class ScreeningCreate(BaseModel):
    """Request model for creating a screening."""
    baby_id: uuid.UUID
    screening_type: ScreeningType
    ear_left: EarResult
    ear_right: EarResult
    attempt_number: Optional[int] = 1
    notes: Optional[str] = None

class ScreeningOut(BaseModel):
    """Response model for screening record."""
    id: uuid.UUID
    baby_id: uuid.UUID
    baby_system_id: Optional[str] = None
    screener_id: uuid.UUID
    hospital_id: uuid.UUID
    screening_type: str
    ear_left: str
    ear_right: str
    screening_date: datetime
    attempt_number: int
    notes: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True

class ShiftSummary(BaseModel):
    """Today's shift summary for screener."""
    screener_id: uuid.UUID
    screener_name: str
    screening_date: str
    total_screened: int
    total_pass: int
    total_refer: int
    total_not_tested: int


class BabyCreate(BaseModel):
    ward: Optional[str] = None
    date_of_birth: date
    gestational_age: Optional[int] = None
    birth_weight: Optional[int] = None
    gender: Optional[str] = None
    full_name_enc: Optional[str] = None
    ic_number_enc: Optional[str] = None


class BabyOut(BaseModel):
    id: uuid.UUID
    system_id: str
    hospital_id: uuid.UUID
    ward: Optional[str]
    date_of_birth: date
    gestational_age: Optional[int]
    birth_weight: Optional[int]
    gender: Optional[str]
    full_name_enc: Optional[str]
    ic_number_enc: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True


class FollowUpStatus(str, Enum):
    pending = "pending"
    contacted = "contacted"
    appointment_booked = "appointment_booked"
    escalated = "escalated"
    closed = "closed"
    scheduled = "scheduled"
    completed = "completed"
    lost_to_followup = "lost_to_followup"


class FollowUpOut(BaseModel):
    id: uuid.UUID
    baby_id: uuid.UUID
    baby_system_id: Optional[str] = None
    screening_id: uuid.UUID
    hospital_id: uuid.UUID
    assigned_to: Optional[uuid.UUID]
    status: str
    due_date: Optional[date]
    notes: Optional[str]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class FollowUpUpdate(BaseModel):
    status: FollowUpStatus
    notes: Optional[str] = None
    due_date: Optional[date] = None


class MonthlyReportSummary(BaseModel):
    hospital_id: uuid.UUID
    hospital_name: str
    year: int
    month: int
    total_screenings: int
    total_pass: int
    total_refer: int
    total_not_tested: int


class NationalHospitalSummary(BaseModel):
    hospital_id: uuid.UUID
    hospital_name: str
    total_screenings: int
    total_pass: int
    total_refer: int
    total_not_tested: int


class NationalSummaryOut(BaseModel):
    year: int
    month: int
    total_hospitals: int
    total_screenings: int
    total_pass: int
    total_refer: int
    total_not_tested: int
    hospitals: list[NationalHospitalSummary]


class AuditLogEntry(BaseModel):
    id: int
    action: str
    table_name: Optional[str]
    actor_name: str
    created_at: datetime
