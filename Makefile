

imports:
	which gci || go install -mod=mod github.com/daixiang0/gci@latest
	gci write --custom-order -s standard -s default -s "prefix(k8s.io)" -s "prefix(github.com/openshift)" -s localmodule --skip-vendor .
.PHONY: imports

generate-go:
	go fmt ./...
	go mod tidy
.PHONY: generate-go

unit:
	go test ./...
.PHONY: unit

test: unit
.PHONY: test

verify: test imports generate-go lint
	git diff --exit-code
.PHONY: verify

lint:
	which golangci-lint || go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v2.11.3
	golangci-lint run
.PHONY: lint
