# validate-release

A validation tool for OpenShift releases in the cincinnati-graph-data repository. Ensures that new releases added to update channels have valid semantic versioning and metadata before merging.

## Features

- Validates new releases added to `internal-channels/candidate.yaml` in PRs
- Verifies semantic versioning constraints (all `previous` versions must be smaller than current version)
- Supports multi-architecture releases (x86_64, aarch64, s390x, ppc64le)
- Fetches and inspects release container images from quay.io
- Extracts release metadata directly from container image layers

## How It Works

1. **Detects New Releases**: Fetches `internal-channels/candidate.yaml` from both the base branch and PR branch of openshift/cincinnati-graph-data to identify newly added release versions
2. **Pulls Release Images**: For each new version, pulls the release container image from `quay.io/openshift-release-dev/ocp-release:{version}-{arch}`
3. **Extracts Metadata**: Extracts `release-manifests/release-metadata` from the container image layers (tar archive format)
4. **Validates Versions**: Verifies that all versions listed in the `previous` field are semantically smaller than the current release version

## Architecture Support

- **OpenShift 4.14+**: Validates all architectures (x86_64, aarch64, s390x, ppc64le)
- **OpenShift 4.13 and earlier**: Only validates x86_64 (due to limited multi-arch support in earlier releases)

Image tags follow the format: `{version}-{arch}` (e.g., `4.15.0-x86_64`)

## Usage

### Prerequisites

- GitHub API access (unauthenticated access supported, rate limits apply)
- Network access to quay.io for pulling release images

### Environment Variables

Required for PR validation mode:

- `PULL_BASE_REF` - Base branch of the PR (typically `main`)
- `PULL_NUMBER` - Pull request number to validate

### Running the Tool

```bash
# Build the binary
make build
# or
./hack/build.sh

# Run against a PR
export PULL_BASE_REF=main
export PULL_NUMBER=1234
./_out/validate-release

# Run in container
podman build -f images/validate-release/Containerfile -t validate-release:local .
podman run --rm \
  -e PULL_BASE_REF=main \
  -e PULL_NUMBER=1234 \
  validate-release:local
```

### Fallback Mode

If `internal-channels/candidate.yaml` exists in the current directory, the tool will use it instead of fetching from GitHub. This is useful for local testing:

```bash
# Place candidate.yaml in current directory
cp /path/to/candidate.yaml internal-channels/candidate.yaml

# Run without environment variables
./_out/validate-release
```

## Example Output

```
Validating release 4.15.0-x86_64...
✓ Version 4.14.5 < 4.15.0
✓ Version 4.14.6 < 4.15.0
✓ All previous versions valid for 4.15.0-x86_64

Validating release 4.15.0-aarch64...
✓ Version 4.14.5 < 4.15.0
✓ All previous versions valid for 4.15.0-aarch64

All releases validated successfully
```

## Error Cases

The tool will exit with an error if:

- A `previous` version is greater than or equal to the current version
- Release metadata cannot be extracted from the container image
- Container image is not found on quay.io
- Required environment variables are missing (in PR mode)
- Invalid YAML in candidate.yaml

## CI Integration

This tool is designed to run in CI pipelines for the openshift/cincinnati-graph-data repository:

1. PR is opened adding new releases to `internal-channels/candidate.yaml`
2. CI sets `PULL_BASE_REF` and `PULL_NUMBER` environment variables
3. Tool validates all newly added releases
4. PR is blocked if validation fails

## Development

```bash
# Run tests
make test

# Run linter
make lint

# Format code
make generate-go

# Full verification
make verify
```

## Dependencies

- **github.com/spf13/cobra**: CLI framework
- **github.com/google/go-github/v60**: GitHub API client for fetching PR data
- **github.com/google/go-containerregistry**: Container image inspection and layer extraction
- **github.com/blang/semver/v4**: Semantic version parsing and comparison
- **sigs.k8s.io/yaml**: YAML parsing for candidate.yaml

## Target Repository

This tool is designed specifically for validating releases in the [openshift/cincinnati-graph-data](https://github.com/openshift/cincinnati-graph-data) repository. It runs in a [presubmit](https://github.com/openshift/release/blob/d9a6ea580cef81c0c5754ac1455a9b08f3b8b517/ci-operator/config/openshift/cincinnati-graph-data/openshift-cincinnati-graph-data-master.yaml#L117) of the repo.
