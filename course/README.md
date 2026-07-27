# BioVault Database Masterclass

This folder contains the beginner-to-advanced learning companion for the
BioVault project.

## Ready-to-read files

- `BioVault_Database_Masterclass.pdf` — print-ready A4 course book
- `BioVault_Database_Masterclass.docx` — editable Microsoft Word edition

## Source

- `BioVault_Database_Masterclass.md` — complete course source
- `pandoc-header.tex` — PDF typography, page headers, and code styling
- `../scripts/generate_course.ps1` — reproducible PDF/DOCX generator

## Rebuild

From the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/generate_course.ps1
```

Requirements:

- Pandoc
- XeLaTeX (the repository uses MiKTeX on Windows)
- Arial and Consolas fonts

The book begins with data, tables, and keys, then progresses through ER modeling,
3NF, PostgreSQL DDL/DML, advanced queries, views, indexes, ACID, concurrency,
triggers, auditing, Python CRUD, automated tests, delivery, and oral defense.
It includes guided labs, solution sketches, cheat sheets, a glossary, and
references.

