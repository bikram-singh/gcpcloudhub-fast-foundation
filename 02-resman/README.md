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

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_folder.department](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder) | resource |
| [google_folder.nonprod](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder) | resource |
| [google_folder.prod](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder) | resource |
| [google_folder_iam_member.devops_nonprod](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder_iam_member) | resource |
| [google_organization_iam_member.billing_admins](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/organization_iam_member) | resource |
| [google_organization_iam_member.org_admins](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/organization_iam_member) | resource |
| [google_organization_iam_member.security_admins](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/organization_iam_member) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_groups"></a> [groups](#input\_groups) | Admin group emails. | <pre>object({<br/>    org_admins      = string<br/>    billing_admins  = string<br/>    devops          = string<br/>    security_admins = string<br/>  })</pre> | n/a | yes |
| <a name="input_org_id"></a> [org\_id](#input\_org\_id) | Numeric GCP organization ID. | `string` | n/a | yes |
| <a name="input_departments"></a> [departments](#input\_departments) | List of department names, each gets Prod/NonProd sub-folders. | `list(string)` | <pre>[<br/>  "HR",<br/>  "Finance",<br/>  "IT",<br/>  "Sales",<br/>  "AI"<br/>]</pre> | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Short prefix used for all resource names. | `string` | `"gch"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_department_folder_ids"></a> [department\_folder\_ids](#output\_department\_folder\_ids) | n/a |
| <a name="output_nonprod_folder_ids"></a> [nonprod\_folder\_ids](#output\_nonprod\_folder\_ids) | n/a |
| <a name="output_prod_folder_ids"></a> [prod\_folder\_ids](#output\_prod\_folder\_ids) | n/a |
<!-- END_TF_DOCS -->
