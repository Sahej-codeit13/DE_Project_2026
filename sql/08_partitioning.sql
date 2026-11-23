-- CP4: PostgreSQL 15+ demonstration of RANGE partitioning.
-- Run against a COPY of the database. This creates applications_partitioned
-- without replacing the live applications table or changing workload semantics.
SET search_path TO linkedin;

CREATE TABLE IF NOT EXISTS applications_partitioned (
    application_id INTEGER NOT NULL,
    job_id INTEGER NOT NULL REFERENCES jobs(job_id),
    member_id INTEGER NOT NULL REFERENCES members(member_id),
    applied_at TIMESTAMPTZ NOT NULL,
    easy_apply BOOLEAN NOT NULL,
    status VARCHAR(30) NOT NULL CHECK (status IN
        ('APPLIED','HIRED','INTERVIEW','OFFER','REJECTED','SHORTLISTED','VIEWED','WITHDRAWN')),
    status_updated_at TIMESTAMPTZ,
    PRIMARY KEY (application_id, applied_at),
    UNIQUE (job_id, member_id, applied_at)
) PARTITION BY RANGE (applied_at);

-- PostgreSQL requires every partitioned-table PRIMARY KEY / UNIQUE constraint
-- to include the partition key. Thus neither application_id alone nor
-- (job_id, member_id) alone can be globally enforced here.
-- A separate unpartitioned registry or application-level transaction is needed
-- if global uniqueness of those original keys is mandatory.

CREATE TABLE IF NOT EXISTS applications_p2025 PARTITION OF applications_partitioned
 FOR VALUES FROM ('2025-01-01 00:00:00+00') TO ('2026-01-01 00:00:00+00');
CREATE TABLE IF NOT EXISTS applications_p2026 PARTITION OF applications_partitioned
 FOR VALUES FROM ('2026-01-01 00:00:00+00') TO ('2027-01-01 00:00:00+00');
CREATE TABLE IF NOT EXISTS applications_p2027 PARTITION OF applications_partitioned
 FOR VALUES FROM ('2027-01-01 00:00:00+00') TO ('2028-01-01 00:00:00+00');
CREATE TABLE IF NOT EXISTS applications_pdefault PARTITION OF applications_partitioned DEFAULT;

CREATE INDEX IF NOT EXISTS idx_apppart_member_recent ON applications_partitioned(member_id, applied_at DESC);
CREATE INDEX IF NOT EXISTS idx_apppart_job_applied ON applications_partitioned(job_id, applied_at DESC);
CREATE INDEX IF NOT EXISTS idx_apppart_recent ON applications_partitioned(applied_at DESC);

-- Only populate on a scratch database; rerunning avoids duplicate rows.
INSERT INTO applications_partitioned
 SELECT * FROM applications a
 WHERE NOT EXISTS (
   SELECT 1 FROM applications_partitioned p
   WHERE p.application_id = a.application_id AND p.applied_at = a.applied_at
 );
ANALYZE applications_partitioned;

-- Inspect the plan: the bounded date filter should prune irrelevant partitions.
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*) FROM applications_partitioned
WHERE applied_at >= TIMESTAMPTZ '2026-06-01 00:00:00+00'
  AND applied_at < TIMESTAMPTZ '2026-07-01 00:00:00+00';

-- Verify all source rows were copied before considering any migration.
SELECT (SELECT count(*) FROM applications) AS source_rows,
       (SELECT count(*) FROM applications_partitioned) AS partitioned_rows;
