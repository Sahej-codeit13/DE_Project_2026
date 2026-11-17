-- =========================================
-- CP1: LinkedIn Database Schema
-- PostgreSQL 15+
-- =========================================

CREATE SCHEMA IF NOT EXISTS linkedin;
SET search_path TO linkedin;

CREATE TABLE cities (
    city_id INTEGER PRIMARY KEY,
    city_name VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL
);

-- =========================================
-- 2. SKILLS
-- =========================================

CREATE TABLE skills (
    skill_id INTEGER PRIMARY KEY,
    skill_name VARCHAR(100) NOT NULL UNIQUE
);

-- =========================================
-- 3. MEMBERS
-- =========================================

CREATE TABLE members (
    member_id INTEGER PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    headline TEXT,
    email VARCHAR(255) NOT NULL UNIQUE,
    city_id INTEGER,
    industry VARCHAR(100),
    is_premium BOOLEAN NOT NULL DEFAULT FALSE,
    open_to_work BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL,

    FOREIGN KEY (city_id)
        REFERENCES cities(city_id)
);

-- =========================================
-- 4. COMPANIES
-- =========================================

CREATE TABLE companies (
    company_id INTEGER PRIMARY KEY,
    company_name VARCHAR(255) NOT NULL,
    industry VARCHAR(100),
    company_size VARCHAR(20),
    hq_city_id INTEGER,
    founded_year INTEGER,
    website TEXT,

    FOREIGN KEY (hq_city_id)
        REFERENCES cities(city_id)
);

-- =========================================
-- 5. POSITIONS
-- =========================================

CREATE TABLE positions (
    position_id INTEGER PRIMARY KEY,
    member_id INTEGER NOT NULL,
    company_id INTEGER NOT NULL,
    title VARCHAR(150) NOT NULL,
    employment_type VARCHAR(30) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,

    FOREIGN KEY (member_id)
        REFERENCES members(member_id),

    FOREIGN KEY (company_id)
        REFERENCES companies(company_id),

    CHECK (employment_type IN ('CONTRACT', 'FULL_TIME', 'INTERNSHIP'))
);

-- =========================================
-- 6. MEMBER SKILLS
-- =========================================

CREATE TABLE member_skills (
    member_id INTEGER NOT NULL,
    skill_id INTEGER NOT NULL,
    endorsements INTEGER NOT NULL DEFAULT 0,

    PRIMARY KEY (member_id, skill_id),

    FOREIGN KEY (member_id)
        REFERENCES members(member_id),

    FOREIGN KEY (skill_id)
        REFERENCES skills(skill_id),

    CHECK (endorsements >= 0)
);

-- =========================================
-- 7. JOBS
-- =========================================

CREATE TABLE jobs (
    job_id INTEGER PRIMARY KEY,
    company_id INTEGER NOT NULL,
    title VARCHAR(150) NOT NULL,
    city_id INTEGER,
    workplace_type VARCHAR(20) NOT NULL,
    employment_type VARCHAR(30) NOT NULL,
    min_experience INTEGER,
    min_salary_lpa NUMERIC(10,2),
    max_salary_lpa NUMERIC(10,2),
    posted_at TIMESTAMPTZ NOT NULL,
    closes_at TIMESTAMPTZ,
    status VARCHAR(20) NOT NULL,

    FOREIGN KEY (company_id)
        REFERENCES companies(company_id),

    FOREIGN KEY (city_id)
        REFERENCES cities(city_id),

    CHECK (workplace_type IN ('HYBRID', 'ONSITE', 'REMOTE')),
    CHECK (employment_type IN ('CONTRACT', 'FULL_TIME', 'INTERNSHIP')),
    CHECK (status IN ('OPEN', 'CLOSED')),
    CHECK (min_experience >= 0),
    CHECK (min_salary_lpa IS NULL OR min_salary_lpa >= 0),
    CHECK (max_salary_lpa IS NULL OR max_salary_lpa >= 0),
    CHECK (
        min_salary_lpa IS NULL
        OR max_salary_lpa IS NULL
        OR min_salary_lpa <= max_salary_lpa
    )
);

-- =========================================
-- 8. JOB SKILLS
-- =========================================

CREATE TABLE job_skills (
    job_id INTEGER NOT NULL,
    skill_id INTEGER NOT NULL,

    PRIMARY KEY (job_id, skill_id),

    FOREIGN KEY (job_id)
        REFERENCES jobs(job_id),

    FOREIGN KEY (skill_id)
        REFERENCES skills(skill_id)
);

-- =========================================
-- 9. APPLICATIONS
-- =========================================

CREATE TABLE applications (
    application_id INTEGER PRIMARY KEY,
    job_id INTEGER NOT NULL,
    member_id INTEGER NOT NULL,
    applied_at TIMESTAMPTZ NOT NULL,
    easy_apply BOOLEAN NOT NULL,
    status VARCHAR(30) NOT NULL,
    status_updated_at TIMESTAMPTZ,
CONSTRAINT applications_job_member_unique UNIQUE (job_id, member_id),

    FOREIGN KEY (job_id)
        REFERENCES jobs(job_id),

    FOREIGN KEY (member_id)
        REFERENCES members(member_id),

    CHECK (
        status IN (
            'APPLIED',
            'HIRED',
            'INTERVIEW',
            'OFFER',
            'REJECTED',
            'SHORTLISTED',
            'VIEWED',
            'WITHDRAWN'
        )
    )
);

-- =========================================
-- 10. CONNECTIONS
-- =========================================

CREATE TABLE connections (
    member_a INTEGER NOT NULL,
    member_b INTEGER NOT NULL,
    connected_at TIMESTAMPTZ NOT NULL,

    PRIMARY KEY (member_a, member_b),

    FOREIGN KEY (member_a)
        REFERENCES members(member_id),

    FOREIGN KEY (member_b)
        REFERENCES members(member_id)
);

-- =========================================
-- 11. INVITATIONS
-- =========================================

CREATE TABLE invitations (
    invitation_id INTEGER PRIMARY KEY,
    sender_id INTEGER NOT NULL,
    recipient_id INTEGER NOT NULL,
    note TEXT,
    sent_at TIMESTAMPTZ NOT NULL,
    status VARCHAR(20) NOT NULL,
    responded_at TIMESTAMPTZ,

    FOREIGN KEY (sender_id)
        REFERENCES members(member_id),

    FOREIGN KEY (recipient_id)
        REFERENCES members(member_id),

    CHECK (
        status IN ('ACCEPTED', 'IGNORED', 'PENDING', 'WITHDRAWN')
    )
);

-- =========================================
-- 12. PROFILE VIEWS
-- =========================================

CREATE TABLE profile_views (
    view_id INTEGER PRIMARY KEY,
    viewer_id INTEGER,
    viewed_id INTEGER NOT NULL,
    viewed_at TIMESTAMPTZ NOT NULL,

    FOREIGN KEY (viewer_id)
        REFERENCES members(member_id),

    FOREIGN KEY (viewed_id)
        REFERENCES members(member_id)
);
