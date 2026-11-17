# Database Optimization Report

## 1. Overview

- Database: `linkedin_network`
- Schema: `linkedin`
- Original workload: `queries/workload_30.sql`
- Optimized workload: `sql/06_optimized_queries.sql`
- Index definitions: `sql/05_indexes.sql`
- Benchmark repetitions: 3 runs per query

## 2. Overall Results

| Metric | Before (ms) | After (ms) | Improvement |
|---|---:|---:|---:|
| Average read time | 24.084 | 7.316 | 69.6% |
| Average write time | 4.745 | 6.542 | -37.9% |

Read improvement is positive when execution time decreases. A negative write improvement indicates slower writes.

## 3. Individual Query Comparison

| Query | Type | Before (ms) | After (ms) | Improvement | Speedup |
|---|---|---:|---:|---:|---:|
| R01 | READ | 9.430 | 0.294 | +96.9% | 32.07x |
| R02 | READ | 8.599 | 0.293 | +96.6% | 29.35x |
| R03 | READ | 6.314 | 0.517 | +91.8% | 12.21x |
| R04 | READ | 14.369 | 0.262 | +98.2% | 54.84x |
| R05 | READ | 30.143 | 3.130 | +89.6% | 9.63x |
| R06 | READ | 4.199 | 2.248 | +46.5% | 1.87x |
| R07 | READ | 6.029 | 4.006 | +33.6% | 1.50x |
| R08 | READ | 0.236 | 0.344 | -45.8% | 0.69x |
| R09 | READ | 3.457 | 0.288 | +91.7% | 12.00x |
| R10 | READ | 5.487 | 0.326 | +94.1% | 16.83x |
| R11 | READ | 10.993 | 0.310 | +97.2% | 35.46x |
| R12 | READ | 10.356 | 0.572 | +94.5% | 18.10x |
| R13 | READ | 27.701 | 37.090 | -33.9% | 0.75x |
| R14 | READ | 8.462 | 3.759 | +55.6% | 2.25x |
| R15 | READ | 8.642 | 9.715 | -12.4% | 0.89x |
| R16 | READ | 2.040 | 1.916 | +6.1% | 1.06x |
| R17 | READ | 38.191 | 30.701 | +19.6% | 1.24x |
| R18 | READ | 8.017 | 3.282 | +59.1% | 2.44x |
| R19 | READ | 226.472 | 3.181 | +98.6% | 71.20x |
| R20 | READ | 6.885 | 1.394 | +79.8% | 4.94x |
| R21 | READ | 83.054 | 31.506 | +62.1% | 2.64x |
| R22 | READ | 29.538 | 7.901 | +73.3% | 3.74x |
| R23 | READ | 7.176 | 0.122 | +98.3% | 58.82x |
| R24 | READ | 10.775 | 12.428 | -15.3% | 0.87x |
| R25 | READ | 35.525 | 27.312 | +23.1% | 1.30x |
| W01 | WRITE | 0.490 | 0.794 | -62.0% | 0.62x |
| W02 | WRITE | 3.451 | 0.464 | +86.6% | 7.44x |
| W03 | WRITE | 4.107 | 1.140 | +72.2% | 3.60x |
| W04 | WRITE | 6.299 | 9.633 | -52.9% | 0.65x |
| W05 | WRITE | 9.380 | 20.681 | -120.5% | 0.45x |

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

### R19 — Company application and open-job counts

Replaced repeated correlated subqueries with grouped common table expressions and joins. This reduces repeated aggregation work.

### R20 — Application date filtering

Replaced a date cast in the WHERE condition with a half-open timestamp range from June 1 inclusive to July 1 exclusive. This allows the timestamp index to support filtering more effectively.

### R21 — Highest-endorsed member per skill

Replaced window ranking with PostgreSQL DISTINCT ON, preserving the endorsement ordering and member ID tie-breaker.

## 6. Execution Plan Observations

The optimized plans show index scans, bitmap index scans, and index-only scans for many important lookup patterns. Some queries still use sequential scans. These are not necessarily inefficient: PostgreSQL may prefer them when reading a large portion of a table.

R13, R15, and R24 regressed compared with baseline and deserve further investigation. R17 and R25 also remain relatively expensive.

## 7. Read and Write Trade-off

The average read-query time decreased from 24.084 ms to 7.316 ms, a 69.6% reduction. 21 of 25 read queries improved.

The average write-query time changed from 4.745 ms to 6.542 ms. 2 of 5 write queries improved.

Additional indexes improve read access but introduce maintenance overhead during inserts and updates. This is an important trade-off in index-heavy database design.

## 8. Conclusion

The optimized workload achieved a 3.29x average read speedup. The strongest gains came from targeted indexing and the R19, R20, and R21 query rewrites. Write overhead and the remaining slower queries should be considered when evaluating the final design.

All measurements are specific to this database, dataset, PostgreSQL configuration, and three-run benchmark.
