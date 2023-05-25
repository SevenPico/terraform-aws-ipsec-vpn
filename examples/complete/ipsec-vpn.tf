#------------------------------------------------------------------------------
# IPsec VPN Context
#------------------------------------------------------------------------------
module "ipsec_vpn_context" {
  source  = "SevenPico/context/null"
  version = "2.0.0"
  context = module.context.self
  name    = "ipsec-vpn"
}


#------------------------------------------------------------------------------
# IPsec VPN
#------------------------------------------------------------------------------
module "ipsec-vpn" {
  source  = "../../"
  context = module.ipsec_vpn_context.self

  acm_certificate_arn            = module.ssl_certificate.acm_certificate_arn
  cloudwatch_log_expiration_days = 90
  private_subnet_ids             = module.vpc_subnets.private_subnet_ids
  public_subnet_ids              = module.vpc_subnets.public_subnet_ids
  ssl_kms_key_arn                = module.ssl_certificate.kms_key_arn
  ssl_secret_arn                 = module.ssl_certificate.secret_arn
  vpc_id                         = module.vpc.vpc_id

  create_nlb              = true
  nlb_acm_certificate_arn = null
}


# ------------------------------------------------------------------------------
# IPsec VPN NLB DNS Records
# ------------------------------------------------------------------------------
resource "aws_route53_record" "openvpn_nlb" {
  count   = module.ipsec_vpn_context.enabled ? 1 : 0
  zone_id = aws_route53_zone.public[0].id
  name    = module.ipsec_vpn_context.dns_name
  type    = "A"
  alias {
    name                   = module.ipsec-vpn.nlb_dns_name
    zone_id                = module.ipsec-vpn.nlb_zone_id
    evaluate_target_health = true
  }
}