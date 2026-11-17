# Baseline Query Timings

Each of the 30 workload queries was executed 3 times.
Timings are PostgreSQL execution times in milliseconds.

| Query | Type | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Average (ms) |
|---|---|---:|---:|---:|---:|
| R01 | READ | 9.139 | 9.449 | 9.702 | 9.430 |
| R02 | READ | 10.152 | 8.386 | 7.259 | 8.599 |
| R03 | READ | 7.493 | 5.875 | 5.574 | 6.314 |
| R04 | READ | 16.184 | 14.676 | 12.248 | 14.369 |
| R05 | READ | 38.012 | 28.152 | 24.265 | 30.143 |
| R06 | READ | 4.152 | 4.129 | 4.316 | 4.199 |
| R07 | READ | 6.469 | 5.938 | 5.679 | 6.029 |
| R08 | READ | 0.566 | 0.071 | 0.071 | 0.236 |
| R09 | READ | 3.273 | 3.309 | 3.788 | 3.457 |
| R10 | READ | 5.285 | 5.672 | 5.504 | 5.487 |
| R11 | READ | 12.568 | 10.968 | 9.442 | 10.993 |
| R12 | READ | 11.953 | 9.450 | 9.666 | 10.356 |
| R13 | READ | 35.785 | 25.199 | 22.119 | 27.701 |
| R14 | READ | 8.433 | 8.497 | 8.455 | 8.462 |
| R15 | READ | 8.581 | 8.760 | 8.584 | 8.642 |
| R16 | READ | 1.938 | 1.897 | 2.286 | 2.040 |
| R17 | READ | 43.556 | 35.756 | 35.260 | 38.191 |
| R18 | READ | 8.072 | 8.124 | 7.856 | 8.017 |
| R19 | READ | 225.253 | 227.831 | 226.332 | 226.472 |
| R20 | READ | 6.827 | 6.902 | 6.927 | 6.885 |
| R21 | READ | 86.945 | 80.389 | 81.827 | 83.054 |
| R22 | READ | 30.898 | 28.932 | 28.785 | 29.538 |
| R23 | READ | 6.674 | 7.394 | 7.459 | 7.176 |
| R24 | READ | 10.927 | 10.803 | 10.595 | 10.775 |
| R25 | READ | 38.041 | 33.533 | 35.001 | 35.525 |
| W01 | WRITE | 0.529 | 0.495 | 0.446 | 0.490 |
| W02 | WRITE | 3.553 | 3.265 | 3.534 | 3.451 |
| W03 | WRITE | 2.704 | 3.632 | 5.984 | 4.107 |
| W04 | WRITE | 6.618 | 5.514 | 6.766 | 6.299 |
| W05 | WRITE | 9.515 | 10.150 | 8.474 | 9.380 |

## Execution Plan: Scan Types and Performance Notes

The scan types below are taken from the recorded PostgreSQL execution plans. Sequential scans are not necessarily inefficient: they can be appropriate when a query needs to process a large part of a table.

| Query | Observed scan type(s) | Performance explanation |
|---|---|---|
| R01 | Index Scan (members, companies); Seq Scan (positions) | The member and company lookups use indexes. Positions are scanned to find the member's current position. |
| R02 | Seq Scan (positions); Index Scan (companies) | Positions are scanned to find the member's experience records; company details use the primary-key index. |
| R03 | Bitmap Index Scan and Bitmap Heap Scan (connections) | The bitmap plan supports the two-sided OR condition on member_a/member_b and retrieves matching connections. |
| R04 | Parallel Seq Scan (connections) | Both sides of the mutual-connection query use OR conditions, requiring broad scans of the connections table. |
| R05 | Bitmap Index Scan and Bitmap Heap Scan (connections); CTE Scan (my_conn) | The query builds the first-degree connection list, then repeatedly uses it while finding and counting second-degree connections. |
| R06 | Seq Scan (jobs); Index Scan (companies) | PostgreSQL scans jobs for the status, title, city/workplace and date filters. The leading-wildcard ILIKE condition makes ordinary title indexes less useful. |
| R07 | Seq Scan (jobs, job_skills); Index Only Scan (member_skills) | The query joins job skills with the member's skills, then groups and counts matches. The job and job-skill scans process many candidate rows. |
| R08 | Index Scan (applications_job_member_unique) | The job filter uses the applications composite index, making this grouped applicant-status query comparatively fast. |
| R09 | Index Scan (applications_job_member_unique, jobs_pkey, companies_pkey) | Indexed lookups retrieve the member's applications and related job/company records, avoiding broad table scans. |
| R10 | Seq Scan (invitations); Index Scan (members_pkey) | The sender's member record is indexed, but invitations are scanned to find pending invitations for the recipient. |
| R11 | Parallel Seq Scan (profile_views) | PostgreSQL scans profile-view records to filter the target member and date range before grouping viewers. |
| R12 | Seq Scan (companies, positions) | The company-name and current-position filters require scanning these tables; the query then aggregates employee counts and tenure. |
| R13 | Seq Scan (profile_views) | The NOT IN subquery must identify members who have viewed profiles. The profile_views table is scanned to build that set. |
| R14 | Seq Scan (jobs, applications, companies) | The query joins and filters application/job/company data before grouping hires by company. Multiple broad scans contribute to the work. |
| R15 | Seq Scan (jobs, skills); Index Only Scan (job_skills) | The year filter and aggregation process job-skill demand across 2026 postings. The year extraction makes a simple date-index lookup less useful. |
| R16 | Seq Scan (cities, jobs) | The query processes salary-bearing job postings and groups them by title and city. A scan of the jobs table is needed for this aggregation. |
| R17 | Seq Scan (positions, companies); Subquery Scan (t); Index Scan (companies_pkey) | The LEAD window function processes position history to identify the next company. The window operation and subsequent joins add substantial work. |
| R18 | Parallel Seq Scan (member_skills); Seq Scan (skills); Index Scan (members_pkey) | The query searches skill records for SQL endorsements, then checks matching members. Scanning member_skills is the main broad operation. |
| R19 | Seq Scan (jobs, companies); Index Scan (applications_job_member_unique) | This is the slowest query. Its correlated subqueries repeatedly count open jobs and June applications for each IT Services company, causing repeated scans and index lookups. |
| R20 | Parallel Seq Scan (applications) | The query processes June applications, groups them by day and calculates a running total. Casting applied_at to a date can limit the usefulness of a normal timestamp index. |
| R21 | Seq Scan (skills, member_skills); Subquery Scan (t) | ROW_NUMBER ranks members within every skill. PostgreSQL must process and rank a large member_skills dataset before selecting the top member for each skill. |
| R22 | Seq Scan (applications) | OFFSET 100000 requires PostgreSQL to process and skip a large number of rows before returning the requested page, making deep pagination expensive. |
| R23 | Seq Scan (members) | lower(email) is applied in the filter. Without a matching functional index on lower(email), PostgreSQL scans members to find the case-insensitive email match. |
| R24 | Seq Scan (invitations, members) | The query processes invitations from 2026, joins their senders and calculates acceptance rates for premium and free members. |
| R25 | Seq Scan (positions); Subquery Scan (t) | The LAG window function needs position history ordered by member and start date. PostgreSQL processes the position records before filtering career gaps. |
| W01 | No table scan reported; unique conflict-arbiter index | The insert uses applications_job_member_unique to check for an existing application. The indexed conflict check keeps this write very fast. |
| W02 | Seq Scan (invitations); Index Scan (invitations_pkey) | The subquery scans invitations to find the oldest pending invitation for the recipient; the selected row is then updated using its primary key. |
| W03 | Seq Scan (invitations) | The subquery searches for the oldest pending invitation before inserting a normalized connection. The connection insert also checks conflicts. |
| W04 | Seq Scan (jobs) | The update checks jobs for open status and an expired closing date. A broad scan is expected when checking many rows for a bulk update. |
| W05 | Seq Scan (companies, jobs); Index Scan (applications_job_member_unique) | The query identifies TCS jobs and finds matching unreviewed applications. Repeated application lookups and the company/job filtering contribute to its execution time. |

### Key observations

- R19 is the main performance bottleneck because its correlated subqueries repeat work for each company.
- R21, R17 and R25 perform window-function operations over large datasets.
- R22 demonstrates the cost of deep OFFSET-based pagination.
- R23 can benefit from a functional index on lower(email), subject to the Phase 4 optimization design.
- Sequential scans on large tables should be evaluated against the amount of data the query needs to process; they are not automatically a sign of a poor plan.
- W01 benefits from the unique conflict-arbiter index, while W02 and W03 scan invitations to locate the pending invitation.
