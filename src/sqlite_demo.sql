PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS donors (
    donor_id       INTEGER PRIMARY KEY AUTOINCREMENT,
    donor_code     TEXT NOT NULL UNIQUE
                   CHECK (donor_code GLOB 'BIO-D[0-9][0-9][0-9][0-9]'),
    sex_at_birth   TEXT NOT NULL
                   CHECK (sex_at_birth IN ('FEMALE', 'MALE', 'INTERSEX', 'UNKNOWN')),
    birth_year     INTEGER CHECK (birth_year IS NULL OR birth_year BETWEEN 1900 AND 2100),
    blood_type     TEXT CHECK (
                   blood_type IS NULL OR blood_type IN
                   ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
    ethnicity      TEXT,
    donor_status   TEXT NOT NULL
                   CHECK (donor_status IN ('ACTIVE', 'INACTIVE', 'WITHDRAWN', 'DECEASED')),
    registered_on  TEXT NOT NULL,
    created_at     TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS researchers (
    researcher_id   INTEGER PRIMARY KEY,
    researcher_code TEXT NOT NULL UNIQUE,
    full_name       TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS sample_types (
    sample_type_id INTEGER PRIMARY KEY,
    type_code      TEXT NOT NULL UNIQUE,
    type_name      TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS collection_events (
    collection_event_id INTEGER PRIMARY KEY,
    event_code          TEXT NOT NULL UNIQUE,
    donor_id            INTEGER NOT NULL REFERENCES donors(donor_id) ON DELETE RESTRICT,
    collected_by        INTEGER NOT NULL REFERENCES researchers(researcher_id) ON DELETE RESTRICT,
    collected_at        TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS samples (
    sample_id           INTEGER PRIMARY KEY,
    sample_code         TEXT NOT NULL UNIQUE,
    collection_event_id INTEGER NOT NULL REFERENCES collection_events(collection_event_id),
    sample_type_id      INTEGER NOT NULL REFERENCES sample_types(sample_type_id),
    received_at         TEXT NOT NULL,
    initial_quantity    NUMERIC NOT NULL CHECK (initial_quantity > 0),
    quantity_unit       TEXT NOT NULL,
    quality_status      TEXT NOT NULL,
    sample_status       TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS test_types (
    test_type_id INTEGER PRIMARY KEY,
    test_code    TEXT NOT NULL UNIQUE,
    test_name    TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS test_requests (
    test_request_id INTEGER PRIMARY KEY,
    request_code    TEXT NOT NULL UNIQUE,
    sample_id       INTEGER NOT NULL REFERENCES samples(sample_id),
    test_type_id    INTEGER NOT NULL REFERENCES test_types(test_type_id),
    requested_by    INTEGER NOT NULL REFERENCES researchers(researcher_id),
    requested_on    TEXT NOT NULL,
    request_status  TEXT NOT NULL,
    numeric_result  NUMERIC,
    text_result     TEXT
);

CREATE TRIGGER IF NOT EXISTS trg_donors_updated_at
AFTER UPDATE ON donors
FOR EACH ROW
BEGIN
    UPDATE donors
    SET updated_at = CURRENT_TIMESTAMP
    WHERE donor_id = NEW.donor_id;
END;

INSERT OR IGNORE INTO donors (
    donor_id, donor_code, sex_at_birth, birth_year, blood_type,
    ethnicity, donor_status, registered_on
) VALUES
    (1,  'BIO-D0001', 'FEMALE', 1985, 'A+',  'North African',       'ACTIVE',    '2024-01-10'),
    (2,  'BIO-D0002', 'MALE',   1978, 'O+',  'Middle Eastern',      'ACTIVE',    '2024-01-18'),
    (3,  'BIO-D0003', 'FEMALE', 1992, 'B+',  'North African',       'ACTIVE',    '2024-02-03'),
    (4,  'BIO-D0004', 'MALE',   1969, 'AB-', 'Mediterranean',       'ACTIVE',    '2024-02-20'),
    (5,  'BIO-D0005', 'FEMALE', 1988, 'O-',  'Middle Eastern',      'ACTIVE',    '2024-03-12'),
    (6,  'BIO-D0006', 'MALE',   1995, 'A-',  'North African',       'ACTIVE',    '2024-04-09'),
    (7,  'BIO-D0007', 'FEMALE', 1974, 'B-',  'Mediterranean',       'ACTIVE',    '2024-04-22'),
    (8,  'BIO-D0008', 'MALE',   1982, 'AB+', 'Sub-Saharan African', 'ACTIVE',    '2024-05-04'),
    (9,  'BIO-D0009', 'FEMALE', 1999, 'O+',  'Middle Eastern',      'ACTIVE',    '2024-05-17'),
    (10, 'BIO-D0010', 'MALE',   1990, 'A+',  'North African',       'ACTIVE',    '2024-06-01'),
    (11, 'BIO-D0011', 'FEMALE', 1965, 'B+',  'Mediterranean',       'INACTIVE',  '2024-06-14'),
    (12, 'BIO-D0012', 'UNKNOWN',NULL,  NULL,  'Not disclosed',      'WITHDRAWN', '2024-07-02');

INSERT OR IGNORE INTO researchers (researcher_id, researcher_code, full_name) VALUES
    (1,  'RES-001', 'Dr. Lina Hassan'),
    (2,  'RES-002', 'Dr. Omar Nabil'),
    (3,  'RES-003', 'Dr. Sara Kamal'),
    (4,  'RES-004', 'Dr. Youssef Adel'),
    (5,  'RES-005', 'Dr. Mariam Fawzy'),
    (6,  'RES-006', 'Dr. Karim Samir'),
    (7,  'RES-007', 'Dr. Nour Hatem'),
    (8,  'RES-008', 'Dr. Ahmed Tarek'),
    (9,  'RES-009', 'Dr. Salma Wael'),
    (10, 'RES-010', 'Dr. Hany Emad');

INSERT OR IGNORE INTO sample_types (sample_type_id, type_code, type_name) VALUES
    (1, 'WHOLE_BLOOD', 'Whole Blood'),
    (2, 'PLASMA',      'Plasma'),
    (3, 'SERUM',       'Serum'),
    (4, 'DNA',         'Extracted DNA'),
    (5, 'RNA',         'Extracted RNA'),
    (6, 'TISSUE',      'Frozen Tissue'),
    (7, 'PBMC',        'Peripheral Blood Mononuclear Cells'),
    (8, 'SALIVA',      'Saliva');

INSERT OR IGNORE INTO collection_events (
    collection_event_id, event_code, donor_id, collected_by, collected_at
) VALUES
    (1,  'CE-0001', 1,  1,  '2025-01-12 08:15'),
    (2,  'CE-0002', 2,  2,  '2025-02-03 09:10'),
    (3,  'CE-0003', 3,  3,  '2025-02-20 07:55'),
    (4,  'CE-0004', 4,  4,  '2025-03-08 10:20'),
    (5,  'CE-0005', 5,  5,  '2025-04-14 08:40'),
    (6,  'CE-0006', 6,  6,  '2025-05-06 11:05'),
    (7,  'CE-0007', 7,  7,  '2025-06-18 09:25'),
    (8,  'CE-0008', 8,  8,  '2025-07-09 08:05'),
    (9,  'CE-0009', 9,  9,  '2025-08-23 12:10'),
    (10, 'CE-0010', 10, 10, '2025-09-17 07:45'),
    (11, 'CE-0011', 11, 2,  '2025-10-11 09:35'),
    (12, 'CE-0012', 12, 5,  '2025-11-02 10:00');

INSERT OR IGNORE INTO samples (
    sample_id, sample_code, collection_event_id, sample_type_id, received_at,
    initial_quantity, quantity_unit, quality_status, sample_status
) VALUES
    (1,  'SMP-00001', 1,  2, '2025-01-12 09:00', 6.000,   'mL',    'ACCEPTED',    'AVAILABLE'),
    (2,  'SMP-00002', 2,  1, '2025-02-03 09:40', 9.000,   'mL',    'ACCEPTED',    'AVAILABLE'),
    (3,  'SMP-00003', 3,  3, '2025-02-20 08:35', 5.000,   'mL',    'ACCEPTED',    'AVAILABLE'),
    (4,  'SMP-00004', 4,  6, '2025-03-08 10:45', 420.000, 'mg',    'ACCEPTED',    'AVAILABLE'),
    (5,  'SMP-00005', 5,  2, '2025-04-14 09:25', 6.500,   'mL',    'ACCEPTED',    'AVAILABLE'),
    (6,  'SMP-00006', 6,  7, '2025-05-06 13:00', 12000000,'count', 'ACCEPTED',    'AVAILABLE'),
    (7,  'SMP-00007', 7,  4, '2025-06-18 13:40', 180.000, 'uL',    'ACCEPTED',    'AVAILABLE'),
    (8,  'SMP-00008', 8,  3, '2025-07-09 08:55', 5.500,   'mL',    'ACCEPTED',    'AVAILABLE'),
    (9,  'SMP-00009', 9,  6, '2025-08-23 12:45', 350.000, 'mg',    'ACCEPTED',    'AVAILABLE'),
    (10, 'SMP-00010', 10, 5, '2025-09-17 11:10', 140.000, 'uL',    'ACCEPTED',    'AVAILABLE'),
    (11, 'SMP-00011', 11, 1, '2025-10-11 10:05', 8.000,   'mL',    'ACCEPTED',    'RESERVED'),
    (12, 'SMP-00012', 12, 2, '2025-11-02 10:50', 6.000,   'mL',    'QUARANTINED', 'RESERVED'),
    (13, 'SMP-00013', 1,  4, '2025-01-12 14:00', 200.000, 'uL',    'ACCEPTED',    'AVAILABLE'),
    (14, 'SMP-00014', 2,  2, '2025-02-03 10:30', 4.000,   'mL',    'ACCEPTED',    'AVAILABLE'),
    (15, 'SMP-00015', 3,  5, '2025-02-20 12:20', 160.000, 'uL',    'ACCEPTED',    'AVAILABLE'),
    (16, 'SMP-00016', 4,  4, '2025-03-08 16:10', 220.000, 'uL',    'ACCEPTED',    'AVAILABLE'),
    (17, 'SMP-00017', 5,  3, '2025-04-14 10:10', 5.200,   'mL',    'ACCEPTED',    'AVAILABLE'),
    (18, 'SMP-00018', 6,  2, '2025-05-06 11:50', 5.800,   'mL',    'ACCEPTED',    'AVAILABLE'),
    (19, 'SMP-00019', 7,  8, '2025-06-18 10:10', 3.000,   'mL',    'ACCEPTED',    'AVAILABLE'),
    (20, 'SMP-00020', 8,  4, '2025-07-09 12:20', 190.000, 'uL',    'ACCEPTED',    'AVAILABLE');

INSERT OR IGNORE INTO test_types (test_type_id, test_code, test_name) VALUES
    (1, 'DNA_CONC', 'DNA Concentration'),
    (2, 'RNA_RIN',  'RNA Integrity Number'),
    (3, 'HEMOLYSIS','Hemolysis Index'),
    (4, 'VIABILITY','Cell Viability'),
    (5, 'PATH_QC',  'Pathology Quality Review'),
    (6, 'STERILITY','Microbial Sterility Test');

INSERT OR IGNORE INTO test_requests (
    test_request_id, request_code, sample_id, test_type_id, requested_by,
    requested_on, request_status, numeric_result, text_result
) VALUES
    (1,  'TR-00001', 13, 1, 1,  '2025-01-15', 'COMPLETED', 84.2000, NULL),
    (2,  'TR-00002', 15, 2, 3,  '2025-02-22', 'COMPLETED', 8.7000,  NULL),
    (3,  'TR-00003', 1,  3, 2,  '2025-03-02', 'COMPLETED', 0.1200,  'No visible hemolysis'),
    (4,  'TR-00004', 6,  4, 6,  '2025-05-08', 'COMPLETED', 94.5000, NULL),
    (5,  'TR-00005', 4,  5, 9,  '2025-06-04', 'COMPLETED', NULL,     'Tumor content estimated at 68%'),
    (6,  'TR-00006', 5,  3, 5,  '2025-07-12', 'COMPLETED', 0.1800,  NULL),
    (7,  'TR-00007', 7,  1, 3,  '2025-08-10', 'COMPLETED', 72.9000, NULL),
    (8,  'TR-00008', 9,  5, 9,  '2025-11-05', 'COMPLETED', NULL,     'Adequate tissue morphology'),
    (9,  'TR-00009', 10, 2, 10, '2026-01-20', 'COMPLETED', 7.9000,  NULL),
    (10, 'TR-00010', 8,  6, 8,  '2026-02-02', 'IN_PROGRESS',NULL,     NULL),
    (11, 'TR-00011', 14, 3, 2,  '2026-02-12', 'REQUESTED',  NULL,     NULL),
    (12, 'TR-00012', 16, 1, 4,  '2026-03-03', 'COMPLETED', 91.1000, NULL),
    (13, 'TR-00013', 17, 6, 5,  '2026-04-14', 'CANCELLED',  NULL,     'Cancelled before processing'),
    (14, 'TR-00014', 18, 3, 6,  '2026-05-10', 'COMPLETED', 0.2200,  NULL),
    (15, 'TR-00015', 20, 1, 8,  '2026-06-18', 'IN_PROGRESS',NULL,     NULL);
