# Final submission checklist

## Required one-time personalization

- [ ] Replace `[REPLACE WITH STUDENT NAME]` everywhere.
- [ ] Replace `[REPLACE WITH STUDENT ID]` everywhere.
- [ ] Regenerate the report and presentation after replacement.
- [ ] Record the presentation in the submitting student's own voice if required.

Find the remaining placeholders:

```powershell
rg -n "\[REPLACE WITH STUDENT (NAME|ID)\]"
```

Regenerate binary deliverables:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/generate_report.ps1
python scripts/generate_presentation.py
powershell -ExecutionPolicy Bypass -File scripts/render_video.ps1
```

## Technical verification

- [x] Approved topic selected: Biobank and Biospecimen Management System.
- [x] 15 relations, including a many-to-many associative table.
- [x] ER diagram includes keys, cardinalities, and participation explanation.
- [x] Relational design normalized through Third Normal Form.
- [x] PostgreSQL DDL includes constraints, indexes, and schema comments.
- [x] Every main table contains at least ten meaningful synthetic rows.
- [x] SQL includes joins, aggregation, subqueries, CTE, window function, and CRUD.
- [x] Three views are included.
- [x] Consent/inventory trigger, public function, and audit triggers are included.
- [x] PostgreSQL acceptance suite passed.
- [x] Python UI tests passed: 8/8.
- [x] PostgreSQL-connected donor CRUD integration passed.
- [x] Report opens as DOCX and PDF.
- [x] Presentation opens as an 18-slide PPTX.
- [x] Rehearsal video is 18:23 with H.264 video and AAC audio.
- [x] Bonus application performs validated database-backed CRUD.
- [x] Git repository is clean and committed.
- [ ] Public GitHub repository URL recorded below.

Public repository: `________________________________________`

## Final upload

After authenticating GitHub CLI:

```powershell
gh auth login -h github.com -p https -w
powershell -ExecutionPolicy Bypass -File scripts/publish_github.ps1
```

Then copy the printed public URL above and submit it to the instructor.
