output "acm_certificate_arn" {
  description = "Certificate ARN that needs to be passed to the site module"
  value       = "${aws_acm_certificate.certificate.arn}"
}
