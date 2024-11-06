/*
resource "aws_route53_zone" "main" {
  name = var.main_uri
}
 */

/*
resource "aws_route53_record" "factorio_record" {
  zone_id = aws_route53_zone.main.id
  name = var.factorio_uri
  type = "A"
  ttl = 60
}
*/