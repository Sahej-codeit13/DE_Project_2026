-- =====================================================================
-- CP4: Database Partitioning Implementation
-- Project: LinkedIn Professional Networking & Jobs Database
-- File: sql/08_partitioning.sql
-- Table: linkedin.applications
-- Strategy: PostgreSQL Declarative Partitioning (RANGE on applied_at)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. ARCHITECTURAL RATIONALE FOR PARTITIONING 'applications'
-- ---------------------------------------------------------------------
-- In the LinkedIn schema, `applications` is the highest-velocity,
-- write-intensive table (149,984 rows in seed data, ~3,000,000 rows in large
-- dataset, and projected 15,000,000+ rows at 100x scale).
--
-- Why Range Partitioning on `applied_at`?
-- 1. Temporal Query Locality: Workload queries predominantly query recent
--    windows (e.g., R19/R20 filter on June 2026, R14 filters on 2026 hires,
--    W05 cleans up applications older than 60 days).
-- 2. Partition Pruning: The PostgreSQL optimizer prunes non-matching partition
--    scans during planning and execution time, drastically reducing buffer I/O.
-- 3. Maintenance & Archival: Dropping or detaching old partitions (DROP TABLE
--    applications_y2024m01) executes instantaneously with zero MVCC table bloat,
--    avoiding expensive bulk DELETE operations and VACUUM overhead.
-- 4. Granular Autovacuum & Indexing: Indexes are maintained locally per
--    partition, fitting working sets into PostgreSQL `shared_buffers`.
-- ---------------------------------------------------------------------

SET search_path TO linkedin;

-- ---------------------------------------------------------------------
-- 2. PARTITIONED TABLE DEFINITION
-- ---------------------------------------------------------------------
-- POSTGRESQL CONSTRAINT RULES FOR PARTITIONED TABLES:
-- Rule: A UNIQUE or PRIMARY KEY constraint on a partitioned table MUST
-- include all partition key columns. Therefore, the Primary Key is
-- defined as composite: (application_id, applied_at).
--
-- Candidate Key (job_id, member_id, applied_at):
-- Enforces uniqueness per applicant per job within temporal windows.
-- Cross-partition application deduplication (if strictly required without
-- applied_at) is handled via application-level checks or a global hash lock.
-- ---------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS linkedin.applications_partitioned (
    application_id BIGINT NOT NULL,
    job_id INTEGER NOT NULL,
    member_id INTEGER NOT NULL,
    applied_at TIMESTAMPTZ NOT NULL,
    easy_apply BOOLEAN NOT NULL DEFAULT FALSE,
    status VARCHAR(20) NOT NULL,
    status_updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT pk_applications_partitioned PRIMARY KEY (application_id, applied_at),
    CONSTRAINT uk_applications_job_member_date UNIQUE (job_id, member_id, applied_at),
    CONSTRAINT chk_app_status CHECK (status IN ('APPLIED', 'VIEWED', 'SHORTLISTED', 'INTERVIEW', 'OFFER', 'HIRED', 'REJECTED')),
    CONSTRAINT chk_app_status_dates CHECK (status_updated_at >= applied_at)
) PARTITION BY RANGE (applied_at);

-- ---------------------------------------------------------------------
-- 3. MONTHLY PARTITIONS (2025 - 2026) + DEFAULT PARTITION
-- ---------------------------------------------------------------------
-- Historical data spans 2025-01-01 to 2026-06-30 in seed data.
-- We partition monthly through 2026-12-31 and add a DEFAULT catch-all.

-- Year 2025 Partitions
CREATE TABLE IF NOT EXISTS linkedin.applications_y2025m01 PARTITION OF linkedin.applications_partitioned
    FOR VALUES FROM ('2025-01-01 00:00:00+05:30') TO ('2025-02-01 00:00:00+05:30');

CREATE TABLE IF NOT EXISTS linkedin.applications_y2025m02 PARTITION OF linkedin.applications_partitioned
    FOR VALUES FROM ('2025-02-01 00:00:00+05:30') TO ('2025-03-01 00:00:00+05:30');

CREATE TABLE IF NOT EXISTS linkedin.applications_y2025m03 PARTITION OF linkedin.applications_partitioned
    FOR VALUES FROM ('2025-03-01 00:00:00+05:30') TO ('2025-04-01 00:00:00+05:30');

CREATE TABLE IF NOT EXISTS linkedin.applications_y2025m04 PARTITION OF linkedin.applications_partitioned
    FOR VALUES FROM ('2025-04-01 00:00:00+05:30') TO ('2025-05-01 00:00:00+05:30');

CREATE TABLE IF NOT EXISTS linkedin.applications_y2025m05 PARTITION OF linkedin.applications_partitioned
    FOR VALUES FROM ('2025-05-01 00:00:00+05:30') TO ('2025-06-01 00:00:00+05:30');

CREATE TABLE IF NOT EXISTS linkedin.applications_y2025m06 PARTITION OF linkedin.applications_partitioned
    FOR VALUES FROM ('2025-06-01 00:00:00+05:30') TO ('2025-07-01 00:00:00+05:30');

CREATE TABLE IF NOT EXISTS linkedin.applications_y2025m07 PARTITION OF linkedin.applications_partitioned
    FOR VALUES FROM ('2025-07-01 00:00:00+05:30') TO ('2025-08-01 00:00:00+05:30');

CREATE TABLE IF NOT EXISTS linkedin.applications_y2025m08 PARTITION OF linkedin.applications_partitioned
    FOR VALUES FROM ('2025-08-01 00:00:00+05:30') TO ('2025-09-01 00:00:00+05:30');

CREATE TABLE IF NOT EXISTS linkedin.applications_y2025m09 PARTITION OF linkedin.applications_partitioned
    FOR VALUES FROM ('2025-09-01 00:00:00+05:30') TO ('2025-10-01 00:00:00+05:30');

CREATE TABLE IF NOT EXISTS linkedin.applications_y2025m10 PARTITION OF linkedin.applications_partitioned
    FOR VALUES FROM ('2025-10-01 00:00:00+05:30') TO ('2025-11-01 00:00:00+05:30');

CREATE TABLE IF NOT EXISTS linkedin.applications_y2025m11 PARTITION OF linkedin.applications_partitioned
    FOR VALUES FROM ('2025-11-01 00:00:00+05:30') TO ('2025-12-01 00:00:00+05:30');

CREATE TABLE IF NOT EXISTS linkedin.applications_y2025m12 PARTITION OF linkedin.applications_partitioned
    FOR VALUES FROM ('2025-12-01 00:00:00+05:30') TO ('2026-01-01 00:00:00+05:30');

-- Year 2026 Partitions
CREATE TABLE IF NOT EXISTS linkedin.applications_y2026m01 PARTITION OF linkedin.applications_partitioned
    FOR VALUES FROM ('2026-01-01 00:00:00+05:30') TO ('2026-02-01 00:00:00+05:30');

CREATE TABLE IF NOT EXISTS linkedin.applications_y2026m02 PARTITION OF linkedin.applications_partitioned
    FOR VALUES FROM ('2026-02-01 00:00:00+05:30') TO ('2026-03-01 00:00:00+05:30');

CREATE TABLE IF NOT EXISTS linkedin.applications_y2026m03 PARTITION OF linkedin.applications_partitioned
    FOR VALUES FROM ('2026-03-01 00:00:00+05:30') TO ('2026-04-01 00:00:00+05:30');

CREATE TABLE IF NOT EXISTS linkedin.applications_y2026m04 PARTITION OF linkedin.applications_partitioned
    FOR VALUES FROM ('2026-04-01 00:00:00+05:30') TO ('2026-05-01 00:00:00+05:30');

CREATE TABLE IF NOT EXISTS linkedin.applications_y2026m05 PARTITION OF linkedin.applications_partitioned
    FOR VALUES FROM ('2026-05-01 00:00:00+05:30') TO ('2026-06-01 00:00:00+05:30');

CREATE TABLE IF NOT EXISTS linkedin.applications_y2026m06 PARTITION OF linkedin.applications_partitioned
    FOR VALUES FROM ('2026-06-01 00:00:00+05:30') TO ('2026-07-01 00:00:00+05:30');

CREATE TABLE IF NOT EXISTS linkedin.applications_y2026m07 PARTITION OF linkedin.applications_partitioned
    FOR VALUES FROM ('2026-07-01 00:00:00+05:30') TO ('2026-08-01 00:00:00+05:30');

CREATE TABLE IF NOT EXISTS linkedin.applications_y2026m08 PARTITION OF linkedin.applications_partitioned
    FOR VALUES FROM ('2026-08-01 00:00:00+05:30') TO ('2026-09-01 00:00:00+05:30');

CREATE TABLE IF NOT EXISTS linkedin.applications_y2026m09 PARTITION OF linkedin.applications_partitioned
    FOR VALUES FROM ('2026-09-01 00:00:00+05:30') TO ('2026-10-01 00:00:00+05:30');

CREATE TABLE IF NOT EXISTS linkedin.applications_y2026m10 PARTITION OF linkedin.applications_partitioned
    FOR VALUES FROM ('2026-10-01 00:00:00+05:30') TO ('2026-11-01 00:00:00+05:30');

CREATE TABLE IF NOT EXISTS linkedin.applications_y2026m11 PARTITION OF linkedin.applications_partitioned
    FOR VALUES FROM ('2026-11-01 00:00:00+05:30') TO ('2026-12-01 00:00:00+05:30');

CREATE TABLE IF NOT EXISTS linkedin.applications_y2026m12 PARTITION OF linkedin.applications_partitioned
    FOR VALUES FROM ('2026-12-01 00:00:00+05:30') TO ('2027-01-01 00:00:00+05:30');

-- Catch-all partition for boundary / future entries
CREATE TABLE IF NOT EXISTS linkedin.applications_default PARTITION OF linkedin.applications_partitioned DEFAULT;

-- ---------------------------------------------------------------------
-- 4. SECONDARY INDEXES ON PARTITIONED TABLE
-- ---------------------------------------------------------------------
-- In PostgreSQL 11+, creating an index on the partitioned parent table
-- automatically generates corresponding local indexes on all current
-- partitions and any newly attached future partitions.

-- Serves R08 (Recruiter pipeline by job) and W05 (Recruiter clean-up)
CREATE INDEX IF NOT EXISTS idx_part_app_job_status
    ON linkedin.applications_partitioned (job_id, status);

-- Serves R09 (My Jobs list for a member)
CREATE INDEX IF NOT EXISTS idx_part_app_member_applied
    ON linkedin.applications_partitioned (member_id, applied_at DESC);

-- Serves R14 (Talent insights: time to hire for HIRED status)
CREATE INDEX IF NOT EXISTS idx_part_app_status_updated
    ON linkedin.applications_partitioned (status, status_updated_at)
    WHERE status = 'HIRED';

-- Serves R20 (Daily applications aggregate) & R22 (Pagination)
CREATE INDEX IF NOT EXISTS idx_part_app_applied_at
    ON linkedin.applications_partitioned (applied_at DESC);

-- ---------------------------------------------------------------------
-- 5. SAFE ZERO-DATA-LOSS MIGRATION STRATEGY
-- ---------------------------------------------------------------------
-- The following idempotent migration block migrates data from an existing
-- non-partitioned `applications` table to the partitioned structure.
-- It runs in a single transaction, verifies row counts, and swaps tables.

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_tables
        WHERE schemaname = 'linkedin' AND tablename = 'applications'
    ) AND NOT EXISTS (
        SELECT 1 FROM pg_partitioned_table pt
        JOIN pg_class c ON pt.partrelid = c.oid
        JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE n.nspname = 'linkedin' AND c.relname = 'applications'
    ) THEN
        RAISE NOTICE 'Migrating existing unpartitioned applications table to partitioned table...';

        -- 1. Copy data preserving all records
        INSERT INTO linkedin.applications_partitioned (
            application_id, job_id, member_id, applied_at, easy_apply, status, status_updated_at
        )
        SELECT application_id, job_id, member_id, applied_at, easy_apply, status, status_updated_at
        FROM linkedin.applications;

        -- 2. Verify row count equivalence
        IF (SELECT count(*) FROM linkedin.applications) <> (SELECT count(*) FROM linkedin.applications_partitioned) THEN
            RAISE EXCEPTION 'Row count mismatch during partition migration! Aborting transaction.';
        END IF;

        -- 3. Atomic swap
        ALTER TABLE linkedin.applications RENAME TO applications_unpartitioned_backup;
        ALTER TABLE linkedin.applications_partitioned RENAME TO applications;

        RAISE NOTICE 'Migration completed successfully. applications is now partitioned.';
    ELSE
        RAISE NOTICE 'applications table is already partitioned or does not exist. No migration needed.';
    END IF;
END $$;

-- ---------------------------------------------------------------------
-- 6. DEMONSTRATION & PROOF OF PARTITION PRUNING
-- ---------------------------------------------------------------------
-- Run EXPLAIN (ANALYZE, BUFFERS) on a date-bounded query (e.g. Workload Query R20).
-- Observe that PostgreSQL scans ONLY `applications_y2026m06`, completely
-- pruning the other 23 monthly partitions and the default partition.

-- Query: June 2026 Applications (R20 range test)
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*)
FROM linkedin.applications_partitioned
WHERE applied_at >= '2026-06-01 00:00:00+05:30'
  AND applied_at < '2026-07-01 00:00:00+05:30';

-- =====================================================================
-- End of sql/08_partitioning.sql
-- =====================================================================
