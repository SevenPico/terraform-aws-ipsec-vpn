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
##  ./secret.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Service Configuration Context
# ------------------------------------------------------------------------------
module "secret_context" {
  source  = "registry.terraform.io/SevenPico/context/null"
  version = "2.0.0"
  context = module.context.self
}


# --------------------------------------------------------------------------
# Service Configuration
# --------------------------------------------------------------------------
module "secret" {
  source  = "registry.terraform.io/SevenPico/secret/aws"
  version = "3.1.0"
  context = module.secret_context.self

  create_sns                      = false
  description                     = "Secrets and environment variables for ${module.context.id}"
  kms_key_deletion_window_in_days = var.kms_key_deletion_window_in_days
  kms_key_enable_key_rotation     = var.kms_key_enable_key_rotation
  secret_ignore_changes           = false
  secret_read_principals          = {}
  secret_string                   = jsonencode(var.secrets_map)
  sns_pub_principals              = null
  sns_sub_principals              = null
}
