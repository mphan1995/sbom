import os
import json
from flask import Flask, render_template, request, redirect, url_for, jsonify, flash
from dotenv import load_dotenv
from utils import sbom_parser, trivy_parser, ai_advisor

load_dotenv()

app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = os.path.join(os.path.dirname(__file__), 'uploads')
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY','dev-secret')

STATE_FILE = os.path.join(os.path.dirname(__file__), 'uploads', 'last_state.json')

def _save_state(state):
    os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
    with open(STATE_FILE, 'w', encoding='utf-8') as f:
        json.dump(state, f, ensure_ascii=False, indent=2)

def _load_state():
    if os.path.exists(STATE_FILE):
        with open(STATE_FILE, 'r', encoding='utf-8') as f:
            return json.load(f)
    return {'vulns': [], 'summary': {'severity_counts':{}, 'top_packages':[], 'total':0}}

@app.route('/')
def index():
    return render_template('index.html', title='Upload SBOM / Trivy')

@app.route('/upload', methods=['POST'])
def upload():
    sbom_file = request.files.get('sbom_file')
    trivy_file = request.files.get('trivy_file')
    vulns = []
    packages = []
    messages = []

    # Ensure upload dir exists
    os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

    # SBOM
    if sbom_file and sbom_file.filename:
        path = os.path.join(app.config['UPLOAD_FOLDER'], sbom_file.filename)
        sbom_file.save(path)
        try:
            doc = sbom_parser.load_json(path)
            packages = sbom_parser.extract_packages(doc)
            messages.append(f"Loaded SBOM: {sbom_file.filename} with {len(packages)} packages.")
        except Exception as e:
            messages.append(f"SBOM parse error: {e}")

    # Trivy
    if trivy_file and trivy_file.filename:
        path = os.path.join(app.config['UPLOAD_FOLDER'], trivy_file.filename)
        trivy_file.save(path)
        try:
            doc = trivy_parser.load_json(path)
            vulns = trivy_parser.extract_vulnerabilities(doc)
            messages.append(f"Loaded Trivy: {trivy_file.filename} with {len(vulns)} vulns.")
        except Exception as e:
            messages.append(f"Trivy parse error: {e}")

    # Fallback to sample data
    if not sbom_file and not trivy_file:
        sample_s = os.path.join(os.path.dirname(__file__), 'data', 'sample_cyclonedx.json')
        sample_t = os.path.join(os.path.dirname(__file__), 'data', 'sample_trivy_scan.json')
        try:
            packages = sbom_parser.extract_packages(sbom_parser.load_json(sample_s))
            vulns = trivy_parser.extract_vulnerabilities(trivy_parser.load_json(sample_t))
            messages.append("Loaded sample data (no files uploaded).")
        except Exception as e:
            messages.append(f"Sample load error: {e}")

    summary = trivy_parser.summarize_vulns(vulns)
    state = {'vulns': vulns, 'packages': packages, 'summary': summary}
    _save_state(state)

    flash(" ".join(messages))
    return redirect(url_for('dashboard'))


@app.route('/dashboard')
def dashboard():
    st = _load_state()
    vulns = st.get('vulns', [])
    summary = st.get('summary', {'severity_counts':{}, 'top_packages':[]})
    return render_template('dashboard.html', title='Dashboard', vulns=vulns, summary_json=json.dumps(summary))

@app.route('/chat')
def chat_page():
    return render_template('chat.html', title='AI Chat')

@app.route('/api/chat', methods=['POST'])
def chat_api():
    data = request.get_json(force=True, silent=True) or {}
    q = data.get('question') or data.get('q') or ''
    if not q.strip():
        return jsonify({'error': 'Missing question'}), 400
    st = _load_state()
    vulns = st.get('vulns', [])
    rsp = ai_advisor.ask_advice(q, vulns)
    code = 200 if 'answer' in rsp else 500
    return jsonify(rsp), code

if __name__ == '__main__':
    app.run(debug=True)
