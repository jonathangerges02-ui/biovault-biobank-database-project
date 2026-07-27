# Relational schema

Notation: `PK` primary key, `FK` foreign key, `UQ` unique candidate key,
`NN` not null.

- **DONORS**(`donor_id` PK, `donor_code` UQ NN, `sex_at_birth` NN,
  `birth_year`, `blood_type`, `ethnicity`, `donor_status` NN,
  `registered_on` NN, timestamps)
- **CONSENT_TYPES**(`consent_type_id` PK, `consent_code` UQ NN,
  `consent_name` NN, `description`)
- **CONSENTS**(`consent_id` PK, `donor_id` FK→DONORS NN,
  `consent_type_id` FK→CONSENT_TYPES NN, `version_no` NN, `granted_on` NN,
  `expires_on`, `consent_status` NN, `restrictions`);
  UQ(`donor_id`, `consent_type_id`, `version_no`)
- **RESEARCHERS**(`researcher_id` PK, `researcher_code` UQ NN,
  `full_name` NN, `email` UQ NN, `institution` NN, `role_title` NN,
  `is_active` NN)
- **RESEARCH_PROJECTS**(`project_id` PK, `project_code` UQ NN,
  `project_title` NN, `lead_researcher_id` FK→RESEARCHERS NN,
  `ethics_approval_code` UQ NN, `start_date` NN, `end_date`,
  `project_status` NN)
- **PROJECT_RESEARCHERS**(`project_id` PK/FK→RESEARCH_PROJECTS,
  `researcher_id` PK/FK→RESEARCHERS, `project_role` NN, `joined_on` NN,
  `left_on`)
- **SAMPLE_TYPES**(`sample_type_id` PK, `type_code` UQ NN, `type_name` NN,
  `default_unit` NN, `min_storage_temp_c`, `max_storage_temp_c`)
- **COLLECTION_EVENTS**(`collection_event_id` PK, `event_code` UQ NN,
  `donor_id` FK→DONORS NN, `collected_by` FK→RESEARCHERS NN,
  `collected_at` NN, `collection_site` NN, `protocol_code` NN,
  `fasting_status` NN, `notes`)
- **SAMPLES**(`sample_id` PK, `sample_code` UQ NN,
  `collection_event_id` FK→COLLECTION_EVENTS NN,
  `sample_type_id` FK→SAMPLE_TYPES NN, `received_at` NN,
  `initial_quantity` NN, `quantity_unit` NN, `quality_status` NN,
  `sample_status` NN, `processing_method`, `notes`, timestamps)
- **STORAGE_UNITS**(`storage_unit_id` PK,
  `parent_storage_unit_id` FK→STORAGE_UNITS, `location_code` UQ NN,
  `unit_name` NN, `unit_type` NN, `temperature_c`, `capacity_positions`,
  `is_active` NN)
- **ALIQUOTS**(`aliquot_id` PK, `aliquot_code` UQ NN,
  `sample_id` FK→SAMPLES NN, `storage_unit_id` FK→STORAGE_UNITS NN,
  `position_code` NN, `initial_quantity` NN, `current_quantity` NN,
  `quantity_unit` NN, `aliquot_status` NN, `prepared_on` NN,
  `freeze_thaw_cycles` NN, timestamps);
  UQ(`storage_unit_id`, `position_code`)
- **TEST_TYPES**(`test_type_id` PK, `test_code` UQ NN, `test_name` NN,
  `result_unit`)
- **TEST_REQUESTS**(`test_request_id` PK, `request_code` UQ NN,
  `sample_id` FK→SAMPLES NN, `test_type_id` FK→TEST_TYPES NN,
  `requested_by` FK→RESEARCHERS NN,
  `project_id` FK→RESEARCH_PROJECTS, `requested_on` NN, `completed_on`,
  `request_status` NN, `numeric_result`, `text_result`)
- **SAMPLE_USAGE**(`usage_id` PK, `aliquot_id` FK→ALIQUOTS NN,
  `project_id` FK→RESEARCH_PROJECTS NN,
  `researcher_id` FK→RESEARCHERS NN, `used_on` NN, `quantity_used` NN,
  `purpose` NN, `recorded_at` NN)
- **AUDIT_LOG**(`audit_id` PK, `table_name` NN, `record_id` NN,
  `operation` NN, `old_values`, `new_values`, `changed_by` NN,
  `changed_at` NN)

The executable source of truth is [`../sql/create_tables.sql`](../sql/create_tables.sql).
