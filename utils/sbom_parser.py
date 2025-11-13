import json
from typing import Dict, Any, List

def load_json(path: str) -> Any:
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def detect_format(doc: Dict[str, Any]) -> str:
    if isinstance(doc, dict):
        if doc.get('bomFormat') == 'CycloneDX':
            return 'cyclonedx'
        if 'spdxVersion' in doc or doc.get('@context') == 'https://spdx.org/rdf/':
            return 'spdx'
    return 'unknown'

def extract_packages(doc: Dict[str, Any]) -> List[Dict[str, Any]]:
    fmt = detect_format(doc)
    pkgs = []
    if fmt == 'cyclonedx':
        for c in doc.get('components', []) or []:
            pkgs.append({
                'name': c.get('name'),
                'version': c.get('version'),
                'purl': c.get('purl'),
                'type': c.get('type'),
                'licenses': [l.get('license', {}).get('id') for l in (c.get('licenses') or []) if l.get('license')],
            })
    elif fmt == 'spdx':
        for p in doc.get('packages', []) or []:
            pkgs.append({
                'name': p.get('name') or p.get('packageName'),
                'version': (p.get('versionInfo') or p.get('packageVersion')),
                'purl': None,
                'type': None,
                'licenses': [p.get('licenseConcluded') or p.get('licenseDeclared')],
            })
    return pkgs

def summarize_packages(packages: List[Dict[str, Any]]) -> Dict[str, Any]:
    return {
        'count': len(packages),
        'by_name': sorted({ (p.get('name') or '?') for p in packages }),
    }
