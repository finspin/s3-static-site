output "acm_certificate_arn" {
  description = "Certificate ARN"
  value       = "${aws_acm_certificate.certificate.arn}"
}