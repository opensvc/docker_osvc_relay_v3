# om3 relay

[![docker-build](https://github.com/opensvc/docker_osvc_relay_v3/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/opensvc/docker_osvc_relay_v3/actions/workflows/docker-publish.yml)

## Requirements

- **Docker** installed

## Description

This container contains a OpenSVC agent configured as a heartbeat relay.

A relay is usually deployed on a third site.

A two-nodes OpenSVC cluster stretched over 2 datacenters, configured to use a 3rd site relay, avoids the split brain situation when the communication between the nodes are broken, as the relay heartbeat is still operational.

## Build 

Clone this repository, then run the following command in the project directory:

```
docker buildx build -t relay-v3 . 
```


## Docker Image Signing

All OpenSVC Docker images published to `ghcr.io/opensvc` are signed with [Cosign](https://docs.sigstore.dev/cosign/) using Sigstore's keyless signing via GitHub Actions OIDC. The signing is performed automatically by the [release workflow](.github/workflows/docker-publish.yml) on Git tag creation.

To verify an image signature:

```bash
cosign verify \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com \
  --certificate-identity-regexp='^https://github.com/opensvc/docker_osvc_relay_v3/.github/workflows/docker-publish.yml@' \
  ghcr.io/opensvc/relay3:TAG
```

Replace `TAG` with the version (e.g., `3.0.0-rc1`).
