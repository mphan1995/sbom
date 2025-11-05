#!/bin/bash
set -e
BASEDIR=$(dirname "$0")
cd "$BASEDIR/../.."

echo "Running Black Duck scan for SPDX SBOM..."
./tools/blackduck/detect.sh \
  --blackduck.url=https://your-blackduck-server \
  --blackduck.api.token=$BLACKDUCK_API_TOKEN \
  --detect.project.name=sbom-ericsson \
  --detect.project.version.name=1.0 \
  --detect.source.path=. \
  --detect.output.path=sbom/output/blackduck \
  --detect.bom.format=SPDX \
  --detect.spdx.file.path=sbom/output/blackduck/sbom-blackduck.spdx.json \
  --blackduck.trust.cert=true

echo "✅ SPDX SBOM generated in sbom/output/blackduck/"
