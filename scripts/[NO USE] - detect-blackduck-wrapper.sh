#!/bin/bash
# ===================================================
# Script: scan_blackduck_local.sh
# Purpose: Generate SBOM offline using Synopsys Detect CLI
# ===================================================

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DETECT_SCRIPT="${PROJECT_DIR}/scripts/detect.sh"
OUTPUT_DIR="${PROJECT_DIR}/sbom/output/blackduck"
SOURCE_DIR="${PROJECT_DIR}/projects"

mkdir -p "${OUTPUT_DIR}"

PROJECT_NAME="SBOM-MAX-BUILD"
PROJECT_VERSION="1.0.0"

echo "🔍 Running Black Duck Detect (Offline Mode)..."

bash "${DETECT_SCRIPT}" \
  --detect.tools=DETECTOR \
  --detect.project.name="${PROJECT_NAME}" \
  --detect.project.version="${PROJECT_VERSION}" \
  --detect.source.path="${SOURCE_DIR}" \
  --detect.output.path="${OUTPUT_DIR}" \
  --detect.blackduck.signature.scanner.local.mode=true \
  --detect.bom.aggregate.name=true \
  --detect.notices.report=true \
  --detect.report.timeout=600 \
  --detect.cleanup=false

echo "✅ SBOM successfully generated (offline)"
echo "Output directory: ${OUTPUT_DIR}"
ls -lh "${OUTPUT_DIR}"
