# ============================================
# Makefile - SBOM-MAX-BUILD Pipeline
# Stages: Build -> Scan -> Merge -> Validate -> Sign -> Deploy
# ============================================

PROJECT_DIR := $(shell pwd)
PROJECTS_DIR := $(PROJECT_DIR)/projects
OUTPUT_DIR := $(PROJECT_DIR)/sbom/output
CONFIG_DIR := $(PROJECT_DIR)/ort-config
ORT_CONFIG := $(CONFIG_DIR)/ort.conf.yaml
GRYPE_CONFIG := $(PROJECT_DIR)/grype-config/grype.yaml
MERGED_SBOM := $(OUTPUT_DIR)/merged-sbom.json
SIGNED_SBOM := $(OUTPUT_DIR)/signed-sbom.json

# Auto-detect ORT binary
ORT_BIN := $(shell if [ -x "$(PROJECT_DIR)/tools/ort/ort" ]; then echo "$(PROJECT_DIR)/tools/ort/ort"; \
             elif [ -x "$(PROJECT_DIR)/tools/ort/cli/build/install/ort/bin/ort" ]; then echo "$(PROJECT_DIR)/tools/ort/cli/build/install/ort/bin/ort"; \
             else echo "ort"; fi)

GRYPE := grype
COSIGN := cosign

# Ensure output directory
prepare:
	mkdir -p $(OUTPUT_DIR)

# ============================================
# 1️⃣ BUILD STAGE - Generate SBOM (SPDX + CycloneDX)
# ============================================
build: prepare
	@echo "🔨 Running ORT Analyzer for all projects under $(PROJECTS_DIR)..."
	$(ORT_BIN) analyze \
		-i $(PROJECTS_DIR) \
		-o $(OUTPUT_DIR)

	@echo "📦 Generating SPDX + CycloneDX SBOM..."
	$(ORT_BIN) report \
		-i $(OUTPUT_DIR)/analyzer-result.yml \
		-o $(OUTPUT_DIR) \
		-f SpdxDocument \
		-f CycloneDX

	@echo "✅ Build SBOM generated at $(OUTPUT_DIR)"
	@ls -lh $(OUTPUT_DIR)

# ============================================
# 2️⃣ SCAN STAGE - Vulnerability scan using Grype
# ============================================
scan: build
	@echo "🔍 Scanning CycloneDX SBOM with Grype..."
	$(GRYPE) sbom:$(OUTPUT_DIR)/analyzer-result.cyclonedx.json \
		-o json \
		-c $(GRYPE_CONFIG) > $(OUTPUT_DIR)/grype-scan.json
	@echo "✅ Vulnerability scan completed: $(OUTPUT_DIR)/grype-scan.json"

# ============================================
# 3️⃣ MERGE STAGE - Combine multiple SBOMs (if any)
# ============================================
merge: scan
	@echo "🧩 Merging SBOM files..."
	@bash $(PROJECT_DIR)/scripts/merge_sbom.sh \
		$(OUTPUT_DIR)/analyzer-result.spdx.json \
		$(OUTPUT_DIR)/analyzer-result.cyclonedx.json \
		$(OUTPUT_DIR)/grype-scan.json \
		> $(MERGED_SBOM)
	@echo "✅ Merged SBOM created: $(MERGED_SBOM)"

# ============================================
# 4️⃣ VALIDATE STAGE - Completeness / Quality validation
# ============================================
validate: merge
	@echo "🧠 Validating SBOM completeness..."
	@if command -v sbomqs >/dev/null 2>&1; then \
		sbomqs score $(MERGED_SBOM); \
	else \
		echo "⚠️ sbomqs not found, skipping validation. Install with: pip install sbomqs"; \
	fi

# ============================================
# 5️⃣ SIGN STAGE - Digital signing with Cosign
# ============================================
sign: validate
	@echo "✍️ Signing SBOM..."
	@if [ -z "$$COSIGN_KEY" ]; then \
		echo "⚠️ Please export COSIGN_KEY=<your-key-path>"; exit 1; \
	fi
	$(COSIGN) sign-blob --key $$COSIGN_KEY \
		--output-signature $(OUTPUT_DIR)/sbom.sig \
		$(MERGED_SBOM)
	cp $(MERGED_SBOM) $(SIGNED_SBOM)
	@echo "✅ SBOM signed: $(SIGNED_SBOM)"
	@echo "Signature: $(OUTPUT_DIR)/sbom.sig"

# ============================================
# 6️⃣ DEPLOY STAGE - Push SBOM to registry or repo
# ============================================
deploy: sign
	@echo "🚀 Deploying SBOM to target registry..."
	@bash $(PROJECT_DIR)/scripts/push_oci.sh $(SIGNED_SBOM)
	@echo "✅ SBOM successfully deployed."

# ============================================
# Utility targets
# ============================================
clean:
	rm -rf $(OUTPUT_DIR)
	@echo "🧹 Cleaned build artifacts."

help:
	@echo ""
	@echo "Available targets:"
	@echo "  make build     - Generate SPDX & CycloneDX SBOM for all projects/"
	@echo "  make scan      - Run Grype vulnerability scan"
	@echo "  make merge     - Merge SBOMs (SPDX + CycloneDX + scan)"
	@echo "  make validate  - Validate SBOM quality (sbomqs)"
	@echo "  make sign      - Sign SBOM with Cosign"
	@echo "  make deploy    - Push signed SBOM to registry"
	@echo "  make clean     - Remove generated files"
	@echo ""
