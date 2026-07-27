-- Meaningful synthetic data. No row represents a real person.
-- Run after create_tables.sql and triggers_procedures.sql.
\set ON_ERROR_STOP on
SET search_path TO biobank, public;

BEGIN;

TRUNCATE TABLE
    audit_log,
    sample_usage,
    test_requests,
    test_types,
    aliquots,
    storage_units,
    samples,
    collection_events,
    sample_types,
    project_researchers,
    research_projects,
    researchers,
    consents,
    consent_types,
    donors
RESTART IDENTITY CASCADE;

INSERT INTO donors (
    donor_id, donor_code, sex_at_birth, birth_year, blood_type,
    ethnicity, donor_status, registered_on
) VALUES
    (1,  'BIO-D0001', 'FEMALE', 1985, 'A+',  'North African',      'ACTIVE',    '2024-01-10'),
    (2,  'BIO-D0002', 'MALE',   1978, 'O+',  'Middle Eastern',     'ACTIVE',    '2024-01-18'),
    (3,  'BIO-D0003', 'FEMALE', 1992, 'B+',  'North African',      'ACTIVE',    '2024-02-03'),
    (4,  'BIO-D0004', 'MALE',   1969, 'AB-', 'Mediterranean',      'ACTIVE',    '2024-02-20'),
    (5,  'BIO-D0005', 'FEMALE', 1988, 'O-',  'Middle Eastern',     'ACTIVE',    '2024-03-12'),
    (6,  'BIO-D0006', 'MALE',   1995, 'A-',  'North African',      'ACTIVE',    '2024-04-09'),
    (7,  'BIO-D0007', 'FEMALE', 1974, 'B-',  'Mediterranean',      'ACTIVE',    '2024-04-22'),
    (8,  'BIO-D0008', 'MALE',   1982, 'AB+', 'Sub-Saharan African','ACTIVE',    '2024-05-04'),
    (9,  'BIO-D0009', 'FEMALE', 1999, 'O+',  'Middle Eastern',     'ACTIVE',    '2024-05-17'),
    (10, 'BIO-D0010', 'MALE',   1990, 'A+',  'North African',      'ACTIVE',    '2024-06-01'),
    (11, 'BIO-D0011', 'FEMALE', 1965, 'B+',  'Mediterranean',      'INACTIVE',  '2024-06-14'),
    (12, 'BIO-D0012', 'UNKNOWN',NULL,  NULL,  'Not disclosed',      'WITHDRAWN', '2024-07-02');

INSERT INTO consent_types (
    consent_type_id, consent_code, consent_name, description
) VALUES
    (1, 'RESEARCH_USE', 'General Research Use', 'Authorizes approved non-therapeutic research use.'),
    (2, 'GENOMIC_ANALYSIS', 'Genomic Analysis', 'Authorizes sequencing and genomic analysis.'),
    (3, 'DATA_SHARING', 'Coded Data Sharing', 'Authorizes controlled sharing of coded research data.'),
    (4, 'RECONTACT', 'Permission to Recontact', 'Authorizes future contact through the custodian.');

INSERT INTO consents (
    consent_id, donor_id, consent_type_id, version_no, granted_on,
    expires_on, consent_status, restrictions
) VALUES
    (1,  1,  1, 'v2.1', '2024-01-10', '2028-01-09', 'ACTIVE',    NULL),
    (2,  2,  1, 'v2.1', '2024-01-18', '2028-01-17', 'ACTIVE',    NULL),
    (3,  3,  1, 'v2.1', '2024-02-03', NULL,         'ACTIVE',    'Cancer research only'),
    (4,  4,  1, 'v2.1', '2024-02-20', '2029-02-19', 'ACTIVE',    NULL),
    (5,  5,  1, 'v2.1', '2024-03-12', '2028-03-11', 'ACTIVE',    NULL),
    (6,  6,  1, 'v2.1', '2024-04-09', NULL,         'ACTIVE',    NULL),
    (7,  7,  1, 'v2.1', '2024-04-22', '2028-04-21', 'ACTIVE',    'No commercial use'),
    (8,  8,  1, 'v2.1', '2024-05-04', '2028-05-03', 'ACTIVE',    NULL),
    (9,  9,  1, 'v2.1', '2024-05-17', NULL,         'ACTIVE',    NULL),
    (10, 10, 1, 'v2.1', '2024-06-01', '2029-05-31', 'ACTIVE',    NULL),
    (11, 11, 1, 'v1.8', '2022-06-14', '2025-06-13', 'EXPIRED',   NULL),
    (12, 12, 1, 'v2.1', '2024-07-02', NULL,         'WITHDRAWN', 'Withdrawn 2025-11-20'),
    (13, 1,  2, 'v1.4', '2024-01-10', '2028-01-09', 'ACTIVE',    NULL),
    (14, 2,  2, 'v1.4', '2024-01-18', '2028-01-17', 'ACTIVE',    NULL),
    (15, 3,  3, 'v1.2', '2024-02-03', NULL,         'ACTIVE',    'Controlled access only'),
    (16, 4,  4, 'v1.0', '2024-02-20', '2027-02-19', 'ACTIVE',    NULL);

INSERT INTO researchers (
    researcher_id, researcher_code, full_name, email, institution, role_title, is_active
) VALUES
    (1,  'RES-001', 'Dr. Lina Hassan',    'lina.hassan@biovault.example',   'BioVault Research Center', 'Principal Investigator', TRUE),
    (2,  'RES-002', 'Dr. Omar Nabil',     'omar.nabil@biovault.example',    'BioVault Research Center', 'Molecular Biologist',     TRUE),
    (3,  'RES-003', 'Dr. Sara Kamal',     'sara.kamal@genomics.example',    'National Genomics Lab',    'Bioinformatician',        TRUE),
    (4,  'RES-004', 'Dr. Youssef Adel',   'youssef.adel@oncology.example',  'Cairo Oncology Institute', 'Clinical Researcher',     TRUE),
    (5,  'RES-005', 'Dr. Mariam Fawzy',   'mariam.fawzy@biovault.example',  'BioVault Research Center', 'Biobank Manager',         TRUE),
    (6,  'RES-006', 'Dr. Karim Samir',    'karim.samir@immunology.example', 'Immunology Institute',     'Immunologist',            TRUE),
    (7,  'RES-007', 'Dr. Nour Hatem',     'nour.hatem@biovault.example',    'BioVault Research Center', 'Quality Specialist',      TRUE),
    (8,  'RES-008', 'Dr. Ahmed Tarek',    'ahmed.tarek@metabolic.example',  'Metabolic Research Unit',  'Research Scientist',      TRUE),
    (9,  'RES-009', 'Dr. Salma Wael',     'salma.wael@pathology.example',   'Pathology Center',         'Pathologist',             TRUE),
    (10, 'RES-010', 'Dr. Hany Emad',      'hany.emad@biovault.example',     'BioVault Research Center', 'Laboratory Scientist',    TRUE);

INSERT INTO research_projects (
    project_id, project_code, project_title, lead_researcher_id,
    ethics_approval_code, start_date, end_date, project_status
) VALUES
    (1,  'PRJ-001', 'Circulating Biomarkers in Early Cancer',         1,  'IRB-2025-001', '2025-01-01', '2027-12-31', 'ACTIVE'),
    (2,  'PRJ-002', 'Population Genomics Reference Panel',            2,  'IRB-2025-014', '2025-03-01', '2028-02-29', 'ACTIVE'),
    (3,  'PRJ-003', 'Inflammatory Cytokine Response Study',           3,  'IRB-2025-022', '2025-04-15', '2027-04-14', 'ACTIVE'),
    (4,  'PRJ-004', 'Tumor Tissue Molecular Profiling',               4,  'IRB-2025-031', '2025-06-01', '2028-05-31', 'ACTIVE'),
    (5,  'PRJ-005', 'Biobank Pre-analytical Quality Factors',         5,  'IRB-2025-044', '2025-07-01', '2027-06-30', 'ACTIVE'),
    (6,  'PRJ-006', 'Adaptive Immunity Marker Discovery',             6,  'IRB-2025-052', '2025-08-01', '2028-07-31', 'ACTIVE'),
    (7,  'PRJ-007', 'Cryostorage Stability Validation',               7,  'IRB-2025-060', '2025-09-01', '2027-08-31', 'ACTIVE'),
    (8,  'PRJ-008', 'Metabolic Risk Biomarker Panel',                 8,  'IRB-2025-071', '2025-10-01', '2028-09-30', 'ACTIVE'),
    (9,  'PRJ-009', 'Digital Pathology Concordance Study',            9,  'IRB-2025-083', '2025-11-01', '2026-06-30', 'COMPLETED'),
    (10, 'PRJ-010', 'RNA Integrity Under Delayed Processing',        10,  'IRB-2026-003', '2026-01-15', '2027-01-14', 'ACTIVE');

INSERT INTO project_researchers (
    project_id, researcher_id, project_role, joined_on, left_on
) VALUES
    (1,  1,  'Principal Investigator', '2025-01-01', NULL),
    (1,  2,  'Molecular Analyst',       '2025-01-01', NULL),
    (2,  2,  'Principal Investigator', '2025-03-01', NULL),
    (2,  3,  'Bioinformatics Lead',     '2025-03-01', NULL),
    (3,  3,  'Principal Investigator', '2025-04-15', NULL),
    (3,  6,  'Immunology Advisor',      '2025-04-15', NULL),
    (4,  4,  'Principal Investigator', '2025-06-01', NULL),
    (4,  9,  'Pathology Reviewer',      '2025-06-01', NULL),
    (5,  5,  'Principal Investigator', '2025-07-01', NULL),
    (5,  7,  'Quality Analyst',         '2025-07-01', NULL),
    (6,  6,  'Principal Investigator', '2025-08-01', NULL),
    (6,  1,  'Clinical Advisor',        '2025-08-01', NULL),
    (7,  7,  'Principal Investigator', '2025-09-01', NULL),
    (7,  5,  'Biobank Advisor',         '2025-09-01', NULL),
    (8,  8,  'Principal Investigator', '2025-10-01', NULL),
    (8,  3,  'Data Analyst',            '2025-10-01', NULL),
    (9,  9,  'Principal Investigator', '2025-11-01', NULL),
    (9,  4,  'Clinical Reviewer',       '2025-11-01', '2026-06-30'),
    (10, 10, 'Principal Investigator', '2026-01-15', NULL),
    (10, 7,  'Quality Reviewer',        '2026-01-15', NULL);

INSERT INTO sample_types (
    sample_type_id, type_code, type_name, default_unit,
    min_storage_temp_c, max_storage_temp_c
) VALUES
    (1, 'WHOLE_BLOOD', 'Whole Blood',          'mL', -85.0, -70.0),
    (2, 'PLASMA',      'Plasma',               'mL', -85.0, -70.0),
    (3, 'SERUM',       'Serum',                'mL', -85.0, -70.0),
    (4, 'DNA',         'Extracted DNA',        'uL', -25.0, -15.0),
    (5, 'RNA',         'Extracted RNA',        'uL', -85.0, -70.0),
    (6, 'TISSUE',      'Frozen Tissue',        'mg', -200.0, -150.0),
    (7, 'PBMC',        'Peripheral Blood Mononuclear Cells', 'count', -200.0, -150.0),
    (8, 'SALIVA',      'Saliva',               'mL', -25.0, -15.0);

INSERT INTO collection_events (
    collection_event_id, event_code, donor_id, collected_by, collected_at,
    collection_site, protocol_code, fasting_status, notes
) VALUES
    (1,  'CE-0001', 1,  1,  '2025-01-12 08:15+02', 'Cairo Central Clinic',  'SOP-COL-01', 'FASTING',     NULL),
    (2,  'CE-0002', 2,  2,  '2025-02-03 09:10+02', 'Cairo Central Clinic',  'SOP-COL-01', 'NON_FASTING', NULL),
    (3,  'CE-0003', 3,  3,  '2025-02-20 07:55+02', 'Giza Research Clinic',  'SOP-COL-02', 'FASTING',     NULL),
    (4,  'CE-0004', 4,  4,  '2025-03-08 10:20+02', 'Oncology Institute',    'SOP-TIS-03', 'UNKNOWN',     'Surgical tissue collection'),
    (5,  'CE-0005', 5,  5,  '2025-04-14 08:40+02', 'Cairo Central Clinic',  'SOP-COL-01', 'FASTING',     NULL),
    (6,  'CE-0006', 6,  6,  '2025-05-06 11:05+02', 'Immunology Institute',  'SOP-PBMC-02','NON_FASTING', NULL),
    (7,  'CE-0007', 7,  7,  '2025-06-18 09:25+02', 'Giza Research Clinic',  'SOP-COL-02', 'FASTING',     NULL),
    (8,  'CE-0008', 8,  8,  '2025-07-09 08:05+02', 'Metabolic Research Unit','SOP-COL-01','FASTING',     NULL),
    (9,  'CE-0009', 9,  9,  '2025-08-23 12:10+02', 'Pathology Center',      'SOP-TIS-03', 'UNKNOWN',     NULL),
    (10, 'CE-0010', 10, 10, '2025-09-17 07:45+02', 'Cairo Central Clinic',  'SOP-COL-01', 'FASTING',     NULL),
    (11, 'CE-0011', 11, 2,  '2025-10-11 09:35+02', 'Giza Research Clinic',  'SOP-COL-02', 'NON_FASTING', 'Archived; consent now expired'),
    (12, 'CE-0012', 12, 5,  '2025-11-02 10:00+02', 'Cairo Central Clinic',  'SOP-COL-01', 'UNKNOWN',     'Quarantined after withdrawal');

INSERT INTO samples (
    sample_id, sample_code, collection_event_id, sample_type_id, received_at,
    initial_quantity, quantity_unit, quality_status, sample_status,
    processing_method, notes
) VALUES
    (1,  'SMP-00001', 1,  2, '2025-01-12 09:00+02', 6.000,  'mL',    'ACCEPTED',    'AVAILABLE', 'Double centrifugation', NULL),
    (2,  'SMP-00002', 2,  1, '2025-02-03 09:40+02', 9.000,  'mL',    'ACCEPTED',    'AVAILABLE', 'EDTA tube inversion',   NULL),
    (3,  'SMP-00003', 3,  3, '2025-02-20 08:35+02', 5.000,  'mL',    'ACCEPTED',    'AVAILABLE', 'Clot and centrifuge',    NULL),
    (4,  'SMP-00004', 4,  6, '2025-03-08 10:45+02', 420.000,'mg',    'ACCEPTED',    'AVAILABLE', 'Snap frozen',            NULL),
    (5,  'SMP-00005', 5,  2, '2025-04-14 09:25+02', 6.500,  'mL',    'ACCEPTED',    'AVAILABLE', 'Double centrifugation', NULL),
    (6,  'SMP-00006', 6,  7, '2025-05-06 13:00+02', 12000000,'count','ACCEPTED',    'AVAILABLE', 'Ficoll separation',      NULL),
    (7,  'SMP-00007', 7,  4, '2025-06-18 13:40+02', 180.000,'uL',    'ACCEPTED',    'AVAILABLE', 'Silica column extraction',NULL),
    (8,  'SMP-00008', 8,  3, '2025-07-09 08:55+02', 5.500,  'mL',    'ACCEPTED',    'AVAILABLE', 'Clot and centrifuge',    NULL),
    (9,  'SMP-00009', 9,  6, '2025-08-23 12:45+02', 350.000,'mg',    'ACCEPTED',    'AVAILABLE', 'Snap frozen',            NULL),
    (10, 'SMP-00010', 10, 5, '2025-09-17 11:10+02', 140.000,'uL',    'ACCEPTED',    'AVAILABLE', 'Magnetic bead extraction',NULL),
    (11, 'SMP-00011', 11, 1, '2025-10-11 10:05+02', 8.000,  'mL',    'ACCEPTED',    'RESERVED',  'EDTA tube inversion',   'Research use blocked by expired consent'),
    (12, 'SMP-00012', 12, 2, '2025-11-02 10:50+02', 6.000,  'mL',    'QUARANTINED', 'RESERVED',  'Double centrifugation', 'Research use blocked after withdrawal'),
    (13, 'SMP-00013', 1,  4, '2025-01-12 14:00+02', 200.000,'uL',    'ACCEPTED',    'AVAILABLE', 'Silica column extraction',NULL),
    (14, 'SMP-00014', 2,  2, '2025-02-03 10:30+02', 4.000,  'mL',    'ACCEPTED',    'AVAILABLE', 'Double centrifugation', NULL),
    (15, 'SMP-00015', 3,  5, '2025-02-20 12:20+02', 160.000,'uL',    'ACCEPTED',    'AVAILABLE', 'Magnetic bead extraction',NULL),
    (16, 'SMP-00016', 4,  4, '2025-03-08 16:10+02', 220.000,'uL',    'ACCEPTED',    'AVAILABLE', 'Silica column extraction',NULL),
    (17, 'SMP-00017', 5,  3, '2025-04-14 10:10+02', 5.200,  'mL',    'ACCEPTED',    'AVAILABLE', 'Clot and centrifuge',    NULL),
    (18, 'SMP-00018', 6,  2, '2025-05-06 11:50+02', 5.800,  'mL',    'ACCEPTED',    'AVAILABLE', 'Double centrifugation', NULL),
    (19, 'SMP-00019', 7,  8, '2025-06-18 10:10+02', 3.000,  'mL',    'ACCEPTED',    'AVAILABLE', 'Stabilization buffer',  NULL),
    (20, 'SMP-00020', 8,  4, '2025-07-09 12:20+02', 190.000,'uL',    'ACCEPTED',    'AVAILABLE', 'Silica column extraction',NULL);

INSERT INTO storage_units (
    storage_unit_id, parent_storage_unit_id, location_code, unit_name,
    unit_type, temperature_c, capacity_positions, is_active
) VALUES
    (1,  NULL, 'FAC-CAI-01',                'Cairo Biobank Facility',      'FACILITY', NULL,   NULL, TRUE),
    (2,  1,    'FAC-CAI-01/ROOM-CRYO',      'Cryogenic Storage Room',     'ROOM',    20.0,    NULL, TRUE),
    (3,  2,    'FAC-CAI-01/FZR-80-A',       'Ultra-low Freezer A',        'FREEZER', -80.0,   12,   TRUE),
    (4,  3,    'FAC-CAI-01/FZR-80-A/R01',   'Freezer A Rack 01',          'RACK',    -80.0,   10,   TRUE),
    (5,  4,    'FAC-CAI-01/FZR-80-A/R01/B01','Freezer A Box 01',          'BOX',     -80.0,   100,  TRUE),
    (6,  2,    'FAC-CAI-01/LN2-A',          'Liquid Nitrogen Tank A',     'FREEZER', -196.0,  8,    TRUE),
    (7,  6,    'FAC-CAI-01/LN2-A/R01',      'LN2 Canister Rack 01',       'RACK',    -196.0,  8,    TRUE),
    (8,  7,    'FAC-CAI-01/LN2-A/R01/B01',  'LN2 Cryobox 01',             'BOX',     -196.0,  81,   TRUE),
    (9,  2,    'FAC-CAI-01/FZR-20-A',       'Standard Freezer A',        'FREEZER', -20.0,   10,   TRUE),
    (10, 9,    'FAC-CAI-01/FZR-20-A/R01',   'Freezer -20 Rack 01',        'RACK',    -20.0,   8,    TRUE),
    (11, 10,   'FAC-CAI-01/FZR-20-A/R01/B01','Freezer -20 Box 01',        'BOX',     -20.0,   100,  TRUE),
    (12, 4,    'FAC-CAI-01/FZR-80-A/R01/B02','Freezer A Box 02',          'BOX',     -80.0,   100,  TRUE),
    (13, 4,    'FAC-CAI-01/FZR-80-A/R01/B03','Freezer A Box 03',          'BOX',     -80.0,   100,  TRUE),
    (14, 7,    'FAC-CAI-01/LN2-A/R01/B02',  'LN2 Cryobox 02',             'BOX',     -196.0,  81,   TRUE);

INSERT INTO aliquots (
    aliquot_id, aliquot_code, sample_id, storage_unit_id, position_code,
    initial_quantity, current_quantity, quantity_unit, aliquot_status,
    prepared_on, freeze_thaw_cycles
) VALUES
    (1,  'ALQ-00001', 1,  5,  'A01', 2.000,    2.000,    'mL',    'AVAILABLE', '2025-01-12', 0),
    (2,  'ALQ-00002', 2,  5,  'A02', 3.000,    3.000,    'mL',    'AVAILABLE', '2025-02-03', 0),
    (3,  'ALQ-00003', 3,  5,  'A03', 2.000,    2.000,    'mL',    'AVAILABLE', '2025-02-20', 0),
    (4,  'ALQ-00004', 4,  8,  'A01', 100.000,  100.000,  'mg',    'AVAILABLE', '2025-03-08', 0),
    (5,  'ALQ-00005', 5,  5,  'A04', 2.000,    2.000,    'mL',    'AVAILABLE', '2025-04-14', 0),
    (6,  'ALQ-00006', 6,  8,  'A02', 4000000,  4000000,  'count', 'AVAILABLE', '2025-05-06', 0),
    (7,  'ALQ-00007', 7,  11, 'A01', 60.000,   60.000,   'uL',    'AVAILABLE', '2025-06-18', 0),
    (8,  'ALQ-00008', 8,  5,  'A05', 2.000,    2.000,    'mL',    'AVAILABLE', '2025-07-09', 0),
    (9,  'ALQ-00009', 9,  8,  'A03', 100.000,  100.000,  'mg',    'AVAILABLE', '2025-08-23', 0),
    (10, 'ALQ-00010', 10, 12, 'A01', 50.000,   50.000,   'uL',    'AVAILABLE', '2025-09-17', 0),
    (11, 'ALQ-00011', 11, 5,  'A06', 2.500,    2.500,    'mL',    'RESERVED',  '2025-10-11', 0),
    (12, 'ALQ-00012', 12, 5,  'A07', 2.000,    2.000,    'mL',    'RESERVED',  '2025-11-02', 0),
    (13, 'ALQ-00013', 13, 11, 'A02', 70.000,   70.000,   'uL',    'AVAILABLE', '2025-01-12', 0),
    (14, 'ALQ-00014', 14, 12, 'A02', 1.500,    1.500,    'mL',    'AVAILABLE', '2025-02-03', 0),
    (15, 'ALQ-00015', 15, 13, 'A01', 55.000,   55.000,   'uL',    'AVAILABLE', '2025-02-20', 0),
    (16, 'ALQ-00016', 16, 11, 'A03', 75.000,   75.000,   'uL',    'AVAILABLE', '2025-03-08', 0),
    (17, 'ALQ-00017', 17, 13, 'A02', 1.800,    1.800,    'mL',    'AVAILABLE', '2025-04-14', 0),
    (18, 'ALQ-00018', 18, 12, 'A03', 2.000,    2.000,    'mL',    'AVAILABLE', '2025-05-06', 0),
    (19, 'ALQ-00019', 19, 11, 'A04', 1.000,    1.000,    'mL',    'AVAILABLE', '2025-06-18', 0),
    (20, 'ALQ-00020', 20, 11, 'A05', 65.000,   65.000,   'uL',    'AVAILABLE', '2025-07-09', 0);

INSERT INTO test_types (
    test_type_id, test_code, test_name, result_unit
) VALUES
    (1, 'DNA_CONC', 'DNA Concentration', 'ng/uL'),
    (2, 'RNA_RIN',  'RNA Integrity Number', 'RIN'),
    (3, 'HEMOLYSIS','Hemolysis Index', 'index'),
    (4, 'VIABILITY','Cell Viability', '%'),
    (5, 'PATH_QC',  'Pathology Quality Review', NULL),
    (6, 'STERILITY','Microbial Sterility Test', NULL);

INSERT INTO test_requests (
    test_request_id, request_code, sample_id, test_type_id, requested_by,
    project_id, requested_on, completed_on, request_status,
    numeric_result, text_result
) VALUES
    (1,  'TR-00001', 13, 1, 1,  1,  '2025-01-15', '2025-01-16', 'COMPLETED', 84.2000, NULL),
    (2,  'TR-00002', 15, 2, 3,  3,  '2025-02-22', '2025-02-23', 'COMPLETED', 8.7000,  NULL),
    (3,  'TR-00003', 1,  3, 2,  1,  '2025-03-02', '2025-03-02', 'COMPLETED', 0.1200,  'No visible hemolysis'),
    (4,  'TR-00004', 6,  4, 6,  6,  '2025-05-08', '2025-05-08', 'COMPLETED', 94.5000, NULL),
    (5,  'TR-00005', 4,  5, 9,  4,  '2025-06-04', '2025-06-06', 'COMPLETED', NULL,     'Tumor content estimated at 68%'),
    (6,  'TR-00006', 5,  3, 5,  5,  '2025-07-12', '2025-07-12', 'COMPLETED', 0.1800,  NULL),
    (7,  'TR-00007', 7,  1, 3,  2,  '2025-08-10', '2025-08-11', 'COMPLETED', 72.9000, NULL),
    (8,  'TR-00008', 9,  5, 9,  9,  '2025-11-05', '2025-11-06', 'COMPLETED', NULL,     'Adequate tissue morphology'),
    (9,  'TR-00009', 10, 2, 10, 10, '2026-01-20', '2026-01-21', 'COMPLETED', 7.9000,  NULL),
    (10, 'TR-00010', 8,  6, 8,  8,  '2026-02-02', NULL,         'IN_PROGRESS',NULL,     NULL),
    (11, 'TR-00011', 14, 3, 2,  2,  '2026-02-12', NULL,         'REQUESTED',  NULL,     NULL),
    (12, 'TR-00012', 16, 1, 4,  4,  '2026-03-03', '2026-03-04', 'COMPLETED', 91.1000, NULL),
    (13, 'TR-00013', 17, 6, 5,  5,  '2026-04-14', NULL,         'CANCELLED',  NULL,     'Cancelled before processing'),
    (14, 'TR-00014', 18, 3, 6,  6,  '2026-05-10', '2026-05-10', 'COMPLETED', 0.2200,  NULL),
    (15, 'TR-00015', 20, 1, 8,  8,  '2026-06-18', NULL,         'IN_PROGRESS',NULL,     NULL);

-- These calls exercise the real consent/authorization/stock trigger while loading data.
SELECT record_sample_usage(1,  1,  1,  '2025-02-10', 0.250,    'Plasma biomarker assay');
SELECT record_sample_usage(2,  2,  2,  '2025-04-18', 0.500,    'Reference DNA extraction');
SELECT record_sample_usage(3,  3,  3,  '2025-05-20', 0.300,    'Cytokine quantification');
SELECT record_sample_usage(4,  4,  4,  '2025-07-15', 20.000,   'Tumor molecular profiling');
SELECT record_sample_usage(5,  5,  5,  '2025-08-21', 0.200,    'Pre-analytical stability check');
SELECT record_sample_usage(6,  6,  6,  '2025-10-02', 500000,   'T-cell response assay');
SELECT record_sample_usage(7,  7,  7,  '2025-11-14', 10.000,   'Storage stability validation');
SELECT record_sample_usage(8,  8,  8,  '2025-12-03', 0.350,    'Metabolic marker panel');
SELECT record_sample_usage(9,  9,  9,  '2026-02-09', 25.000,   'Digital slide concordance');
SELECT record_sample_usage(10, 10, 10, '2026-03-01', 12.000,   'RNA integrity experiment');
SELECT record_sample_usage(14, 1,  2,  '2026-04-12', 0.250,    'Confirmatory plasma biomarker validation');
SELECT record_sample_usage(14, 2,  3,  '2026-05-18', 0.250,    'Population allele validation');

-- Explicit IDs do not advance identity sequences, so synchronize them for future CRUD.
SELECT setval(pg_get_serial_sequence('donors', 'donor_id'),                    (SELECT MAX(donor_id) FROM donors), TRUE);
SELECT setval(pg_get_serial_sequence('consent_types', 'consent_type_id'),      (SELECT MAX(consent_type_id) FROM consent_types), TRUE);
SELECT setval(pg_get_serial_sequence('consents', 'consent_id'),                (SELECT MAX(consent_id) FROM consents), TRUE);
SELECT setval(pg_get_serial_sequence('researchers', 'researcher_id'),          (SELECT MAX(researcher_id) FROM researchers), TRUE);
SELECT setval(pg_get_serial_sequence('research_projects', 'project_id'),       (SELECT MAX(project_id) FROM research_projects), TRUE);
SELECT setval(pg_get_serial_sequence('sample_types', 'sample_type_id'),        (SELECT MAX(sample_type_id) FROM sample_types), TRUE);
SELECT setval(pg_get_serial_sequence('collection_events', 'collection_event_id'), (SELECT MAX(collection_event_id) FROM collection_events), TRUE);
SELECT setval(pg_get_serial_sequence('samples', 'sample_id'),                  (SELECT MAX(sample_id) FROM samples), TRUE);
SELECT setval(pg_get_serial_sequence('storage_units', 'storage_unit_id'),      (SELECT MAX(storage_unit_id) FROM storage_units), TRUE);
SELECT setval(pg_get_serial_sequence('aliquots', 'aliquot_id'),                (SELECT MAX(aliquot_id) FROM aliquots), TRUE);
SELECT setval(pg_get_serial_sequence('test_types', 'test_type_id'),            (SELECT MAX(test_type_id) FROM test_types), TRUE);
SELECT setval(pg_get_serial_sequence('test_requests', 'test_request_id'),      (SELECT MAX(test_request_id) FROM test_requests), TRUE);
SELECT setval(pg_get_serial_sequence('sample_usage', 'usage_id'),              (SELECT MAX(usage_id) FROM sample_usage), TRUE);
SELECT setval(pg_get_serial_sequence('audit_log', 'audit_id'),                 (SELECT COALESCE(MAX(audit_id), 1) FROM audit_log), TRUE);

COMMIT;

SELECT
    (SELECT COUNT(*) FROM donors) AS donors,
    (SELECT COUNT(*) FROM researchers) AS researchers,
    (SELECT COUNT(*) FROM research_projects) AS projects,
    (SELECT COUNT(*) FROM samples) AS samples,
    (SELECT COUNT(*) FROM aliquots) AS aliquots,
    (SELECT COUNT(*) FROM test_requests) AS test_requests,
    (SELECT COUNT(*) FROM sample_usage) AS usage_events;
