-- Monthly cost by department and environment, using the labels applied
-- by 04-project-factory (department, environment, cost-center).
-- Run this against gch_billing_export once daily export data has landed
-- (data starts flowing the day after billing export is enabled).

SELECT
  labels_map.value AS department,
  project.id AS project_id,
  service.description AS service,
  SUM(cost) AS total_cost,
  currency
FROM
  `gch-seed-28bdf9.gch_billing_export.gcp_billing_export_v1_*`,
  UNNEST(labels) AS labels_map
WHERE
  labels_map.key = 'department'
  AND _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_TRUNC(CURRENT_DATE(), MONTH))
                        AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
GROUP BY
  department, project_id, service, currency
ORDER BY
  total_cost DESC;
