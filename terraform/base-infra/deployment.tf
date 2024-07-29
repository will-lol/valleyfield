variable "repo_name_id" {
  type = string
  default = "will-lol/valleyfield"
}

variable "repo_branch" {
  type = string
  default = "main"
}

resource "aws_codepipeline" "codepipeline" {
  name     = "${module.constants.prefix}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn
  pipeline_type = "V2"

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.repo.arn
        FullRepositoryId = var.repo_name_id
        BranchName       = var.repo_branch
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.codebuild.id
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CloudFormation"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ActionMode     = "REPLACE_ON_FAILURE"
        Capabilities   = "CAPABILITY_AUTO_EXPAND,CAPABILITY_IAM"
        OutputFileName = "CreateStackOutput.json"
        StackName      = "MyStack"
        TemplatePath   = "build_output::sam-templated.yaml"
      }
    }
  }
}

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "${module.constants.prefix}-artifact-store"
}

resource "aws_codestarconnections_connection" "repo" {
  name          = "${module.constants.prefix}-repo"
  provider_type = "GitHub"
}

resource "aws_s3_bucket_public_access_block" "codepipeline_bucket_pab" {
  bucket = aws_s3_bucket.codepipeline_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "codepipeline_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name               = "${module.constants.prefix}-codepipeline-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume_role.json
}

data "aws_iam_policy_document" "codepipeline_policy_data" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject",
    ]

    resources = [
      aws_s3_bucket.codepipeline_bucket.arn,
      "${aws_s3_bucket.codepipeline_bucket.arn}/*"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["codestar-connections:UseConnection"]
    resources = [aws_codestarconnections_connection.repo.arn]
  }

  statement {
    effect = "Allow"

    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "codepipeline_policy" {
  name = "${module.constants.prefix}-codepipeline-policy"
  path = "/"
  policy = data.aws_iam_policy_document.codepipeline_policy_data.json
}

resource "aws_iam_role_policy_attachment" "codepipeline_role_attachment" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}

data "aws_iam_policy_document" "codebuild_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "codebuild_policy_data" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject",
    ]

    resources = [
      aws_s3_bucket.codepipeline_bucket.arn,
      "${aws_s3_bucket.codepipeline_bucket.arn}/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "codebuild:CreateReportGroup",
      "codebuild:CreateReport",
      "codebuild:UpdateReport",
      "codebuild:BatchPutTestCases",
      "codebuild:BatchPutCodeCoverages"
    ]

    resources = [aws_codebuild_project.codebuild.arn]
  }

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      aws_cloudwatch_log_group.codebuild_logs.arn,
      "${aws_cloudwatch_log_group.codebuild_logs.arn}:*"
    ]
  }
}

resource "aws_iam_policy" "codebuild_policy" {
  name = "${module.constants.prefix}-codebuild-policy"
  path = "/"
  policy = data.aws_iam_policy_document.codebuild_policy_data.json
}

resource "aws_iam_role" "codebuild_role" {
  name = "${module.constants.prefix}-codebuild-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json
}

resource "aws_iam_role_policy_attachment" "codebuild_role_attachment" {
  role = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_policy.arn
}

resource "aws_cloudwatch_log_group" "codebuild_logs" {
  name = "/aws/codebuild/${module.constants.prefix}-codebuild-logs"
}

resource "aws_codebuild_project" "codebuild" {
  name = "${module.constants.prefix}-codebuild"
  build_timeout = 5
  service_role = aws_iam_role.codebuild_role.arn

  source {
    type = "CODEPIPELINE"
    buildspec = yamlencode({
      version = 0.2
      phases = {
        build = {
          commands = [
            "ls",
            "nix build",
            "ls"
          ]
        }
      }
      artifacts = {
        files = ["**/*"]
        base-directory = "result"
        secondary-artifacts = merge(
          {for s in module.constants.lambda_functions : s => ({
            discard-paths = true
            files = ["lambda/${s}.zip"]
          })},
          {
            frontend = {
              base-directory = "frontend"
              discard-paths = false
              files = ["**/*"]
            }
          }
        )
      }
    })
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild_logs.name
    }
  }

  environment {
    type = "ARM_CONTAINER"
    compute_type = "BUILD_GENERAL1_SMALL"
    image = aws_ecr_repository.codebuild_image_repo.repository_url
  }
}

resource "aws_ecr_repository" "codebuild_image_repo" {
  name = "${module.constants.prefix}-codebuild_image_repo"
}

resource "aws_ecr_repository_policy" "codebuild_image_repo_policy" {
  repository = aws_ecr_repository.codebuild_image_repo.name
  policy = data.aws_iam_policy_document.codebuild_image_repo_policy_data.json
}

data "aws_iam_policy_document" "codebuild_image_repo_policy_data" {
  statement {
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [aws_codebuild_project.codebuild.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [module.constants.account_id]
    }
  }
}

output "codebuild_image_repo_id" {
  value = aws_ecr_repository.codebuild_image_repo
}
