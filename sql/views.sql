-- Read models for inventory, consent monitoring, and project reporting.
\set ON_ERROR_STOP on
SET search_path TO biobank, public;

CREATE OR REPLACE VIEW v_available_inventory AS
SELECT
    a.aliquot_id,
    a.aliquot_code,
    s.sample_code,
    st.type_name AS sample_type,
    a.current_quantity,
    a.quantity_unit,
    a.aliquot_status,
    su.location_code,
    su.unit_name AS storage_unit,
    su.temperature_c,
    ce.event_code,
    d.donor_code,
    s.quality_status
FROM aliquots a
JOIN samples s ON s.sample_id = a.sample_id
JOIN sample_types st ON st.sample_type_id = s.sample_type_id
JOIN storage_units su ON su.storage_unit_id = a.storage_unit_id
JOIN collection_events ce ON ce.collection_event_id = s.collection_event_id
JOIN donors d ON d.donor_id = ce.donor_id
WHERE a.aliquot_status IN ('AVAILABLE', 'RESERVED')
  AND a.current_quantity > 0
  AND s.sample_status IN ('AVAILABLE', 'RESERVED')
  AND s.quality_status = 'ACCEPTED';

CREATE OR REPLACE VIEW v_project_usage_summary AS
SELECT
    p.project_id,
    p.project_code,
    p.project_title,
    p.project_status,
    COUNT(u.usage_id) AS usage_events,
    COUNT(DISTINCT a.sample_id) AS distinct_samples,
    COUNT(DISTINCT ce.donor_id) AS distinct_donors,
    COALESCE(SUM(u.quantity_used), 0)::NUMERIC(12,3) AS total_quantity_used
FROM research_projects p
LEFT JOIN sample_usage u ON u.project_id = p.project_id
LEFT JOIN aliquots a ON a.aliquot_id = u.aliquot_id
LEFT JOIN samples s ON s.sample_id = a.sample_id
LEFT JOIN collection_events ce ON ce.collection_event_id = s.collection_event_id
GROUP BY p.project_id, p.project_code, p.project_title, p.project_status;

CREATE OR REPLACE VIEW v_donor_consent_status AS
SELECT
    d.donor_id,
    d.donor_code,
    d.donor_status,
    BOOL_OR(
        ct.consent_code = 'RESEARCH_USE'
        AND c.consent_status = 'ACTIVE'
        AND c.granted_on <= CURRENT_DATE
        AND (c.expires_on IS NULL OR c.expires_on >= CURRENT_DATE)
    ) AS has_active_research_consent,
    MAX(c.expires_on) FILTER (WHERE ct.consent_code = 'RESEARCH_USE') AS latest_research_expiry
FROM donors d
LEFT JOIN consents c ON c.donor_id = d.donor_id
LEFT JOIN consent_types ct ON ct.consent_type_id = c.consent_type_id
GROUP BY d.donor_id, d.donor_code, d.donor_status;

COMMENT ON VIEW v_available_inventory IS
    'Searchable accepted aliquots with remaining inventory and physical locations.';
COMMENT ON VIEW v_project_usage_summary IS
    'Per-project counts and total consumption, including projects with no use.';
COMMENT ON VIEW v_donor_consent_status IS
    'Current research-consent flag without exposing direct donor identifiers.';
