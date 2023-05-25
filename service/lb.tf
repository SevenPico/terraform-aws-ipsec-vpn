module "lb_context" {
  source  = "registry.terraform.io/SevenPico/context/null"
  version = "2.0.0"
  context = module.context.self
}

locals {
  lb_enabled = module.context.enabled
}

# ------------------------------------------------------------------------------
# Target Group and Listener
# ------------------------------------------------------------------------------
resource "aws_lb_target_group" "default" {
  count                = local.lb_enabled && var.create_listener_tg ? 1 : 0
  name                 = module.lb_context.id
  port                 = var.container_port
  protocol             = var.target_group_protocol
  vpc_id               = var.vpc_id
  target_type          = var.target_group_type
  deregistration_delay = 300

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
    protocol            = var.health_check_protocol
    port                = var.health_check_port
    path                = var.health_check_path
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = module.lb_context.tags
}

resource "aws_lb_listener" "default" {
  count             = local.lb_enabled && var.create_listener_tg ? 1 : 0
  load_balancer_arn = var.load_balancer_arn
  port              = 443
  protocol          = var.listener_protocol
  certificate_arn   = var.listener_protocol == "TLS" ||  var.listener_protocol == "HTTPS"? var.acm_certificate_arn : null
  default_action {
    target_group_arn = aws_lb_target_group.default[count.index].arn
    type             = "forward"
  }
}

locals {
  load_balancers = module.lb_context.enabled && var.create_listener_tg ? {
    lb-1 : {
      elb_name : null
      target_group_arn : join("", aws_lb_target_group.default.*.arn)
      container_name : local.container_name
      container_port : var.container_port
    }
  } : {}
}