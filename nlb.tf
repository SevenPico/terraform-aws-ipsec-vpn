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
##  ./nlb.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# NLB Labels
# ------------------------------------------------------------------------------
module "nlb_context" {
  source          = "SevenPico/context/null"
  version         = "2.0.0"
  context         = module.context.self
  enabled         = module.context.enabled && var.create_nlb
  attributes      = ["nlb"]
  id_length_limit = 32
}

module "nlb_tgt_context" {
  count      = length(local.nlb_listener_protocols)
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.nlb_context.self
  attributes = [local.nlb_listener_ports[count.index], "tgt"]
}

locals {
  #ui_https_protocol   = var.ui_https_port != null ? "TLS" : null
  #daemon_tcp_protocol = var.daemon_tcp_port != null ? "TCP" : null
  daemon_udp_protocol_1 = var.daemon_udp_port_1 != null ? "UDP" : null
  daemon_udp_protocol_2 = var.daemon_udp_port_2 != null ? "UDP" : null
  #ui_https_type       = var.ui_https_port != null ? "instance" : null
  #daemon_tcp_type     = var.daemon_tcp_port != null ? "instance" : null
  daemon_udp_type1     = var.daemon_udp_port_1 != null ? "ip" : null
  daemon_udp_type2     = var.daemon_udp_port_2 != null ? "ip" : null
  nlb_listener_protocols      = compact([local.daemon_udp_protocol_1, local.daemon_udp_protocol_2])
  nlb_listener_ports          = compact([var.daemon_udp_port_1, var.daemon_udp_port_2])
  nlb_target_protocols        = compact([local.daemon_udp_protocol_1, local.daemon_udp_protocol_2])
  nlb_target_ports            = compact([var.daemon_udp_port_1, var.daemon_udp_port_2])
  nlb_target_type             = compact([local.daemon_udp_type1, local.daemon_udp_type2])
}


# ------------------------------------------------------------------------------
# NLB
# ------------------------------------------------------------------------------
module "nlb" {
  source  = "SevenPicoForks/nlb/aws"
  version = "2.0.0"
  context = module.nlb_context.self

  access_logs_enabled               = var.nlb_access_logs_s3_bucket_id != null
  access_logs_prefix                = var.nlb_access_logs_prefix_override == null ? module.nlb_context.id : var.nlb_access_logs_prefix_override
  access_logs_s3_bucket_id          = var.nlb_access_logs_s3_bucket_id
  certificate_arn                   = var.nlb_acm_certificate_arn
  create_default_target_group       = false
  cross_zone_load_balancing_enabled = false
  deletion_protection_enabled       = var.nlb_deletion_protection_enabled
  deregistration_delay              = 300
  health_check_enabled              = false
  health_check_interval             = 10
  health_check_path                 = "/"
  health_check_port                 = null
  health_check_protocol             = "HTTPS"
  health_check_threshold            = 2
  internal                          = false
  ip_address_type                   = "ipv4"
  subnet_ids                        = var.public_subnet_ids
  target_group_additional_tags      = {}
  target_group_name                 = ""
  target_group_port                 = 0
  target_group_target_type          = "ip"
  tcp_enabled                       = false
  tcp_port                          = null
  tls_enabled                       = false
  tls_port                          = null
  tls_ssl_policy                    = var.nlb_tls_ssl_policy
  udp_enabled                       = false
  udp_port                          = null
  vpc_id                            = var.vpc_id
}


# ------------------------------------------------------------------------------
# NLB Target Groups and Listeners
# ------------------------------------------------------------------------------
resource "aws_lb_target_group" "nlb" {
  count                = module.nlb_context.enabled ? length(local.nlb_target_protocols) : 0
  name                 = module.nlb_tgt_context[count.index].id
  port                 = local.nlb_target_ports[count.index]
  protocol             = local.nlb_target_protocols[count.index]
  vpc_id               = var.vpc_id
  target_type          = local.nlb_target_type[count.index]
  deregistration_delay = 300
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
    protocol            = "HTTPS"
    port                = 443
    path                = "/"
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = module.nlb_tgt_context[count.index].tags
}

resource "aws_lb_listener" "nlb" {
  count             = module.nlb_context.enabled ? length(local.nlb_listener_protocols) : 0
  load_balancer_arn = module.nlb.nlb_arn
  port              = local.nlb_listener_ports[count.index]
  ssl_policy        = local.nlb_listener_protocols[count.index] == "TLS" ? var.nlb_tls_ssl_policy : null
  protocol          = local.nlb_listener_protocols[count.index]
  certificate_arn   = local.nlb_listener_protocols[count.index] == "TLS" ? var.nlb_acm_certificate_arn : null
  default_action {
    target_group_arn = aws_lb_target_group.nlb[count.index].arn
    type             = "forward"
  }
}
