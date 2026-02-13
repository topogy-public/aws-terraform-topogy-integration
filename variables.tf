variable "use_legacy_finte_naming" {
  description = "Set to true if you have existing Finte-named resources (finte-cur, FinteCostExportDaily, FinTeCrossAccountRole, FinTeCURAccessPolicy). New deployments should omit this."
  type        = bool
  default     = false
}

variable "bucket_name" {
  description = "Name of the S3 bucket for storing CUR files. When null, uses topogy-cur (or finte-cur when use_legacy_finte_naming is true)."
  type        = string
  default     = null
  nullable    = true
}

variable "s3_path_prefix" {
  description = "S3 path prefix for organizing CUR files within the bucket"
  type        = string
  default     = "cur-v2"
}

variable "enable_versioning" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = false
}

variable "enable_encryption" {
  description = "Enable server-side encryption using AES256 for the S3 bucket"
  type        = bool
  default     = true
}

variable "enable_lifecycle" {
  description = "Enable lifecycle configuration for the S3 bucket"
  type        = bool
  default     = true
}

variable "lifecycle_expiration_days" {
  description = "Number of days after which objects in the bucket expire"
  type        = number
  default     = 365 # 1 year
}

variable "lifecycle_noncurrent_version_expiration_days" {
  description = "Number of days after which non-current versions of objects expire (limits version storage)"
  type        = number
  default     = 2 # 2 days - short retention for version storage
}

variable "bucket_policy" {
  description = "JSON policy document for the S3 bucket. Grants permission to write the CUR 2.0 report to the S3 bucket. If null, bucket will use default permissions"
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to assign to the S3 bucket"
  type        = map(string)
  default     = {}
}

# Cost and Usage Report (CUR) 2.0 configuration variables
variable "enable_cur" {
  description = "Enable Cost and Usage Report 2.0 creation"
  type        = bool
  default     = true
}

variable "cur_report_name" {
  description = "Name of the Cost and Usage Report 2.0 export. When null, uses TopogyCostExportDaily (or FinteCostExportDaily when use_legacy_finte_naming is true)."
  type        = string
  default     = null
  nullable    = true
}

variable "cur_query_statement" {
  description = "SQL query statement for the CUR 2.0 export. Default includes all standard CUR columns."
  type        = string
  default     = "SELECT bill_bill_type, bill_billing_entity, bill_billing_period_end_date, bill_billing_period_start_date, bill_invoice_id, bill_invoicing_entity, bill_payer_account_id, bill_payer_account_name, cost_category, discount, discount_bundled_discount, discount_total_discount, identity_line_item_id, identity_time_interval, line_item_availability_zone, line_item_blended_cost, line_item_blended_rate, line_item_currency_code, line_item_legal_entity, line_item_line_item_description, line_item_line_item_type, line_item_net_unblended_cost, line_item_net_unblended_rate, line_item_normalization_factor, line_item_normalized_usage_amount, line_item_operation, line_item_product_code, line_item_resource_id, line_item_tax_type, line_item_unblended_cost, line_item_unblended_rate, line_item_usage_account_id, line_item_usage_account_name, line_item_usage_amount, line_item_usage_end_date, line_item_usage_start_date, line_item_usage_type, pricing_currency, pricing_lease_contract_length, pricing_offering_class, pricing_public_on_demand_cost, pricing_public_on_demand_rate, pricing_purchase_option, pricing_rate_code, pricing_rate_id, pricing_term, pricing_unit, product, product_comment, product_fee_code, product_fee_description, product_from_location, product_from_location_type, product_from_region_code, product_instance_family, product_instance_type, product_instancesku, product_location, product_location_type, product_operation, product_pricing_unit, product_product_family, product_region_code, product_servicecode, product_sku, product_to_location, product_to_location_type, product_to_region_code, product_usagetype, reservation_amortized_upfront_cost_for_usage, reservation_amortized_upfront_fee_for_billing_period, reservation_availability_zone, reservation_effective_cost, reservation_end_time, reservation_modification_status, reservation_net_amortized_upfront_cost_for_usage, reservation_net_amortized_upfront_fee_for_billing_period, reservation_net_effective_cost, reservation_net_recurring_fee_for_usage, reservation_net_unused_amortized_upfront_fee_for_billing_period, reservation_net_unused_recurring_fee, reservation_net_upfront_value, reservation_normalized_units_per_reservation, reservation_number_of_reservations, reservation_recurring_fee_for_usage, reservation_reservation_a_r_n, reservation_start_time, reservation_subscription_id, reservation_total_reserved_normalized_units, reservation_total_reserved_units, reservation_units_per_reservation, reservation_unused_amortized_upfront_fee_for_billing_period, reservation_unused_normalized_unit_quantity, reservation_unused_quantity, reservation_unused_recurring_fee, reservation_upfront_value, resource_tags, savings_plan_amortized_upfront_commitment_for_billing_period, savings_plan_end_time, savings_plan_instance_type_family, savings_plan_net_amortized_upfront_commitment_for_billing_period, savings_plan_net_recurring_commitment_for_billing_period, savings_plan_net_savings_plan_effective_cost, savings_plan_offering_type, savings_plan_payment_option, savings_plan_purchase_term, savings_plan_recurring_commitment_for_billing_period, savings_plan_region, savings_plan_savings_plan_a_r_n, savings_plan_savings_plan_effective_cost, savings_plan_savings_plan_rate, savings_plan_start_time, savings_plan_total_commitment_to_date, savings_plan_used_commitment FROM COST_AND_USAGE_REPORT"
}

variable "cur_billing_view_arn" {
  description = "ARN of the billing view to use for the CUR 2.0 export. If empty, will be auto-generated."
  type        = string
  default     = ""
}

variable "cur_table_configurations" {
  description = "Table configurations for the CUR 2.0 export"
  type = map(object({
    BILLING_VIEW_ARN                      = string
    TIME_GRANULARITY                      = string
    INCLUDE_RESOURCES                     = string
    INCLUDE_MANUAL_DISCOUNT_COMPATIBILITY = string
    INCLUDE_SPLIT_COST_ALLOCATION_DATA    = string
  }))
  default = {
    COST_AND_USAGE_REPORT = {
      BILLING_VIEW_ARN                      = ""
      TIME_GRANULARITY                      = "DAILY"
      INCLUDE_RESOURCES                     = "TRUE"
      INCLUDE_MANUAL_DISCOUNT_COMPATIBILITY = "FALSE"
      INCLUDE_SPLIT_COST_ALLOCATION_DATA    = "FALSE"
    }
  }
}

variable "cur_output_type" {
  description = "Output type for the CUR 2.0 export"
  type        = string
  default     = "CUSTOM"
  validation {
    condition     = contains(["CUSTOM"], var.cur_output_type)
    error_message = "Output type must be CUSTOM."
  }
}

variable "cur_format" {
  description = "The format that you want the Cost and Usage Report to be delivered in. We do not recommend changing this from the default value."
  type        = string
  default     = "PARQUET"
  validation {
    condition     = contains(["TEXT_OR_CSV", "PARQUET"], var.cur_format)
    error_message = "Format must be TEXT_OR_CSV or PARQUET."
  }
}

variable "cur_compression" {
  description = "The compression format that you want the Cost and Usage Report to be delivered in. We do not recommend changing this from the default value."
  type        = string
  default     = "PARQUET"
  validation {
    condition     = contains(["GZIP", "PARQUET"], var.cur_compression)
    error_message = "Compression must be GZIP, or PARQUET."
  }
}

variable "cur_overwrite" {
  description = "Whether to overwrite existing files in the S3 destination. We do not recommend changing this from the default value."
  type        = string
  default     = "OVERWRITE_REPORT"
  validation {
    condition     = contains(["OVERWRITE_REPORT", "CREATE_NEW_REPORT"], var.cur_overwrite)
    error_message = "Overwrite must be OVERWRITE_REPORT or CREATE_NEW_REPORT."
  }
}

variable "cur_frequency" {
  description = "The frequency that you want the Cost and Usage Report to be generated. We do not recommend changing this from the default value."
  type        = string
  default     = "SYNCHRONOUS"
  validation {
    condition     = contains(["SYNCHRONOUS"], var.cur_frequency)
    error_message = "Frequency must be SYNCHRONOUS."
  }
}

# IAM policy configuration for CUR access
variable "create_cur_access_policy" {
  description = "Whether to create the TopogyCURAccessPolicy IAM policy used to grant the TopogyCrossAccountRole access to the S3 bucket which is storing the CUR 2.0 report. If false, you will need to create the policy manually."
  type        = bool
  default     = true
}

variable "cross_account_role_name" {
  description = "Name of the existing IAM role to attach the CUR access policy to. When null, uses TopogyCrossAccountRole (or FinTeCrossAccountRole when use_legacy_finte_naming is true)."
  type        = string
  default     = null
  nullable    = true
}

variable "cur_access_policy_name" {
  description = "Name of the IAM policy used to grant the cross-account role access to the S3 bucket. When null, uses TopogyCURAccessPolicy (or FinTeCURAccessPolicy when use_legacy_finte_naming is true)."
  type        = string
  default     = null
  nullable    = true
}
