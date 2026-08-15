<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | 7.44.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.9.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_billing_account_iam_member.automation_billing_admin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/billing_account_iam_member) | resource |
| [google_billing_budget.trial_guard](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/billing_budget) | resource |
| [google_iam_workload_identity_pool.github](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool) | resource |
| [google_iam_workload_identity_pool_provider.github](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool_provider) | resource |
| [google_organization_iam_member.automation_folder_admin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/organization_iam_member) | resource |
| [google_organization_iam_member.automation_org_admin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/organization_iam_member) | resource |
| [google_project.seed](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project) | resource |
| [google_project_iam_audit_config.seed_audit](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_audit_config) | resource |
| [google_project_service.seed_apis](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_service_account.automation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account_iam_member.wif_impersonation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |
| [google_storage_bucket.tf_state](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |
| [random_id.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_billing_account_id"></a> [billing\_account\_id](#input\_billing\_account\_id) | Billing account ID (XXXXXX-XXXXXX-XXXXXX). | `string` | n/a | yes |
| <a name="input_domain"></a> [domain](#input\_domain) | Organization primary domain. | `string` | n/a | yes |
| <a name="input_github_repo"></a> [github\_repo](#input\_github\_repo) | GitHub repo allowed to impersonate the automation SA, format owner/repo. | `string` | `"bikram-singh/gcpcloudhub-fast-foundation"` | no |
| <a name="input_org_id"></a> [org\_id](#input\_org\_id) | Numeric GCP organization ID. | `string` | n/a | yes |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Short prefix used for all resource names. | `string` | `"gch"` | no |
| <a name="input_region"></a> [region](#input\_region) | Default region for resources. | `string` | `"asia-south1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_automation_sa_email"></a> [automation\_sa\_email](#output\_automation\_sa\_email) | n/a |
| <a name="output_seed_project_id"></a> [seed\_project\_id](#output\_seed\_project\_id) | n/a |
| <a name="output_tf_state_bucket"></a> [tf\_state\_bucket](#output\_tf\_state\_bucket) | n/a |
<!-- END_TF_DOCS -->
