from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from auth.auth import decode_token
from db.database import get_db

security = HTTPBearer()

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security), db: Session = Depends(get_db)):
    token = credentials.credentials
    payload = decode_token(token)
    if not payload:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    return payload

def require_role(*roles):
    def role_checker(current_user: dict = Depends(get_current_user)):
        if current_user.get("role") not in roles:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")
        return current_user
    return role_checker

# Role dependencies — use these in your routes
screener_only       = require_role("screener")
coordinator_only    = require_role("coordinator")
unhs_coordinator_only = require_role("unhs_coordinator")
moh_only            = require_role("moh")
coordinator_or_unhs = require_role("coordinator", "unhs_coordinator")
hospital_summary_roles = require_role("coordinator", "unhs_coordinator")

# Backward-compatible aliases for routers that will be renamed in a later pass.
hospital_admin_only = unhs_coordinator_only
coordinator_or_admin = coordinator_or_unhs
