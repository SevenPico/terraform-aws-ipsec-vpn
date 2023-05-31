variable "create_ec2_autoscale_sns_topic" {
  type    = bool
  default = false
}

variable "create_nlb" {
  type    = bool
  default = true
}

variable "create_vpn_secret" {
  type    = bool
  default = true
}

variable "enable_efs" {
  type    = bool
  default = false
}

variable "enable_custom_ssl" {
  type        = bool
  default     = false
  description = <<EOF
  When this is true SSL values from the SSL SecretsManager document will be written to the EC2 Instance and VPN will
  use the Certificate instead of default VPN Certificate.
EOF
}

variable "enable_ec2_cloudwatch_logs" {
  type    = bool
  default = true
}

variable "cloudwatch_logs_expiration_days" {
  type    = number
  default = 90
}

variable "ssl_secret_certificate_bundle_keyname" {
  type    = string
  default = "CERTIFICATE_CHAIN"
}

variable "ssl_secret_certificate_keyname" {
  type    = string
  default = "CERTIFICATE"
}

variable "ssl_secret_certificate_private_key_keyname" {
  type    = string
  default = "CERTIFICATE_PRIVATE_KEY"
}

variable "ec2_associate_public_ip_address" {
  type    = bool
  default = true
}

variable "ec2_ami_id" {
  type    = string
  default = "ami-0574da719dca65348"
}

variable "ec2_autoscale_desired_count" {
  type    = number
  default = 1
}

variable "ec2_autoscale_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ec2_autoscale_max_count" {
  type    = number
  default = 1
}

variable "ec2_autoscale_min_count" {
  type    = number
  default = 1
}

variable "ec2_autoscale_sns_topic_default_result" {
  type    = string
  default = "CONTINUE"
}

variable "ec2_autoscale_sns_topic_heartbeat_timeout" {
  type    = number
  default = 180
}

variable "ec2_additional_security_group_ids" {
  type    = list(string)
  default = []
}

variable "ec2_disable_api_termination" {
  type        = bool
  description = "If `true`, enables EC2 Instance Termination Protection"
  default     = false
}

variable "ec2_role_source_policy_documents" {
  type        = list(string)
  default     = []
  description = "If necessary, provide additional JSON Policy Documents for the EC2 Instance."
}

variable "ec2_upgrade_schedule_expression" {
  type    = string
  default = "cron(15 13 ? * SUN *)"
}

variable "ec2_security_group_allow_all_egress" {
  type    = bool
  default = true
}

variable "ec2_security_group_rules" {
  type    = list(any)
  default = []
}

variable "ec2_block_device_mappings" {
  description = "Specify volumes to attach to the instance besides the volumes specified by the AMI"
  type = list(object({
    device_name  = string
    no_device    = bool
    virtual_name = string
    ebs = object({
      delete_on_termination = bool
      encrypted             = bool
      iops                  = number
      kms_key_id            = string
      snapshot_id           = string
      volume_size           = number
      volume_type           = string
    })
  }))

  default = []
}

variable "nlb_access_logs_prefix_override" {
  type    = string
  default = null
}

variable "nlb_access_logs_s3_bucket_id" {
  type    = string
  default = null
}

variable "nlb_acm_certificate_arn" {
  type    = string
  default = null
}

variable "nlb_deletion_protection_enabled" {
  type    = bool
  default = false
}

variable "nlb_subnet_ids" {
  type    = list(string)
  default = []
}

variable "nlb_tls_ssl_policy" {
  type    = string
  default = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "s3_source_policy_documents" {
  type        = list(string)
  default     = []
  description = <<-EOT
    List of IAM policy documents that are merged together into the exported document.
    Statements defined in source_policy_documents must have unique SIDs.
    Statement having SIDs that match policy SIDs generated by this module will override them.
    EOT
}

variable "vpn_daemon_ingress_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "vpn_secret_admin_password_key" {
  type    = string
  default = "ADMIN_PASSWORD"
}

variable "vpn_secret_arn" {
  type    = string
  default = ""
}

variable "vpn_secret_enable_kms_key_rotation" {
  type    = bool
  default = true
}

variable "vpn_secret_kms_key_arn" {
  type    = string
  default = null
}

variable "s3_access_logs_prefix_override" {
  type    = string
  default = null
}

variable "s3_access_logs_s3_bucket_id" {
  type    = string
  default = null
}

variable "s3_force_destroy" {
  type    = bool
  default = true
}

variable "s3_lifecycle_configuration_rules" {
  type    = list(any)
  default = []
}

variable "s3_versioning_enabled" {
  type    = bool
  default = true
}

variable "s3_object_ownership" {
  type    = string
  default = "BucketOwnerEnforced"
}

variable "vpc_cidr_block" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "root_domain" {
  type = string
}