# SBOM-MAX-BUILD

> Full project skeleton for generating SBOMs (SPDX 2.2 / CycloneDX 1.5) with **OSS Review Toolkit v70.0.0**, and scanning vulnerabilities via **Grype** — designed to work with Java builds (Maven/Gradle, Java 17+).

## Features
- Build artifacts for **Maven** and **Gradle** projects (Java 17+)
- Dependency analysis & SBOM generation using **ORT v70.0.0**
- SBOM formats: **SPDX 2.2** and **CycloneDX 1.5**
- Vulnerability scanning using **Grype** reading directly from SBOMs
- Optional containerized toolchain via the provided `Dockerfile`
- Push SBOMs to an **OCI registry** (e.g., `ghcr.io`) using **oras**

> **Note**: The `sbom/` folder is intentionally empty; generate SBOMs using the Make targets below.

---

## Quick Start

### Prerequisites
- Java 17+
- Docker 24+
- `oras` CLI (for pushing SBOM to OCI, optional)
- `grype` CLI (if running outside the container)
- Access to an OCI registry (e.g., `ghcr.io`) + login

### Make targets
```bash
# Analyze dependencies and generate SBOMs via ORT
make sbom

# Merge/normalize SBOMs (if multiple) and produce SPDX/CycloneDX
make merge

# Scan vulnerabilities from SBOMs with Grype
make scan

# Build toolchain image (contains Java 17, ORT v70, grype, oras)
make image

# Push merged SBOM to OCI registry (oras)
# Example: make push OCI_REPO=ghcr.io/myuser/sbom OCI_TAG=demo
make push
```

### Environment variables
- `OCI_REPO` — e.g. `ghcr.io/<org-or-user>/sbom`
- `OCI_TAG`  — e.g. `demo` or a commit SHA
- `IMAGE`    — toolchain image tag (defaults to `sbom-max-build:latest`)

### Authenticate to GHCR (oras uses Docker auth if `~/.oras/config.json` not present)
```bash
echo "$GITHUB_TOKEN" | docker login ghcr.io -u <your-username> --password-stdin
```

### Typical workflow
```bash
# 1) Build toolchain container once
make image

# 2) Generate SBOMs (mounted workspace)
make sbom

# 3) Optionally merge/normalize into a single SPDX/CycloneDX
make merge

# 4) Scan vulnerabilities from SBOMs
make scan

# 5) Push merged SBOM to OCI
make push OCI_REPO=ghcr.io/<you>/sbom OCI_TAG=demo
```

---

## Project layout
```
SBOM-MAX-BUILD/
├─ Dockerfile
├─ Makefile
├─ README.md
├─ .gitignore
├─ scripts/
│  ├─ run_ort.sh
│  ├─ merge_sbom.sh
│  ├─ scan_grype.sh
│  └─ push_oci.sh
├─ ort-config/
│  └─ ort.conf.yaml
├─ grype-config/
│  └─ grype.yaml
├─ sbom/            # (empty; generated at runtime)
├─ docker/
│  └─ entrypoint.sh
└─ .github/workflows/
   └─ ci.yml
```

---

## Notes & Versions
- ORT: **v70.0.0**
- CycloneDX: **1.5**
- SPDX: **2.2**
- Grype: compatible with SBOM inputs via `sbom:<path>`

If your registry denies `HEAD`/`PUT` with oras, ensure the repository exists or your token has `packages:write` scope on GitHub, and retry `docker login ghcr.io`.

---

## Troubleshooting
- **oras denied**: Check `~/.docker/config.json` auth, ensure `GITHUB_TOKEN` has `read:packages` + `write:packages`.
- **ORT Java**: Ensure Java 17+ is available; in container we install it automatically.
- **Grype findings differ**: Keep Grype up to date and verify the SBOM spec version.
```