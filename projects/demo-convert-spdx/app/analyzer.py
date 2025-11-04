from app.utils import compute_hash

def summarize_data(local_data, api_data):
    summary = {
        "local_items": len(local_data.get("items", [])),
        "api_fields": len(api_data.keys()),
        "combined_hash": compute_hash(str(local_data) + str(api_data))
    }
    return summary
