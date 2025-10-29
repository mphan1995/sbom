#!/bin/bash
# ========================================
# Script: run_ort_local.sh
# Purpose: Generate SBOM locally using ORT (SPDX + CycloneDX)
# ========================================

set -e

# --- Config ---
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="${PROJECT_DIR}/sbom/output"
CONFIG_DIR="${PROJECT_DIR}/ort-config"
ORT_CONFIG="${CONFIG_DIR}/ort.conf.yaml"

mkdir -p "$OUTPUT_DIR"

# --- Detect ORT binary ---
if [ -x "${PROJECT_DIR}/tools/ort/cli/build/install/ort/bin/ort" ]; then
  ORT_BIN="${PROJECT_DIR}/tools/ort/cli/build/install/ort/bin/ort"
elif [ -x "${PROJECT_DIR}/tools/ort/cli/build/scripts/ort" ]; then
  ORT_BIN="${PROJECT_DIR}/tools/ort/cli/build/scripts/ort"
elif command -v ort >/dev/null 2>&1; then
  ORT_BIN="$(command -v ort)"
else
  echo "[ERROR] ORT binary not found!"
  echo "Please build ORT or ensure it's available at:"
  echo "  tools/ort/cli/build/install/ort/bin/ort"
  exit 1
fi

echo "[INFO] Using ORT binary: ${ORT_BIN}"

# --- Run Analyzer ---
echo "[INFO] Running ORT Analyzer..."
"${ORT_BIN}" analyze \
  -i "${PROJECT_DIR}/projects" \
  -o "${OUTPUT_DIR}" \

# --- Generate SPDX & CycloneDX ---
echo "[INFO] Generating SPDX and CycloneDX..."
"${ORT_BIN}" report \
  -i "${OUTPUT_DIR}/analyzer-result.yml" \
  -o "${OUTPUT_DIR}" \
  -f SpdxDocument \
  -f CycloneDX

echo "[SUCCESS] SBOM generated at: ${OUTPUT_DIR}"
echo " - SPDX       : analyzer-result.spdx.json"
echo " - CycloneDX  : analyzer-result.cyclonedx.json"
