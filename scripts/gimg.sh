#!/usr/bin/env bash
# Generate one image via the Gemini API using GOOGLE_API_KEY from the environment.
# The key is passed as a header and never appears in a URL, argv, or log line.
# Usage: gimg.sh <out-name> <prompt-file> [model]
set -euo pipefail
: "${GOOGLE_API_KEY:?GOOGLE_API_KEY not set in environment}"
OUT="$1"; PROMPT_FILE="$2"; MODEL="${3:-gemini-3-pro-image}"
DIR="$(cd "$(dirname "$0")/.." && pwd)"; mkdir -p "$DIR/layers"

REQ="$(mktemp)"; RESP="$(mktemp)"
trap 'rm -f "$REQ" "$RESP"' EXIT
python3 - "$PROMPT_FILE" > "$REQ" <<'PY'
import json,sys
print(json.dumps({"contents":[{"role":"user",
  "parts":[{"text":open(sys.argv[1]).read().strip()}]}]}))
PY

HTTP=$(curl -s -w "%{http_code}" -o "$RESP" \
  -H "x-goog-api-key: $GOOGLE_API_KEY" -H "Content-Type: application/json" \
  "https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent" \
  -d @"$REQ")
[ "$HTTP" = "200" ] || { echo "HTTP $HTTP"; head -c 600 "$RESP"; echo; exit 1; }

python3 - "$RESP" "$DIR/layers/$OUT.png" <<'PY'
import json,sys,base64
d=json.load(open(sys.argv[1]))
for c in d.get("candidates",[]):
    for p in c.get("content",{}).get("parts",[]):
        b=p.get("inlineData") or p.get("inline_data")
        if b and b.get("data"):
            open(sys.argv[2],"wb").write(base64.b64decode(b["data"]))
            print("saved", sys.argv[2]); raise SystemExit
print("no image part. keys:", json.dumps(d)[:400]); sys.exit(1)
PY
