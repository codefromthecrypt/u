# Copyright 2021 Tetrate
# Licensed under the Apache License, Version 2.0 (the "License")
#
# This script uses automatic variables (ex $<) and substitution references $(<:.signed=)
# Please see GNU make's documentation if unfamiliar: https://www.gnu.org/software/make/manual/html_node/
.PHONY: test

# Use the GitHub Actions runner version-specific GOROOT, unless overridden.
# Ex. go.mod uses 1.17 and GOARCH=amd64 -> GOROOT=${GOROOT_1_17_X64}
ifeq ($(GOROOT),)
go_version      = $(shell sed -ne 's/^go //gp' go.mod)
goroot_release  = $(go_version:.=_)
goroot_arch     = $(if $(findstring $(shell uname -m),x86_64),X64,ARM64)
goroot          = $(GOROOT_$(goroot_release)_$(goroot_arch))
# Remove this branch after actions/virtual-environments#4156 is solved.
ifeq ($(goroot),)
	# This works around missing variables on macOS via naming convention.
	# Ex. /Users/runner/hostedtoolcache/go/1.17.1/x64
	goroot      := $(shell ls -d /Users/runner/hostedtoolcache/go/$(go_version)*/x64|sort -n|tail -1)
endif
ifneq ($(goroot),)
	export GOROOT := $(goroot)
	export PATH   := $(goroot)/bin:${PATH}
endif
endif

test:
	echo $(GOROOT)
	which go
