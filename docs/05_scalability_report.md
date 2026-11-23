# CP4 — Scalability Report (LinkedIn DBMS, PostgreSQL 15+)

**Measurement status:** Seed-data optimized timings are available in `benchmarks/results/optimized/summary.csv`. Large-dataset measurements have **not** been executed or verified; blank fields are deliberately not fabricated. `benchmarks/results/large/summary.csv` is a pending-results template, not evidence of passing targets.

## Reproducible experiment

1. Create a fresh PostgreSQL database for large-data testing; use the team's existing `sql/01_schema.sql` and load the faculty's `large_data/` CSVs in dependency order (adapt the path in `sql/02_load_data.sql`).
2. Apply `sql/05_indexes.sql`, run `ANALYZE`, and verify counts, constraints, and representative query results.
3. Run `./benchmarks/run_benchmark.sh <large_database_name> large 3 sql/06_optimized_queries.sql` from the repository root. This overwrites the placeholder CSV with measured averages, medians, minima, maxima, scan nodes, and saves three raw plans per query.
4. For every failing target, inspect the corresponding `benchmarks/results/large/<ID>.txt`, fix the query/index in a reproducible migration, and rerun. Keep before/after plans for every scale-specific fix. Writes must be rolled back between runs.
5. Use the same machine and PostgreSQL configuration for seed and large experiments; record hardware, PostgreSQL version, and dataset row counts.

## Performance targets and comparison

The seed times below are the repository's existing **optimized** averages, in milliseconds. `—` means unmeasured, **not** zero or passed. Growth = large average / seed average; pass only when the measured large average is strictly below the target.

| Query | Seed optimized (ms) | Large (ms) | Growth | Target (ms) | Meets target? | Action if missed |
|---|---:|---:|---:|---:|---|---|
| R01 | 0.107 | — | — | <5 | Not evaluated | Inspect large EXPLAIN plan |
| R02 | 0.096 | — | — | <5 | Not evaluated | Inspect large EXPLAIN plan |
| R03 | 0.120 | — | — | <5 | Not evaluated | Inspect large EXPLAIN plan |
| R04 | 0.154 | — | — | <5 | Not evaluated | Inspect large EXPLAIN plan |
| R05 | 0.693 | — | — | <250 | Not evaluated | Inspect large EXPLAIN plan |
| R06 | 2.599 | — | — | <250 | Not evaluated | Inspect large EXPLAIN plan |
| R07 | 2.996 | — | — | <250 | Not evaluated | Inspect large EXPLAIN plan |
| R08 | 0.221 | — | — | <5 | Not evaluated | Inspect large EXPLAIN plan |
| R09 | 0.252 | — | — | <5 | Not evaluated | Inspect large EXPLAIN plan |
| R10 | 0.153 | — | — | <5 | Not evaluated | Inspect large EXPLAIN plan |
| R11 | 0.222 | — | — | <5 | Not evaluated | Inspect large EXPLAIN plan |
| R12 | 0.453 | — | — | <250 | Not evaluated | Inspect large EXPLAIN plan |
| R13 | 19.287 | — | — | <250 | Not evaluated | Inspect large EXPLAIN plan |
| R14 | 3.247 | — | — | <5,000 | Not evaluated | Inspect large EXPLAIN plan |
| R15 | 16.056 | — | — | <5,000 | Not evaluated | Inspect large EXPLAIN plan |
| R16 | 3.257 | — | — | <5,000 | Not evaluated | Inspect large EXPLAIN plan |
| R17 | 13.638 | — | — | <5,000 | Not evaluated | Inspect large EXPLAIN plan |
| R18 | 5.253 | — | — | <250 | Not evaluated | Inspect large EXPLAIN plan |
| R19 | 5.740 | — | — | <5,000 | Not evaluated | Inspect large EXPLAIN plan |
| R20 | 3.861 | — | — | <5,000 | Not evaluated | Inspect large EXPLAIN plan |
| R21 | 0.849 | — | — | <5,000 | Not evaluated | Inspect large EXPLAIN plan |
| R22 | 14.919 | — | — | <250 | Not evaluated | Inspect large EXPLAIN plan |
| R23 | 0.092 | — | — | <5 | Not evaluated | Inspect large EXPLAIN plan |
| R24 | 19.303 | — | — | <5,000 | Not evaluated | Inspect large EXPLAIN plan |
| R25 | 25.818 | — | — | <5,000 | Not evaluated | Inspect large EXPLAIN plan |
| W01 | 0.594 | — | — | <5 | Not evaluated | Inspect large EXPLAIN plan |
| W02 | 0.257 | — | — | <5 | Not evaluated | Inspect large EXPLAIN plan |
| W03 | 1.012 | — | — | <5 | Not evaluated | Inspect large EXPLAIN plan |
| W04 | 7.029 | — | — | <1,000 | Not evaluated | Inspect large EXPLAIN plan |
| W05 | 6.813 | — | — | <250 | Not evaluated | Inspect large EXPLAIN plan |

## Growth analysis (pending large run)

Classify **after measurement**, not by assumption:
- **Approximately unchanged:** typically selective indexed point lookups; confirm using observed growth ratios and index plans.
- **Approximately 20×:** often scans/aggregates processing a roughly constant fraction of a 20× larger relation; verify buffers and row counts.
- **Greater than 20×:** investigate nested-loop amplification, disk spills, stale statistics, sort cost, bad selectivity estimates, and missing partition pruning. Document before/after plans and actual ratios.

The optimized seed results suggest that R13, R15, R17, R22, R24, and R25 merit particular attention, but they cannot be classified into growth bands without large measurements.

## Scale-specific failures and remediation

**Not yet verified.** For each failed query, record: original large plan, observed time and buffers, root cause, index/query/partition change, revised plan, revised time, and semantic equivalence proof. Do not claim a fix without an observed before/after comparison.

## Storage accounting

Execute the following on **each** database and record the results (bytes or `pg_size_pretty`):

```sql
SELECT current_database() AS database_name,
       pg_database_size(current_database()) AS database_bytes;
SELECT sum(pg_relation_size(c.oid)) AS table_bytes,
       sum(pg_indexes_size(c.oid)) AS index_bytes,
       sum(pg_total_relation_size(c.oid)) AS total_relation_bytes
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'linkedin' AND c.relkind IN ('r','p')
  AND NOT c.relispartition;
```

Seed database: **not measured**. Large database: **not measured**. Include TOAST/other overhead when reconciling total database size; avoid summing parent and child partition sizes twice.

## Architecture for 100× growth

### Partitioning

`sql/08_partitioning.sql` builds a **non-destructive demonstration** of RANGE partitioning on `applications.applied_at` (annual UTC boundaries), copies the source rows, creates per-partition indexes through partitioned index definitions, and runs a bounded June 2026 `EXPLAIN (ANALYZE, BUFFERS)`. This is a design demonstration, **not** a production cutover. Time-based partitioning can prune irrelevant partitions for R20 and date-bounded reporting, but member/job lookups without an `applied_at` predicate may touch many partitions. Compare measured plans before adopting it.

**Important key tradeoff:** PostgreSQL requires partition keys in partitioned PRIMARY KEY and UNIQUE constraints. `(application_id, applied_at)` and `(job_id, member_id, applied_at)` cannot enforce the original global `application_id` or `(job_id, member_id)` uniqueness. A real migration must retain these invariants with an appropriate unpartitioned registry/transactional enforcement strategy, or choose another partitioning key and document its compromises. Do not replace the original table blindly.

### Sharding

Sharding by `member_id` places profile, skills, and member application lookups close to the member, benefiting R01/R02/R09/R23-like access. However, R03 connections have two member endpoints and R05 two-hop recommendations can cross shards. Store canonical undirected edges once plus a replicated or maintained adjacency projection per endpoint; fan out bounded neighbor lookups, deduplicate, and reconcile updates. Job-centric recruiter queries R08 and W05, company analytics, and global reporting also become cross-shard. Route them through a job/company-oriented projection or an analytical warehouse, rather than uncontrolled distributed joins. Shard only when actual capacity measurements justify the operational cost.

### Replicas and caching

Route latency-tolerant read-only analytics R12–R17, R19–R21, R24–R25 to read replicas or refreshed reporting tables. R05/R06/R07/R18 may use a short-lived cache with explicit invalidation. Keep W01–W05 on the primary, and use primary reads for immediately consistent R08/R09/R10/R11 and authentication-sensitive R23 where replica lag is unacceptable. R22 can use a read replica only if snapshot freshness is acceptable; document lag and pagination consistency.

### Maintenance

Monitor dead tuples, autovacuum runs, table/index bloat, cache hit rate, WAL generation, replica lag, and query latency percentiles. For high-churn `applications`, consider table-level `autovacuum_vacuum_scale_factor = 0.02` and `autovacuum_analyze_scale_factor = 0.01` as **starting hypotheses**, not tested production settings; tune against observed write rate. Archive/detach old partitions only after retention and FK dependencies are reviewed. Refresh analytical summary tables with a documented cadence, and track refresh duration and staleness.

## Conclusion

The seed workload has optimized measurements, but **next-year readiness is unproven** until the faculty's large dataset is loaded, all 30 queries are benchmarked, failing targets are remediated, and storage and partition pruning are measured. The principal remaining risks are high-cardinality scans, write/index overhead, cross-shard graph queries, partitioned-table uniqueness, and operational maintenance.
