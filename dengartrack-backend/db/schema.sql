-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─────────────────────────────────────────
-- USERS (all roles live here)
-- ─────────────────────────────────────────
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name       VARCHAR(255) NOT NULL,
    email           VARCHAR(255) UNIQUE NOT NULL,
    password_hash   TEXT NOT NULL,
    role            VARCHAR(50) NOT NULL 
                    CHECK (role IN ('screener','coordinator','unhs_coordinator','moh')),
    hospital_id     UUID,
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- HOSPITALS
-- ─────────────────────────────────────────
CREATE TABLE hospitals (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name            VARCHAR(255) NOT NULL,
    code            VARCHAR(50) UNIQUE NOT NULL,
    state           VARCHAR(100) NOT NULL,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Add FK after both tables exist
ALTER TABLE users 
    ADD CONSTRAINT fk_users_hospital 
    FOREIGN KEY (hospital_id) REFERENCES hospitals(id);

-- ─────────────────────────────────────────
-- BABIES (anonymised)
-- ─────────────────────────────────────────
CREATE TABLE babies (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_id       VARCHAR(50) UNIQUE NOT NULL, -- only ID used externally
    hospital_id     UUID NOT NULL REFERENCES hospitals(id),
    ward            VARCHAR(100),
    date_of_birth   DATE NOT NULL,
    gestational_age INTEGER, -- in weeks
    birth_weight    INTEGER, -- in grams
    gender          CHAR(1) CHECK (gender IN ('M','F')),
    -- Sensitive fields encrypted at application level
    full_name_enc   TEXT,  -- AES-256 encrypted
    ic_number_enc   TEXT,  -- AES-256 encrypted
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- SCREENINGS
-- ─────────────────────────────────────────
CREATE TABLE screenings (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    baby_id         UUID NOT NULL REFERENCES babies(id),
    screener_id     UUID NOT NULL REFERENCES users(id),
    hospital_id     UUID NOT NULL REFERENCES hospitals(id),
    screening_type  VARCHAR(50) NOT NULL 
                    CHECK (screening_type IN ('TEOAE','AABR','ABR')),
    ear_left        VARCHAR(20) CHECK (ear_left IN ('pass','refer','not_tested')),
    ear_right       VARCHAR(20) CHECK (ear_right IN ('pass','refer','not_tested')),
    screening_date  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    attempt_number  INTEGER DEFAULT 1,
    notes           TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- FOLLOW UPS
-- ─────────────────────────────────────────
CREATE TABLE follow_ups (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    baby_id         UUID NOT NULL REFERENCES babies(id),
    screening_id    UUID NOT NULL REFERENCES screenings(id),
    hospital_id     UUID NOT NULL REFERENCES hospitals(id),
    assigned_to     UUID REFERENCES users(id), -- coordinator
    status          VARCHAR(50) DEFAULT 'pending'
                    CHECK (status IN ('pending','contacted','scheduled','appointment_booked','escalated','completed','closed','lost_to_followup')),
    due_date        DATE,
    last_contacted_at TIMESTAMPTZ,
    appointment_date  TIMESTAMPTZ,
    completed_at      TIMESTAMPTZ,
    ltfu_reason       VARCHAR(100),
    contact_attempts  INTEGER DEFAULT 0,
    notes           TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE follow_ups
    ADD CONSTRAINT uq_follow_ups_screening UNIQUE (screening_id);

CREATE TABLE follow_up_events (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    follow_up_id    UUID NOT NULL REFERENCES follow_ups(id) ON DELETE CASCADE,
    user_id         UUID REFERENCES users(id),
    action          VARCHAR(100) NOT NULL,
    from_status     VARCHAR(50),
    to_status       VARCHAR(50),
    notes           TEXT,
    metadata        JSONB,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- AUDIT LOG (immutable — no updates/deletes ever)
-- ─────────────────────────────────────────
CREATE TABLE audit_logs (
    id              BIGSERIAL PRIMARY KEY,
    user_id         UUID NOT NULL REFERENCES users(id),
    action          VARCHAR(100) NOT NULL,
    table_name      VARCHAR(100),
    record_id       UUID,
    old_values      JSONB,
    new_values      JSONB,
    ip_address      INET,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Prevent any updates or deletes on audit_logs
CREATE RULE no_update_audit AS ON UPDATE TO audit_logs DO INSTEAD NOTHING;
CREATE RULE no_delete_audit AS ON DELETE TO audit_logs DO INSTEAD NOTHING;
