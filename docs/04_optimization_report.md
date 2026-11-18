# Database Optimization Report

## 1. Overview

- Database: `linkedin_network`
- Schema: `linkedin`
- Original workload: `queries/workload_30.sql`
- Optimized workload: `sql/06_optimized_queries.sql`
- Index definitions: `sql/05_indexes.sql`
- Benchmark repetitions: 5 runs per query

## 2. Overall Results

| Metric | Before (ms) | After (ms) | Improvement |
|---|---:|---:|---:|
| Average read time | 24.084 | 5.575 | 76.8% |
| Average write time | 4.745 | 3.141 | 33.8% |

The optimized workload achieved a 4.32x average read speedup.
Both read and write workloads improved overall.

## 3. Individual Query Comparison

| Query | Type | Before (ms) | After (ms) | Improvement | Speedup |
|---|---|---:|---:|---:|---:|
| R01 | READ | 9.430 | 0.107 | +98.9% | 88.13x |
| R02 | READ | 8.599 | 0.096 | +98.9% | 89.57x |
| R03 | READ | 6.314 | 0.120 | +98.1% | 52.62x |
| R04 | READ | 14.369 | 0.154 | +98.9% | 93.31x |
| R05 | READ | 30.143 | 0.693 | +97.7% | 43.50x |
| R06 | READ | 4.199 | 2.599 | +38.1% | 1.62x |
| R07 | READ | 6.029 | 2.996 | +50.3% | 2.01x |
| R08 | READ | 0.236 | 0.221 | +6.4% | 1.07x |
| R09 | READ | 3.457 | 0.252 | +92.7% | 13.72x |
| R10 | READ | 5.487 | 0.153 | +97.2% | 35.86x |
| R11 | READ | 10.993 | 0.222 | +98.0% | 49.52x |
| R12 | READ | 10.356 | 0.453 | +95.6% | 22.86x |
| R13 | READ | 27.701 | 19.287 | +30.4% | 1.44x |
| R14 | READ | 8.462 | 3.247 | +61.6% | 2.61x |
| R15 | READ | 8.642 | 16.056 | -85.8% | 0.54x |
| R16 | READ | 2.040 | 3.257 | -59.7% | 0.63x |
| R17 | READ | 38.191 | 13.638 | +64.3% | 2.80x |
| R18 | READ | 8.017 | 5.253 | +34.5% | 1.53x |
| R19 | READ | 226.472 | 5.740 | +97.5% | 39.46x |
| R20 | READ | 6.885 | 3.861 | +43.9% | 1.78x |
| R21 | READ | 83.054 | 0.849 | +99.0% | 97.83x |
| R22 | READ | 29.538 | 14.919 | +49.5% | 1.98x |
| R23 | READ | 7.176 | 0.092 | +98.7% | 78.00x |
| R24 | READ | 10.775 | 19.303 | -79.1% | 0.56x |
| R25 | READ | 35.525 | 25.818 | +27.3% | 1.38x |
| W01 | WRITE | 0.490 | 0.594 | -21.2% | 0.82x |
| W02 | WRITE | 3.451 | 0.257 | +92.6% | 13.43x |
| W03 | WRITE | 4.107 | 1.012 | +75.4% | 4.06x |
| W04 | WRITE | 6.299 | 7.029 | -11.6% | 0.90x |
| W05 | WRITE | 9.380 | 6.813 | +27.4% | 1.38x |

Positive improvement means execution time decreased.
Negative improvement means execution time increased.

## 4. Indexing Strategy

The optimization uses indexes for frequently filtered, joined, and sorted columns. The strategy includes:

- Composite indexes for multi-column lookups and ordering.
- Partial indexes for open jobs and hired applications.
- Covering indexes using INCLUDE columns to support index-only scans.
- Indexes for both directions of connection lookups.
- Indexes for member skills and job skills.
- An expression index on `lower(email)` for case-insensitive lookup.
- Indexes supporting recent applications, invitations, and profile views.
- ANALYZE to refresh PostgreSQL table statistics.

## 5. SQL Query Rewrites

### R13 — Members who have never viewed a profile

Replaced `NOT IN` with `NOT EXISTS` to avoid incorrect NULL-related
behavior. The original subquery contained NULL viewer IDs, which
caused `NOT IN` to return no matching members.

### R15 — Job and skill filtering

Replaced year extraction from the timestamp with a half-open
timestamp range. This makes the date condition more index-friendly.

### R17 — Employee career movement

Replaced the window-function approach with a LATERAL subquery
that finds the next position for each TCS employee using the
member and start-date index.

### R19 — Before and after execution plan

The original query used correlated subqueries for every IT Services
company. PostgreSQL scanned the companies table and repeatedly scanned
the jobs table to calculate open jobs and June application counts.
The plan recorded 106,834 shared buffer hits and an average execution
time of 226.472 ms.

The optimized query uses a set-based approach with a CTE, joins,
aggregation, and a half-open June 2026 date range. PostgreSQL uses
`idx_applications_recent` through an Index Only Scan and
`idx_companies_industry` through a Bitmap Index Scan. The open-job
calculation uses `idx_jobs_open_closes`.

The optimized plan recorded 1,962 shared buffer hits and an average
execution time of 5.740 ms. This represents approximately 39.5x
faster execution and a 98.2% reduction in shared buffer hits.

### R21 — Highest-endorsed member per skill

Replaced `DISTINCT ON` with a LATERAL subquery that retrieves
the top member for each skill using the skill and endorsement
index.

### R24 — Invitation date filtering

Used a half-open date range to filter invitations within 2026,
avoiding an open-ended date condition.

## 6. Execution Plan Observations

The optimized plans use index scans, bitmap index scans, and
index-only scans for many important lookup patterns.

Some queries continue to use sequential scans. These are not
necessarily inefficient: PostgreSQL may prefer them when a
large portion of a table must be read.

R15, R16, and R24 take longer than their baseline versions and
remain candidates for further investigation. R17 and R25 also
remain relatively expensive, although both improved compared
with baseline.

R13 improved in measured execution time and also fixes a
correctness issue in the original query.

## 7. Read and Write Trade-off

The average read-query execution time decreased from 24.084 ms
in the baseline workload to 5.575 ms in the optimized workload,
representing a 76.8% reduction and an average speedup of 4.32x.

Out of 25 read queries, 22 improved. R15, R16, and R24
showed higher execution times after optimization and remain
candidates for further investigation.

The average write-query execution time decreased from 4.745 ms
to 3.141 ms, an improvement of approximately 33.8%.
Three of the five write queries improved, while W01 and W04
showed higher execution times.

The total database size is approximately 171 MB, and the
combined index storage is approximately 102 MB. Indexes
therefore account for approximately 59.6% of the database size.

Indexes improve lookup and filtering performance but require
additional storage and maintenance during data modifications.
The measured results show that both read and write workloads
improved overall.

## 8. Conclusion

The optimized workload achieved an average read speedup of
approximately 4.32x, reducing average read execution time
by 76.8%.

The strongest improvements came from targeted indexing and
query rewrites, particularly R19, R21, and R17. R13 was also
corrected to use NOT EXISTS, avoiding the NULL-related
incorrect behavior of the original NOT IN query.

Although R15, R16, and R24 remain slower than their baseline
versions, the overall workload demonstrates substantial
performance improvement.

All measurements are specific to this database, dataset,
PostgreSQL configuration, and five-run benchmark. Execution
times may vary between runs.

## 9. Before and After Execution Plan Evidence

The following five queries produced the largest measured read-query
speedups. Average execution times are taken from the five-run benchmark
summary. Buffer counts are from the saved EXPLAIN ANALYZE plans.

### R21 — Highest-endorsed member per skill

- Average execution time: 83.054 ms -> 0.849 ms (97.83x faster).
- Original plan: Sequential Scan of 212,417 member_skills rows,
  followed by a Sort and WindowAgg.
- The sort used an external merge and spilled 6,544 kB to disk.
- Original plan: 1,188 shared buffer hits, with temporary reads
  and writes.
- Optimized plan: Nested Loop over 72 skills, with a Limit and
  Index Only Scan using idx_member_skills_skill_endorsements.
- Optimized plan: 221 shared buffer hits and zero heap fetches.

The LATERAL query retrieves only the highest-ranked member for each
skill instead of sorting and processing the complete member_skills
table for a window calculation.

### R04 — Connection lookup in both directions

- Average execution time: 14.369 ms -> 0.154 ms (93.31x faster).
- Original plan: Parallel Sequential Scans on connections for both
  connection directions.
- Original plan: 2,593 shared buffer hits.
- Optimized plan: Bitmap Heap Scans combined with BitmapOr.
- The bitmap operations use idx_connections_member_a_recent and
  idx_connections_member_b_recent.
- Optimized plan: 38 shared buffer hits.

The two composite indexes allow PostgreSQL to locate matching
connections without scanning the entire table twice.

### R02 — Latest position lookup

- Average execution time: 8.599 ms -> 0.096 ms (89.57x faster).
- Original plan: Sequential Scan on positions followed by a Sort
  on start_date DESC.
- Original plan: 991 shared buffer hits.
- Optimized plan: Index Only Scan Backward using
  idx_positions_member_start.
- Optimized plan: 16 shared buffer hits.

The index ordering allows PostgreSQL to retrieve the latest position
directly, avoiding the full table scan and sort.

### R01 — Current position lookup

- Average execution time: 9.430 ms -> 0.107 ms (88.13x faster).
- Original plan: Sequential Scan on positions, with 982 shared
  buffer hits.
- Optimized plan: Index Only Scan using
  idx_positions_current_member.
- The member and company lookups use their primary-key indexes.
- Optimized plan: 9 shared buffer hits.

The current-position index allows the query to locate the required
position directly rather than scanning all position records.

### R23 — Case-insensitive email lookup

- Average execution time: 7.176 ms -> 0.092 ms (78.00x faster).
- Original plan: Sequential Scan on members.
- Original plan: 656 shared buffer hits.
- Optimized plan: Index Scan using idx_members_lower_email.
- Optimized plan: 4 shared buffer hits.

The expression index on lower(email) supports the case-insensitive
lookup and avoids scanning the members table.

### Additional improvement — R19

R19 improved from 226.472 ms to 5.740 ms (39.46x faster).
The original correlated subqueries repeatedly accessed jobs and
applications for each IT Services company. The optimized set-based
query uses joins, aggregation, and indexes. Shared buffer hits
decreased from 106,834 to 1,962.

## 10. Query Equivalence and Correctness Verification

EXCEPT ALL comparisons were used to compare the original and
optimized result sets. A zero difference means both versions
returned the same rows, including duplicate counts.

| Query | Original rows | Optimized rows | Differing rows |
|---|---:|---:|---:|
| R17 | 15 | 15 | 0 |
| R19 | 200 | 200 | 0 |
| R20 | 30 | 30 | 0 |
| R21 | 72 | 72 | 0 |
| R24 | 2 | 2 | 0 |

R13 is an intentional correctness fix rather than an equivalent
rewrite. The original NOT IN subquery contained 50,173 NULL
viewer IDs. Because of SQL NULL semantics, the original query
returned zero rows. The corrected NOT EXISTS query returned
6,513 members who had never viewed another profile.

The R13 difference is therefore expected and fixes incorrect
original behavior.

R15 changes the year filter to a half-open timestamp range.
R20 changes its date filtering to a half-open range. R24 adds
an upper date boundary. In the current dataset, no existing
rows are excluded by the added upper boundaries.

## 11. Index Storage Measurements

The following sizes were measured using PostgreSQL relation sizes.
The table size column represents the table heap, excluding indexes.
The percentage compares each index size with its table heap size.

| Table | Index | Index size | Table heap | Index / heap |
|---|---|---:|---:|---:|
| applications | idx_applications_member_recent | 8,888 kB | 11 MB | 78.9% |
| applications | idx_applications_recent | 7,584 kB | 11 MB | 67.3% |
| applications | idx_applications_job_applied | 4,640 kB | 11 MB | 41.2% |
| applications | applications_pkey | 3,312 kB | 11 MB | 29.4% |
| applications | applications_job_member_unique | 3,312 kB | 11 MB | 29.4% |
| applications | idx_applications_hired_updated | 312 kB | 11 MB | 2.8% |
| cities | cities_pkey | 16 kB | 8 kB | 200% |
| companies | idx_companies_industry | 120 kB | 208 kB | 57.7% |
| companies | companies_pkey | 64 kB | 208 kB | 30.8% |
| connections | idx_connections_member_a_recent | 8,744 kB | 9,984 kB | 87.6% |
| connections | idx_connections_member_b_recent | 8,744 kB | 9,984 kB | 87.6% |
| connections | connections_pkey | 4,840 kB | 9,984 kB | 48.5% |
| invitations | idx_invitations_recipient_status | 4,256 kB | 5,152 kB | 82.6% |
| invitations | idx_invitations_sender_sent | 2,768 kB | 5,152 kB | 53.7% |
| invitations | invitations_pkey | 1,328 kB | 5,152 kB | 25.8% |
| job_skills | job_skills_pkey | 1,456 kB | 2,328 kB | 62.5% |
| job_skills | idx_job_skills_skill_job | 1,456 kB | 2,328 kB | 62.5% |
| jobs | idx_jobs_company_status | 408 kB | 2,104 kB | 19.4% |
| jobs | jobs_pkey | 344 kB | 2,104 kB | 16.3% |
| jobs | idx_jobs_open_closes | 56 kB | 2,104 kB | 2.7% |
| member_skills | idx_member_skills_skill_endorsements | 6,560 kB | 9,472 kB | 69.3% |
| member_skills | member_skills_pkey | 4,680 kB | 9,472 kB | 49.4% |
| members | members_email_key | 2,352 kB | 5,248 kB | 44.8% |
| members | idx_members_lower_email | 1,952 kB | 5,248 kB | 37.2% |
| members | members_pkey | 896 kB | 5,248 kB | 17.1% |
| positions | idx_positions_member_start | 6,456 kB | 7,808 kB | 82.7% |
| positions | positions_pkey | 2,200 kB | 7,808 kB | 28.2% |
| positions | idx_positions_current_member | 1,584 kB | 7,808 kB | 20.3% |
| positions | idx_positions_company_current | 1,072 kB | 7,808 kB | 13.7% |
| profile_views | idx_profile_views_viewed_time | 7,944 kB | 10,112 kB | 78.6% |
| profile_views | profile_views_pkey | 4,408 kB | 10,112 kB | 43.6% |
| profile_views | idx_profile_views_viewer | 2,160 kB | 10,112 kB | 21.4% |
| skills | skills_skill_name_key | 16 kB | 8 kB | 200% |
| skills | skills_pkey | 16 kB | 8 kB | 200% |

The combined index storage is approximately 102 MB. The database
occupies approximately 171 MB. Small tables can have indexes larger
than their heap because indexes have their own page and storage
overhead. This is why the ratio can exceed 100%.

## 12. Queries With Regressions and Remaining Limitations

Three read queries were slower after optimization:

- R15: 8.642 ms -> 16.056 ms. Rewriting the year extraction as a
  timestamp range did not guarantee an index scan. PostgreSQL may
  still prefer a sequential scan when it estimates that reading
  the table is cheaper.
- R16: 2.040 ms -> 3.257 ms. This query regressed in the measured
  benchmark. The timing should be monitored rather than assuming
  that every index or rewrite improves every workload.
- R24: 10.775 ms -> 19.303 ms. A substantial portion of invitations
  matches the date condition, so a sequential scan and hash-based
  processing can be cheaper than using an index.

The write queries W01 and W04 also regressed:

- W01: 0.490 ms -> 0.594 ms (21.2% slower).
- W04: 6.299 ms -> 7.029 ms (11.6% slower).

Additional indexes require PostgreSQL to maintain index entries
during inserts, updates, and deletes. This creates storage and
write-maintenance overhead. The measured regressions are small
in absolute milliseconds, but should be monitored with larger
datasets and heavier write workloads.

The benchmark results are specific to the current dataset,
PostgreSQL configuration, and five-run test procedure. The
large-data workload should be used to reassess index selectivity,
query plans, storage, and write overhead at scale.
