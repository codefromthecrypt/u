# Copyright 2021 Tetrate
# Licensed under the Apache License, Version 2.0 (the "License")
#
# This script uses automatic variables (ex $<) and substitution references $(<:.signed=)
# Please see GNU make's documentation if unfamiliar: https://www.gnu.org/software/make/manual/html_node/
.PHONY: test

# This selects the goroot to use in the following priority order:
# 1. ${GOROOT}          - Ex actions/setup-go
# 2. ${GOROOT_1_17_X64} - Ex GitHub Actions runner
# 3. $(go env GOROOT)   - Implicit from the go binary in the path
#
# There may be multiple GOROOT variables, so pick the one matching go.mod.
go_release          := $(shell sed -ne 's/^go //gp' go.mod)
# https://github.com/actions/runner/blob/master/src/Runner.Common/Constants.cs
github_runner_arch  := $(if $(findstring $(shell uname -m),x86_64),X64,ARM64)
github_goroot_name  := GOROOT_$(subst .,_,$(go_release))_$(github_runner_arch)
github_goroot_val   := $(value $(github_goroot_name))
goroot_path         := $(shell go env GOROOT 2>/dev/null)
goroot              := $(firstword $(GOROOT) $(github_goroot_val) $(goroot_path))

ifndef goroot
$(error could not determine GOROOT)
endif

# Ensure POSIX-style GOROOT even in Windows, to support PATH updates in bash.
ifdef COMSPEC
goroot := $(shell cygpath $(goroot))
endif

# We must ensure `go` executes with GOROOT and PATH variables exported:
# * GOROOT ensures versions don't conflict with /usr/local/go or c:\Go
# * PATH ensures tools like golint can fork and execute the correct go binary.
#
# We may be using a very old version of Make (ex. 3.81 on macOS). This means we
# can't re-set GOROOT or PATH via 'export' or use '.ONESHELL' to persist
# variables across lines. Hence, we set variables on one-line.
go := export PATH="$(goroot)/bin:$${PATH}" && export GOROOT="$(goroot)" && go

test:
	$(go) env GOOS
	$(go) test ./...
