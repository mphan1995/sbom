# ============================================
# Makefile - SBOM-MAX-BUILD Pipeline (v2025.11-RC)
# Source -> Build -> Analyze -> Merge -> Validate -> Sign -> Deploy
# ============================================

PROJECT_DIR   := $(shell pwd)
PROJECTS_DIR  := $(PROJECT_DIR)/projects
OUTPUT_DIR    := $(PROJECT_DIR)/sbom/output
CONFIG_DIR    := $(PROJECT_DIR)/ort-config
GRYPE_CONFIG  := $(PROJECT_DIR)/grype-config/grype.yaml
MERGE_CONFIG  := $(PROJECT_DIR)/sbom-config/merge.conf.yaml

# Source SBOM (ORT)
ANALYZER_YML  := $(OUTPUT_DIR)/analyzer-result.yml

# Build SBOM
SPDX_YML      := $(OUTPUT_DIR)/analyzer-result.spdx.yml
SPDX_JSON     := $(OUTPUT_DIR)/analyzer-result.spdx.json
CDX_JSON      := $(OUTPUT_DIR)/analyzer-result.cyclonedx.json

# Analyzed SBOM (Grype)
TRIVY_JSON    := $(OUTPUT_DIR)/grype-scan.json

# Final Deployed SBOM
MERGED_SBOM   := $(OUTPUT_DIR)/merged-sbom.json
SIGNED_SBOM   := $(OUTPUT_DIR)/signed-sbom.json

# Tools
ORT_BIN := $(shell if [ -x "$(PROJECT_DIR)/tools/ort/ort" ]; then echo "$(PROJECT_DIR)/tools/ort/ort"; \
             elif [ -x "$(PROJECT_DIR)/tools/ort/cli/build/install/ort/bin/ort" ]; then echo "$(PROJECT_DIR)/tools/ort/cli/build/install/ort/bin/ort"; \
             else echo "ort"; fi)
# Force correct yq (Go version)
YQ_BIN := $(shell if [ -x "/snap/bin/yq" ]; then echo "/snap/bin/yq"; else echo "yq"; fi)

GRYPE  := grype
COSIGN := cosign

.PHONY: prepare build scan merge validate sign deploy clean rebuild help

# ------------------------------------------------
# PREPARE
# ------------------------------------------------
prepare:
	@mkdir -p $(OUTPUT_DIR)

# ------------------------------------------------
# SOURCE SBOM (analyzer-result.yml)
# ------------------------------------------------
$(ANALYZER_YML): prepare
	@if [ -f "$(ANALYZER_YML)" ]; then \
		echo "ℹ️ analyzer-result.yml already exists, skipping ORT analyze."; \
	else \
		echo "🔨 Running ORT analyze -> $(ANALYZER_YML)"; \
		"$(ORT_BIN)" analyze \
			--input-dir "$(PROJECTS_DIR)" \
			--output-dir "$(OUTPUT_DIR)"; \
	fi

# ------------------------------------------------
# BUILD SBOM (SPDX + CycloneDX)
# ------------------------------------------------
# SPDX v2.2 report
$(SPDX_YML): $(ANALYZER_YML)
	@echo "📦 Generating SPDX (YAML) -> $@"
	@"$(ORT_BIN)" report \
		--ort-file "$(ANALYZER_YML)" \
		--output-dir "$(OUTPUT_DIR)" \
		--report-formats SpdxDocument >/dev/null

	# Auto-detect any *.spdx.yml file in output
	@FOUND_FILE=$$(find "$(OUTPUT_DIR)" -maxdepth 2 -type f -name "*.spdx.yml" | head -n 1); \
	if [ -z "$$FOUND_FILE" ]; then \
		echo "❌ SPDX YAML not found in $(OUTPUT_DIR)."; \
		find "$(OUTPUT_DIR)" -type f -maxdepth 2; \
		exit 1; \
	else \
		mv "$$FOUND_FILE" "$(SPDX_YML)"; \
		echo "✅ SPDX YAML normalized: $(SPDX_YML)"; \
	fi

$(CDX_JSON): $(ANALYZER_YML)
	@echo "📦 Generating CycloneDX (JSON) -> $@"
	@"$(ORT_BIN)" report \
		--ort-file "$(ANALYZER_YML)" \
		--output-dir "$(OUTPUT_DIR)" \
		--report-formats CycloneDX >/dev/null

	# Tìm file .cyclonedx.json và rename về tên chuẩn
	@FOUND_CDX=$$(find "$(OUTPUT_DIR)" -maxdepth 2 -type f -name "*.cyclonedx.json" -o -name "CycloneDX.json" | head -n 1); \
	if [ -z "$$FOUND_CDX" ]; then \
		echo "❌ CycloneDX JSON not found in $(OUTPUT_DIR):"; \
		find "$(OUTPUT_DIR)" -maxdepth 2 -type f; \
		exit 1; \
	else \
		mv "$$FOUND_CDX" "$(CDX_JSON)"; \
		echo "✅ CycloneDX JSON normalized: $(CDX_JSON)"; \
	fi
# ------------------------------------------------
# CONVERT SPDX YAML → JSON
# ------------------------------------------------
$(SPDX_JSON): $(SPDX_YML)
	@echo "🔄 Converting SPDX YAML -> JSON"
	@/snap/bin/yq -o=json '.' "$(SPDX_YML)" > "$(SPDX_JSON)"
	@echo "✅ SPDX JSON ready: $(SPDX_JSON)"

# ------------------------------------------------
# SCAN (Trivy v0.54+) - scan cả SPDX + CycloneDX
# ------------------------------------------------
TRIVY := trivy
TRIVY_JSON_SPDX := $(OUTPUT_DIR)/trivy-scan-spdx.json
TRIVY_JSON_CDX  := $(OUTPUT_DIR)/trivy-scan-cdx.json

$(TRIVY_JSON): $(SPDX_JSON) $(CDX_JSON)
	@echo "🔍 Running Trivy vulnerability scans (SPDX + CycloneDX)..."
	@if ! command -v $(TRIVY) >/dev/null 2>&1; then \
		echo "⚠️ Trivy not found. Install via: https://aquasecurity.github.io/trivy/latest/getting-started/installation/"; \
		exit 1; \
	fi

	# SPDX JSON
	@echo "📦 Scanning SPDX SBOM -> $(TRIVY_JSON_SPDX)"
	@$(TRIVY) sbom "$(SPDX_JSON)" --format json --output "$(TRIVY_JSON_SPDX)" || true

	# CycloneDX JSON
	@echo "📦 Scanning CycloneDX SBOM -> $(TRIVY_JSON_CDX)"
	@$(TRIVY) sbom "$(CDX_JSON)" --format json --output "$(TRIVY_JSON_CDX)" || true

	# Merge hai kết quả
	@echo "🧩 Combining SPDX & CycloneDX scan results -> $(TRIVY_JSON)"
	@jq -s '{Results: (.[0].Results + .[1].Results)}' "$(TRIVY_JSON_SPDX)" "$(TRIVY_JSON_CDX)" > "$(TRIVY_JSON)"
	@echo "✅ Trivy combined scan saved to $(TRIVY_JSON)"

scan: $(TRIVY_JSON)

# ------------------------------------------------
# MERGE (using CycloneDX CLI)
# ------------------------------------------------
MERGE_TOOL := cyclonedx
MERGE_FORMAT := json

$(MERGED_SBOM): $(SPDX_JSON) $(CDX_JSON) $(TRIVY_JSON)
	@echo "🧩 Merging SBOMs with CycloneDX CLI..."
	@$(MERGE_TOOL) merge \
		--input-files $(CDX_JSON) \
		--input-files $(SPDX_JSON) \
		--input-files $(TRIVY_JSON) \
		--output-files $(MERGED_SBOM) \
		--output-format $(MERGE_FORMAT)
	@echo "✅ Merged SBOM ready: $(MERGED_SBOM)"

merge: $(MERGED_SBOM)

# ------------------------------------------------
# VALIDATE
# ------------------------------------------------
SBOMQS_BIN := $(PROJECT_DIR)/tools/sbomqs
VALIDATE_REPORT := $(OUTPUT_DIR)/sbomqs-report.txt

validate: $(MERGED_SBOM)
	@echo "🧠 Validating SBOM completeness..."
	@$(SBOMQS_BIN) score "$(MERGED_SBOM)" > "$(VALIDATE_REPORT)"
	@echo "✅ Validation report saved to: $(VALIDATE_REPORT)"


# ------------------------------------------------
# SIGN
# ------------------------------------------------
COSIGN_BIN := $(PROJECT_DIR)/tools/cosign
COSIGN_KEY := $(PROJECT_DIR)/tools/cosign.key
SIGNED_SBOM := $(OUTPUT_DIR)/signed-sbom.json
SBOM_SIGNATURE := $(OUTPUT_DIR)/sbom.sig
SBOM_BUNDLE := $(OUTPUT_DIR)/sbom.bundle

sign: validate
	@echo "✍️ Signing merged SBOM..."
	@$(COSIGN_BIN) sign-blob \
		--key $(COSIGN_KEY) \
		--bundle $(SBOM_BUNDLE) \
		--output-signature $(SBOM_SIGNATURE) \
		$(MERGED_SBOM)
	@cp $(MERGED_SBOM) $(SIGNED_SBOM)
	@echo "✅ Signed SBOM: $(SIGNED_SBOM)"
	@echo "📦 Signature bundle: $(SBOM_BUNDLE)"


# ------------------------------------------------
# VERIFY
# ------------------------------------------------
COSIGN_BIN := $(PROJECT_DIR)/tools/cosign
COSIGN_PUB := $(PROJECT_DIR)/tools/cosign.pub
SBOM_SIGNATURE := $(OUTPUT_DIR)/sbom.sig
SIGNED_SBOM := $(OUTPUT_DIR)/signed-sbom.json

verify:
	@if [ ! -f "$(SIGNED_SBOM)" ]; then \
		echo "⚠️  No signed SBOM found — skipping verify."; \
	elif [ ! -f "$(SBOM_SIGNATURE)" ]; then \
		echo "⚠️  No signature file found — skipping verify."; \
	else \
		echo "🔍 Verifying signed SBOM integrity (offline mode)..."; \
		if $(COSIGN_BIN) verify-blob \
			--key $(COSIGN_PUB) \
			--signature $(SBOM_SIGNATURE) \
			--offline \
			$(SIGNED_SBOM); then \
			echo "✅ SBOM signature verified successfully (offline)."; \
		else \
			echo "❌ Verification failed — signature mismatch or invalid key."; \
			exit 1; \
		fi; \
	fi


# ------------------------------------------------
# DEPLOY
# ------------------------------------------------
deploy: verify
	@if [ ! -f "$(SIGNED_SBOM)" ]; then \
		echo "🖋️ No signed SBOM found, signing now..."; \
		$(MAKE) sign; \
	else \
		echo "✅ Signed SBOM already exists: $(SIGNED_SBOM), skipping sign."; \
	fi
	@bash "$(PROJECT_DIR)/scripts/push_oci.sh" "$(SIGNED_SBOM)"
	@echo "🚀 Deployed successfully."

# ------------------------------------------------
# SHORTCUTS
# ------------------------------------------------
build: $(SPDX_JSON) $(CDX_JSON)
scan: $(TRIVY_JSON)


rebuild: clean build
clean:
	@rm -rf "$(OUTPUT_DIR)"
	@echo "🧹 Cleaned $(OUTPUT_DIR)."

help:
	@echo ""
	@echo "🧭 SBOM-MAX-BUILD Pipeline Test (2025.11)"
	@echo "  make build     - Generate SPDX + CycloneDX from Source SBOM" as Build Tools
	@echo "  make scan      - Analyze vulnerabilities using Trivy" - Grype is not appropriate with CI/CD
	@echo "  make merge     - Merge SPDX + CycloneDX + Trivy results"
	@echo "  make validate  - Validate merged SBOM completeness"
	@echo "  make sign      - Sign SBOM with Cosign"
	@echo "  make deploy    - Push signed SBOM to ECR (need Private Key for Sign)"
	@echo "  make clean     - Remove outputs"
