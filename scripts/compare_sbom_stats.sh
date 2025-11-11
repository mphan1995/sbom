#!/bin/bash
# Use to compares SBOMs each other . 
# Author: Max Phan. 

SBOM_DIR="$(dirname "$0")/../sbom/output"
OUT_FILE="$SBOM_DIR/sbom_stats_full.txt"

echo "🔍 Generating full SBOM statistics report..."
echo "==================================================" > "$OUT_FILE"

# --- SPDX SECTION ---
echo "=== SPDX STATS ===" | tee -a "$OUT_FILE"
jq -r '"SPDX Format: \(.spdxVersion)"' "$SBOM_DIR/analyzer-result.spdx.json" | tee -a "$OUT_FILE"
echo "Packages: $(jq '.packages | length' "$SBOM_DIR/analyzer-result.spdx.json")" | tee -a "$OUT_FILE"
echo "Unique versions: $(jq -r '.packages[].versionInfo // empty' "$SBOM_DIR/analyzer-result.spdx.json" | sort -u | wc -l)" | tee -a "$OUT_FILE"
echo "Unique licenses: $(jq -r '.packages[].licenseDeclared // empty' "$SBOM_DIR/analyzer-result.spdx.json" | sort -u | wc -l)" | tee -a "$OUT_FILE"
echo "Unique suppliers: $(jq -r '.packages[].supplier // empty' "$SBOM_DIR/analyzer-result.spdx.json" | sort -u | wc -l)" | tee -a "$OUT_FILE"
echo "Files analyzed: $(jq '.files | length // 0' "$SBOM_DIR/analyzer-result.spdx.json")" | tee -a "$OUT_FILE"
echo "External refs: $(jq -r '.packages[].externalRefs // [] | length' "$SBOM_DIR/analyzer-result.spdx.json" | awk '{s+=$1} END {print s}')" | tee -a "$OUT_FILE"
jq -r '.creationInfo | "Created by: \(.creators[] // empty)\nCreated: \(.created // empty)"' "$SBOM_DIR/analyzer-result.spdx.json" | tee -a "$OUT_FILE"
echo "" | tee -a "$OUT_FILE"

# --- CycloneDX SECTION ---
echo "=== CycloneDX STATS ===" | tee -a "$OUT_FILE"
jq -r '"BOM Format: \(.bomFormat)\nSpec Version: \(.specVersion)"' "$SBOM_DIR/analyzer-result.cyclonedx.json" | tee -a "$OUT_FILE"
echo "Components: $(jq '.components | length' "$SBOM_DIR/analyzer-result.cyclonedx.json")" | tee -a "$OUT_FILE"
echo "Unique versions: $(jq -r '.components[].version // empty' "$SBOM_DIR/analyzer-result.cyclonedx.json" | sort -u | wc -l)" | tee -a "$OUT_FILE"
echo "Unique licenses: $(jq -r '.components[].licenses[].license.id // empty' "$SBOM_DIR/analyzer-result.cyclonedx.json" | sort -u | wc -l)" | tee -a "$OUT_FILE"
echo "Unique suppliers: $(jq -r '.components[].supplier // empty' "$SBOM_DIR/analyzer-result.cyclonedx.json" | sort -u | wc -l)" | tee -a "$OUT_FILE"
echo "External references: $(jq -r '.components[].externalReferences // [] | length' "$SBOM_DIR/analyzer-result.cyclonedx.json" | awk '{s+=$1} END {print s}')" | tee -a "$OUT_FILE"
echo "Tools used: $(jq -r '.metadata.tools[].name // empty' "$SBOM_DIR/analyzer-result.cyclonedx.json" | tr '\n' ', ')" | tee -a "$OUT_FILE"
jq -r '.metadata.timestamp? // empty | "Created: \(. // "N/A")"' "$SBOM_DIR/analyzer-result.cyclonedx.json" | tee -a "$OUT_FILE"
echo "" | tee -a "$OUT_FILE"

# --- SUMMARY COMPARISON ---
echo "=== SUMMARY COMPARISON ===" | tee -a "$OUT_FILE"
SPDX_PKG=$(jq '.packages | length' "$SBOM_DIR/analyzer-result.spdx.json")
CYC_PKG=$(jq '.components | length' "$SBOM_DIR/analyzer-result.cyclonedx.json")
DIFF=$(( SPDX_PKG - CYC_PKG ))
echo "Package count difference (SPDX - CycloneDX): $DIFF" | tee -a "$OUT_FILE"

echo "==================================================" | tee -a "$OUT_FILE"
echo "✅ Full SBOM stats report saved to: $OUT_FILE"
