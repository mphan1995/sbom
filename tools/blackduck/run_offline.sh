#!/bin/bash
set -e

# Di chuyển về root project
cd "$(dirname "$0")/../.."

echo "🧭 Running Black Duck Detect (offline mode)..."

java -jar tools/blackduck/detect-11.0.0.jar \
  --blackduck.offline.mode=true \
  --detect.project.name=sbom-ericsson-offline \
  --detect.project.version.name=1.0.0 \
  --detect.source.path=. \
  --detect.output.path=sbom/output/blackduck \
  --detect.tools=DETECTOR \
  --detect.detector.buildless=true \
  --detect.detector.search.depth=6 \
  --detect.bom.format=SPDX \
  --detect.spdx.file.path=sbom/output/blackduck/sbom-blackduck.spdx.json \
  --logging.level.com.synopsys.integration=INFO

echo "✅ Done. SPDX SBOM saved to sbom/output/blackduck/"
