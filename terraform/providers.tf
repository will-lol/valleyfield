provider "aws" { 
	region = var.aws_region
}

provider "aws" {
	alias = "us-east-1"
	region = "us-east-1"
}

terraform {
	required_providers {
		aws = {
			source = "hashicorp/aws"
			version = ">= 5.54.1"
			configuration_aliases = [ aws.us-east-1 ]
		}
	}

	backend "s3" { }
}
