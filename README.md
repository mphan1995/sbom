# 🧩 SBOM-MAX-BUILD (v2025.11)

**SBOM-MAX-BUILD** là pipeline tự động hóa việc **phân tích, tạo, quét, hợp nhất, ký và triển khai Software Bill of Materials (SBOM)**.  
Dự án sử dụng các công cụ open-source hàng đầu:
- **ORT (OSS Review Toolkit)** – Phân tích và sinh Build SBOM  
- **Grype** – Quét lỗ hổng từ SBOM  
- **sbomqs** – Đánh giá mức độ hoàn thiện SBOM  
- **Cosign** – Ký và xác thực SBOM  
- **Makefile** – Quản lý các giai đoạn pipeline theo chuẩn DevSecOps  

---

## 🚀 1. Yêu cầu môi trường

| Thành phần | Phiên bản khuyến nghị |
|-------------|----------------------|
| **Java JDK** | ≥ 17 (ORT cần JDK 17+) |
| **Python 3** | ≥ 3.8 (để dùng `yq`, `sbomqs`) |
| **ORT CLI** | v71.x+ |
| **Grype** | v0.81+ |
| **Cosign** | v2.x+ |
| **sbomqs** | v1.4+ |
| **yq** | v4+ (`yq eval -j` hỗ trợ YAML→JSON) |

Cài nhanh các công cụ cần thiết:
```bash
sudo apt install openjdk-21-jdk jq -y
pip install yq sbomqs
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh
curl -sSfL https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64 -o /usr/local/bin/cosign
chmod +x /usr/local/bin/cosign

