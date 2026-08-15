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
| [google_org_policy_policy.bucket_public_access_prevention](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/org_policy_policy) | resource |
| [google_org_policy_policy.disable_sa_key_creation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/org_policy_policy) | resource |
| [google_org_policy_policy.domain_restricted_sharing](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/org_policy_policy) | resource |
| [google_org_policy_policy.skip_default_network](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/org_policy_policy) | resource |
| [google_org_policy_policy.sql_restrict_public_ip](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/org_policy_policy) | resource |
| [google_org_policy_policy.vm_external_ip](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/org_policy_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_customer_id"></a> [customer\_id](#input\_customer\_id) | Cloud Identity customer ID, used for domain-restricted sharing. | `string` | n/a | yes |
| <a name="input_org_id"></a> [org\_id](#input\_org\_id) | Numeric GCP organization ID. | `string` | n/a | yes |
| <a name="input_state_bucket"></a> [state\_bucket](#input\_state\_bucket) | GCS bucket used for all stage state files. | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
