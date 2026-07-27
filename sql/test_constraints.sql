-- Database acceptance tests. Any failed assertion stops psql with a non-zero exit.
\set ON_ERROR_STOP on
SET search_path TO biobank, public;

BEGIN;

DO $$
DECLARE
    v_main_table_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_main_table_count
    FROM (
        SELECT 'donors' WHERE (SELECT COUNT(*) FROM donors) >= 10
        UNION ALL SELECT 'researchers' WHERE (SELECT COUNT(*) FROM researchers) >= 10
        UNION ALL SELECT 'research_projects' WHERE (SELECT COUNT(*) FROM research_projects) >= 10
        UNION ALL SELECT 'collection_events' WHERE (SELECT COUNT(*) FROM collection_events) >= 10
        UNION ALL SELECT 'samples' WHERE (SELECT COUNT(*) FROM samples) >= 10
        UNION ALL SELECT 'storage_units' WHERE (SELECT COUNT(*) FROM storage_units) >= 10
        UNION ALL SELECT 'aliquots' WHERE (SELECT COUNT(*) FROM aliquots) >= 10
        UNION ALL SELECT 'test_requests' WHERE (SELECT COUNT(*) FROM test_requests) >= 10
        UNION ALL SELECT 'sample_usage' WHERE (SELECT COUNT(*) FROM sample_usage) >= 10
    ) passed_tables;

    IF v_main_table_count <> 9 THEN
        RAISE EXCEPTION 'TEST FAILED: one or more main tables contain fewer than 10 rows';
    END IF;
    RAISE NOTICE 'PASS: all nine main tables contain at least 10 rows';
END;
$$;

DO $$
DECLARE
    v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO donors (
            donor_code, sex_at_birth, donor_status, registered_on
        ) VALUES (
            'INVALID-CODE', 'UNKNOWN', 'ACTIVE', CURRENT_DATE
        );
    EXCEPTION WHEN check_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION 'TEST FAILED: malformed donor code was accepted';
    END IF;
    RAISE NOTICE 'PASS: donor code CHECK constraint rejects malformed codes';
END;
$$;

DO $$
DECLARE
    v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO aliquots (
            aliquot_code, sample_id, storage_unit_id, position_code,
            initial_quantity, current_quantity, quantity_unit,
            aliquot_status, prepared_on
        ) VALUES (
            'ALQ-99991', 1, 5, 'Z99',
            1.000, 2.000, 'mL', 'AVAILABLE', CURRENT_DATE
        );
    EXCEPTION WHEN check_violation THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION 'TEST FAILED: current quantity above initial quantity was accepted';
    END IF;
    RAISE NOTICE 'PASS: aliquot quantity CHECK constraint works';
END;
$$;

DO $$
DECLARE
    v_before NUMERIC(14,3);
    v_after  NUMERIC(14,3);
BEGIN
    SELECT current_quantity INTO v_before
    FROM aliquots WHERE aliquot_id = 1;

    PERFORM record_sample_usage(
        1, 1, 1, DATE '2026-06-15', 0.100,
        'Automated valid-usage test'
    );

    SELECT current_quantity INTO v_after
    FROM aliquots WHERE aliquot_id = 1;

    IF v_after <> v_before - 0.100 THEN
        RAISE EXCEPTION
            'TEST FAILED: expected aliquot reduction from % to %, got %',
            v_before, v_before - 0.100, v_after;
    END IF;
    RAISE NOTICE 'PASS: valid use atomically deducted 0.100 from inventory';
END;
$$;

DO $$
DECLARE
    v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        PERFORM record_sample_usage(
            1, 1, 1, DATE '2026-06-15', 999.000,
            'Intentional overdraw test'
        );
    EXCEPTION WHEN raise_exception THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION 'TEST FAILED: inventory overdraw was accepted';
    END IF;
    RAISE NOTICE 'PASS: inventory overdraw is rejected';
END;
$$;

DO $$
DECLARE
    v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        -- Aliquot 11 belongs to donor 11, whose research consent is expired.
        PERFORM record_sample_usage(
            11, 1, 1, DATE '2026-06-15', 0.100,
            'Intentional expired-consent test'
        );
    EXCEPTION WHEN raise_exception THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION 'TEST FAILED: use with expired consent was accepted';
    END IF;
    RAISE NOTICE 'PASS: expired consent blocks research use';
END;
$$;

DO $$
DECLARE
    v_rejected BOOLEAN := FALSE;
BEGIN
    BEGIN
        -- Researcher 10 is not assigned to project 1.
        PERFORM record_sample_usage(
            1, 1, 10, DATE '2026-06-15', 0.100,
            'Intentional project-authorization test'
        );
    EXCEPTION WHEN raise_exception THEN
        v_rejected := TRUE;
    END;

    IF NOT v_rejected THEN
        RAISE EXCEPTION 'TEST FAILED: unassigned researcher was allowed';
    END IF;
    RAISE NOTICE 'PASS: unassigned researcher is rejected';
END;
$$;

DO $$
DECLARE
    v_audit_before BIGINT;
    v_audit_after  BIGINT;
BEGIN
    SELECT COUNT(*) INTO v_audit_before
    FROM audit_log
    WHERE table_name = 'donors' AND record_id = 1;

    UPDATE donors
    SET ethnicity = ethnicity
    WHERE donor_id = 1;

    SELECT COUNT(*) INTO v_audit_after
    FROM audit_log
    WHERE table_name = 'donors' AND record_id = 1;

    IF v_audit_after <> v_audit_before + 1 THEN
        RAISE EXCEPTION 'TEST FAILED: donor update was not audited';
    END IF;
    RAISE NOTICE 'PASS: audit trigger records donor updates';
END;
$$;

DO $$
DECLARE
    v_view_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_view_count
    FROM information_schema.views
    WHERE table_schema = 'biobank'
      AND table_name IN (
          'v_available_inventory',
          'v_project_usage_summary',
          'v_donor_consent_status'
      );

    IF v_view_count <> 3 THEN
        RAISE EXCEPTION 'TEST FAILED: expected 3 project views, found %', v_view_count;
    END IF;
    RAISE NOTICE 'PASS: all three required views exist';
END;
$$;

ROLLBACK;

SELECT 'ALL DATABASE ACCEPTANCE TESTS PASSED' AS result;
