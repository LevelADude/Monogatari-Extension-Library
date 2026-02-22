#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p ci_out/snapshots
: > ci_out/failures.json

if ! command -v java >/dev/null 2>&1; then
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y openjdk-21-jre-headless || true
  fi
fi

if ! command -v java >/dev/null 2>&1; then
  echo "Java 21 is required but not available." >&2
  exit 1
fi

bash ./dev-setup.sh --tester

export UA="Mozilla/5.0 (compatible; Shosetsu-CI/1.0; +https://github.com/Shosetsu/Monogatari-Extension-Library)"
export AL="en-US,en;q=0.9"

python3 - <<'PY'
import json, os, re, subprocess, html
from pathlib import Path

root = Path('.')
out = root / 'ci_out'
(out / 'snapshots').mkdir(parents=True, exist_ok=True)

samples = json.loads((root / 'ci_samples.json').read_text())['samples']
failures = []
rows = []

def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True)

def curl_fetch(url, name, step):
    safe = re.sub(r'[^a-zA-Z0-9._-]+', '_', f"{name}_{step}")
    headers_path = out / 'snapshots' / f"{safe}.headers.txt"
    body_path = out / 'snapshots' / f"{safe}.body.html"
    cmd = [
        'curl','-sS','-L',url,
        '-A', os.environ.get('UA', ''),
        '-H', f"Accept: text/html,application/xhtml+xml",
        '-H', f"Accept-Language: {os.environ.get('AL', 'en-US,en;q=0.9')}",
        '-D', str(headers_path),
        '-o', str(body_path),
        '-w', '%{http_code}'
    ]
    p = run(cmd)
    code = p.stdout.strip() if p.returncode == 0 else '000'
    body = body_path.read_text(errors='ignore') if body_path.exists() else ''
    return code, body, str(headers_path), str(body_path), p.stderr.strip()

passed = 0
failed = 0
skipped = 0

for s in samples:
    name = s['name']
    ext = s['extension']
    if s.get('skip'):
        skipped += 1
        rows.append((name, 'SKIP', s.get('skipReason','')))
        continue

    tester = run(['java', '-jar', 'bin/extension-tester.jar', '--ci', ext])
    if tester.returncode != 0:
        failed += 1
        rows.append((name, 'FAIL', 'extension-tester failed'))
        failures.append({'extension': name, 'step': 'extension_tester', 'url': ext, 'http_status': None, 'error': tester.stderr[-4000:]})
        continue

    exp = s.get('expectations', {})
    detail_code, detail_body, detail_headers, detail_snap, detail_err = curl_fetch(s['detailUrl'], name, 'detail')
    if not detail_code.startswith('2'):
        failed += 1
        rows.append((name, 'FAIL', f"detail http {detail_code}"))
        failures.append({'extension': name, 'step': 'detail', 'url': s['detailUrl'], 'http_status': detail_code, 'error': detail_err, 'headers': detail_headers, 'snapshot': detail_snap})
        continue

    chapter_code, chapter_body, chapter_headers, chapter_snap, chapter_err = curl_fetch(s['chapterUrl'], name, 'chapter')
    if not chapter_code.startswith('2'):
        failed += 1
        rows.append((name, 'FAIL', f"chapter http {chapter_code}"))
        failures.append({'extension': name, 'step': 'chapter', 'url': s['chapterUrl'], 'http_status': chapter_code, 'error': chapter_err, 'headers': chapter_headers, 'snapshot': chapter_snap})
        continue

    clean_detail = re.sub(r'<[^>]+>', ' ', detail_body)
    clean_ch = re.sub(r'<[^>]+>', ' ', chapter_body)
    clean_detail = html.unescape(clean_detail)
    clean_ch = html.unescape(clean_ch)

    ok = True
    reason = 'ok'
    if exp.get('titleContains') and exp['titleContains'].lower() not in clean_detail.lower():
        ok = False
        reason = f"titleContains not found: {exp['titleContains']}"
    if ok and len(clean_ch.strip()) < int(exp.get('minContentLength', 0)):
        ok = False
        reason = f"chapter content too short: {len(clean_ch.strip())}"
    if ok and int(exp.get('minChapters', 0)) > 1:
        found = len(re.findall(r'chapter', clean_detail, flags=re.IGNORECASE))
        if found < int(exp['minChapters']):
            ok = False
            reason = f"possible chapter count below threshold ({found} < {exp['minChapters']})"

    if ok:
        passed += 1
        rows.append((name, 'PASS', 'all checks passed'))
    else:
        failed += 1
        rows.append((name, 'FAIL', reason))
        failures.append({'extension': name, 'step': 'expectations', 'url': s['chapterUrl'], 'http_status': chapter_code, 'error': reason, 'detail_snapshot': detail_snap, 'chapter_snapshot': chapter_snap})

summary = [
    '# CI Sample Summary',
    '',
    '## Format definition',
    '- Columns: `Extension | Status | Notes`',
    '- Status values: `PASS`, `FAIL`, `SKIP`.',
    '- `SKIP` entries must include a reason (e.g. JS/auth/anti-bot constraints).',
    '',
    '## Example',
    '| Extension | Status | Notes |',
    '|---|---|---|',
    '| ExampleSite | PASS | all checks passed |',
    '| ExampleBlockedSite | SKIP | Requires login / anti-bot JS challenge |',
    '',
    '## Run results',
    '| Extension | Status | Notes |',
    '|---|---|---|',
]
for name, st, note in rows:
    summary.append(f"| {name} | {st} | {note} |")
summary += [
    '',
    f"Passed: {passed}",
    f"Failed: {failed}",
    f"Skipped: {skipped}",
]
(out / 'summary.md').write_text('\n'.join(summary) + '\n')
(out / 'failures.json').write_text(json.dumps(failures, indent=2) + '\n')

if failed:
    raise SystemExit(1)
PY
