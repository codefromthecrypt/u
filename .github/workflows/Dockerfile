# This builds Docker images similar to the GitHub Actions Virtual Environments,
# with the dependencies we need for end-to-end (e2e) tests.
#
# Notably, this installs make and go, as other build tools aren't referenced by
# `make e2e` and CGO is disabled (eliminating a gcc dependency).
#
# This build is intended for use in a matrix, testing all major Linux platforms
# supported by Envoy: Ubuntu and CentOS * amd64 and arm64. Notably, this adds
# CentOS and arm64 which aren't available natively on GitHub Actions. It is
# intended to run arm64 with Travis (as opposed to via emulation). In any case,
# all matrixes should be pushed for local debugging.
#
# Ex.
# ```bash
# $ docker build --build-arg go_revision=1.17.1 \
#                --build-arg parent_image=centos:8 -t func-e-internal:centos-8 \
#                .github/workflows
# $ docker run --rm -v $PWD:/work func-e-internal:centos-8 e2e
#
# You can troubleshoot like this:
# ```bash
# $ docker run --rm -it -v $PWD:/work --entrypoint /bin/bash func-e-internal:centos-8
# ```
ARG parent_image=centos:8
FROM ${parent_image}

# To simplify mandatory build-args, we detect the OS here.
ARG yum="yum -qy"
ARG apt_get="apt-get -qq -y"
RUN if [ -f /etc/centos-release ]; then \
    ${yum} install make && ${yum} clean all; \
    else \
    ${apt_get} update && ${apt_get} install curl make && ${apt_get} clean; \
    fi

# See https://docs.docker.com/engine/reference/builder/#automatic-platform-args-in-the-global-scope
ARG TARGETARCH

ARG go_revision
ARG go_stable_url=https://golang.org/dl/go${go_revision}.linux-${TARGETARCH}.tar.gz

# Extract into the default GOROOT
RUN curl -sSL ${go_stable_url} | tar -xzC /usr/local

# Add and switch to the same user as the GitHub Actions runner.
ARG user=runner
RUN useradd -md /home/runner -s /bin/bash -N ${user}
USER ${user}

# Setup the default GOROOT
ENV GOROOT=/usr/local/go
ENV PATH=$GOROOT/bin:$PATH

# Disable gcc to avoid a build dependency on gcc: its glibc might affect Envoy.
ENV CGO_ENABLED 0

# Set CWD to the work directory to avoid overlaps with $HOME.
WORKDIR /work

# Almost everything uses make, but you can override `--entrypoint /bin/bash`.
ENTRYPOINT ["/usr/bin/make"]
CMD ["help"]
