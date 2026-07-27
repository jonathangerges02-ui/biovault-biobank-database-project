-- Business logic for consent enforcement, atomic inventory deduction, timestamps, and auditing.
\set ON_ERROR_STOP on
SET search_path TO biobank, public;

CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_donors_updated_at
BEFORE UPDATE ON donors
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_samples_updated_at
BEFORE UPDATE ON samples
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_aliquots_updated_at
BEFORE UPDATE ON aliquots
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE OR REPLACE FUNCTION fn_validate_and_apply_sample_usage()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_available_quantity NUMERIC(14,3);
    v_aliquot_status     VARCHAR(12);
    v_donor_id           BIGINT;
    v_project_start      DATE;
    v_project_end        DATE;
    v_project_status     VARCHAR(12);
BEGIN
    -- Lock the inventory row so two concurrent requests cannot overdraw it.
    SELECT a.current_quantity, a.aliquot_status, ce.donor_id
      INTO v_available_quantity, v_aliquot_status, v_donor_id
      FROM aliquots a
      JOIN samples s ON s.sample_id = a.sample_id
      JOIN collection_events ce ON ce.collection_event_id = s.collection_event_id
     WHERE a.aliquot_id = NEW.aliquot_id
     FOR UPDATE OF a;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Aliquot % does not exist', NEW.aliquot_id;
    END IF;

    IF v_aliquot_status NOT IN ('AVAILABLE', 'RESERVED') THEN
        RAISE EXCEPTION 'Aliquot % is not usable (status: %)', NEW.aliquot_id, v_aliquot_status;
    END IF;

    IF NEW.quantity_used > v_available_quantity THEN
        RAISE EXCEPTION
            'Insufficient quantity in aliquot %: requested %, available %',
            NEW.aliquot_id, NEW.quantity_used, v_available_quantity;
    END IF;

    SELECT start_date, end_date, project_status
      INTO v_project_start, v_project_end, v_project_status
      FROM research_projects
     WHERE project_id = NEW.project_id;

    IF NEW.used_on < v_project_start
       OR (v_project_end IS NOT NULL AND NEW.used_on > v_project_end)
       OR v_project_status NOT IN ('ACTIVE', 'COMPLETED') THEN
        RAISE EXCEPTION 'Project % was not authorized on %', NEW.project_id, NEW.used_on;
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM project_researchers pr
         WHERE pr.project_id = NEW.project_id
           AND pr.researcher_id = NEW.researcher_id
           AND pr.joined_on <= NEW.used_on
           AND (pr.left_on IS NULL OR pr.left_on >= NEW.used_on)
    ) THEN
        RAISE EXCEPTION
            'Researcher % is not assigned to project % on %',
            NEW.researcher_id, NEW.project_id, NEW.used_on;
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM consents c
          JOIN consent_types ct ON ct.consent_type_id = c.consent_type_id
         WHERE c.donor_id = v_donor_id
           AND ct.consent_code = 'RESEARCH_USE'
           AND c.consent_status = 'ACTIVE'
           AND c.granted_on <= NEW.used_on
           AND (c.expires_on IS NULL OR c.expires_on >= NEW.used_on)
    ) THEN
        RAISE EXCEPTION
            'No active RESEARCH_USE consent for donor % on %',
            v_donor_id, NEW.used_on;
    END IF;

    UPDATE aliquots
       SET current_quantity = current_quantity - NEW.quantity_used,
           aliquot_status = CASE
               WHEN current_quantity - NEW.quantity_used = 0 THEN 'EXHAUSTED'
               ELSE aliquot_status
           END
     WHERE aliquot_id = NEW.aliquot_id;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_validate_and_apply_sample_usage
BEFORE INSERT ON sample_usage
FOR EACH ROW EXECUTE FUNCTION fn_validate_and_apply_sample_usage();

CREATE OR REPLACE FUNCTION record_sample_usage(
    p_aliquot_id       BIGINT,
    p_project_id       BIGINT,
    p_researcher_id    BIGINT,
    p_used_on          DATE,
    p_quantity_used    NUMERIC,
    p_purpose          VARCHAR
)
RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
    v_usage_id BIGINT;
BEGIN
    INSERT INTO sample_usage (
        aliquot_id, project_id, researcher_id, used_on, quantity_used, purpose
    )
    VALUES (
        p_aliquot_id, p_project_id, p_researcher_id, p_used_on, p_quantity_used, p_purpose
    )
    RETURNING usage_id INTO v_usage_id;

    RETURN v_usage_id;
END;
$$;

CREATE OR REPLACE FUNCTION fn_audit_row_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_record_id BIGINT;
    v_row        JSONB;
    v_id_column  TEXT;
BEGIN
    v_id_column := CASE TG_TABLE_NAME
        WHEN 'donors' THEN 'donor_id'
        WHEN 'samples' THEN 'sample_id'
        WHEN 'aliquots' THEN 'aliquot_id'
    END;
    v_row := COALESCE(to_jsonb(NEW), to_jsonb(OLD));
    v_record_id := (v_row ->> v_id_column)::BIGINT;

    INSERT INTO audit_log (
        table_name, record_id, operation, old_values, new_values
    )
    VALUES (
        TG_TABLE_NAME,
        v_record_id,
        TG_OP,
        CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN to_jsonb(OLD) END,
        CASE WHEN TG_OP = 'UPDATE' THEN to_jsonb(NEW) END
    );

    RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE TRIGGER trg_audit_donors
AFTER UPDATE OR DELETE ON donors
FOR EACH ROW EXECUTE FUNCTION fn_audit_row_changes();

CREATE TRIGGER trg_audit_samples
AFTER UPDATE OR DELETE ON samples
FOR EACH ROW EXECUTE FUNCTION fn_audit_row_changes();

CREATE TRIGGER trg_audit_aliquots
AFTER UPDATE OR DELETE ON aliquots
FOR EACH ROW EXECUTE FUNCTION fn_audit_row_changes();

COMMENT ON FUNCTION record_sample_usage(BIGINT, BIGINT, BIGINT, DATE, NUMERIC, VARCHAR) IS
    'Records authorized research use and delegates consent, assignment, and stock checks to a concurrency-safe trigger.';
