import sys
import json
from spdx_tools.spdx.parser.jsonparser import parse_from_file

def main(spdx_path):
    try:
        print(f"📂 Reading SPDX JSON: {spdx_path}")
        # Parse JSON → SPDX Document object
        document = parse_from_file(spdx_path)

        print(f"\n✅ SPDX Document Loaded Successfully!")
        print(f"Document Name: {document.name}")
        print(f"SPDX Version: {document.version_info if hasattr(document, 'version_info') else 'N/A'}")
        print(f"Creator(s): {document.creation_info.creators}")
        print(f"Created Date: {document.creation_info.created}")
        print(f"Total Packages: {len(document.packages)}")

    except Exception as e:
        print(f"❌ Failed to parse SPDX JSON: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 convert_spdx.py <spdx_json_file>")
        sys.exit(1)
    main(sys.argv[1])
