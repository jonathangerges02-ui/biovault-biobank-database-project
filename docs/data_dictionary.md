# Data dictionary summary

| Table | Purpose | Primary key | Important candidate/foreign keys |
|---|---|---|---|
| `donors` | Pseudonymous donor demographics and lifecycle status | `donor_id` | `donor_code` unique |
| `consent_types` | Controlled consent purposes | `consent_type_id` | `consent_code` unique |
| `consents` | Versioned donor permissions and restrictions | `consent_id` | donor/type/version unique; donor and type FKs |
| `researchers` | Authorized scientific and laboratory staff | `researcher_id` | code and email unique |
| `research_projects` | Ethics-approved research work | `project_id` | project and approval codes unique; lead FK |
| `project_researchers` | Project membership (M:N bridge) | project + researcher | both columns are FKs |
| `sample_types` | Biospecimen classification and expected storage range | `sample_type_id` | `type_code` unique |
| `collection_events` | Time, site, protocol, donor, and collector | `collection_event_id` | event code unique; donor and collector FKs |
| `samples` | Parent biospecimens and quality state | `sample_id` | sample code unique; event and type FKs |
| `storage_units` | Hierarchical facility/freezer/rack/box inventory | `storage_unit_id` | location unique; self-parent FK |
| `aliquots` | Consumable physical portions and remaining stock | `aliquot_id` | aliquot code and box position unique |
| `test_types` | Controlled laboratory test catalog | `test_type_id` | `test_code` unique |
| `test_requests` | Requested tests, workflow status, and result | `test_request_id` | request code unique; sample/test/researcher/project FKs |
| `sample_usage` | Immutable research consumption event | `usage_id` | aliquot/project/researcher FKs |
| `audit_log` | Before/after snapshots for critical updates/deletes | `audit_id` | logical `table_name + record_id` index |

## Domain choices

- Codes are human-readable candidate keys, while identity values make joins
  compact and stable.
- Dates describe ethical/administrative validity; `TIMESTAMPTZ` describes
  events that may cross locations and time zones.
- `NUMERIC(14,3)` avoids floating-point rounding in volumes, masses, and cell
  counts.
- Status values are explicit `CHECK` domains, making invalid states impossible
  without requiring vendor-specific enum migrations.
- `ON DELETE RESTRICT` protects scientific traceability; cascading deletion is
  limited to the project membership bridge.
