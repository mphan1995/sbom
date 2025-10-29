#!/usr/bin/env bash
set -euo pipefail
SBOM_DIR="${1:-sbom}"
echo "[merge] Looking for SBOMs in $SBOM_DIR"

# Placeholder merge: choose the newest SPDX and newest CycloneDX and copy to canonical names
spdx_src=$(ls -1t "$SBOM_DIR"/*spdx*json 2>/dev/null | head -n1 || true)
cdx_src=$(ls -1t "$SBOM_DIR"/*cyclonedx*json 2>/dev/null | head -n1 || true)

if [ -n "${spdx_src}" ]; then
  cp "${spdx_src}" "$SBOM_DIR/merged.spdx.json"
  echo "[merge] SPDX -> $SBOM_DIR/merged.spdx.json"
else
  echo "[merge] No SPDX JSON found."
fi

if [ -n "${cdx_src}" ]; then
  cp "${cdx_src}" "$SBOM_DIR/merged.cdx.json"
  echo "[merge] CycloneDX -> $SBOM_DIR/merged.cdx.json"
else
  echo "[merge] No CycloneDX JSON found."
fi