#!/usr/bin/env bash

set -euo pipefail

eval $(go env | grep -e "GOHOSTOS" -e "GOHOSTARCH")
GOOS=${GOOS:-${GOHOSTOS}}

OUT_DIR=${OUT_DIR-_out}
mkdir -p ${OUT_DIR}

while IFS= read -r line;
do
  command=$(basename "${line}")
  echo "${command}"
  git_commit="$( git describe --tags --always --dirty )"

  build_date="$( date -u '+%Y%m%d' )"
  version="v${build_date}-${git_commit}"

  (set -x; CGO_ENABLED=0 GOOS="${GOOS}" go build -ldflags "-X 'github.com/openshift-eng/ota-tools/pkg/version.Name=${command}' -X 'github.com/openshift-eng/ota-tools/pkg/version.Version=${version}'" -a -installsuffix cgo -o "${OUT_DIR}/${command}" "./cmd/${command}")
done < <(find ./cmd -maxdepth 1 -mindepth 1 -type d)
