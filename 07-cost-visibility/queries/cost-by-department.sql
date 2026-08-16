-- Monthly cost by department and environment, using the labels applied
-- by 04-project-factory (department, environment, cost-center).
--
-- NOTE: Table name confirmed as gcp_billing_export_resource_v1_<billing_account_id>
-- (underscored), not the generic gcp_billing_export_v1_* pattern - this is
-- specific to "Detailed usage cost" export, which includes resource-level data.

SELECT
  labels_map.value AS department,
  project.id AS project_id,
  service.description AS service,
  SUM(cost) AS total_cost,
  currency
FROM
  `gch-seed-28bdf9.gch_billing_export.gcp_billing_export_resource_v1_012E9C_0D5AF1_5575CE`,
  UNNEST(project.labels) AS labels_map
WHERE
  labels_map.key = 'department'
  AND usage_start_time >= TIMESTAMP_TRUNC(CURRENT_TIMESTAMP(), MONTH)
GROUP BY
  department, project_id, service, currency
ORDER BY
  total_cost DESC;
