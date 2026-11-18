cat > docs/04_optimization_report.md <<'EOF'
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
EOF
