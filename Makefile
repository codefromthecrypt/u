# Copyright 2021 Tetrate
# Licensed under the Apache License, Version 2.0 (the "License")
#
# This script uses automatic variables (ex $<) and substitution references $(<:.signed=)
# Please see GNU make's documentation if unfamiliar: https://www.gnu.org/software/make/manual/html_node/
.PHONY: test

# Use the GitHub Actions runner version-specific GOROOT, unless overridden.
# Ex. go.mod uses 1.17 and GOARCH=amd64 -> GOROOT=${GOROOT_1_17_X64}
#
# When GOROOT lookup fails, this defaults to whichever go is in the PATH.
# When GOROOT is not already set, it attempts lookup from a GitHub Actions
# version-specific ENV variable, and failing that the PATH.
#
# Ex. go.mod uses 1.17 and GOARCH=amd64 -> GOROOT=${GOROOT_1_17_X64}
ifndef GOROOT
go_version    = $(shell sed -ne 's/^go //gp' go.mod)
env_version   = $(shell echo $(go_version) | tr . _)
env_arch      = $(if $(findstring $(shell uname -m),x86_64),X64,ARM64)
goroot_env    = $(GOROOT_$(env_version)_$(env_arch))
# This works around missing variables on macOS via naming convention.
# Ex. /Users/runner/hostedtoolcache/go/1.17.1/x64
# Remove this after actions/virtual-environments#4156 is solved.
goroot_macos  = $(firstword $(shell ls -d /Users/runner/hostedtoolcache/go/$(go_version)*/x64 2>/dev/null))
goroot_path   = $(shell go env GOROOT 2>/dev/null)
goroot        = $(firstword $(goroot_env) $(goroot_macos) $(goroot_path))
endif

# Build the path relating to the current runtime (goos,goarch)
go  := "$(goroot)/bin/go"

test:
	echo $(GOROOT)
	$(go) env
