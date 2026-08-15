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
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_compute_shared_vpc_service_project.attach](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_shared_vpc_service_project) | resource |
| [google_project.workload](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project) | resource |
| [google_project_iam_audit_config.workload_audit](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_audit_config) | resource |
| [google_project_service.workload_apis](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [random_id.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [terraform_remote_state.networking](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |
| [terraform_remote_state.resman](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_billing_account_id"></a> [billing\_account\_id](#input\_billing\_account\_id) | n/a | `string` | n/a | yes |
| <a name="input_departments"></a> [departments](#input\_departments) | n/a | `list(string)` | <pre>[<br/>  "HR",<br/>  "Finance",<br/>  "IT",<br/>  "Sales",<br/>  "AI"<br/>]</pre> | no |
| <a name="input_enabled_workloads"></a> [enabled\_workloads](#input\_enabled\_workloads) | Explicit list of department/env pairs to actually provision, gated by billing quota. | <pre>list(object({<br/>    department = string<br/>    env        = string<br/>  }))</pre> | n/a | yes |
| <a name="input_org_id"></a> [org\_id](#input\_org\_id) | n/a | `string` | n/a | yes |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | n/a | `string` | `"gch"` | no |
| <a name="input_state_bucket"></a> [state\_bucket](#input\_state\_bucket) | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_workload_project_ids"></a> [workload\_project\_ids](#output\_workload\_project\_ids) | n/a |
<!-- END_TF_DOCS -->
