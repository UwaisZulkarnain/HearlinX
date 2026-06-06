-- Migration: Fix follow_ups status CHECK constraint
-- Date: 2026-06-06
-- Issue: appointment_booked and escalated were missing from CHECK constraint
-- on the deployed database (schema.sql is already correct).

-- Drop the old constraint (safe, no data loss)
ALTER TABLE follow_ups DROP CONSTRAINT IF EXISTS follow_ups_status_check;

-- Add the corrected constraint with all valid statuses
ALTER TABLE follow_ups ADD CONSTRAINT follow_ups_status_check
    CHECK (status IN (
        'pending',
        'contacted', 
        'scheduled',
        'appointment_booked',
        'escalated',
        'completed',
        'closed',
        'lost_to_followup'
    ));