-- Demonstration queries covering retrieval, joins, aggregation, subqueries,
-- CTEs, window functions, views, and safe data modification.
\set ON_ERROR_STOP on
SET search_path TO biobank, public;

-- Q1. Simple retrieval with filtering and ordering.
SELECT sample_code, received_at, initial_quantity, quantity_unit
FROM samples
WHERE quality_status = 'ACCEPTED'
  AND sample_status = 'AVAILABLE'
ORDER BY received_at DESC;

-- Q2. Multi-table join: trace an aliquot from donor to physical storage.
SELECT
    d.donor_code,
    ce.event_code,
    s.sample_code,
    st.type_name,
    a.aliquot_code,
    a.current_quantity,
    a.quantity_unit,
    su.location_code
FROM donors d
JOIN collection_events ce ON ce.donor_id = d.donor_id
JOIN samples s ON s.collection_event_id = ce.collection_event_id
JOIN sample_types st ON st.sample_type_id = s.sample_type_id
JOIN aliquots a ON a.sample_id = s.sample_id
JOIN storage_units su ON su.storage_unit_id = a.storage_unit_id
ORDER BY d.donor_code, s.sample_code;

-- Q3. Many-to-many relationship resolved by project_researchers.
SELECT
    p.project_code,
    p.project_title,
    r.researcher_code,
    r.full_name,
    pr.project_role
FROM project_researchers pr
JOIN research_projects p ON p.project_id = pr.project_id
JOIN researchers r ON r.researcher_id = pr.researcher_id
ORDER BY p.project_code, pr.project_role;

-- Q4. Aggregation by sample type.
SELECT
    st.type_name,
    COUNT(DISTINCT s.sample_id) AS sample_count,
    COUNT(a.aliquot_id) AS aliquot_count,
    COALESCE(SUM(a.current_quantity), 0) AS quantity_remaining
FROM sample_types st
LEFT JOIN samples s ON s.sample_type_id = st.sample_type_id
LEFT JOIN aliquots a ON a.sample_id = s.sample_id
GROUP BY st.sample_type_id, st.type_name
ORDER BY sample_count DESC, st.type_name;

-- Q5. GROUP BY with HAVING: projects using more than one donor.
SELECT
    p.project_code,
    COUNT(DISTINCT ce.donor_id) AS donors_used,
    SUM(u.quantity_used) AS total_quantity_used
FROM research_projects p
JOIN sample_usage u ON u.project_id = p.project_id
JOIN aliquots a ON a.aliquot_id = u.aliquot_id
JOIN samples s ON s.sample_id = a.sample_id
JOIN collection_events ce ON ce.collection_event_id = s.collection_event_id
GROUP BY p.project_id, p.project_code
HAVING COUNT(DISTINCT ce.donor_id) > 1
ORDER BY donors_used DESC;

-- Q6. Nested query: aliquots with more remaining quantity than the average
-- for aliquots using the same unit of measure.
SELECT a.aliquot_code, a.current_quantity, a.quantity_unit
FROM aliquots a
WHERE a.current_quantity > (
    SELECT AVG(a2.current_quantity)
    FROM aliquots a2
    WHERE a2.quantity_unit = a.quantity_unit
)
ORDER BY a.quantity_unit, a.current_quantity DESC;

-- Q7. EXISTS subquery: donors with accepted samples and active current consent.
SELECT d.donor_code, d.donor_status
FROM donors d
WHERE EXISTS (
    SELECT 1
    FROM collection_events ce
    JOIN samples s ON s.collection_event_id = ce.collection_event_id
    WHERE ce.donor_id = d.donor_id
      AND s.quality_status = 'ACCEPTED'
)
AND EXISTS (
    SELECT 1
    FROM consents c
    JOIN consent_types ct ON ct.consent_type_id = c.consent_type_id
    WHERE c.donor_id = d.donor_id
      AND ct.consent_code = 'RESEARCH_USE'
      AND c.consent_status = 'ACTIVE'
      AND (c.expires_on IS NULL OR c.expires_on >= CURRENT_DATE)
)
ORDER BY d.donor_code;

-- Q8. Window function: rank projects by number of usage events.
SELECT
    project_code,
    usage_events,
    distinct_samples,
    DENSE_RANK() OVER (ORDER BY usage_events DESC) AS usage_rank
FROM v_project_usage_summary
ORDER BY usage_rank, project_code;

-- Q9. Recursive CTE reconstructs each leaf storage path.
WITH RECURSIVE storage_tree AS (
    SELECT
        storage_unit_id,
        parent_storage_unit_id,
        unit_name,
        unit_name::TEXT AS full_path,
        1 AS depth
    FROM storage_units
    WHERE parent_storage_unit_id IS NULL

    UNION ALL

    SELECT
        child.storage_unit_id,
        child.parent_storage_unit_id,
        child.unit_name,
        parent.full_path || ' > ' || child.unit_name,
        parent.depth + 1
    FROM storage_units child
    JOIN storage_tree parent
      ON parent.storage_unit_id = child.parent_storage_unit_id
)
SELECT storage_unit_id, depth, full_path
FROM storage_tree
ORDER BY full_path;

-- Q10. CASE expression for operational stock alerts.
SELECT
    aliquot_code,
    current_quantity,
    quantity_unit,
    CASE
        WHEN current_quantity = 0 THEN 'EMPTY'
        WHEN current_quantity <= initial_quantity * 0.25 THEN 'LOW'
        ELSE 'ADEQUATE'
    END AS stock_level
FROM aliquots
ORDER BY stock_level, aliquot_code;

-- Q11. View query for the operational UI.
SELECT
    aliquot_code, sample_code, sample_type, current_quantity,
    quantity_unit, location_code
FROM v_available_inventory
WHERE sample_type ILIKE '%plasma%'
ORDER BY current_quantity DESC;

-- Q12. Test workload turnaround time.
SELECT
    tt.test_name,
    COUNT(*) FILTER (WHERE tr.request_status = 'COMPLETED') AS completed_tests,
    ROUND(AVG(tr.completed_on - tr.requested_on)
        FILTER (WHERE tr.request_status = 'COMPLETED'), 2) AS avg_days_to_complete
FROM test_types tt
LEFT JOIN test_requests tr ON tr.test_type_id = tt.test_type_id
GROUP BY tt.test_type_id, tt.test_name
ORDER BY completed_tests DESC, tt.test_name;

-- Q13-Q15. INSERT, UPDATE, and DELETE are demonstrated safely in one rolled-back
-- transaction so repeated execution never pollutes the submitted dataset.
BEGIN;

INSERT INTO donors (
    donor_code, sex_at_birth, birth_year, blood_type,
    ethnicity, donor_status, registered_on
) VALUES (
    'BIO-D9999', 'UNKNOWN', NULL, NULL,
    'Not disclosed', 'ACTIVE', CURRENT_DATE
)
RETURNING donor_id, donor_code;

UPDATE donors
SET donor_status = 'INACTIVE'
WHERE donor_code = 'BIO-D9999'
RETURNING donor_id, donor_code, donor_status;

DELETE FROM donors
WHERE donor_code = 'BIO-D9999'
RETURNING donor_id, donor_code;

ROLLBACK;

-- Q16. Business function demonstration. The trigger validates consent,
-- authorization, and available quantity and deducts stock atomically.
BEGIN;

SELECT record_sample_usage(
    1, 1, 1, DATE '2026-06-15', 0.050,
    'Defense demonstration: reversible validation run'
) AS new_usage_id;

SELECT aliquot_code, current_quantity, aliquot_status
FROM aliquots
WHERE aliquot_id = 1;

ROLLBACK;
