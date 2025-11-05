#!/bin/bash
set -e
java -jar tools/blackduck/synopsys-detect-11.0.0.jar \
  --blackduck.offline.mode=true \
  --detect.project.name=sbom-ericsson-offline \
  --detect.project.version.name=1.0.0 \
  --detect.source.path=. \
  --detect.output.path=sbom/output/blackduck \
  --detect.bom.format=SPDX \
  --detect.spdx.file.path=sbom/output/blackduck/sbom-blackduck.spdx.json
echo "✅  SPDX SBOM generated under sbom/output/blackduck/"
