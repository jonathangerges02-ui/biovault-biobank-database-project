# BioVault voiceover script

Planned duration: **17:50** (18 slides). Speak naturally and replace the student placeholders.

> The generated rehearsal video uses a synthetic system voice. For academic submission, record this script in the submitting student's own voice if the instructor requires personal narration.

## Slide 1: BioVault (0:00–0:45)

Hello. My project is BioVault, a biobank and biospecimen management system implemented with PostgreSQL and a connected Python desktop application. The goal is to manage anonymized donors, consent, collection, samples, aliquots, storage, testing, and research use in one traceable relational design. I will explain the requirements, the entity relationship model, the mapping to Third Normal Form, the implementation, and the most important trigger. I will then show test evidence and the bonus application. All submitted data is synthetic, and direct donor identity is intentionally outside this database. Please replace the name and student ID placeholders on this slide before final submission.

## Slide 2: The database problem (0:45–1:40)

A biobank is not simply a sample list. One donor may sign different consent types and versions and may participate in several collection events. Each event can produce multiple samples, and each sample is divided into physical aliquots stored at specific positions. Researchers work across several ethics-approved projects, so that relationship is many-to-many. Finally, every research use consumes a measurable amount and must remain linked to the donor's permission, the project, the researcher, and the storage lineage. In a spreadsheet these facts repeat, causing update, insertion, and deletion anomalies. BioVault replaces that fragile structure with normalized relations and database-side integrity rules.

## Slide 3: Scope and stakeholders (1:40–2:35)

The system scope is a research biobank. It covers pseudonymous donor registration, versioned consent, collection events, sample processing, aliquots, hierarchical storage, laboratory test requests, projects, membership, and sample consumption. Its main users are the biobank manager, laboratory scientist, quality specialist, principal investigator, and database administrator. Clinical diagnosis, treatment, billing, and instrument control are excluded. Direct identifiers such as names, national IDs, addresses, and phone numbers are also excluded. In a real organization a separate authorized custodian would keep the re-identification key. This scope makes the project realistic while keeping its purpose and privacy boundary clear.

## Slide 4: Core business rules (2:35–3:35)

The design begins with explicit business rules. Codes for donors, samples, aliquots, projects, and requests are unique and format checked. Consent is typed, versioned, dated, and can be active, expired, withdrawn, or declined. Each collection event must have one donor and one collector. Every sample has one event and one type. An aliquot occupies a unique position, and its current quantity can never be negative or exceed its initial quantity. The key rule is research consumption: general research consent must be active on the use date, the project must be authorized, the researcher must be a member on that date, and sufficient quantity must remain. These conditions are enforced inside PostgreSQL.

## Slide 5: Conceptual ER model (3:35–4:50)

This is the final entity relationship model. At the top are donor, consent, collection, and researcher entities. The specimen chain continues through sample type, sample, aliquot, and storage unit. Test types and test requests model the laboratory workflow. Research projects connect to researchers through the project researchers associative entity, and sample usage connects an aliquot, project, and researcher. The audit log is a technical history relation. The colors group related responsibilities. The diagram shows primary, foreign, and unique candidate keys. A high-resolution PNG and an exact Mermaid crow's-foot source are included, so both visual inspection and cardinality details are available.

## Slide 6: Cardinality and participation (4:50–5:45)

The important cardinalities follow the domain. One donor can have zero or many consents and collection events, but every consent and event requires exactly one donor. An event produces one or more samples by process expectation, and every sample requires exactly one event and type. A sample is divided into one or more aliquots, while every aliquot requires one sample and one storage unit. Projects and researchers form the required many-to-many relationship, resolved by a bridge containing role and membership dates. Total child participation is enforced by not-null foreign keys. Optional participation is represented by a nullable foreign key, such as the project on a test request, or by no child row.

## Slide 7: Relational schema and keys (5:45–6:45)

The relational schema uses generated identity values as compact primary keys. Human-readable codes remain protected as unique candidate keys, so users can refer to BIO-D0001 or SMP-00001 without using those strings in every foreign key. The project researcher bridge has the composite primary key project ID plus researcher ID, preventing duplicate membership. Most historical relationships use delete restrict because silently deleting a donor or sample would break scientific traceability. Cascade is limited to project membership rows, which cannot exist independently of a project. Foreign key indexes are declared explicitly because PostgreSQL does not automatically create every supporting index.

## Slide 8: Normalization to 3NF (6:45–7:50)

Normalization starts from a hypothetical wide spreadsheet containing donor, consent, sample, storage, project, researcher, and usage columns. First Normal Form removes repeating consent, member, aliquot, and test groups and gives every relation a key. Second Normal Form matters most in the composite project membership table: role and membership dates depend on both project and researcher, while researcher and project descriptions are stored elsewhere. Third Normal Form removes transitive dependencies. Consent descriptions belong to consent types, sample units and temperature ranges belong to sample types, and test names belong to test types. Donor data is reached through the collection event instead of copied into samples. Audit JSONB is an intentional historical snapshot, not operational master data.

## Slide 9: PostgreSQL implementation (7:50–8:45)

Implementation is separated into readable scripts. Create tables recreates the schema, tables, constraints, and thirteen indexes. Triggers and procedures installs timestamps, consent and inventory logic, the public usage function, and auditing. Load data inserts coherent synthetic records and calls the real usage function, so the seed itself exercises business logic. Views creates the three read models. Setup uses psql include commands to run them in the correct order and stops on the first error. Docker Compose provides PostgreSQL 16 on host port 55432, avoiding conflict with common existing database installations. This makes a clean demonstration repeatable.

## Slide 10: Constraints and indexes (8:45–9:40)

The schema combines several layers of integrity. Check constraints validate code formats, status domains, date order, positive quantities, and the rule that current quantity cannot exceed initial quantity. Unique constraints protect business identifiers, ethics approval codes, consent versions, and storage positions. Foreign keys guarantee complete lineage from usage back to aliquot, sample, collection event, and donor. Indexes match expected access paths: active consent by donor and date, samples by type and status, tests by sample and workflow state, usage by project and date, and audit rows by record. A partial index covers only available aliquots with stock, keeping that operational search smaller.

## Slide 11: Advanced business object (9:40–11:00)

The most important advanced object is the sample usage workflow. The application or SQL client calls record sample usage with an aliquot, project, researcher, date, quantity, and purpose. Before insert, the trigger selects the aliquot for update. This row lock prevents two concurrent sessions from reading the same old quantity and both spending it. It checks that the aliquot exists and is usable, and that the request does not exceed remaining stock. It then checks project dates and status, verifies dated researcher membership, traces the aliquot back to its donor, and confirms active research-use consent on that date. Only then does it deduct inventory. If any step fails, the entire transaction rolls back.

## Slide 12: Views and SQL operations (11:00–12:00)

Three views simplify repeated questions. Available inventory presents accepted samples, remaining aliquots, donor codes, and physical locations. Project usage summary reports events, samples, donors, and consumption for every project. Donor consent status presents a current research permission flag. The query script demonstrates much more than basic select statements: a six-table lineage join, aggregation, group by with having, a correlated unit-specific subquery, two exists predicates, dense rank, a recursive storage path, and case classification. Insert, update, delete, and business function calls are wrapped in transactions that roll back, so I can rerun the file safely during the defense.

## Slide 13: Meaningful synthetic data (12:00–12:45)

The seed is synthetic but meaningful. It includes twelve donors, ten researchers, ten projects, twenty project memberships, twelve collection events, twenty samples, fourteen storage units, twenty aliquots, fifteen test requests, and twelve usage events. Lookup tables are smaller where logically justified. States are varied: tests may be requested, in progress, completed, or cancelled. Samples can be accepted, quarantined, available, or reserved. One donor has expired research consent and another has withdrawn it. Their historical material remains in the database for traceability, but the usage trigger blocks new research consumption. This lets the data demonstrate both successful and rejected workflows.

## Slide 14: Verification evidence (12:45–13:50)

Testing is executable evidence, not only screenshots. The PostgreSQL suite first confirms that nine main tables meet the ten-row requirement. It then proves malformed donor codes and impossible quantities are rejected. A valid usage deducts exactly the requested amount. Separate negative tests prove that overdraw, expired consent, and an unassigned researcher are rejected. Another test verifies that critical updates create an audit row, and the final assertion verifies all views. The entire suite finishes with all database acceptance tests passed. The Python suite has eight passing tests covering live counts, joined searches, the complete donor CRUD round trip, validation errors, and foreign-key protection.

## Slide 15: Bonus: connected desktop UI (13:50–15:05)

The bonus application is a Tkinter desktop interface. Its dashboard reads live counts from the database. Donor, sample, and test request screens show database rows and support cross-field search. Donor creation and editing use controlled options and validate code format, dates, birth year, blood type, and status before parameterized SQL is sent. Delete is real; a new unreferenced donor can be deleted, while a seeded donor is protected by the foreign key and the UI reports the database error. The same repository works with PostgreSQL. A SQLite mirror is included for a zero-configuration demonstration, but it is clearly labeled and PostgreSQL remains the submitted source of truth.

## Slide 16: Live demonstration plan (15:05–16:05)

For the live demonstration I use a deterministic sequence. First I run setup against a clean schema and show the returned table counts. Second I run the acceptance suite so the positive and negative rules are visible. Third I query available inventory, project usage, and the recursive freezer path. I call the usage function inside a transaction, show the reduced aliquot quantity, and roll back. Finally I open the PostgreSQL-connected application, search samples, create a donor, edit its status, find it with search, and delete it. I also attempt to delete a referenced donor to demonstrate that the interface respects database constraints. The full command list is included in the runbook.

## Slide 17: Limitations and future work (16:05–16:55)

This project has deliberate limits. Authentication is not implemented because the bonus is a trusted local demonstration. Test results use generic numeric and text fields rather than a specialized result schema for every assay. Quantities preserve their units but there is no conversion catalog. The storage hierarchy does not yet prevent an invalid parent type such as a box directly under a facility. Production work would add role-based access, TLS, secrets management, encrypted backups, retention policies, barcode scanning, temperature sensor events, reservation workflow, chain of custody, and possibly row-level security. These extensions fit the current normalized core without changing its main lineage.

## Slide 18: Conclusion & questions (16:55–17:50)

In conclusion, BioVault completes the database lifecycle from requirements and business rules through conceptual design, Third Normal Form, PostgreSQL implementation, data, queries, advanced logic, testing, documentation, and the bonus interface. The design is traceable and privacy-aware, and every key integrity claim is executable. The strongest technical decision is placing consent, project authorization, concurrency control, and stock deduction inside PostgreSQL so every client receives the same protection. The repository includes a one-command setup, test evidence, a detailed report, this presentation, the voiceover script, a live demo runbook, and defense questions. Thank you. I am ready to explain any table, constraint, query, normalization decision, or test.
