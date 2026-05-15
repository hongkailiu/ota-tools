# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This repository contains internal tools for the OpenShift OTA (Over-The-Air) team. These tools are not included in any OpenShift product but are useful for the team's daily operations.

## Architecture

### validate-release Tool

The primary tool in this repository validates OpenShift releases against the cincinnati-graph-data repository:

1. **Release Validation Flow**:
   - Fetches `internal-channels/candidate.yaml` from the base branch of openshift/cincinnati-graph-data
   - Compares against the PR branch to identify new release versions
   - For each new version, pulls the release container image from quay.io/openshift-release-dev/ocp-release
   - Extracts `release-manifests/release-metadata` from the image layers (tar archive)
   - Validates that all `previous` versions are semantically smaller than the current version

2. **Multi-Architecture Support**:
   - OpenShift 4.14+: Validates all architectures (x86_64, aarch64, s390x, ppc64le)
   - OpenShift 4.13 and earlier: Only validates x86_64 (due to limited multi-arch support)
   - Image tags follow format: `{version}-{arch}` (e.g., `4.15.0-x86_64`)

3. **Configuration**:
   - Environment-driven: Requires `PULL_BASE_REF` and `PULL_NUMBER` environment variables
   - Fallback mechanism: Can read `internal-channels/candidate.yaml` from local disk if present
   - Target repository: openshift/cincinnati-graph-data

### Code Structure

- **cmd/validate-release/**: Main CLI tool implementation
  - `main.go`: Cobra CLI setup and entry point
  - `options.go`: Environment variable parsing, GitHub API interaction, validation logic
  - `quay.go`: Container image inspection and metadata extraction using go-containerregistry
  
- **pkg/version/**: Version information package
  - Variables (`Name`, `Version`) are injected at build time via ldflags
  - Format: `v{YYYYMMDD}-{git-describe}`

- **hack/build.sh**: Build script that:
  - Discovers all commands in `cmd/` directory
  - Builds each with CGO disabled for static binaries
  - Injects version information via ldflags
  - Outputs binaries to `_out/` directory

## Development Commands

### Building

```bash
# Build all commands (outputs to _out/)
./hack/build.sh

# Build with custom output directory
OUT_DIR=/custom/path ./hack/build.sh

# Build container image
podman build -f images/validate-release/Containerfile -t validate-release:local .
```

### Testing

```bash
# Run all unit tests
make test

# Run tests with gotestsum (auto-installs if missing)
make unit

# Run linter
make lint

# Run YAML linter
make yaml-lint
```

### Code Quality

```bash
# Format imports (auto-installs gci if missing)
make imports

# Format code and tidy dependencies
make generate-go

# Full verification (tests, linting, formatting, git diff check)
make verify

# Full verification including YAML
make verify-all
```

### Running validate-release

```bash
# Set required environment variables
export PULL_BASE_REF=main
export PULL_NUMBER=1234

# Run the built binary
./_out/validate-release

# Or build and run in container
podman run --rm \
  -e PULL_BASE_REF=main \
  -e PULL_NUMBER=1234 \
  validate-release:local
```

## Key Dependencies

- **github.com/spf13/cobra**: CLI framework
- **github.com/google/go-github/v60**: GitHub API client
- **github.com/google/go-containerregistry**: Container image inspection
- **github.com/blang/semver/v4**: Semantic version parsing and comparison
- **sigs.k8s.io/yaml**: YAML parsing for candidate.yaml

## Adding New Tools

When adding a new command-line tool:

1. Create a new directory under `cmd/{tool-name}/`
2. Implement using Cobra CLI pattern (see validate-release for reference)
3. Use `pkg/version` for version information
4. Create corresponding Containerfile in `images/{tool-name}/` if containerization is needed
5. The build script automatically discovers and builds all commands in `cmd/`
