# This builds Docker images similar to the GitHub Actions Virtual Environments,
# with the dependencies we need for end-to-end (e2e) tests.
#
# Notably, this installs make, gcc, and Golang, as other build tools either
# aren't referenced by `make e2e` or are built on-demand with go. gcc is needed
# for golint.
#
# This build is intended for use in a matrix, testing all major Linux platforms
# supported by Envoy: Ubuntu and CentOS * amd64 and arm64. Notably, this adds
# CentOS and arm64 which aren't available natively on GitHub Actions. It is
# intended to run arm64 with Travis (as opposed to via emulation). In any case,
# all matrixes should be pushed for local debugging.
#
# Ex.
# ```bash
# $ docker build --build-arg GO_STABLE_RELEASE=1_17 \
#                --build-arg GO_STABLE_REVISION=1.17.1 \
#                --build-arg GO_PRIOR_RELEASE=1_16 \
#                --build-arg GO_PRIOR_REVISION=1.16.8 \
#                --build-arg LINUX=ubuntu -t internal:ubuntu \
#                .github/workflows
# $ docker run --rm -v $PWD:/func-e internal:ubuntu -C /func-e check
# ```

# Default to CentOS, which isn't available in GitHub Actions
ARG LINUX=centos
ARG CENTOS_RELEASE=8
ARG UBUNTU_RELEASE=focal

# This installs two GOROOTs: the stable and prior release. Two allows pull
# requests to update from a stale release to current without a chicken-egg
# problem or the skew and install time risks of on-demand installation. This
# publishes only two versions as more would bloat the image.
#
# Build args control the precise GOROOTs to install, and should be taken from
# the current GitHub Actions runner. Doing so allows version coherency between
# normal runners and Docker, with version skew bounded by image push frequency.
# See https://github.com/actions/virtual-environments for current versions.
#
# GO_XXX_RELEASE is the underscore delimited release version. Ex. "1_17"
# GO_XXX_REVISION is the full version number. Ex. "1.17.1"
#
# These are used along with the architecture to build GOROOT variables.
# Ex. GOROOT_1_17_X64=/opt/hostedtoolcache/go/1.17.1/x64
ARG GO_STABLE_RELEASE
ARG GO_STABLE_REVISION
ARG GO_PRIOR_RELEASE
ARG GO_PRIOR_REVISION

# Default location of the GitHub Actions runner for Ubuntu (which we also use for CentOS)
ARG RUNNER_TOOL_CACHE=/opt/hostedtoolcache

# We make a CentOS image because it is a widely used platform for Envoy, but
# doesn't exist on GitHub Actions runner
FROM centos:${CENTOS_RELEASE} as base-centos
RUN yum="yum -qy" && \
    ${yum} install make gcc && ${yum} clean all

ARG UBUNTU_RELEASE
FROM ubuntu:${UBUNTU_RELEASE} as base-ubuntu
RUN apt_get="apt-get -qq -y" && \
    ${apt_get} update && ${apt_get} install curl make gcc && ${apt_get} clean

# This section looks odd, but it is needed to match conventions of the GitHub
# Actions runner. For example, TARGETARCH in Docker is "amd64" whereas GitHub
# actions uses "x64". Moreover, depending on use, case format will change.
# Docker lacks variable substitution options to do this, so we fake it with
# stages. See https://github.com/moby/moby/issues/42904
ARG LINUX
FROM base-${LINUX} as base-amd64
ARG ARCH=X64
ARG ARCH_LC=x64

ARG LINUX
FROM base-${LINUX} as base-arm64
ARG ARCH=ARM64
ARG ARCH_LC=arm64

FROM base-${TARGETARCH}

ARG RUNNER_TOOL_CACHE
ARG GO_STABLE_RELEASE
ARG GO_STABLE_REVISION
ARG GOROOT_STABLE_NAME=GOROOT_${GO_STABLE_RELEASE}_${ARCH}
ARG GOROOT_STABLE=${RUNNER_TOOL_CACHE}/go/${GO_STABLE_REVISION}/${ARCH_LC}
WORKDIR ${GOROOT_STABLE}
ARG TARGETARCH
RUN curl -sSL https://golang.org/dl/go${GO_STABLE_REVISION}.linux-${TARGETARCH}.tar.gz | tar --strip-components 1 -xzpf -

ARG GO_PRIOR_RELEASE
ARG GO_PRIOR_REVISION
ARG GOROOT_PRIOR_NAME=GOROOT_${GO_PRIOR_RELEASE}_${ARCH}
ARG GOROOT_PRIOR=${RUNNER_TOOL_CACHE}/go/${GO_PRIOR_REVISION}/${ARCH_LC}
WORKDIR ${GOROOT_PRIOR}
ARG TARGETARCH
RUN curl -sSL https://golang.org/dl/go${GO_PRIOR_REVISION}.linux-${TARGETARCH}.tar.gz | tar --strip-components 1 -xzpf -

ARG USER=runner
ARG HOME_DIR=/home/runner
RUN useradd -md ${HOME_DIR} -s /bin/bash -N ${USER}

# Switch to the same runtime user as exists in GitHub Actions runner
USER ${USER}

# Setup ENV variables used in make that match the GitHub Actions runner
ENV RUNNER_TOOL_CACHE ${RUNNER_TOOL_CACHE}
ENV ${GOROOT_STABLE_NAME} ${GOROOT_STABLE}
ENV ${GOROOT_PRIOR_NAME} ${GOROOT_PRIOR}

# Set CWD to the work directory to avoid overlaps with $HOME
WORKDIR /work

ENTRYPOINT ["/usr/bin/make"]

