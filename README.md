# BioVault — Biobank and Biospecimen Management System

BioVault is a complete relational-database project for an anonymized research
biobank. It covers requirements analysis, ER modeling, 3NF mapping, PostgreSQL
implementation, synthetic data, advanced queries, business-rule enforcement,
automated testing, documentation, presentation, and a connected desktop CRUD
application for the five bonus marks.

**Public repository:**  
https://github.com/jonathangerges02-ui/biovault-biobank-database-project

> **Student:** `[REPLACE WITH STUDENT NAME]`  
> **Student ID:** `[REPLACE WITH STUDENT ID]`  
> **Course:** Fundamentals of Databases  
> **DBMS:** PostgreSQL 16 (SQLite is provided only for instant UI demonstration)

## What is included

- 14 operational/support tables plus the `project_researchers` M:N bridge
- 12–20 meaningful rows in every main table and smaller justified lookup tables
- primary, foreign, unique, not-null, date, quantity, format, and status constraints
- 13 targeted indexes, including a partial available-inventory index
- three views for inventory, project usage, and consent monitoring
- a concurrency-safe trigger and function that enforce consent, project
  membership, project dates, and remaining aliquot quantity
- update/delete auditing for donors, samples, and aliquots
- 16 demonstrations covering joins, aggregation, subqueries, `EXISTS`, a
  recursive CTE, a window function, and reversible INSERT/UPDATE/DELETE
- PostgreSQL acceptance tests and Python UI tests
- a desktop interface with dashboard, data viewing, search, and validated donor
  create/update/delete operations
- report in DOCX/PDF, ERD in PNG/source form, PowerPoint, narration script,
  defense guide, and demonstration video
- a complete English beginner-to-advanced course book in PDF and editable DOCX,
  with guided labs, solutions, cheat sheets, and a glossary

## Beginner-to-advanced course book

The learning companion starts at “What is data?” and progresses through the
entire project: requirements, ER modeling, keys, 3NF, PostgreSQL, constraints,
basic and advanced SQL, views, indexes, ACID transactions, concurrency-safe
triggers, auditing, the Python CRUD application, automated testing, Git, and
oral defense.

- [Read the PDF course](course/BioVault_Database_Masterclass.pdf)
- [Open the editable Word edition](course/BioVault_Database_Masterclass.docx)
- [Browse the Markdown source](course/BioVault_Database_Masterclass.md)
- [Course build instructions](course/README.md)

## Repository layout

```text
.
├── README.md
├── report.docx
├── report.pdf
├── presentation.pptx
├── compose.yaml
├── sql/
│   ├── create_tables.sql
│   ├── load_data.sql
│   ├── queries.sql
│   ├── views.sql
│   ├── triggers_procedures.sql
│   ├── test_constraints.sql
│   └── setup.sql
├── diagrams/
│   ├── ERD.png
│   └── ERD.mmd
├── src/
│   ├── app.py
│   ├── database.py
│   ├── repository.py
│   └── sqlite_demo.sql
├── tests/
├── docs/
├── presentation/
├── evidence/
├── course/
└── scripts/
```

## Quick start: PostgreSQL

Prerequisites: Docker Desktop and a terminal in the repository root.

```powershell
docker compose up -d database
docker compose exec -T database psql -U biobank -d biobank -f /project/sql/setup.sql
docker compose exec -T database psql -U biobank -d biobank -f /project/sql/test_constraints.sql
```

The container publishes PostgreSQL on host port `55432` to avoid common local
port conflicts. The submitted application URL is:

```text
postgresql://biobank:biobank_dev@localhost:55432/biobank
```

Run the complete setup, database tests, and query demonstration:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/test_database.ps1 -KeepDatabase
```

Stop the project container without deleting its volume:

```powershell
docker compose down
```

For a clean rebuild, remove only this project's volume and rerun setup:

```powershell
docker compose down -v
docker compose up -d database
docker compose exec -T database psql -U biobank -d biobank -f /project/sql/setup.sql
```

## Bonus application

### Zero-configuration demonstration

Python 3.11+ includes SQLite and Tkinter on the standard Windows installer.
The first run creates `data/biobank_demo.db` from the submitted synthetic seed.

```powershell
python -m src.app
```

### Connect the same UI to PostgreSQL

Start and initialize PostgreSQL first, then:

```powershell
$env:BIOBANK_DATABASE_URL = "postgresql://biobank:biobank_dev@localhost:55432/biobank"
python -m pip install -r src/requirements.txt
python -m src.app
```

The UI reads the database rather than hard-coded lists. It provides:

- dashboard counts from live tables;
- donor, sample, and test-request viewing;
- cross-field searching;
- validated donor creation and update;
- protected deletion with clear foreign-key error reporting.

The SQLite mode is a portable demonstration convenience. PostgreSQL remains the
source of truth and the target used by all graded SQL scripts.

## Tests

Python data-layer and CRUD tests:

```powershell
$env:PYTEST_DISABLE_PLUGIN_AUTOLOAD = "1"
python -m pytest -q
```

PostgreSQL acceptance tests:

```powershell
docker compose exec -T database psql -U biobank -d biobank -f /project/sql/test_constraints.sql
```

The database suite proves:

1. all nine main tables exceed the ten-row requirement;
2. malformed donor codes are rejected;
3. impossible aliquot quantities are rejected;
4. valid usage deducts stock;
5. inventory overdraw is rejected;
6. expired consent blocks use;
7. unassigned researchers are blocked;
8. critical updates are audited;
9. all three views exist.

See [evidence/test_summary.md](evidence/test_summary.md) for the verified result.

## Design highlights

The operational schema is in Third Normal Form. Lookup facts such as sample type,
test type, and consent type are stored once. Donor identity is reached through
the collection event instead of being copied into samples and aliquots.
Project membership is an associative relation with its own role and validity
dates.

`record_sample_usage(...)` is the only intended write path for research
consumption. Its trigger locks the target aliquot and checks active consent,
researcher membership, project validity, status, and available quantity before
deducting stock in the same transaction.

Detailed reasoning:

- [Scope and business rules](docs/business_rules.md)
- [Relational schema](docs/relational_schema.md)
- [Normalization decisions](docs/normalization.md)
- [Data dictionary](docs/data_dictionary.md)
- [References](docs/references.md)

## Presentation and defense

- Open `presentation.pptx`.
- Follow `presentation/voiceover_script.md` for a 15–20 minute explanation.
- Use `presentation/live_demo_runbook.md` for a deterministic live demo.
- Study `presentation/defense_questions.md` before the oral defense.
- `presentation/BioVault_Presentation_Video.mp4` is a generated rehearsal
  version. Replace its synthetic narration with the submitting student's own
  voice before final academic submission if the instructor requires personal
  narration.

## Academic integrity

All records are synthetic. Domain and technical references are acknowledged in
the report. The submitting student must replace the name/ID placeholders,
review every design decision and SQL statement, and be able to modify or explain
them during defense. AI-assisted material should be disclosed if required by the
institution's policy.

## Publish as the required public GitHub repository

The local repository is already committed on branch `main`. Authenticate the
GitHub CLI once, then run the included guarded publishing script:

```powershell
gh auth login -h github.com -p https -w
powershell -ExecutionPolicy Bypass -File scripts/publish_github.ps1
```

The script refuses to publish a dirty worktree or overwrite an existing
`origin`. By default it creates the public repository
`biovault-biobank-database-project`, pushes `main`, and prints the public URL.

Before academic submission, complete [SUBMISSION_CHECKLIST.md](SUBMISSION_CHECKLIST.md)
and replace the student name/ID placeholders.
