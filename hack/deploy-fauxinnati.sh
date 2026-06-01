#!/usr/bin/env bash

set -euo pipefail

echo "Deploying fauxinnati with image: ${image_digest}"
exit
oc apply -f deploy/fauxinnati/00-project.yaml
oc process -f deploy/fauxinnati/01-deployment.yaml --param IMAGE_DIGEST="${image_digest}" | oc apply -n fauxinnati -f -
oc apply -f deploy/fauxinnati/02-service.yaml
oc apply -f deploy/fauxinnati/03-route.yaml
