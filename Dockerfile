FROM    golang:alpine AS build
LABEL   maintainer="me@codar.nl"
ARG     PKGS="git upx binutils"
ARG     REPO="https://github.com/jonnenauha/prometheus_varnish_exporter.git"
ENV     GOOS=linux \
        GOARCH=amd64 \
        CGO_ENABLED=0

WORKDIR /build
RUN     set -x && \
        apk add --no-cache --upgrade ${PKGS} && \
        git clone ${REPO} && \
        cd /build/prometheus_varnish_exporter && \
        go build -ldflags="-w -s" -o /build/prometheus_varnish_exporter . && \
        strip --strip-unneeded prometheus_varnish_exporter && \
        chmod a+x prometheus_varnish_exporter && \
        upx -q -9 prometheus_varnish_exporter && \
        upx -t prometheus_varnish_exporter && \
        rm -rf /tmp/* /var/cache/apk/*

# STAGE 2: build the container to run
FROM gcr.io/distroless/static AS run
USER nonroot:nonroot

# copy compiled app
COPY --from=build --chown=nonroot:nonroot /build/prometheus_varnish_exporter /prometheus_varnish_exporter

# run binary; use vector form
ENTRYPOINT ["/prometheus_varnish_exporter"]
