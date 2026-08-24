
ARG OM_IMAGE=ghcr.io/opensvc/om:3.0.0-rc31

FROM ${OM_IMAGE} AS om_provider

FROM alpine:3.24.1@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b

COPY --from=om_provider /usr/bin/om /usr/bin/om
COPY --chmod=0755 ./entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
CMD ["relay"]
