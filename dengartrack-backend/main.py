from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), 'dtbackend.env'))

from routers.auth_router import router as auth_router
from routers.audit_logs import router as audit_logs_router
from routers.babies import router as babies_router
from routers.followups import router as followups_router
from routers.hospitals import router as hospitals_router
from routers.reports import router as reports_router
from routers.screenings import router as screenings_router
from routers.users import router as users_router

app = FastAPI(
    title="DengarTrack API", 
    version="1.0.0",
    generate_unique_id_function=lambda route: route.name
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth_router)
app.include_router(audit_logs_router)
app.include_router(babies_router)
app.include_router(followups_router)
app.include_router(hospitals_router, prefix="/hospitals")
app.include_router(reports_router)
app.include_router(screenings_router)
app.include_router(users_router, prefix="/users")

@app.get("/")
def root():
    return {"message": "DengarTrack API running", "version": "1.0.0"}
