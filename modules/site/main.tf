# ---------------------------------------------------------------------------------------------------------------------
# AWS CONFIGURATION DETAILS
# ---------------------------------------------------------------------------------------------------------------------

provider "aws" {
  region = "${var.aws_region}"
}


# ---------------------------------------------------------------------------------------------------------------------
# CREATE S3 BUCKET
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket" "www" {
  bucket = "www.${var.domain_name}"
  acl    = "private"
  policy = <<POLICY
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Sid":"AddPerm",
      "Effect":"Allow",
      "Principal": "*",
      "Action":["s3:GetObject"],
      "Resource":["arn:aws:s3:::www.${var.domain_name}/*"]
    }
  ]
}
POLICY
  website {
    index_document = "index.html"
    error_document = "404.html"
  }
}

resource "aws_s3_bucket" "non_www" {
  bucket = "${var.domain_name}"
  acl    = "private"
  policy = <<POLICY
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Sid":"AddPerm",
      "Effect":"Allow",
      "Principal": "*",
      "Action":["s3:GetObject"],
      "Resource":["arn:aws:s3:::${var.domain_name}/*"]
    }
  ]
}
POLICY

  website {
    redirect_all_requests_to = "https://www.${var.domain_name}"
  }
}


# ---------------------------------------------------------------------------------------------------------------------
# CREATE CLOUDFRONT DISTRIBUTION
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_cloudfront_distribution" "www_distribution" {
  origin {
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = [
        "TLSv1",
        "TLSv1.1",
        "TLSv1.2"]
    }

    domain_name = "${aws_s3_bucket.www.website_endpoint}"
    origin_id   = "www.${var.domain_name}"
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = [
      "GET",
      "HEAD"]
    cached_methods         = [
      "GET",
      "HEAD"]
    target_origin_id       = "www.${var.domain_name}"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  aliases             = [
    "www.${var.domain_name}"]

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = "${var.aws_acm_certificate_arn}"
    ssl_support_method  = "sni-only"
  }
}

resource "aws_cloudfront_distribution" "non_www_distribution" {
  origin {
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = [
        "TLSv1",
        "TLSv1.1",
        "TLSv1.2"]
    }
    domain_name = "${aws_s3_bucket.non_www.website_endpoint}"
    origin_id   = "${var.domain_name}"
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = [
      "GET",
      "HEAD"]
    cached_methods         = [
      "GET",
      "HEAD"]
    target_origin_id       = "${var.domain_name}"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  aliases             = [
    "${var.domain_name}"]

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = "${var.aws_acm_certificate_arn}"
    ssl_support_method  = "sni-only"
  }
}


# ---------------------------------------------------------------------------------------------------------------------
# ADD CLOUDFRONT A RECORDS TO AN EXISTING DOMAIN ZONE
# ---------------------------------------------------------------------------------------------------------------------

data "aws_route53_zone" "zone" {
  name         = "${var.domain_name}."
  private_zone = false
}

resource "aws_route53_record" "www" {
  zone_id = "${data.aws_route53_zone.zone.zone_id}"
  name    = "www.${var.domain_name}"
  type    = "A"

  alias   = {
    name                   = "${aws_cloudfront_distribution.www_distribution.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.www_distribution.hosted_zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "non_www" {
  zone_id = "${data.aws_route53_zone.zone.zone_id}"
  name    = "${var.domain_name}"
  type    = "A"

  alias   = {
    name                   = "${aws_cloudfront_distribution.non_www_distribution.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.non_www_distribution.hosted_zone_id}"
    evaluate_target_health = false
  }
}
