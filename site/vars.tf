# ---------------------------------------------------------------------------------------------------------------------
# MODULE VARIABLES
# ---------------------------------------------------------------------------------------------------------------------

variable "aws_region" {
  description = "The AWS region in which all resources will be created"
}

variable "domain_name" {
  description = "The non-www version of the domain name, e.g. example.com"
}

variable "aws_acm_certificate_arn" {
  description = "ARN of the SSL certificate (created in the /certificate module)"
}
