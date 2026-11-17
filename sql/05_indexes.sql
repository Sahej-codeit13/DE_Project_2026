-- =====================================================
-- CP3: Performance Optimization Indexes
-- PostgreSQL 15+
-- =====================================================

SET search_path TO linkedin;

-- 1. POSITIONS: member history and current positions
CREATE INDEX IF NOT EXISTS idx_positions_member_start
ON positions (member_id, start_date)
INCLUDE (company_id, end_date, title, employment_type);

CREATE INDEX IF NOT EXISTS idx_positions_current_member
ON positions (member_id)
INCLUDE (company_id, title, start_date)
WHERE end_date IS NULL;

CREATE INDEX IF NOT EXISTS idx_positions_company_current
ON positions (company_id)
INCLUDE (member_id, start_date)
WHERE end_date IS NULL;

-- 2. CONNECTIONS: lookups from both sides
CREATE INDEX IF NOT EXISTS idx_connections_member_a_recent
ON connections (member_a, connected_at DESC)
INCLUDE (member_b);

CREATE INDEX IF NOT EXISTS idx_connections_member_b_recent
ON connections (member_b, connected_at DESC)
INCLUDE (member_a);

-- 3. MEMBER SKILLS: skill lookup and endorsement ranking
CREATE INDEX IF NOT EXISTS idx_member_skills_skill_endorsements
ON member_skills (skill_id, endorsements DESC, member_id);

-- 4. JOB SKILLS: reverse skill lookup
CREATE INDEX IF NOT EXISTS idx_job_skills_skill_job
ON job_skills (skill_id, job_id);

-- 5. JOBS: company and status filtering
CREATE INDEX IF NOT EXISTS idx_jobs_company_status
ON jobs (company_id, status);

-- 6. JOBS: expired open jobs
CREATE INDEX IF NOT EXISTS idx_jobs_open_closes
ON jobs (closes_at)
WHERE status = 'OPEN';

-- 7. APPLICATIONS: member application history
CREATE INDEX IF NOT EXISTS idx_applications_member_recent
ON applications (member_id, applied_at DESC)
INCLUDE (application_id, job_id, status);

-- 8. APPLICATIONS: company job application lookup
CREATE INDEX IF NOT EXISTS idx_applications_job_applied
ON applications (job_id, applied_at);

-- 9. APPLICATIONS: chronological pagination
CREATE INDEX IF NOT EXISTS idx_applications_recent
ON applications (applied_at DESC)
INCLUDE (application_id, job_id, member_id, status);

-- 10. APPLICATIONS: hired application filtering
CREATE INDEX IF NOT EXISTS idx_applications_hired_updated
ON applications (status_updated_at)
INCLUDE (job_id, applied_at)
WHERE status = 'HIRED';

-- 11. INVITATIONS: recipient and pending invitation lookup
CREATE INDEX IF NOT EXISTS idx_invitations_recipient_status
ON invitations (recipient_id, status, invitation_id)
INCLUDE (sender_id, sent_at, note);

-- 12. INVITATIONS: sender and date filtering
CREATE INDEX IF NOT EXISTS idx_invitations_sender_sent
ON invitations (sender_id, sent_at)
INCLUDE (status);

-- 13. PROFILE VIEWS: viewed member and date filtering
CREATE INDEX IF NOT EXISTS idx_profile_views_viewed_time
ON profile_views (viewed_id, viewed_at)
INCLUDE (viewer_id);

-- 14. PROFILE VIEWS: non-null viewer lookup
CREATE INDEX IF NOT EXISTS idx_profile_views_viewer
ON profile_views (viewer_id);

-- 15. MEMBERS: case-insensitive email lookup
CREATE INDEX IF NOT EXISTS idx_members_lower_email
ON members (lower(email));

-- 16. COMPANIES: industry filtering
CREATE INDEX IF NOT EXISTS idx_companies_industry
ON companies (industry)
INCLUDE (company_name);

-- Update planner statistics after index creation
ANALYZE;
