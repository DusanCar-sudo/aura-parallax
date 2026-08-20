#!/usr/bin/env bash
# Generate one image with Vertex Imagen using Application Default Credentials.
# Usage: imagen.sh <out-name> <aspect> <prompt-file>
set -euo pipefail
PROJECT="${IMAGEN_PROJECT:-aura-code-501012}"
LOCATION="${IMAGEN_LOCATION:-us-central1}"
MODEL="${IMAGEN_MODEL:-imagen-4.0-generate-001}"
OUT="$1"; ASPECT="$2"; PROMPT_FILE="$3"
DIR="$(cd "$(dirname "$0")/.." && pwd)"

TOKEN="$(gcloud auth application-default print-access-token)"
REQ="$(mktemp)"
python3 - "$PROMPT_FILE" "$ASPECT" > "$REQ" <<'PY'
import json,sys
prompt=open(sys.argv[1]).read().strip()
print(json.dumps({"instances":[{"prompt":prompt}],
 "parameters":{"sampleCount":1,"aspectRatio":sys.argv[2],
 "safetySetting":"block_only_high","personGeneration":"dont_allow",
 "addWatermark":False}}))
PY

RESP="$(mktemp)"
HTTP=$(curl -s -w "%{http_code}" -o "$RESP" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json; charset=utf-8" \
  "https://${LOCATION}-aiplatform.googleapis.com/v1/projects/${PROJECT}/locations/${LOCATION}/publishers/google/models/${MODEL}:predict" \
  -d @"$REQ")

if [ "$HTTP" != "200" ]; then
  echo "HTTP $HTTP"; head -c 900 "$RESP"; echo; exit 1
fi
python3 - "$RESP" "$DIR/layers/$OUT.png" <<'PY'
import json,sys,base64
d=json.load(open(sys.argv[1]))
p=d.get("predictions") or []
if not p or "bytesBase64Encoded" not in p[0]:
    print("no image in response:", json.dumps(d)[:500]); sys.exit(1)
open(sys.argv[2],"wb").write(base64.b64decode(p[0]["bytesBase64Encoded"]))
print("saved", sys.argv[2])
PY
