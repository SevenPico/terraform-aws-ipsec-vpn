variable "vpc_id" {
  type = string
}

variable "vpc_subnet_ids" {
  type    = list(string)
  default = []
}

variable "assign_public_ip" {
  type    = bool
  default = false
}

variable "cluster_arn" {
  type = string
}

variable "cloudwatch_log_group_name" {
  type    = string
  default = ""
}

variable "desired_task_count" {
  type    = number
  default = 1
}

variable "task_cpu" {
  default = 2048
}

variable "task_memory" {
  default = 4096
}

variable "ignore_changes_task_definition" {
  type    = bool
  default = true
}

variable "ignore_changes_desired_count" {
  type    = bool
  default = false
}

variable "container_image" {
  type = string
}

variable "container_port" {
  type = number
}

variable "service_command" {
  type    = list(string)
  default = []
}

variable "container_entrypoint" {
  type    = list(string)
  default = null
}

variable "container_port_mappings" {
  default = []
}

variable "preserve_security_group_id" {
  type    = bool
  default = true
}

variable "security_group_create_before_destroy" {
  type    = bool
  default = false
}

variable "task_role_policy_docs" {
  type    = map(string)
  default = {}
}

variable "task_exec_role_policy_docs" {
  type    = map(any)
  default = {}
}

variable "security_group_rules_map" {
  type    = any
  default = {}
}

variable "security_group_rules" {
  type        = any
  default     = []
  description = <<EOF
Example as follows:
[
  {
    key                      = "ingress-from-$${module.alb_context.id}"
    description              = "Allow ingress from ALB to service"
    type                     = "ingress"
    protocol                 = "tcp"
    from_port                = var.container_port
    to_port                  = var.container_port
    source_security_group_id = module.alb_security_group.id
  }
]
EOF
}

variable "load_balancer_arn" {
  type    = string
}

variable "create_target_group" {
  type    = bool
}

variable "kms_key_deletion_window_in_days" {
  type    = number
  default = 30
}

variable "kms_key_enable_key_rotation" {
  type    = bool
  default = true
}

variable "secrets_map" {
  type    = map(string)
  default = {}
}

variable "health_check_protocol" {
  type = string
}
variable "health_check_port" {
  type = number

}
variable "health_check_path" {
  type    = string
  default = "/"
}

variable "target_group_protocol" {
  type    = string
  default = "HTTPS"
}

variable "target_group_type" {
  type    = string
  default = "ip"
}

variable "listener_protocol" {
  type    = string
  default = ""
}

variable "acm_certificate_arn" {
  type = string
}