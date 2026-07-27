# Scope, assumptions, and business rules

## Scope

BioVault manages anonymized human research biospecimens from registration through
consent, collection, processing, aliquoting, storage, testing, and authorized
research consumption. It supports biobank managers, laboratory staff, quality
staff, and approved researchers. Clinical treatment, billing, diagnosis, direct
patient care, and direct personal identifiers are outside scope.

## Assumptions

- `donor_code` is a pseudonymous identifier. Names, national IDs, addresses,
  phone numbers, and direct contact information are maintained outside this
  research database by an authorized custodian.
- All timestamps are stored as `TIMESTAMPTZ`; the display layer may localize them.
- Quantities are not summed across incompatible units. Reports group or label
  units explicitly.
- Every physical aliquot occupies one unique position within a storage box.
- The submitted dataset is synthetic and contains no real human data.
- PostgreSQL 16 or later is the grading target. SQLite is used only as the
  zero-configuration demonstration mode for the bonus UI.

## Major business rules

1. Every donor has one immutable, unique code matching `BIO-D0000`.
2. A donor may grant several consent types and several document versions.
3. A consent expiry date cannot precede its grant date.
4. Every collection event belongs to exactly one donor and is recorded by one
   researcher.
5. Every sample comes from exactly one collection event and one sample type.
6. Every sample has positive initial quantity and a controlled quality/status.
7. A sample is divided into one or more aliquots; an aliquot belongs to exactly
   one sample.
8. An aliquot's remaining quantity is never negative and never exceeds its
   initial quantity.
9. A storage position is unique within a storage unit.
10. Storage units form a hierarchy: facility → room → freezer → rack → box.
11. A researcher may join many projects and a project has many researchers;
    `project_researchers` resolves this many-to-many relationship.
12. Each project has one lead researcher and one unique ethics approval code.
13. Research use is allowed only with active `RESEARCH_USE` consent on the use
    date.
14. The researcher recording use must be assigned to the project on that date.
15. The project must be authorized on the use date.
16. A usage transaction locks the aliquot, rejects an overdraw, and deducts the
    quantity atomically.
17. Updates and deletes to donors, samples, and aliquots are written to an audit
    log.
18. Completed test requests require a completion date, and it cannot precede
    the request date.
19. Lookup values and status columns use foreign keys or `CHECK` constraints to
    prevent invalid categories.
20. Donors, samples, aliquots, and historical usage use restrictive deletion so
    that scientific traceability is not silently lost.

## Participation constraints

- **Total participation:** each consent requires a donor and consent type; each
  collection event requires a donor and collector; each sample requires a
  collection event and sample type; each aliquot requires a sample and storage
  unit; each usage record requires an aliquot, project, and researcher.
- **Partial participation:** a donor may have no samples yet; a project may have
  no usage yet; a sample may have no test request; a test request may be outside
  a project; a storage facility has no parent.
