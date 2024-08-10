package pipeline

import (
	"infra/pipeline/application"

	"github.com/aws/aws-cdk-go/awscdk/v2"
	"github.com/aws/aws-cdk-go/awscdk/v2/awscodebuild"
	"github.com/aws/aws-cdk-go/awscdk/v2/awsecr"
	"github.com/aws/aws-cdk-go/awscdk/v2/pipelines"
	"github.com/aws/constructs-go/constructs/v10"
	"github.com/aws/jsii-runtime-go"
)

type PipelineCdkStackProps struct {
	awscdk.StackProps
	CodeStarConnectionArn string
	GitHubRepoId          string
	GitHubRepoBranch      string
	Domain                string
	HostedZoneId          string
	Region                string
}

type PipelineCdkStackOutputs struct {
}

func NewPipelineStack(scope constructs.Construct, id string, props *PipelineCdkStackProps) (awscdk.Stack, PipelineCdkStackOutputs) {
	var sprops awscdk.StackProps
	if props != nil {
		sprops = props.StackProps
	}
	stack := awscdk.NewStack(scope, &id, &sprops)

	ecrRepo := awsecr.NewRepository(stack, jsii.String("ecrRepo"), &awsecr.RepositoryProps{
		RemovalPolicy: awscdk.RemovalPolicy_DESTROY,
		EmptyOnDelete: jsii.Bool(true),
	})
	awscdk.NewCfnOutput(stack, jsii.String("ecrRepoUri"), &awscdk.CfnOutputProps{
		Value:       ecrRepo.RepositoryUri(),
		Description: jsii.String("Please push the codebuild docker image generated from nix build .#codebuild to this ECR repository with tag 'latest'."),
	})

	pipeline := pipelines.NewCodePipeline(stack, jsii.String("pipeline"), &pipelines.CodePipelineProps{
		SelfMutation: jsii.Bool(false),
		Synth: pipelines.NewShellStep(jsii.String("Synth"), &pipelines.ShellStepProps{
			Input: pipelines.CodePipelineSource_Connection(&props.GitHubRepoId, &props.GitHubRepoBranch, &pipelines.ConnectionSourceOptions{
				ConnectionArn: &props.CodeStarConnectionArn,
			}),
			Commands: jsii.Strings(
				"npm install",
				"nix build .#cdkGo",
				"npm run build",
				"nix build .",
			),
		}),
		CodeBuildDefaults: &pipelines.CodeBuildOptions{
			BuildEnvironment: &awscodebuild.BuildEnvironment{
				BuildImage:  awscodebuild.LinuxArmBuildImage_FromEcrRepository(ecrRepo, jsii.String("latest")),
				ComputeType: awscodebuild.ComputeType_SMALL,
			},
		},
	})

	pipeline.AddStage(application.NewApplicationStage(stack, "Application", &application.ApplicationStageProps{
		StageProps:   awscdk.StageProps{},
		Domain:       props.Domain,
		HostedZoneId: props.HostedZoneId,
		Region:       props.Region,
	}), &pipelines.AddStageOpts{})

	return stack, PipelineCdkStackOutputs{}
}
