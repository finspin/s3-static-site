# ---------------------------------------------------------------------------------------------------------------------
# THIS MODULE CREATES AND VALIDATES SSL CERTIFICATE. VALIDATION IS DONE BY ADDING A DNS RECORD IN ROUTE 53.
# ---------------------------------------------------------------------------------------------------------------------


# ---------------------------------------------------------------------------------------------------------------------
# AWS CONFIGURATION DETAILS
# ---------------------------------------------------------------------------------------------------------------------

# For static sites hosted from S3 bucket via CloudFront
# the SSL certificate must be issued in the us-east-1 region.
provider "aws" {
  region = "us-east-1"
}


# ---------------------------------------------------------------------------------------------------------------------
# CREATE AND VALIDATE SSL CERTIFICATE
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_acm_certificate" "certificate" {
  domain_name               = "*.${var.domain_name}"
  validation_method         = "DNS"
  subject_alternative_names = [
    "${var.domain_name}"]
}

data "aws_route53_zone" "zone" {
  name         = "${var.domain_name}."
  private_zone = false
}

resource "aws_route53_record" "validation" {
  name    = "${aws_acm_certificate.certificate.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.certificate.domain_validation_options.0.resource_record_type}"
  zone_id = "${data.aws_route53_zone.zone.id}"
  records = [
    "${aws_acm_certificate.certificate.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = "${aws_acm_certificate.certificate.arn}"
  validation_record_fqdns = [
    "${aws_route53_record.validation.fqdn}"]
}
