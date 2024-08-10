package cert

import (
	"github.com/aws/aws-cdk-go/awscdk/v2"
	"github.com/aws/aws-cdk-go/awscdk/v2/awscertificatemanager"
	"github.com/aws/aws-cdk-go/awscdk/v2/awsroute53"
	"github.com/aws/constructs-go/constructs/v10"
	"github.com/aws/jsii-runtime-go"
)

type CertCdkStackProps struct {
	awscdk.StackProps
	DomainName         string
	PublicHostedZoneId string
}

type CertCdkStackOutputs struct {
	Cert *awscertificatemanager.Certificate
}

func NewCertCdkStack(scope constructs.Construct, id string, props *CertCdkStackProps) (awscdk.Stack, CertCdkStackOutputs) {
	var sprops awscdk.StackProps
	if props != nil {
		sprops = props.StackProps
	}
	stack := awscdk.NewStack(scope, &id, &sprops)

	cert := awscertificatemanager.NewCertificate(stack, jsii.String("Cert"), &awscertificatemanager.CertificateProps{
		DomainName: jsii.String(props.DomainName),
		Validation: awscertificatemanager.CertificateValidation_FromDns(awsroute53.PublicHostedZone_FromHostedZoneId(stack, jsii.String("Zone"), jsii.String(props.PublicHostedZoneId))),
	})

	return stack, CertCdkStackOutputs{
		Cert: &cert,
	}
}
