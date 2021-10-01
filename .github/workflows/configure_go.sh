#!/usr/bin/env bash
#
# This configures Go according to go.mod, choosing the a GOROOT based on existing variables.
# For example, if go.mod includes "go 1.17", GOROOT=${GOROOT_1_17} or ${GOROOT_1_17_X64}
#
# Notes:
# * In GitHub, these evaluate to ${RUNNER_TOOL_CACHE}/go/${GO_VERSION}*/x64
#   * RUNNER_TOOL_CACHE lags Go releases by 1-2 weeks https://github.com/actions/virtual-environments
# * To simulate GitHub for testing, set GITHUB_ENV and GITHUB_PATH to temporary files
#   * Ex. `GITHUB_ENV=/tmp/test-env GITHUB_PATH=/tmp/test-path .github/workflows/configure_go.sh
# * This uses bash because we need indirect variable expansion and GHA runners all have bash.
set -uex pipefail

go_version=$(sed -n 's/^go //gp' go.mod)
echo GO_VERSION="${go_version}" >> "${GITHUB_ENV}"

goroot_name=$(env|grep "^GOROOT_${go_version//./_}")

# Patch missing GOROOT env on macOS until actions/virtual-environments#4156
if [ -n "${goroot_name}" ]; then
  go_root=$(ls -d "${RUNNER_TOOL_CACHE}/go/${go_version}*/x64"|sort -n|tail -1)
else
  go_root=${!goroot_name}
fi

# Ensure go works
go="${go_root}/bin/go"
${go} version >/dev/null

# Setup the GOROOT
echo GOROOT="${go_root}" >> "${GITHUB_ENV}"
echo "${go_root}/bin" >>"${GITHUB_PATH}"

# Add the OS-specific GOCACHE (build cache) variable for actions/cache
echo GOCACHE=$(${go} env GOCACHE) >> "${GITHUB_ENV}"
