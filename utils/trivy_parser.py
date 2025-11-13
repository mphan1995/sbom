import json
from typing import Dict, Any, List

def load_json(path: str) -> Any:
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def extract_vulnerabilities(doc: Dict[str, Any]) -> List[Dict[str, Any]]:
    vulns: List[Dict[str, Any]] = []
    results = doc.get('Results') or doc.get('results') or []
    for res in results:
        target = res.get('Target') or res.get('target')
        for v in res.get('Vulnerabilities') or res.get('vulnerabilities') or []:
            cve = v.get('VulnerabilityID') or v.get('vulnerabilityID')
            cvss = None
            if isinstance(v.get('CVSS'), dict):
                cvss = (v.get('CVSS').get('nvd') or v.get('CVSS').get('NVD') or {}).get('V3Score')
            vulns.append({
                'target': target,
                'pkg_name': v.get('PkgName') or v.get('pkgName'),
                'installed_version': v.get('InstalledVersion') or v.get('installedVersion'),
                'severity': v.get('Severity') or v.get('severity'),
                'cve_id': cve,
                'cve_url': f"https://nvd.nist.gov/vuln/detail/{cve}" if cve else None,
                'score': cvss or v.get('CVSSScore') or v.get('cvssScore'),
                'title': v.get('Title') or v.get('title'),
                'description': v.get('Description') or v.get('description'),
                'fixed_version': v.get('FixedVersion') or v.get('fixedVersion'),
            })
    return vulns


def summarize_vulns(vulns: List[Dict[str, Any]]) -> Dict[str, Any]:
    sev_counts = {'critical':0,'high':0,'medium':0,'low':0,'unknown':0}
    for v in vulns:
        s = (v.get('severity') or 'unknown').lower()
        if s not in sev_counts:
            s = 'unknown'
        sev_counts[s] += 1

    # simple risk score: critical=4, high=3, medium=2, low=1
    weight = {'critical':4,'high':3,'medium':2,'low':1,'unknown':0}
    pkg_scores = {}
    for v in vulns:
        s = (v.get('severity') or 'unknown').lower()
        w = weight.get(s, 0)
        key = (v.get('pkg_name') or 'unknown')
        pkg_scores[key] = pkg_scores.get(key, 0) + w

    top_packages = sorted(
        [{'package': k, 'score': s} for k, s in pkg_scores.items() if k != 'unknown'],
        key=lambda x: x['score'], reverse=True
    )[:10]

    return {
        'total': len(vulns),
        'severity_counts': sev_counts,
        'top_packages': top_packages
    }
