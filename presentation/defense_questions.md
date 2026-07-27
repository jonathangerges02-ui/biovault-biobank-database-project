# Defense questions and model answers

## Design

**Why did you choose a biobank?**  
It naturally contains strong entities, one-to-many lineage, a meaningful
many-to-many relationship, history, consent, physical inventory, and integrity
rules. That makes it suitable for demonstrating the full database lifecycle.

**Why is donor ID not copied into samples?**  
The donor is functionally determined by the sample's collection event. Copying
it would create a transitive dependency and allow inconsistent donor/event pairs.

**Why both identity keys and unique codes?**  
Identity keys make foreign keys small and stable. Codes are meaningful candidate
keys used by people and are still protected by unique constraints.

**Explain the many-to-many relationship.**  
A researcher works on many projects and a project has many researchers.
`project_researchers` resolves it with a composite primary key and stores facts
about the membership: role, joined date, and left date.

**Why is storage self-referencing?**  
Facility, room, freezer, rack, and box form a hierarchy. A self-reference allows
arbitrary depth and makes one recursive query sufficient.

## Normalization

**Give one 3NF decision.**  
Sample type name, unit, and temperature range depend on sample type ID, not
sample ID, so they are stored in `sample_types` rather than repeated in
`samples`.

**Is the audit log normalized?**  
It intentionally stores JSON snapshots. It is a technical event history whose
purpose is to preserve exact row state, not operational master data.

## SQL and integrity

**Why use NUMERIC instead of FLOAT?**  
Volumes and counts require predictable decimal comparison. `NUMERIC(14,3)`
avoids binary floating-point rounding and supports the submitted cell counts.

**Why are the trigger checks not only in the UI?**  
Other clients can connect to the database. A database rule protects every client
and cannot be bypassed by a different interface.

**What does FOR UPDATE solve?**  
It locks the aliquot row. Two concurrent usages cannot both read the same
quantity and overdraw it; the second transaction waits and rechecks the updated
row.

**What happens if the trigger fails after beginning the deduction?**  
The function, trigger, insert, and update are one PostgreSQL transaction. An
exception rolls everything back.

**Why use ON DELETE RESTRICT?**  
Deleting referenced donor, sample, or aliquot history would damage traceability.
Restrict makes that loss explicit instead of silent.

**Why are foreign-key indexes explicit?**  
PostgreSQL creates indexes for primary and unique keys, but not automatically for
every referencing foreign key. The declared indexes match expected joins.

## Views and queries

**Difference between a view and a table?**  
A regular view stores a query definition, not its own data. It presents a stable
read model based on current table rows.

**Explain the recursive CTE.**  
The anchor selects root storage units. The recursive part repeatedly joins each
parent to its children and appends the child name to the path.

**Why do modification examples roll back?**  
The instructor can rerun them repeatedly without polluting the submitted seed.
They still execute real insert/update/delete statements.

## Bonus

**Is the UI really connected?**  
Yes. Dashboard counts, searches, and CRUD call parameterized repository queries.
With `BIOBANK_DATABASE_URL`, those queries use the submitted PostgreSQL schema.

**Why provide SQLite too?**  
It is a clearly labeled zero-configuration demonstration mirror. It makes the UI
portable; PostgreSQL remains the grading target and source of truth.

**How is SQL injection avoided?**  
User values are passed as parameters (`%s` or `?`), not concatenated into SQL.

## Likely live changes

**Add a query for samples with no test requests.**

```sql
SELECT s.sample_code
FROM biobank.samples s
WHERE NOT EXISTS (
    SELECT 1
    FROM biobank.test_requests tr
    WHERE tr.sample_id = s.sample_id
);
```

**Change a requested test to in progress.**

```sql
UPDATE biobank.test_requests
SET request_status = 'IN_PROGRESS'
WHERE request_code = 'TR-00011'
RETURNING request_code, request_status;
```

**Count samples by quality.**

```sql
SELECT quality_status, COUNT(*)
FROM biobank.samples
GROUP BY quality_status
ORDER BY quality_status;
```
