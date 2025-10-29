#!/bin/bash
# ========================================
# Script: scan_grype_local.sh
# Purpose: Scan SBOM locally using Grype
# ========================================

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="${PROJECT_DIR}/sbom/output"
GRYPE_CONFIG="${PROJECT_DIR}/grype-config/grype.yaml"
SBOM_FILE="${OUTPUT_DIR}/analyzer-result.cyclonedx.json"
SCAN_RESULT="${OUTPUT_DIR}/grype-scan.json"

if [ ! -f "$SBOM_FILE" ]; then
  echo "[ERROR] SBOM file not found: $SBOM_FILE"
  echo "Please run run_ort_local.sh first."
  exit 1
fi

echo "[INFO] Running Grype scan..."
grype sbom:"${SBOM_FILE}" \
  -o json \
  -c "${GRYPE_CONFIG}" \
  > "${SCAN_RESULT}"

echo "[SUCCESS] Scan completed. Result at: ${SCAN_RESULT}"
