set -eou pipefail

EXIT_CODE=0
BINARY_CACHE_BUCKET=$(aws ssm get-parameter --query "* | [0].Value" --output text --name /prod/ci/nix/s3binarycache) || EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
	export NIX_CONFIG="extra-substituters = s3://$BINARY_CACHE_BUCKET\nrequire-sigs = false"
	export BINARY_CACHE_BUCKET=$BINARY_CACHE_BUCKET
	printf "[INFO] Binary cache enabled" 1>&2 
else
	printf "[WARN] Binary not enabled" 1>&2 
fi
