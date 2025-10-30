#!/usr/bin/env bash
set -euo pipefail

# --------------------------------------------
# CONFIGURATION
# --------------------------------------------
SIGNED_SBOM="${1:-sbom/output/signed-sbom.json}"

# Gán repo và tag (có thể override từ môi trường)
OCI_REPO="${OCI_REPO:-201462388357.dkr.ecr.us-east-1.amazonaws.com/max-flaskci-demo}"

# Tạo tag động (dựa trên số version hoặc thời gian)
# Nếu bạn muốn theo kiểu 1., 2., 3. — dùng FILE_VERSION hoặc COUNT ở đây
COUNT=$(ls -1 sbom/output/signed-sbom*.json 2>/dev/null | wc -l)
OCI_TAG="v$((COUNT + 1))"

# Kiểm tra file tồn tại
if [ ! -f "$SIGNED_SBOM" ]; then
  echo "[push] ❌ SBOM not found: $SIGNED_SBOM"
  exit 1
fi

# Lấy tên file (loại bỏ absolute path)
SBOM_FILENAME=$(basename "$SIGNED_SBOM")

echo "[push] 📦 Uploading SBOM to ${OCI_REPO}:${OCI_TAG}"
echo "[push] -> File: ${SIGNED_SBOM}"

# --------------------------------------------
# PUSH to OCI Registry
# --------------------------------------------
oras push "${OCI_REPO}:${OCI_TAG}" \
  --artifact-type application/vnd.cyclonedx+json \
  "${SIGNED_SBOM}:application/vnd.cyclonedx+json" \
  --disable-path-validation

echo "[push] ✅ Done. SBOM pushed to ${OCI_REPO}:${OCI_TAG}"
