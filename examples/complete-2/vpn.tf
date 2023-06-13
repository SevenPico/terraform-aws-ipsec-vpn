## ----------------------------------------------------------------------------
##  Copyright 2023 SevenPico, Inc.
##
##  Licensed under the Apache License, Version 2.0 (the "License");
##  you may not use this file except in compliance with the License.
##  You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
##  Unless required by applicable law or agreed to in writing, software
##  distributed under the License is distributed on an "AS IS" BASIS,
##  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
##  See the License for the specific language governing permissions and
##  limitations under the License.
## ----------------------------------------------------------------------------

## ----------------------------------------------------------------------------
##  ./examples/complete/vpn.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

#------------------------------------------------------------------------------
# IPsec VPN Labels
#------------------------------------------------------------------------------
module "vpn_context" {
  source  = "SevenPico/context/null"
  version = "2.0.0"
  context = module.context.self
  name    = "vpn"
}


# ------------------------------------------------------------------------------
# IPsec vpn IAM Role Policy Doc
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "vpn_ec2_policy_doc" {
  count = module.vpn_context.enabled ? 1 : 0

  statement {
    sid       = "GetSslSecrets"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [module.ssl_certificate.secret_arn]
  }

  statement {
    sid       = "DecryptSslKmsKey"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [module.ssl_certificate.kms_key_arn]
  }
}

#------------------------------------------------------------------------------
# VPN
#------------------------------------------------------------------------------
module "vpn" {
  source  = "../.."
  context = module.vpn_context.self


  # REQUIRED
  subnet_ids   = module.vpc_subnets.public_subnet_ids
  vpc_id       = module.vpc.vpc_id
  vpn_hostname = module.vpn_context.dns_name

  # Create Options
  create_ec2_autoscale_sns_topic = var.create_ec2_autoscale_sns_topic
  create_nlb                     = var.create_nlb
  create_vpn_secret              = var.create_vpn_secret

  # Enablements
  enable_efs        = var.enable_efs
  enable_custom_ssl = var.enable_custom_ssl
  enable_ec2_cloudwatch_logs = var.enable_ec2_cloudwatch_logs

  # Logging
  cloudwatch_logs_expiration_days = var.cloudwatch_logs_expiration_days

  # SSL
  ssl_secret_arn                             = module.ssl_certificate.secret_arn
  ssl_secret_kms_key_arn                     = module.ssl_certificate.kms_key_arn
  ssl_secret_certificate_bundle_keyname      = var.ssl_secret_certificate_bundle_keyname
  ssl_secret_certificate_keyname             = var.ssl_secret_certificate_keyname
  ssl_secret_certificate_private_key_keyname = var.ssl_secret_certificate_private_key_keyname

  # EC2
  ec2_associate_public_ip_address           = var.ec2_associate_public_ip_address
  ec2_ami_id                                = var.ec2_ami_id
  ec2_autoscale_desired_count               = var.ec2_autoscale_desired_count
  ec2_autoscale_instance_type               = var.ec2_autoscale_instance_type
  ec2_autoscale_max_count                   = var.ec2_autoscale_max_count
  ec2_autoscale_min_count                   = var.ec2_autoscale_min_count
  ec2_autoscale_sns_topic_default_result    = var.ec2_autoscale_sns_topic_default_result
  ec2_autoscale_sns_topic_heartbeat_timeout = var.ec2_autoscale_sns_topic_heartbeat_timeout
  ec2_additional_security_group_ids         = var.ec2_additional_security_group_ids
  ec2_block_device_mappings                 = []
  ec2_disable_api_termination               = false
  ec2_role_source_policy_documents          = try(data.aws_iam_policy_document.vpn_ec2_policy_doc[*].json, [])
  ec2_upgrade_schedule_expression           = var.ec2_upgrade_schedule_expression
  ec2_security_group_allow_all_egress       = var.ec2_security_group_allow_all_egress
  ec2_security_group_rules = [
    {
      key       = "egress-to-vpc-443"
      type      = "egress"
      from_port = 443
      to_port   = 443
      protocol  = "tcp"
      cidr_blocks = [
      module.vpc.vpc_cidr_block]
      ipv6_cidr_blocks         = []
      source_security_group_id = null
      self                     = null
      description              = "Allow https egress to VPC."
    }
  ]

  # NLB
  nlb_access_logs_prefix_override = var.nlb_access_logs_s3_bucket_id
  nlb_access_logs_s3_bucket_id    = var.nlb_access_logs_prefix_override
  nlb_acm_certificate_arn         = module.ssl_certificate.acm_certificate_arn
  nlb_deletion_protection_enabled = var.nlb_deletion_protection_enabled
  nlb_subnet_ids                  = module.vpc_subnets.public_subnet_ids
  nlb_tls_ssl_policy              = var.nlb_tls_ssl_policy

  # S3
  s3_source_policy_documents = var.s3_source_policy_documents

  # VPN
  vpn_daemon_ingress_blocks          = var.vpn_daemon_ingress_blocks
  s3_access_logs_prefix_override     = var.s3_access_logs_prefix_override
  s3_access_logs_s3_bucket_id        = var.s3_access_logs_s3_bucket_id
  s3_force_destroy                   = var.s3_force_destroy
  s3_lifecycle_configuration_rules   = var.s3_lifecycle_configuration_rules
  s3_versioning_enabled              = var.s3_versioning_enabled
  vpn_secret_admin_password_key      = var.vpn_secret_admin_password_key
  vpn_secret_arn                     = var.vpn_secret_arn
  vpn_secret_enable_kms_key_rotation = var.vpn_secret_enable_kms_key_rotation
  vpn_secret_kms_key_arn             = var.vpn_secret_kms_key_arn
  s3_object_ownership                = var.s3_object_ownership
}

# Delays VPN initialization until all resources are in place
resource "null_resource" "vpn_set_autoscale_counts" {
  count = module.vpn_context.enabled ? 1 : 0
  depends_on = [
  module.vpn]

  provisioner "local-exec" {
    command = join(" ", [
      "aws",
      "autoscaling",
      "update-auto-scaling-group",
      "--auto-scaling-group-name",
      module.vpn.autoscale_group_name,
      "--desired-capacity",
      1
    ])
  }
}


