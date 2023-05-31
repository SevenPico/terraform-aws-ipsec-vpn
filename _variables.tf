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
##  ./_variables.tf
##  This file contains code written only by SevenPico, Inc.
## ----------------------------------------------------------------------------
variable "acm_certificate_arn" {
  type = string
}

variable "cloudwatch_log_expiration_days" {
  type = number
}

variable "ssl_secret_arn" {
  type = string
}

variable "ssl_kms_key_arn" {
  type = string
}

variable "desired_task_count" {
  type    = number
  default = 1
}

variable "kms_key_deletion_window_in_days" {
  type    = number
  default = 30
}

variable "kms_key_enable_key_rotation" {
  type    = bool
  default = true
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "create_nlb" {
  type    = bool
  default = false
}

variable "daemon_udp_port_1" {
  type    = number
  default = 500
}

variable "daemon_udp_port_2" {
  type    = number
  default = 4500
}

variable "nlb_access_logs_s3_bucket_id" {
  type    = string
  default = null
}

variable "nlb_access_logs_prefix_override" {
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

variable "nlb_tls_ssl_policy" {
  type    = string
  default = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "assign_public_ip" {
  type    = bool
  default = false
}

variable "container_image" {
  type    = string
  default = "hwdsl2/ipsec-vpn-server"
}
