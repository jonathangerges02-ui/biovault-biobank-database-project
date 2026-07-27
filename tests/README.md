# Automated tests

- `test_repository.py` verifies the bonus UI data layer and validated donor CRUD.
- `../sql/test_constraints.sql` verifies PostgreSQL constraints, views, consent
  enforcement, researcher authorization, inventory deduction, and audit behavior.

Run the Python suite from the repository root:

```powershell
python -m pytest -q
```

Run the full PostgreSQL acceptance suite:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/test_database.ps1
```
