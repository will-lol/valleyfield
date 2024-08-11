BINARY_CACHE_BUCKET=$(aws ssm get-parameter --query "* | [0].Value" --output text --name /prod/ci/nix/s3binarycache)

if [ $? -eq 0 ]; then
	export NIX_CONFIG="extra-substituters = s3://$BINARY_CACHE_BUCKET\nrequire-sigs = false"
	printf "[INFO] Binary cache enabled" 1>&2 
else
	printf "[WARN] Binary not enabled" 1>&2 
fi

nix build .#goCdkBinary -o goCdkBinary
nix build .#artifact -o artifact
npm run build
