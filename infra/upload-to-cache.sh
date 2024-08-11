set -eu
set -f # disable globbing
export IFS=' '

printf "[INFO] Checking \$BINARY_CACHE_BUCKET"
if [ -n "$BINARY_CACHE_BUCKET" ]; then
	echo "[INFO] Uploading paths" $OUT_PATHS
	exec nix copy --to "s3://$BINARY_CACHE_BUCKET" $OUT_PATHS
else 
	printf "[WARN] \$BINARY_CACHE_BUCKET unset, not uploading"
fi
