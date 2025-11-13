import os
from typing import List, Dict, Any
from openai import OpenAI

OPENAI_MODEL_DEFAULT = os.getenv('OPENAI_MODEL', 'gpt-4o-mini')

def _has_api_key() -> bool:
    return bool(os.getenv('OPENAI_API_KEY'))

def summarize_for_prompt(vulns: List[Dict[str, Any]]) -> str:
    # Compact summary to reduce token usage
    lines = []
    for v in vulns[:50]:  # cap for safety
        lines.append(f"{v.get('severity','?')}: {v.get('pkg_name','?')} {v.get('installed_version','?')} — {v.get('cve_id','?')} ({(v.get('title') or '')[:60]}) fix:{v.get('fixed_version') or '-'}")
    return "\n".join(lines)

def ask_advice(question: str, vulns: List[Dict[str, Any]]) -> Dict[str, Any]:
    if not _has_api_key():
        return {'error': 'OPENAI_API_KEY is not set. Please configure it in your .env file.'}

    try:
        client = OpenAI() 
        system_prompt = (
            "You are an SBOM security advisor. Be concise, practical, and actionable. "
            "Use bullet points. When recommending fixes, cite versions and quick steps. "
            "If asked in Vietnamese, answer in Vietnamese; otherwise, answer in English."
        )
        compact = summarize_for_prompt(vulns)
        user_prompt = (
            f"Context vulnerabilities (compact list):\n{compact}\n\n"
            f"User Question: {question}\n"
            "Answer with the top 5 actionable recommendations first, then any notes on false positives or mitigations."
        )
        rsp = client.chat.completions.create(
            model=OPENAI_MODEL_DEFAULT,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            temperature=0.3,
            max_tokens=500,
        )
        answer = rsp.choices[0].message.content.strip()
        return {'answer': answer}
    except Exception as e:
        return {'error': f'AI error: {e}'}
