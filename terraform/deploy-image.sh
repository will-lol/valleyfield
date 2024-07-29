set -euxo pipefail

nix build .#codebuild
docker load < result
URI=$(tofu output -json | jq --raw-output ".codebuild_image_repo_id.value.repository_url")
docker tag codebuild "$URI:latest"
docker push "$URI:latest"
