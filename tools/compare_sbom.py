#!/usr/bin/env python3
import json
import sys
from pathlib import Path

if len(sys.argv) < 3:
    print("Usage: compare_sbom.py <sbom.json> <runtime-loaded.json>")
    sys.exit(1)

sbom_file = Path(sys.argv[1])
runtime_file = Path(sys.argv[2])
output_missing = Path("sbom/output/runtime-missing.json")
output_report = Path("sbom/output/runtime-report.txt")

# Load SBOM (SPDX or CycloneDX)
with open(sbom_file, "r", encoding="utf-8") as f:
    sbom_data = json.load(f)

# Extract all package identifiers
def extract_components(sbom):
    comps = set()
    if "packages" in sbom:
        for pkg in sbom["packages"]:
            comps.add(pkg.get("name", ""))
    elif "components" in sbom:
        for c in sbom["components"]:
            comps.add(c.get("name", ""))
    return {c for c in comps if c}

sbom_comps = extract_components(sbom_data)

# Load runtime dependencies
with open(runtime_file, "r", encoding="utf-8") as f:
    runtime_data = json.load(f)

runtime_deps = set(runtime_data.get("runtime_dependencies", []))

# Find missing deps
missing = sorted(list(runtime_deps - sbom_comps))

# Output report
output_missing.parent.mkdir(parents=True, exist_ok=True)
with open(output_missing, "w", encoding="utf-8") as f:
    json.dump({"missing_dependencies": missing}, f, indent=2)

with open(output_report, "w", encoding="utf-8") as f:
    f.write("=== Runtime Dependency Check Report ===\n\n")
    f.write(f"SBOM file: {sbom_file}\n")
    f.write(f"Runtime log: {runtime_file}\n\n")
    if not missing:
        f.write("✅ No missing runtime dependencies detected.\n")
    else:
        f.write("⚠️ Missing runtime-only dependencies:\n")
        for dep in missing:
            f.write(f" - {dep}\n")

print(f"Runtime check completed. Report saved to {output_report}")
