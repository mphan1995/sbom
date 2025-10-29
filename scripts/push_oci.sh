#!/usr/bin/env bash
set -euo pipefail
SBOM_DIR="${1:-sbom}"
OCI_REPO="${2:?need OCI_REPO}"
OCI_TAG="${3:?need OCI_TAG}"

SPDX="$SBOM_DIR/merged.spdx.json"
CDX="$SBOM_DIR/merged.cdx.json"

if [ ! -f "$SPDX" ] && [ ! -f "$CDX" ]; then
  echo "[push] Neither $SPDX nor $CDX exists. Run 'make merge' first."; exit 1;
fi

echo "[push] Upload SBOM to $OCI_REPO:$OCI_TAG"
if [ -f "$SPDX" ]; then
  echo "[push] -> SPDX $SPDX"
  oras push "$OCI_REPO:$OCI_TAG" \
    --artifact-type application/spdx+json \
    "$SPDX:application/spdx+json"
fi

if [ -f "$CDX" ]; then
  echo "[push] -> CycloneDX $CDX"
  oras push "$OCI_REPO:$OCI_TAG" \
    --artifact-type application/vnd.cyclonedx+json \
    "$CDX:application/vnd.cyclonedx+json"
fi

echo "[push] Done."