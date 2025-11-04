import json
import requests
import hashlib

def load_local_data(path):
    """Load a local JSON file"""
    with open(path, "r") as f:
        data = json.load(f)
    return data

def fetch_data_from_api(url):
    """Simulate fetching data from API"""
    try:
        resp = requests.get(url, timeout=5)
        if resp.status_code == 200:
            return resp.json()
        return {"error": f"HTTP {resp.status_code}"}
    except Exception as e:
        return {"error": str(e)}

def compute_hash(content: str):
    """Compute SHA256 hash of a string"""
    return hashlib.sha256(content.encode()).hexdigest()
