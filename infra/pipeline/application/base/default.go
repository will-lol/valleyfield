package base

import (
	"fmt"

	"github.com/aws/aws-cdk-go/awscdk/v2"
	"github.com/aws/aws-cdk-go/awscdk/v2/awsapigateway"
	"github.com/aws/aws-cdk-go/awscdk/v2/awscertificatemanager"
	"github.com/aws/aws-cdk-go/awscdk/v2/awscloudfront"
	"github.com/aws/aws-cdk-go/awscdk/v2/awscloudfrontorigins"
	"github.com/aws/aws-cdk-go/awscdk/v2/awslambda"
	"github.com/aws/aws-cdk-go/awscdk/v2/awsroute53"
	"github.com/aws/aws-cdk-go/awscdk/v2/awsroute53targets"
	"github.com/aws/aws-cdk-go/awscdk/v2/awss3"
	"github.com/aws/aws-cdk-go/awscdk/v2/awss3assets"
	"github.com/aws/aws-cdk-go/awscdk/v2/awss3deployment"
	"github.com/aws/constructs-go/constructs/v10"
	"github.com/aws/jsii-runtime-go"
)

type BaseCdkStackProps struct {
	awscdk.StackProps
	Cert         *awscertificatemanager.Certificate
	DomainName   string
	HostedZoneId string
}

type BaseCdkStackOutputs struct {
	CloudfrontDistribution *awscloudfront.Distribution
}

func NewBaseCdkStack(scope constructs.Construct, id string, props *BaseCdkStackProps) (awscdk.Stack, BaseCdkStackOutputs) {
	var sprops awscdk.StackProps
	if props != nil {
		sprops = props.StackProps
	}
	stack := awscdk.NewStack(scope, &id, &sprops)

	webBucket := awss3.NewBucket(stack, jsii.String("web"), &awss3.BucketProps{
		BlockPublicAccess: awss3.BlockPublicAccess_BLOCK_ALL(),
		Encryption:        awss3.BucketEncryption_S3_MANAGED,
		EnforceSSL:        jsii.Bool(true),
		RemovalPolicy:     awscdk.RemovalPolicy_DESTROY,
		Versioned:         jsii.Bool(false),
	})
	awss3deployment.NewBucketDeployment(stack, jsii.String("webBucketDeployment"), &awss3deployment.BucketDeploymentProps{
		DestinationBucket: webBucket,
		Sources:           &[]awss3deployment.ISource{awss3deployment.Source_Asset(jsii.String("artifact/frontend"), &awss3assets.AssetOptions{})},
	})

	apiGw := awsapigateway.NewRestApi(stack, jsii.String("api"), &awsapigateway.RestApiProps{})

	apiGw.Root().AddCorsPreflight(&awsapigateway.CorsOptions{
		AllowOrigins: jsii.Strings(fmt.Sprintf("https://%s", props.DomainName)),
	})

	apiGwTestResource := apiGw.Root().AddResource(jsii.String("test"), &awsapigateway.ResourceOptions{})
	apiGwTestResourceBackingLambda := awslambda.NewFunction(stack, jsii.String("apiGwTestResourceBackingLambda"), &awslambda.FunctionProps{
		Architecture: awslambda.Architecture_ARM_64(),
		Runtime:      awslambda.Runtime_PROVIDED_AL2023(),
		Code:         awslambda.AssetCode_FromAsset(jsii.String("artifact/lambda/test.zip"), &awss3assets.AssetOptions{}),
		Handler:      jsii.String("bootstrap"),
	})
	apiGwTestResource.AddMethod(jsii.String("GET"), awsapigateway.NewLambdaIntegration(apiGwTestResourceBackingLambda, &awsapigateway.LambdaIntegrationOptions{}), &awsapigateway.MethodOptions{})

	apiGwOrigin := awscloudfrontorigins.NewRestApiOrigin(apiGw, &awscloudfrontorigins.RestApiOriginProps{})

	s3Origin := awscloudfrontorigins.NewS3Origin(webBucket, &awscloudfrontorigins.S3OriginProps{
		OriginPath: jsii.String("/"),
	})
	cf := awscloudfront.NewDistribution(stack, jsii.String("distribution"), &awscloudfront.DistributionProps{
		HttpVersion:       awscloudfront.HttpVersion_HTTP2_AND_3,
		Certificate:       *props.Cert,
		DomainNames:       jsii.Strings(props.DomainName),
		EnableIpv6:        jsii.Bool(true),
		DefaultRootObject: jsii.String("index.html"),
		DefaultBehavior: &awscloudfront.BehaviorOptions{
			CachePolicy:    awscloudfront.CachePolicy_CACHING_OPTIMIZED(),
			CachedMethods:  awscloudfront.CachedMethods_CACHE_GET_HEAD(),
			AllowedMethods: awscloudfront.AllowedMethods_ALLOW_GET_HEAD_OPTIONS(),
			Origin:         s3Origin,
		},
		AdditionalBehaviors: &map[string]*awscloudfront.BehaviorOptions{
			"/api/*": {
				AllowedMethods: awscloudfront.AllowedMethods_ALLOW_ALL(),
				CachedMethods:  awscloudfront.CachedMethods_CACHE_GET_HEAD(),
				CachePolicy:    awscloudfront.CachePolicy_CACHING_OPTIMIZED(),
				Origin:         apiGwOrigin,
			},
		},
	})

	hostedZone := awsroute53.HostedZone_FromHostedZoneAttributes(stack, jsii.String("HostedZone"), &awsroute53.HostedZoneAttributes{
		HostedZoneId: &props.HostedZoneId,
		ZoneName:     &props.DomainName,
	})

	awsroute53.NewAaaaRecord(stack, jsii.String("CloudfrontRecordAAAA"), &awsroute53.AaaaRecordProps{
		Zone:   hostedZone,
		Target: awsroute53.RecordTarget_FromAlias(awsroute53targets.NewCloudFrontTarget(cf)),
	})

	return stack, BaseCdkStackOutputs{
		CloudfrontDistribution: &cf,
	}
}
