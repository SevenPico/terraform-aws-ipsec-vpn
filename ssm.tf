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
##  ./ssm.tf
##  This file contains code written by SevenPico, Inc.
## ---------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Composite Installer Script
#------------------------------------------------------------------------------
module "composite_installer_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  attributes = ["composite", "installer"]
}

resource "aws_ssm_document" "composite_installer" {
  count           = module.composite_installer_context.enabled ? 1 : 0
  name            = module.composite_installer_context.id
  document_format = "YAML"
  document_type   = "Command"
  tags            = module.composite_installer_context.tags
  content = templatefile("${path.module}/templates/ssm-composite-initializer.tftpl", {
    ec2_initialization = try(aws_ssm_document.ec2_initialization[0].name, "")
    ec2_upgrade        = try(aws_ssm_document.ec2_upgrade[0].name, "")
    install_document   = try(!var.enable_efs ? aws_ssm_document.install_default[0].name : aws_ssm_document.install_with_efs[0].name, "")
    configure_ssl      = var.enable_custom_ssl ? try(aws_ssm_document.configure_ssl[0].name, "") : ""
  })
}

resource "aws_ssm_association" "composite_installer" {
  count               = module.composite_installer_context.enabled ? 1 : 0
  association_name    = module.composite_installer_context.id
  compliance_severity = "CRITICAL"
  name                = try(aws_ssm_document.composite_installer[0].name, "")
  schedule_expression = null
  targets {
    key    = "tag:Name"
    values = [module.context.id]
  }
  dynamic "output_location" {
    for_each = var.vpn_ssm_association_output_bucket_name != null ? [1] : []
    content {
      s3_bucket_name = var.vpn_ssm_association_output_bucket_name
      s3_key_prefix  = try(aws_ssm_document.composite_installer[0].name, "")
    }
  }
}


#------------------------------------------------------------------------------
# EC2 Initialization
#------------------------------------------------------------------------------
module "ec2_initialization_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  attributes = ["ec2", "initialization"]
}

resource "aws_ssm_document" "ec2_initialization" {
  count           = module.ec2_initialization_context.enabled ? 1 : 0
  name            = module.ec2_initialization_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags = module.ec2_initialization_context.tags
  content = templatefile("${path.module}/templates/ssm-ec2-initialization.tftpl", {
    hostname  = var.vpn_hostname
    time_zone = var.vpn_time_zone
    region    = try(data.aws_region.current[0].name, "")
  })
}


#------------------------------------------------------------------------------
# Upgrade EC2 OS
#------------------------------------------------------------------------------
module "ec2_upgrade_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  attributes = ["ec2", "upgrade"]
}

resource "aws_ssm_document" "ec2_upgrade" {
  count           = module.ec2_upgrade_context.enabled ? 1 : 0
  name            = module.ec2_upgrade_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags    = module.ec2_upgrade_context.tags
  content = templatefile("${path.module}/templates/ssm-ec2-upgrade.tftpl", {})

}

resource "aws_ssm_association" "ec2_upgrade" {
  count               = module.context.enabled ? 1 : 0
  association_name    = module.ec2_upgrade_context.id
  name                = one(aws_ssm_document.ec2_upgrade[*].name)
  schedule_expression = var.ec2_upgrade_schedule_expression
  targets {
    key    = "tag:Name"
    values = [module.context.id]
  }
  apply_only_at_cron_interval = true
}


#------------------------------------------------------------------------------
# Install with Defaults
#------------------------------------------------------------------------------
module "install_with_defaults_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  enabled    = module.context.enabled && !var.enable_efs
  attributes = ["install", "with", "defaults"]
}

resource "aws_ssm_document" "install_default" {
  count           = module.install_with_defaults_context.enabled ? 1 : 0
  name            = module.install_with_defaults_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags = module.install_with_defaults_context.tags
  content = templatefile("${path.module}/templates/ssm-install-default.tftpl", {
    openvpnas_version = var.vpn_version
  })
}


#------------------------------------------------------------------------------
# Install with EFS
#------------------------------------------------------------------------------
module "install_with_efs_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  enabled    = module.context.enabled && var.enable_efs
  attributes = ["install", "with", "efs"]
}

resource "aws_ssm_document" "install_with_efs" {
  count           = module.install_with_efs_context.enabled && var.enable_efs ? 1 : 0
  name            = module.install_with_efs_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags = module.install_with_efs_context.tags

  content = templatefile("${path.module}/templates/ssm-install-with-efs.tftpl", {
    openvpnas_version         = var.vpn_version
    efs_mount_target_dns_name = module.efs.mount_target_dns_names[0]
    s3_backup_bucket          = module.backups_bucket.bucket_id
    s3_backup_key             = "backups/openvpn_backup_pre_install.tar.gz"
  })
}


#------------------------------------------------------------------------------
# Configure SSL
#------------------------------------------------------------------------------
module "configure_ssl_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  enabled    = module.context.enabled && var.enable_custom_ssl
  attributes = ["configure", "ssl"]
}

resource "aws_ssm_document" "configure_ssl" {
  count           = module.configure_ssl_context.enabled ? 1 : 0
  name            = module.configure_ssl_context.id
  document_format = "YAML"
  document_type   = "Command"

  tags = module.configure_ssl_context.tags
  content = templatefile("${path.module}/templates/ssm-configure-ssl.tftpl", {
    secret_arn                      = var.ssl_secret_arn,
    region                          = try(data.aws_region.current[0].name, ""),
    certificate_keyname             = var.ssl_secret_certificate_keyname,
    certificate_bundle_keyname      = var.ssl_secret_certificate_bundle_keyname,
    certificate_private_key_keyname = var.ssl_secret_certificate_private_key_keyname
  })
}


