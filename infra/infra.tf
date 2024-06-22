variable "domain" {
	type = string
}

variable "route53_zone_id" {
	type = string
}

locals {
	aws_cloudfront_distribution_cache_policy_ids = {
		amplify = "2e54312d-136d-493c-8eb9-b001f22f67d2"
		caching_disabled = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
		caching_optimised = "658327ea-f89d-4fab-a63d-7e88639e58f6"
		caching_optimised_for_uncompressed_objects = "b2884449-e4de-46a7-ac36-70bc7f1ddd6d"
		elemental-media_package = "08627262-05a9-4f76-9ded-b50ca2e3a84f"
		use_origin_cache_control_headers = "83da9c7e-98b4-4e11-a168-04f0df8e2c65"
		use_origin_cache_control_headers-query_strings = "4cc15a8a-d715-48a4-82b8-cc0b614638fe"
	}
}

resource "aws_s3_bucket" "web_files" {
	bucket = var.domain
	tags = {
		Name = "Website files bucket"
	}
}

output "web_files_bucket_arn" {
	value = aws_s3_bucket.web_files.arn
}

data "aws_iam_policy_document" "allow_distribution" {
	statement {
		effect = "Allow"
		actions = ["s3:GetObject"]
		resources = [
			"${aws_s3_bucket.web_files.arn}/*"
		]
		principals {
			type = "Service"
			identifiers = ["cloudfront.amazonaws.com"]
		}
		condition {
			test = "ForAnyValue:StringEquals"
			variable = "AWS:SourceArn"
			values = [aws_cloudfront_distribution.distribution.arn]
		}
	}
}

resource "aws_s3_bucket_policy" "allow_distribution" {
	bucket = aws_s3_bucket.web_files.id
	policy = data.aws_iam_policy_document.allow_distribution.json
}

locals {
	s3_origin_id = "${random_uuid.prefix.result}-bucket"
}

resource "aws_acm_certificate" "cert" {
	provider = aws.us-east-1
	domain_name = var.domain
	validation_method = "DNS"
}

resource "aws_route53_record" "cert_validation_records" {
	provider = aws.us-east-1
	for_each = {
		for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
			name = dvo.resource_record_name
			record = dvo.resource_record_value
			type = dvo.resource_record_type
		}
	}

	allow_overwrite = true
	name = each.value.name
	records = [each.value.record]
	ttl = 60
	type = each.value.type
	zone_id = var.route53_zone_id
}

resource "aws_acm_certificate_validation" "cert_validation" {
	provider = aws.us-east-1
	certificate_arn	= aws_acm_certificate.cert.arn
	validation_record_fqdns = [for record in aws_route53_record.cert_validation_records : record.fqdn]
}

resource "aws_cloudfront_origin_access_control" "distribution_web_files_oac" {
	provider = aws.us-east-1
	name = "${random_uuid.prefix.result}-distribution_web_files_oac"
	origin_access_control_origin_type = "s3"
	signing_behavior = "always"
	signing_protocol = "sigv4"
}

resource "aws_cloudfront_distribution" "distribution" {
	provider = aws.us-east-1
	enabled = true
	is_ipv6_enabled = true
	default_root_object = "index.html"
	aliases = [var.domain]
	http_version = "http3"
	origin {
		domain_name = aws_s3_bucket.web_files.bucket_regional_domain_name
		origin_id = local.s3_origin_id
		origin_access_control_id = aws_cloudfront_origin_access_control.distribution_web_files_oac.id
	}
	default_cache_behavior {
		cache_policy_id = local.aws_cloudfront_distribution_cache_policy_ids.caching_optimised
		allowed_methods = ["GET", "HEAD", "OPTIONS"]
		cached_methods = ["GET", "HEAD"]
		target_origin_id = local.s3_origin_id
		viewer_protocol_policy = "redirect-to-https"
	}
	viewer_certificate {
		ssl_support_method = "sni-only"
		minimum_protocol_version = "TLSv1.2_2021"
		acm_certificate_arn = aws_acm_certificate.cert.arn
	}
	restrictions {
		geo_restriction {
			restriction_type = "none"
			locations = []
		}
	}
}

resource "aws_route53_record" "distribution_A_record" {
	provider = aws.us-east-1
	zone_id = var.route53_zone_id
	name = var.domain
	type = "A"
	alias {
		name = aws_cloudfront_distribution.distribution.domain_name
		zone_id = aws_cloudfront_distribution.distribution.hosted_zone_id
		evaluate_target_health = false
	}
}

resource "aws_route53_record" "distribution_AAAA_record" {
	provider = aws.us-east-1
	zone_id = var.route53_zone_id
	name = var.domain
	type = "AAAA"
	alias {
		name = aws_cloudfront_distribution.distribution.domain_name
		zone_id = aws_cloudfront_distribution.distribution.hosted_zone_id
		evaluate_target_health = false
	}
}

