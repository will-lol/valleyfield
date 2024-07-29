module "base-infra" {
	source = "./base-infra"
	route53_zone_id = var.route53-zone-id
	domain = var.domain
	providers = {
		aws = aws
		aws.us-east-1 = aws.us-east-1
	}
}

module "constants" {
	source = "./constants"
}
