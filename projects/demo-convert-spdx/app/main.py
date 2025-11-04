from app.utils import fetch_data_from_api, load_local_data
from app.analyzer import summarize_data

def main():
    print("🚀 Running demo-convert-spdx-advanced")
    
    # Load local sample JSON
    local_data = load_local_data("app/data/sample.json")

    # Fetch extra data online (mock)
    api_data = fetch_data_from_api("https://api.github.com/repos/psf/requests")

    # Combine and analyze
    summary = summarize_data(local_data, api_data)
    
    print("\n📊 Summary Report:")
    for k, v in summary.items():
        print(f" - {k}: {v}")

if __name__ == "__main__":
    main()
