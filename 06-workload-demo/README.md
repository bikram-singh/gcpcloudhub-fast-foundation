<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_google"></a> [google](#requirement\_google) | 7.44.0 |

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
| [google_cloud_run_v2_service.demo](https://registry.terraform.io/providers/hashicorp/google/7.44.0/docs/resources/cloud_run_v2_service) | resource |
| [google_cloud_run_v2_service_iam_member.public_invoker](https://registry.terraform.io/providers/hashicorp/google/7.44.0/docs/resources/cloud_run_v2_service_iam_member) | resource |
| [google_compute_global_address.psa_range](https://registry.terraform.io/providers/hashicorp/google/7.44.0/docs/resources/compute_global_address) | resource |
| [google_compute_instance.demo_vm](https://registry.terraform.io/providers/hashicorp/google/7.44.0/docs/resources/compute_instance) | resource |
| [google_project_service.run_api](https://registry.terraform.io/providers/hashicorp/google/7.44.0/docs/resources/project_service) | resource |
| [google_project_service.servicenetworking_api](https://registry.terraform.io/providers/hashicorp/google/7.44.0/docs/resources/project_service) | resource |
| [google_project_service.servicenetworking_workload_api](https://registry.terraform.io/providers/hashicorp/google/7.44.0/docs/resources/project_service) | resource |
| [google_project_service.sqladmin_api](https://registry.terraform.io/providers/hashicorp/google/7.44.0/docs/resources/project_service) | resource |
| [google_secret_manager_secret_version.db_credential](https://registry.terraform.io/providers/hashicorp/google/7.44.0/docs/resources/secret_manager_secret_version) | resource |
| [google_service_networking_connection.psa_connection](https://registry.terraform.io/providers/hashicorp/google/7.44.0/docs/resources/service_networking_connection) | resource |
| [google_sql_database.demo_db](https://registry.terraform.io/providers/hashicorp/google/7.44.0/docs/resources/sql_database) | resource |
| [google_sql_database_instance.demo_postgres](https://registry.terraform.io/providers/hashicorp/google/7.44.0/docs/resources/sql_database_instance) | resource |
| [google_sql_user.demo_user](https://registry.terraform.io/providers/hashicorp/google/7.44.0/docs/resources/sql_user) | resource |
| [random_password.db_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [terraform_remote_state.networking](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |
| [terraform_remote_state.project_factory](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_state_bucket"></a> [state\_bucket](#input\_state\_bucket) | n/a | `string` | n/a | yes |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | n/a | `string` | `"gch"` | no |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `"asia-south1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloud_sql_private_ip"></a> [cloud\_sql\_private\_ip](#output\_cloud\_sql\_private\_ip) | n/a |
| <a name="output_demo_service_url"></a> [demo\_service\_url](#output\_demo\_service\_url) | n/a |
| <a name="output_demo_vm_internal_ip"></a> [demo\_vm\_internal\_ip](#output\_demo\_vm\_internal\_ip) | n/a |
<!-- END_TF_DOCS -->
