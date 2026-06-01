#!/usr/bin/env bash
set -euo pipefail

# Get git commit hash (first 8 characters)
git_sha=$(git rev-parse --short=8 HEAD)

# Check if repository is dirty
if [[ -n $(git status --porcelain) ]]; then
    tag="${git_sha}-dirty"
else
    tag="${git_sha}"
fi

echo "Building fauxinnati image with tag: quay.io/openshift-ota/fauxinnati:${tag}"

# Build the image
podman build -t "quay.io/popenshift-ota/fauxinnati:${tag}" -f images/fauxinnati/Containerfile .

echo "Successfully built: quay.io/openshift-ota/fauxinnati:${tag}"
