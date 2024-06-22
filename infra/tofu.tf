variable "aws_region" {
	type = string
	default = "ap-southeast-2"
}

terraform {
	required_providers {
		aws = {
			source = "hashicorp/aws"
			version = ">= 5.54.1"
		}
		random = {
			source = "hashicorp/random"
			version = ">= 3.6.2"
		}
	}

	backend "s3" { }
}


