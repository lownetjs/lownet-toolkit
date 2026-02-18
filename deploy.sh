#!/bin/bash
# LOWNET v1.1.2 Deploy
# 1. Injects CSP script hash into toolkit
# 2. Uploads files to server (one SSH connection)
# 3. Computes toolkit hash ON SERVER
# 4. Injects hash into verify.html, re-uploads
# 5. Publishes hash to GitHub (second channel)
set -euo pipefail

SERVER="root@89.167.29.16"
SSH_KEY="$HOME/.ssh/id_ed25519"
SSH_OPTS="-i $SSH_KEY"
REMOTE="/var/www/lownet"
DIR="$(cd "$(dirname "$0")" && pwd)"
TOOLKIT="$DIR/toolkit.html"
VERIFY="$DIR/verify.html"
HASHES="$DIR/hashes.json"
VERSION="v1.1.2"

echo ""
echo "  === LOWNET $VERSION Deploy ==="
echo ""

# Step 1: CSP script hash
echo "  [1] CSP script hash..."
python3 -c "
import re, hashlib, base64
s = open('$TOOLKIT').read()
m = re.search(r'<script>(.*?)</script>', s, re.DOTALL)
h = base64.b64encode(hashlib.sha256(m.group(1).encode()).digest()).decode()
old = re.search(r\"'sha256-[A-Za-z0-9+/=_]+'\", s)
new = f\"'sha256-{h}'\"
if old.group(0) == new:
    print(f'      Current: sha256-{h[:20]}...')
else:
    open('$TOOLKIT', 'w').write(s.replace(old.group(0), new, 1))
    print(f'      Injected: sha256-{h[:20]}...')
"

if [ "${1:-}" = "--hash" ]; then
  echo ""
  echo "  Hash-only mode. No upload."
  exit 0
fi

# Step 2: Prepare staging
echo "  [2] Preparing..."
STAGING=$(mktemp -d)
trap "rm -rf $STAGING" EXIT

mkdir -p "$STAGING/pro" "$STAGING/public" "$STAGING/verify"

cp "$DIR/toolkit.html" "$STAGING/toolkit.html"
cp "$DIR/sw.js"            "$STAGING/sw.js"
cp "$DIR/verify.html"      "$STAGING/verify/index.html"

[ -f "$DIR/index.html" ]              && cp "$DIR/index.html"              "$STAGING/index.html"
[ -f "$DIR/lownet-pro-landing.html" ] && cp "$DIR/lownet-pro-landing.html" "$STAGING/pro/index.html"
[ -f "$DIR/public-index.html" ]       && cp "$DIR/public-index.html"       "$STAGING/public/index.html"

for f in $(find "$STAGING" -type f | sort); do
  REL="${f#$STAGING/}"
  SIZE=$(wc -c < "$f" | tr -d ' ')
  echo "      $REL ($SIZE)"
done

# Step 3: Upload
echo "  [3] Uploading..."
tar -C "$STAGING" -cf - . | ssh $SSH_OPTS "$SERVER" "tar -C $REMOTE -xf -"
echo "      Done."

# Step 4: Server hash → verify → re-upload
echo "  [4] Server-side hash..."
SERVER_HASH=$(ssh $SSH_OPTS "$SERVER" "sha256sum $REMOTE/toolkit.html | cut -d' ' -f1")
echo "      $SERVER_HASH"

python3 -c "
import re
h = '$SERVER_HASH'
v = open('$VERIFY').read()
v = re.sub(r\"'(?:TOOLKIT_HASH_PLACEHOLDER|[a-f0-9]{64})'\", f\"'{h}'\", v, count=1)
open('$VERIFY', 'w').write(v)
print('      → verify.html updated')
"

scp $SSH_OPTS "$DIR/verify.html" "$SERVER:$REMOTE/verify/index.html"
echo "      → re-uploaded"

# Step 5: Publish hash to GitHub
echo "  [5] Publishing to GitHub..."
python3 -c "
import json
from datetime import datetime
hashes = json.load(open('$HASHES'))
hashes['$VERSION']['toolkit.html'] = '$SERVER_HASH'
hashes['$VERSION']['date'] = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
json.dump(hashes, open('$HASHES', 'w'), indent=2)
print('      → hashes.json updated')
"

if command -v git &>/dev/null && [ -d "$DIR/.git" ]; then
  cd "$DIR"
  git add hashes.json
  git commit -m "deploy $VERSION — ${SERVER_HASH:0:12}" --quiet 2>/dev/null || true
  git push --quiet 2>/dev/null && echo "      → pushed to GitHub" || echo "      ⚠ push failed (run: git push)"
else
  echo "      ⚠ not a git repo — to enable:"
  echo "        cd $DIR && git init && git remote add origin git@github.com:lownetjs/lownet-toolkit.git"
fi

echo ""
echo "  Done"
echo "    Server:  https://lownet.org/toolkit.html"
echo "    Verify:  https://lownet.org/verify/"
echo "    GitHub:  https://github.com/lownetjs/lownet-toolkit"
echo ""
