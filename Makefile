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
go_release    := $(shell sed -ne 's/^go //gp' go.mod)
# https://github.com/actions/runner/blob/master/src/Runner.Common/Constants.cs
runner_arch   := $(if $(findstring $(shell uname -m),x86_64),X64,ARM64)
goroot_github := $(GOROOT_$(shell echo $(go_release) | tr . _)_$(github_arch))
# This works around missing variables on macOS via naming convention.
# Ex. /Users/runner/hostedtoolcache/go/1.17.1/x64
# Remove this after actions/virtual-environments#4156 is solved.
goroot_macos  := $(firstword $(shell ls -d /Users/runner/hostedtoolcache/go/$(go_release)*/x64 2>/dev/null))
goroot_path   := $(shell go env GOROOT 2>/dev/null)
goroot        := $(firstword $(GOROOT) $(goroot_github) $(goroot_macos) $(goroot_path))

# We can't overwrite the shell variable GOROOT or PATH, but we need to when running go.
# GOROOT ensures versions don't conflict with /usr/local/go or c:\Go
# PATH ensures tools run via `go run` can fork and execute the correct go.
go := GOROOT=$(goroot) PATH=$(goroot)$(if $(COMSPEC),\,/)bin$(if $(COMSPEC),;,:)${PATH} go

test:
	$(go) env
