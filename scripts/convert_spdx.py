import sys
from spdx.parsers.jsonparser import Parser #parser Parser - positional 
from spdx.parsers.loggers import StandardLogger #parser Standard Loggers
from spdx.parsers.jsonyamlxmlbuilders import Builder #parsers builder 
from spdx.writers.json import write_document 
from pathlib import Path

def main(spdx_path):
    try:
        print(f"📂 Reading SPDX JSON: {spdx_path}")

        builder = Builder()
        logger = StandardLogger()
        parser = Parser(builder, logger)

        with open(spdx_path, "r") as infile:
            document, error = parser.parse(infile)

        if error:
            print(f"⚠️ Parse completed with issues: {error}")
        else:
            print("\n✅ SPDX Document Loaded Successfully!")

        print(f"Document Name: {document.name}")
        print(f"SPDX Version: {getattr(document, 'version', 'N/A')}")
        print(f"Creator(s): {[c.name for c in document.creation_info.creators]}")
        print(f"Created Date: {document.creation_info.created}")
        print(f"Total Packages: {len(document.packages)}")

        # ====== ✳️ EXPORT TO FILE ======
        output_path = Path("sbom/output/converted-spdx.json")
        with open(output_path, "w") as out:
            write_document(document, out)  # serialize SPDX Document → JSON file

        print(f"\n💾 Converted SPDX file saved to: {output_path.resolve()}")

    except Exception as e:
        print(f"❌ Failed to parse or export SPDX: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 convert_spdx.py <spdx_json_file>")
        sys.exit(1)
    main(sys.argv[1])
