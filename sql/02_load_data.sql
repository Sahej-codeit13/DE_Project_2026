
-- =========================================
-- CP1: Load Seed Data
-- PostgreSQL 15+
-- Run this file from the repository root
-- =========================================

\set ON_ERROR_STOP on

SET search_path TO linkedin;

-- 1. Cities
\echo 'Loading cities...'
\copy linkedin.cities (city_id, city_name, state) FROM 'seed_data/cities.csv' WITH (FORMAT csv, HEADER true, NULL '')

-- 2. Skills
\echo 'Loading skills...'
\copy linkedin.skills (skill_id, skill_name) FROM 'seed_data/skills.csv' WITH (FORMAT csv, HEADER true, NULL '')

-- 3. Members
\echo 'Loading members...'
\copy linkedin.members (member_id, first_name, last_name, headline, email, city_id, industry, is_premium, open_to_work, created_at) FROM 'seed_data/members.csv' WITH (FORMAT csv, HEADER true, NULL '')

-- 4. Companies
\echo 'Loading companies...'
\copy linkedin.companies (company_id, company_name, industry, company_size, hq_city_id, founded_year, website) FROM 'seed_data/companies.csv' WITH (FORMAT csv, HEADER true, NULL '')

-- 5. Positions
\echo 'Loading positions...'
\copy linkedin.positions (position_id, member_id, company_id, title, employment_type, start_date, end_date) FROM 'seed_data/positions.csv' WITH (FORMAT csv, HEADER true, NULL '')

-- 6. Member Skills
\echo 'Loading member skills...'
\copy linkedin.member_skills (member_id, skill_id, endorsements) FROM 'seed_data/member_skills.csv' WITH (FORMAT csv, HEADER true, NULL '')

-- 7. Jobs
\echo 'Loading jobs...'
\copy linkedin.jobs (job_id, company_id, title, city_id, workplace_type, employment_type, min_experience, min_salary_lpa, max_salary_lpa, posted_at, closes_at, status) FROM 'seed_data/jobs.csv' WITH (FORMAT csv, HEADER true, NULL '')

-- 8. Job Skills
\echo 'Loading job skills...'
\copy linkedin.job_skills (job_id, skill_id) FROM 'seed_data/job_skills.csv' WITH (FORMAT csv, HEADER true, NULL '')

-- 9. Applications
\echo 'Loading applications...'
\copy linkedin.applications (application_id, job_id, member_id, applied_at, easy_apply, status, status_updated_at) FROM 'seed_data/applications.csv' WITH (FORMAT csv, HEADER true, NULL '')

-- 10. Connections
\echo 'Loading connections...'
\copy linkedin.connections (member_a, member_b, connected_at) FROM 'seed_data/connections.csv' WITH (FORMAT csv, HEADER true, NULL '')

-- 11. Invitations
\echo 'Loading invitations...'
\copy linkedin.invitations (invitation_id, sender_id, recipient_id, note, sent_at, status, responded_at) FROM 'seed_data/invitations.csv' WITH (FORMAT csv, HEADER true, NULL '')

-- 12. Profile Views
\echo 'Loading profile views...'
\copy linkedin.profile_views (view_id, viewer_id, viewed_id, viewed_at) FROM 'seed_data/profile_views.csv' WITH (FORMAT csv, HEADER true, NULL '')

\echo 'All CSV files loaded successfully!'
