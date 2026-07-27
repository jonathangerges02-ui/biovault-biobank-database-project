# Normalization to Third Normal Form

## Starting point

A single spreadsheet-style relation such as:

`DonorCode, DonorBloodType, ConsentType, ConsentVersion, EventCode, SampleCode,
SampleType, AliquotCode, StorageBox, ProjectCode, ResearcherName, QuantityUsed`

would repeat donor, consent, sample, project, researcher, and storage data. It
would create update anomalies (changing a researcher institution in many rows),
insert anomalies (a new project could not exist before sample use), and delete
anomalies (deleting the last use could erase the project).

## First Normal Form (1NF)

- Every column stores one atomic value.
- Repeating consent, project-member, aliquot, and test groups were split into
  separate relations.
- Each relation has a declared primary key.
- Multi-valued project membership is represented by one
  `project_researchers` row per project/researcher pair.

## Second Normal Form (2NF)

Most relations use a single-column surrogate primary key, so non-key attributes
depend on the complete key. The associative table uses the composite key
`(project_id, researcher_id)`; its attributes `project_role`, `joined_on`, and
`left_on` describe that complete membership, not only the project or researcher.

Sample-type descriptions were not stored in `samples`, and researcher details
were not stored in `project_researchers`, avoiding partial dependencies.

## Third Normal Form (3NF)

No non-key attribute depends transitively on another non-key attribute:

- Consent names depend on `consent_type_id` and live in `consent_types`, not
  `consents`.
- Sample-type name, unit, and temperature range depend on `sample_type_id` and
  live in `sample_types`, not `samples`.
- Test names and result units depend on `test_type_id` and live in `test_types`,
  not `test_requests`.
- Donor data is reached through `collection_event_id`; `donor_id` is not copied
  into `samples` or `aliquots`.
- Storage unit details depend on `storage_unit_id`; aliquots store only that
  foreign key and their unique position.
- Project and researcher details are not duplicated in `sample_usage`.

The audit log is intentionally generic and denormalized (`JSONB` snapshots). It
is a technical history object, not an operational master-data relation, and its
purpose is to preserve the exact before/after state.

## Functional-dependency examples

- `donor_id → donor_code, sex_at_birth, birth_year, blood_type, donor_status`
- `sample_id → collection_event_id, sample_type_id, initial_quantity, status`
- `aliquot_id → sample_id, storage_unit_id, position_code, current_quantity`
- `(storage_unit_id, position_code) → aliquot_id`
- `project_id → project_code, lead_researcher_id, ethics_approval_code, status`
- `(project_id, researcher_id) → project_role, joined_on, left_on`

Candidate keys such as `donor_code`, `sample_code`, `aliquot_code`,
`project_code`, and `ethics_approval_code` are protected by `UNIQUE`
constraints, while compact identity keys are used for foreign-key joins.
