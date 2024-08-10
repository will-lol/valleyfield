package main

import (
	"cdk/pipeline"

	"github.com/aws/aws-cdk-go/awscdk/v2"
	"github.com/aws/jsii-runtime-go"
)

const (
	AccountID             = "381492167517"
	Region                = "ap-southeast-2"
	Domain                = "valleyfield.bradshaw.page"
	HostedZoneId          = "Z0332800WV3HVEFYC0G8"
	CodeStarConnectionArn = "arn:aws:codestar-connections:ap-southeast-2:381492167517:connection/384d8dcb-a299-481b-b10f-486987445be9"
	GitRepoId             = "will-lol/valleyfield"
	GitRepoBranch         = "main"
)

func main() {
	defer jsii.Close()

	app := awscdk.NewApp(nil)
	pipeline.NewPipelineStack(app, "PipelineStack", &pipeline.PipelineCdkStackProps{
		StackProps: awscdk.StackProps{
			Env: &awscdk.Environment{
				Account: jsii.String(AccountID),
				Region:  jsii.String(Region),
			},
		},
		CodeStarConnectionArn: CodeStarConnectionArn,
		GitHubRepoId:          GitRepoId,
		GitHubRepoBranch:      GitRepoBranch,
		Domain:                Domain,
		HostedZoneId:          HostedZoneId,
		Region:                Region,
	})

	app.Synth(nil)
}
