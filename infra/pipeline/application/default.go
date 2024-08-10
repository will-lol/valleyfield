package application

import (
	"infra/pipeline/application/base"
	"infra/pipeline/application/cert"

	"github.com/aws/aws-cdk-go/awscdk/v2"
	"github.com/aws/constructs-go/constructs/v10"
	"github.com/aws/jsii-runtime-go"
)

type ApplicationStageProps struct {
	awscdk.StageProps
	Domain       string
	HostedZoneId string
	Region       string
}

func NewApplicationStage(scope constructs.Construct, id string, props *ApplicationStageProps) awscdk.Stage {
	var sprops awscdk.StageProps
	if props != nil {
		sprops = props.StageProps
	}
	stage := awscdk.NewStage(scope, &id, &sprops)

	_, certStackOutputs := cert.NewCertCdkStack(stage, "MainCdkStack", &cert.CertCdkStackProps{
		StackProps: awscdk.StackProps{
			Env: &awscdk.Environment{
				Region: jsii.String("us-east-1"),
			},
			CrossRegionReferences: jsii.Bool(true),
		},
		DomainName:         props.Domain,
		PublicHostedZoneId: props.HostedZoneId,
	})

	base.NewBaseCdkStack(stage, "BaseCdkStack", &base.BaseCdkStackProps{
		StackProps: awscdk.StackProps{
			Env: &awscdk.Environment{
				Region: &props.Region,
			},
			CrossRegionReferences: jsii.Bool(true),
		},
		Cert:        certStackOutputs.Cert,
		DomainNames: []string{props.Domain},
	})

	return stage
}
