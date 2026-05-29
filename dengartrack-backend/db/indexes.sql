CREATE INDEX idx_screenings_hospital ON screenings(hospital_id);
CREATE INDEX idx_screenings_date ON screenings(screening_date);
CREATE INDEX idx_screenings_baby ON screenings(baby_id);
CREATE INDEX idx_followups_hospital ON follow_ups(hospital_id);
CREATE INDEX idx_followups_status ON follow_ups(status);
CREATE INDEX idx_audit_user ON audit_logs(user_id);
CREATE INDEX idx_audit_created ON audit_logs(created_at);