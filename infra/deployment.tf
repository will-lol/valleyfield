resource "aws_codepipeline" "codepipeline" {
	name = "${random_uuid.prefix.result}-codepipeline"


}
