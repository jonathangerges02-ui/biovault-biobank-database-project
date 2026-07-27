# Verification summary

Verification date: **2026-07-27**  
Database: **PostgreSQL 16.14, 64-bit (Alpine container)**  
Application runtime: **Python 3.11.4**

## Clean database build

`sql/setup.sql` completed from a recreated `biobank` schema:

```text
donors=12
researchers=10
projects=10
samples=20
aliquots=20
test_requests=15
usage_events=12
BioVault setup completed successfully.
```

Verified database objects:

```text
base tables=15
views=3
indexes=43 (including PK/UNIQUE indexes and 13 targeted CREATE INDEX statements)
triggers=10
```

## PostgreSQL acceptance suite

Command:

```powershell
docker compose exec -T database psql -U biobank -d biobank -f /project/sql/test_constraints.sql
```

Result:

```text
PASS: all nine main tables contain at least 10 rows
PASS: donor code CHECK constraint rejects malformed codes
PASS: aliquot quantity CHECK constraint works
PASS: valid use atomically deducted 0.100 from inventory
PASS: inventory overdraw is rejected
PASS: expired consent blocks research use
PASS: unassigned researcher is rejected
PASS: audit trigger records donor updates
PASS: all three required views exist
ALL DATABASE ACCEPTANCE TESTS PASSED
```

The suite is wrapped in a transaction and rolled back, so it is repeatable.

## Python bonus-application suite

Command:

```powershell
$env:PYTEST_DISABLE_PLUGIN_AUTOLOAD = "1"
python -m pytest -q
```

Result:

```text
........
8 passed
```

Covered behaviors:

- SQLite demonstration initialization and live dashboard counts;
- joined sample and test-request search;
- donor create/read/update/delete round trip;
- invalid code, sex, year, and date rejection;
- foreign-key protection for referenced donor records.

## PostgreSQL application integration

The same repository used by the UI was connected to the submitted PostgreSQL
schema on port 55432. Verified result:

```text
counts {'donors': 12, 'samples': 20, 'test_requests': 15}
plasma search rows 5
create BIO-D9002
update status INACTIVE
delete True
```

The temporary integration-test donor was deleted successfully; the final seed
returned to 12 donors.

## Deliverable integrity

- `report.docx` opens as valid OOXML.
- `report.pdf` contains 12 pages.
- `presentation.pptx` opens as valid OOXML and contains 18 slides.
- `BioVault_Presentation_Video.mp4` is 1280×720, approximately 18:23, with
  H.264 video and AAC audio.
- `diagrams/ERD.png` is 3400×1900 and its exact source is included in
  `diagrams/ERD.mmd`.
