FROM golang:latest AS builder

ARG BRANCH=${BRANCH:-main}
ARG OSVC_GITREPO_URL=${OSVC_GITREPO_URL:-https://github.com/opensvc/om3.git}

WORKDIR /opt

RUN git clone $OSVC_GITREPO_URL

WORKDIR /opt/om3

RUN git checkout $BRANCH

RUN go install github.com/oapi-codegen/oapi-codegen/v2/cmd/oapi-codegen@v2.3.0

RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o bin/om ./cmd/om/

RUN ./bin/om node version 

FROM alpine:3.20

RUN apk add --no-cache bash

COPY --from=builder /opt/om3/bin/om /usr/bin/om
COPY ./entrypoint.sh /

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["relay"]

LABEL \
    org.opencontainers.image.authors="OpenSVC SAS" \
    org.opencontainers.image.created="${BUILDTIME}" \
    org.opencontainers.image.licenses="Apache-2.0" \
    org.opencontainers.image.url="https://github.com/opensvc/docker_osvc_relay_v3"
