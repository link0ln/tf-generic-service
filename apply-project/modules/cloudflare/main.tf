provider "cloudflare" {
  api_token = var.cloudflare_token
}

resource "cloudflare_record" "record" {
  zone_id = var.cloudflare_zone_id
  name    = var.cloudflare_domain
  value   = var.cloudflare_target
  type    = var.cloudflare_target_type
  ttl     = 300
}
