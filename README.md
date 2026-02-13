# Topogy Terraform for AWS Integration

This Terraform module enables a Cost and Usage Report 2.0 (CUR 2.0) data export along
with an S3 bucket specifically configured to store these files.

## CUR 2.0 Setup Requirements

The CUR 2.0 report needs to be configured in your Management account, so it is expected that the
terraform user will have access to the Management account and has permission to create the following resources:

1. **S3 bucket** in the same region as your AWS account (the region where the bucket is created is determined by the AWS provider region)
2. **Bucket policy** that allows AWS Billing services to write CUR files
3. **CUR definition** that automatically exports daily billing data
4. **Policy** used to grant Topogy access to read from the S3 bucket.

## Upgrading (Finte → Topogy)

**Existing users** with Finte-named resources: Add `use_legacy_finte_naming = true` to keep your existing names:

```hcl
module "cur_s3_bucket" {
  source = "git::https://github.com/topogy-public/aws-terraform-topogy-integration.git?ref=main"

  use_legacy_finte_naming = true  # Keeps finte-cur, FinteCostExportDaily, FinTeCrossAccountRole, FinTeCURAccessPolicy
}
```

If you already override resource names (e.g., `bucket_name = "finte-cur-terraform"`), those values are used as-is—you may still need `use_legacy_finte_naming = true` for any you don't override.

**New deployments:** No changes needed. Defaults use Topogy naming (topogy-cur, TopogyCostExportDaily, etc.).

## Example Usage

The example below uses ref=main (which is appended in the URL), but it is recommended to use a specific tag version (i.e. ref=0.0.1) to avoid breaking changes. Go to the [release page](https://github.com/topogy-public/aws-terraform-topogy-integration/releases) for a list of published versions.

You do not need to set any variables—defaults to use Topogy naming. You may wish to enable versioning of your S3 bucket via `enable_versioning` variable. We do NOT recommend changing the CUR report.

```hcl
module "cur_s3_bucket" {
  source = "git::https://github.com/topogy-public/aws-terraform-topogy-integration.git?ref=main"

  # enable_versioning = true
}
```

We recommend including the following output statements so you can easily copy the values into the Topogy "Add credentials" form when connecting your AWS account. The outputs map directly to the CUR Credentials section of that form (see the [Integration Guide](https://docs.google.com/document/d/1U9wysY8wVnQMd4If3QJ1wzUZaSlAFZhRCjxnAYTr1eI/edit?tab=t.dqnjmc5bg96p#bookmark=id.dz1b28l35yet) for an example):

| Terraform output   | Topogy form field   |
|--------------------|---------------------|
| `bucket_name`      | S3 bucket name      |
| `s3_path_prefix`   | S3 prefix           |
| `cur_report_name`  | Report name         |
| `bucket_region`    | Region              |

```hcl
output "cur_bucket_name" {
  description = "Name of the CUR S3 bucket"
  value       = try(module.cur_s3_bucket.bucket_name, null)
}

output "cur_s3_path_prefix" {
  description = "S3 path prefix for organizing CUR files"
  value       = try(module.cur_s3_bucket.s3_path_prefix, null)
}

output "cur_bucket_region" {
  description = "AWS region where the bucket is located"
  value       = try(module.cur_s3_bucket.bucket_region, null)
}

output "cur_report_name" {
  description = "Name of the Cost and Usage Report 2.0 export"
  value       = try(module.cur_s3_bucket.cur_report_name, null)
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_bcmdataexports_export.cur_report](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bcmdataexports_export) | resource |
| [aws_iam_policy.cur_access_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role_policy_attachment.cur_access_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_s3_bucket.cur_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.cur_bucket_lifecycle](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_policy.cur_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.cur_bucket_pab](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.cur_bucket_encryption](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.cur_bucket_versioning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Name of the S3 bucket for storing CUR files. When null, uses topogy-cur (or finte-cur when use\_legacy\_finte\_naming is true). | `string` | `null` | no |
| <a name="input_bucket_policy"></a> [bucket\_policy](#input\_bucket\_policy) | JSON policy document for the S3 bucket. Grants permission to write the CUR 2.0 report to the S3 bucket. If null, bucket will use default permissions | `string` | `null` | no |
| <a name="input_create_cur_access_policy"></a> [create\_cur\_access\_policy](#input\_create\_cur\_access\_policy) | Whether to create the TopogyCURAccessPolicy IAM policy used to grant the TopogyCrossAccountRole access to the S3 bucket which is storing the CUR 2.0 report. If false, you will need to create the policy manually. | `bool` | `true` | no |
| <a name="input_cross_account_role_name"></a> [cross\_account\_role\_name](#input\_cross\_account\_role\_name) | Name of the existing IAM role to attach the CUR access policy to. When null, uses TopogyCrossAccountRole (or FinTeCrossAccountRole when use\_legacy\_finte\_naming is true). | `string` | `null` | no |
| <a name="input_cur_access_policy_name"></a> [cur\_access\_policy\_name](#input\_cur\_access\_policy\_name) | Name of the IAM policy used to grant the cross-account role access to the S3 bucket. When null, uses TopogyCURAccessPolicy (or FinTeCURAccessPolicy when use\_legacy\_finte\_naming is true). | `string` | `null` | no |
| <a name="input_cur_billing_view_arn"></a> [cur\_billing\_view\_arn](#input\_cur\_billing\_view\_arn) | ARN of the billing view to use for the CUR 2.0 export. If empty, will be auto-generated. | `string` | `""` | no |
| <a name="input_cur_compression"></a> [cur\_compression](#input\_cur\_compression) | The compression format that you want the Cost and Usage Report to be delivered in. We do not recommend changing this from the default value. | `string` | `"PARQUET"` | no |
| <a name="input_cur_format"></a> [cur\_format](#input\_cur\_format) | The format that you want the Cost and Usage Report to be delivered in. We do not recommend changing this from the default value. | `string` | `"PARQUET"` | no |
| <a name="input_cur_frequency"></a> [cur\_frequency](#input\_cur\_frequency) | The frequency that you want the Cost and Usage Report to be generated. We do not recommend changing this from the default value. | `string` | `"SYNCHRONOUS"` | no |
| <a name="input_cur_output_type"></a> [cur\_output\_type](#input\_cur\_output\_type) | Output type for the CUR 2.0 export | `string` | `"CUSTOM"` | no |
| <a name="input_cur_overwrite"></a> [cur\_overwrite](#input\_cur\_overwrite) | Whether to overwrite existing files in the S3 destination. We do not recommend changing this from the default value. | `string` | `"OVERWRITE_REPORT"` | no |
| <a name="input_cur_query_statement"></a> [cur\_query\_statement](#input\_cur\_query\_statement) | SQL query statement for the CUR 2.0 export. Default includes all standard CUR columns. | `string` | `"SELECT bill_bill_type, bill_billing_entity, bill_billing_period_end_date, bill_billing_period_start_date, bill_invoice_id, bill_invoicing_entity, bill_payer_account_id, bill_payer_account_name, cost_category, discount, discount_bundled_discount, discount_total_discount, identity_line_item_id, identity_time_interval, line_item_availability_zone, line_item_blended_cost, line_item_blended_rate, line_item_currency_code, line_item_legal_entity, line_item_line_item_description, line_item_line_item_type, line_item_net_unblended_cost, line_item_net_unblended_rate, line_item_normalization_factor, line_item_normalized_usage_amount, line_item_operation, line_item_product_code, line_item_resource_id, line_item_tax_type, line_item_unblended_cost, line_item_unblended_rate, line_item_usage_account_id, line_item_usage_account_name, line_item_usage_amount, line_item_usage_end_date, line_item_usage_start_date, line_item_usage_type, pricing_currency, pricing_lease_contract_length, pricing_offering_class, pricing_public_on_demand_cost, pricing_public_on_demand_rate, pricing_purchase_option, pricing_rate_code, pricing_rate_id, pricing_term, pricing_unit, product, product_comment, product_fee_code, product_fee_description, product_from_location, product_from_location_type, product_from_region_code, product_instance_family, product_instance_type, product_instancesku, product_location, product_location_type, product_operation, product_pricing_unit, product_product_family, product_region_code, product_servicecode, product_sku, product_to_location, product_to_location_type, product_to_region_code, product_usagetype, reservation_amortized_upfront_cost_for_usage, reservation_amortized_upfront_fee_for_billing_period, reservation_availability_zone, reservation_effective_cost, reservation_end_time, reservation_modification_status, reservation_net_amortized_upfront_cost_for_usage, reservation_net_amortized_upfront_fee_for_billing_period, reservation_net_effective_cost, reservation_net_recurring_fee_for_usage, reservation_net_unused_amortized_upfront_fee_for_billing_period, reservation_net_unused_recurring_fee, reservation_net_upfront_value, reservation_normalized_units_per_reservation, reservation_number_of_reservations, reservation_recurring_fee_for_usage, reservation_reservation_a_r_n, reservation_start_time, reservation_subscription_id, reservation_total_reserved_normalized_units, reservation_total_reserved_units, reservation_units_per_reservation, reservation_unused_amortized_upfront_fee_for_billing_period, reservation_unused_normalized_unit_quantity, reservation_unused_quantity, reservation_unused_recurring_fee, reservation_upfront_value, resource_tags, savings_plan_amortized_upfront_commitment_for_billing_period, savings_plan_end_time, savings_plan_instance_type_family, savings_plan_net_amortized_upfront_commitment_for_billing_period, savings_plan_net_recurring_commitment_for_billing_period, savings_plan_net_savings_plan_effective_cost, savings_plan_offering_type, savings_plan_payment_option, savings_plan_purchase_term, savings_plan_recurring_commitment_for_billing_period, savings_plan_region, savings_plan_savings_plan_a_r_n, savings_plan_savings_plan_effective_cost, savings_plan_savings_plan_rate, savings_plan_start_time, savings_plan_total_commitment_to_date, savings_plan_used_commitment FROM COST_AND_USAGE_REPORT"` | no |
| <a name="input_cur_report_name"></a> [cur\_report\_name](#input\_cur\_report\_name) | Name of the Cost and Usage Report 2.0 export. When null, uses TopogyCostExportDaily (or FinteCostExportDaily when use\_legacy\_finte\_naming is true). | `string` | `null` | no |
| <a name="input_cur_table_configurations"></a> [cur\_table\_configurations](#input\_cur\_table\_configurations) | Table configurations for the CUR 2.0 export | <pre>map(object({<br/>    BILLING_VIEW_ARN                      = string<br/>    TIME_GRANULARITY                      = string<br/>    INCLUDE_RESOURCES                     = string<br/>    INCLUDE_MANUAL_DISCOUNT_COMPATIBILITY = string<br/>    INCLUDE_SPLIT_COST_ALLOCATION_DATA    = string<br/>  }))</pre> | <pre>{<br/>  "COST_AND_USAGE_REPORT": {<br/>    "BILLING_VIEW_ARN": "",<br/>    "INCLUDE_MANUAL_DISCOUNT_COMPATIBILITY": "FALSE",<br/>    "INCLUDE_RESOURCES": "TRUE",<br/>    "INCLUDE_SPLIT_COST_ALLOCATION_DATA": "FALSE",<br/>    "TIME_GRANULARITY": "DAILY"<br/>  }<br/>}</pre> | no |
| <a name="input_enable_cur"></a> [enable\_cur](#input\_enable\_cur) | Enable Cost and Usage Report 2.0 creation | `bool` | `true` | no |
| <a name="input_enable_encryption"></a> [enable\_encryption](#input\_enable\_encryption) | Enable server-side encryption using AES256 for the S3 bucket | `bool` | `true` | no |
| <a name="input_enable_lifecycle"></a> [enable\_lifecycle](#input\_enable\_lifecycle) | Enable lifecycle configuration for the S3 bucket | `bool` | `true` | no |
| <a name="input_enable_versioning"></a> [enable\_versioning](#input\_enable\_versioning) | Enable versioning for the S3 bucket | `bool` | `false` | no |
| <a name="input_lifecycle_expiration_days"></a> [lifecycle\_expiration\_days](#input\_lifecycle\_expiration\_days) | Number of days after which objects in the bucket expire | `number` | `365` | no |
| <a name="input_lifecycle_noncurrent_version_expiration_days"></a> [lifecycle\_noncurrent\_version\_expiration\_days](#input\_lifecycle\_noncurrent\_version\_expiration\_days) | Number of days after which non-current versions of objects expire (limits version storage) | `number` | `2` | no |
| <a name="input_s3_path_prefix"></a> [s3\_path\_prefix](#input\_s3\_path\_prefix) | S3 path prefix for organizing CUR files within the bucket | `string` | `"cur-v2"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to the S3 bucket | `map(string)` | `{}` | no |
| <a name="input_use_legacy_finte_naming"></a> [use\_legacy\_finte\_naming](#input\_use\_legacy\_finte\_naming) | Set to true if you have existing Finte-named resources (finte-cur, FinteCostExportDaily, FinTeCrossAccountRole, FinTeCURAccessPolicy). New deployments should omit this. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | The name of the S3 bucket |
| <a name="output_bucket_region"></a> [bucket\_region](#output\_bucket\_region) | The AWS region this bucket resides in |
| <a name="output_cur_report_name"></a> [cur\_report\_name](#output\_cur\_report\_name) | Name of the Cost and Usage Report 2.0 export |
| <a name="output_s3_path_prefix"></a> [s3\_path\_prefix](#output\_s3\_path\_prefix) | The S3 path prefix for organizing CUR files |
<!-- END_TF_DOCS -->