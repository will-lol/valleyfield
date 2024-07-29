STACK_NAME="opentofu-cloudformation-bootstrap"
aws cloudformation deploy --template-file ./infra/cloudformation-bootstrap.yaml --stack-name $STACK_NAME

BUCKET_NAME=$(aws cloudformation describe-stacks --query "Stacks[?StackName=='$STACK_NAME'][].Outputs[?OutputKey=='BucketName'].OutputValue" --output text)
TABLE_NAME=$(aws cloudformation describe-stacks --query "Stacks[?StackName=='opentofu-cloudformation-bootstrap'][].Outputs[?OutputKey=='DynamoDBTableName'].OutputValue" --output text)
REGION=$(aws configure get region)

tofu init \
	-backend-config="bucket=$BUCKET_NAME" \
	-backend-config="key=tofu.tfstate" \
	-backend-config="region=$REGION" \
	-backend-config="dynamodb_table=$TABLE_NAME"
