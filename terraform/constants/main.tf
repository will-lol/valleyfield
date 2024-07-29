resource "random_id" "prefix" {
	byte_length = 8
}

output "prefix" {
	value = random_id.prefix.hex
}

data "aws_caller_identity" "current" {}

output "account_id" {
 value = data.aws_caller_identity.current.account_id
}
