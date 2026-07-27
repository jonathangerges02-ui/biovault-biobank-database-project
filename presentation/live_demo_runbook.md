# BioVault live demonstration runbook

Target duration: 5–6 minutes. Run commands from the repository root.

## 1. Start and rebuild (about 60 seconds)

```powershell
docker compose up -d database
docker compose exec -T database psql -U biobank -d biobank -f /project/sql/setup.sql
```

Point out the final counts: 12 donors, 10 researchers, 10 projects, 20 samples,
20 aliquots, 15 test requests, and 12 usage events.

## 2. Prove integrity (about 75 seconds)

```powershell
docker compose exec -T database psql -U biobank -d biobank -f /project/sql/test_constraints.sql
```

Highlight:

- malformed donor code is rejected;
- overdraw is rejected;
- expired consent is rejected;
- unassigned researcher is rejected;
- valid use deducts exactly 0.100;
- transaction rolls back, keeping the submitted seed unchanged.

## 3. Show views and complex queries (about 60 seconds)

Enter psql:

```powershell
docker compose exec database psql -U biobank -d biobank
```

Then:

```sql
SET search_path TO biobank, public;

SELECT aliquot_code, sample_code, sample_type,
       current_quantity, quantity_unit, location_code
FROM v_available_inventory
ORDER BY sample_type, aliquot_code;

SELECT project_code, usage_events, distinct_samples, distinct_donors
FROM v_project_usage_summary
ORDER BY usage_events DESC, project_code;
```

Explain that `queries.sql` also contains aggregation, subqueries, `EXISTS`, a
window function, and a recursive storage path.

## 4. Demonstrate atomic usage (about 60 seconds)

```sql
BEGIN;

SELECT current_quantity FROM aliquots WHERE aliquot_id = 1;

SELECT record_sample_usage(
    1, 1, 1, DATE '2026-06-15', 0.050,
    'Live defense demonstration'
);

SELECT current_quantity FROM aliquots WHERE aliquot_id = 1;

ROLLBACK;
```

Say: the function inserted one usage row, the trigger locked and validated the
aliquot, and the rollback makes the demo repeatable.

Exit psql with `\q`.

## 5. Bonus UI CRUD (about 90 seconds)

```powershell
$env:BIOBANK_DATABASE_URL = "postgresql://biobank:biobank_dev@localhost:55432/biobank"
python -m src.app
```

1. Show live dashboard counts.
2. Search samples for `plasma`.
3. Open Donors and add `BIO-D9001`.
4. Edit it from `ACTIVE` to `INACTIVE`.
5. Search for `9001`.
6. Delete the new donor.
7. Try deleting `BIO-D0001`; explain the foreign-key protection message.

## Recovery

If the UI environment is unavailable, run `python -m src.app` without the
environment variable. It uses the submitted SQLite demo and still proves
view/search/CRUD. State clearly that all graded SQL remains PostgreSQL.
