# Copyright 2021 Tetrate
# Licensed under the Apache License, Version 2.0 (the "License")
#
# This script uses automatic variables (ex $<) and substitution references $(<:.signed=)
# Please see GNU make's documentation if unfamiliar: https://www.gnu.org/software/make/manual/html_node/
.PHONY: test

# This selects the goroot to use in the following priority order:
# 1. ${GOROOT} - Ex actions/setup-go
# 2. ${GOROOT_1_17_X64} (go.mod qualifies version) - Ex GitHub Actions runner
# 3. $(go env GOROOT) - Implicit from the go binary in the path
go_release           := $(shell sed -ne 's/^go //gp' go.mod)
# https://github.com/actions/runner/blob/master/src/Runner.Common/Constants.cs
github_runner_arch   := $(if $(findstring $(shell uname -m),x86_64),X64,ARM64)
goroot_github_env    := $(GOROOT_$(shell echo $(go_release) | tr . _)_$(github_runner_arch))
# This works around missing variables on macOS via naming convention.
# Ex. /Users/runner/hostedtoolcache/go/1.17.1/x64
# Remove this after actions/virtual-environments#4156 is solved.
goroot_github_cache  := $(lastword $(shell ls -d $(RUNNER_TOOL_CACHE)/go/$(go_release)*/$(github_runner_arch) 2>/dev/null))
goroot_path          := $(shell go env GOROOT 2>/dev/null)
goroot               := $(firstword $(GOROOT) $(goroot_github_env) $(goroot_github_cache) $(goroot_path))
ifdef COMSPEC
goroot := $(shell cygpath $(goroot))
endif

# We can't overwrite the shell variable GOROOT, but we need to when running go.
# * GOROOT ensures versions don't conflict with /usr/local/go or c:\Go
# * PATH ensures tools like golint can fork and execute the correct go binary.
#
# .ONESHELL is not supported on the old Make installed on darwin (3.81), so we
# have to concatenate lines to achieve the same
go    := export PATH="$(goroot)/bin:$${PATH}" && export GOROOT="$(goroot)" && echo $$PATH && echo $$GOROOT && go

test:
	$(go) run github.com/golangci/golangci-lint/cmd/golangci-lint@v1.42.1 run .
