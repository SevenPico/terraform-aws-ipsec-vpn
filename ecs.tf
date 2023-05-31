#------------------------------------------------------------------------------
# ECS Context
#------------------------------------------------------------------------------
module "ecs_cluster_context" {
  source     = "registry.terraform.io/SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  enabled    = module.context.enabled
  attributes = ["cluster"]
}

module "ecs_task_exec_policy_context" {
  source     = "registry.terraform.io/SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  attributes = ["ecs-ipsec-vpn-task-exec-policy"]
}

module "ecs_ipsec_vpn_service_context" {
  source  = "registry.terraform.io/SevenPico/context/null"
  version = "2.0.0"
  context = module.context.self
  name    = "ipsec-vpn"
}


#------------------------------------------------------------------------------
# ECS Cluster
#------------------------------------------------------------------------------
resource "aws_ecs_cluster" "core" {
  count = module.ecs_cluster_context.enabled ? 1 : 0
  name  = module.ecs_cluster_context.id
  tags  = module.ecs_cluster_context.tags
}


#------------------------------------------------------------------------------
# ECS Cloudwatch Log Group for Services
#------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "ecs_services" {
  count             = module.ecs_cluster_context.enabled ? 1 : 0
  name              = "/aws/ecs/${aws_ecs_cluster.core[0].name}/services"
  retention_in_days = var.cloudwatch_log_expiration_days
}


#------------------------------------------------------------------------------
# ECS Cloudwatch Log Group for Tasks
#------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "ecs_tasks" {
  count             = module.ecs_cluster_context.enabled ? 1 : 0
  name              = "/aws/ecs/${aws_ecs_cluster.core[0].name}/tasks"
  retention_in_days = var.cloudwatch_log_expiration_days
}


# ------------------------------------------------------------------------------
# ECS IAM
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "ecs_task_exec_policy_doc" {
  count = module.ecs_task_exec_policy_context.enabled ? 1 : 0

  statement {
    sid     = "AllowSslSecretRead"
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = compact([
      var.ssl_secret_arn
    ])
  }

  statement {
    sid     = "AllowSslSecretKeyAccess"
    effect  = "Allow"
    actions = ["kms:Decrypt"]
    resources = compact([
      var.ssl_kms_key_arn
    ])
  }
}


#------------------------------------------------------------------------------
# IPsec VPN Service
#------------------------------------------------------------------------------
module "ecs_ipsec_vpn_service" {
  source  = "./service"
  context = module.ecs_ipsec_vpn_service_context.self

  create_listener_tg              = false
  acm_certificate_arn             = var.acm_certificate_arn
  assign_public_ip                = false
  cloudwatch_log_group_name       = join("", aws_cloudwatch_log_group.ecs_services.*.name)
  cluster_arn                     = join("", aws_ecs_cluster.core.*.arn)
  container_entrypoint            = []
  container_image                 = "hwdsl2/ipsec-vpn-server"
  container_port                  = null
  container_port_mappings         = [
    {
      containerPort = 500
      hostPort = 500
      protocol = "udp"
    },
    {
      containerPort = 4500
      hostPort = 4500
      protocol = "udp"
    }
  ]
  desired_task_count              = var.desired_task_count
  health_check_path               = "/"
  health_check_port               = null
  health_check_protocol           = ""
  ignore_changes_desired_count    = true
  ignore_changes_task_definition  = true
  kms_key_deletion_window_in_days = var.kms_key_deletion_window_in_days
  kms_key_enable_key_rotation     = var.kms_key_enable_key_rotation
  listener_protocol               = ""
  load_balancer_arn               = module.nlb.nlb_arn
  preserve_security_group_id      = true
  secrets_map = {
    VPN_IPSEC_PSK : try(random_password.ipsec_psk[0].result, "")
    VPN_USER : "vpnuser"
    VPN_PASSWORD : try(random_password.admin_password[0].result, "")
    VPN_DNS_NAME : module.ecs_ipsec_vpn_service_context.dns_name
    VPN_CLIENT_NAME : "vpnclient"
  }
  security_group_create_before_destroy = false
  security_group_rules = [
    {
      key                      = "IngressFrom500"
      description              = "Allow ingress from 500."
      type                     = "ingress"
      protocol                 = "udp"
      from_port                = 500
      to_port                  = 500
      cidr_blocks              = ["0.0.0.0/0"]
    },
    {
      key                      = "IngressFrom4500"
      description              = "Allow ingress from 4500."
      type                     = "ingress"
      protocol                 = "udp"
      from_port                = 4500
      to_port                  = 4500
      cidr_blocks              = ["0.0.0.0/0"]
    }
  ]
  security_group_rules_map   = {}
  service_command            = []
  #service_role_policy_docs   = []
  target_group_protocol      = ""
  target_group_type          = ""
  task_cpu                   = 512
  task_exec_role_policy_docs = { default : try(data.aws_iam_policy_document.ecs_task_exec_policy_doc[0].json, {}) }
  task_memory                = 1024
  task_role_policy_docs      = {}
  vpc_id                     = var.vpc_id
  vpc_subnet_ids             = var.private_subnet_ids
}

resource "aws_cloudwatch_metric_alarm" "ecs_ipsec_vpn_cpu" {
  count = module.ecs_ipsec_vpn_service_context.enabled ? 1 : 0

  alarm_name          = "${module.ecs_ipsec_vpn_service_context.id}-cpu"
  tags                = module.context.tags
  alarm_description   = "Monitors ${module.ecs_ipsec_vpn_service_context.id} CPU Utilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60" # seconds
  statistic           = "Average"
  threshold           = "80" # percent
  dimensions = {
    ServiceName = module.ecs_ipsec_vpn_service_context.id
    ClusterName = aws_ecs_cluster.core[0].name
  }

  actions_enabled                       = false
  alarm_actions                         = []
  datapoints_to_alarm                   = null
  evaluate_low_sample_count_percentiles = null
  extended_statistic                    = null
  insufficient_data_actions             = []
  ok_actions                            = []
  threshold_metric_id                   = null
  treat_missing_data                    = null
  unit                                  = null
}

resource "random_password" "admin_password" {
  count   = module.ecs_ipsec_vpn_service_context.enabled ? 1 : 0
  length  = 32
  special = false
}

resource "random_password" "ipsec_psk" {
  count   = module.ecs_ipsec_vpn_service_context.enabled ? 1 : 0
  length  = 32
  special = false
}

#module "secret_random-password" {
#  source  = "SevenPico/secret/aws//modules/random-password"
#  version = "3.2.7"
#
#  password_length = 32
#
#}

#resource "null_resource" "env_file_update" {
#  count   = module.ecs_ipsec_vpn_service_context.enabled ? 1 : 0
#  triggers = {
#    VPN_IPSEC_PSK = try(random_password.ipsec_psk[0].result, "")
#    VPN_PASSWORD = try(random_password.admin_password[0].result, "")
#  }
#  provisioner "local-exec" {
#    command = <<-EOT
#      echo "VPN_IPSEC_PSK=${random_password.ipsec_psk[0].result}" > ${path.module}/vpn.env
#      echo "VPN_USER=vpnuser" >> ${path.module}/vpn.env
#      echo "VPN_PASSWORD=${random_password.admin_password[0].result}" >> ${path.module}/vpn.env
#      echo "VPN_DNS_NAME=${module.ecs_ipsec_vpn_service_context.dns_name}" >> ${path.module}/vpn.env
#      echo "VPN_CLIENT_NAME=vpnclient" >> ${path.module}/vpn.env
#    EOT
#  }
#}
