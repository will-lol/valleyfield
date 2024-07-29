terraform {
	required_providers {
		random = {
			source = "hashicorp/random"
			version = ">= 3.6.2"
		}
		aws = {
			source = "hashicorp/aws"
		}
	}
}
