#!/usr/bin/env bash
# Docker MCP lab — one-shot setup.
# Runs mcp-server-docker behind supergateway over SSE, with a tiny proxy that
# patches the schema bug so ALL tools (incl. run/create/recreate) work in VS Code.
#
# Usage:  bash docker-mcp-lab.sh
# Then point VS Code at:  http://<this-host>:8811/sse
#
# LAB ONLY: this exposes full Docker control on port 8811. Fine on an isolated
# demo network; do NOT open 8811 to the internet.

set -euo pipefail

# 1) write the schema-fix proxy (adds missing JSON-Schema "items" so VS Code stops rejecting tools)
cat > /tmp/fix_proxy.py <<'PY'
import sys, json, subprocess, threading
SERVER_CMD = ["uvx", "mcp-server-docker"]
def fix(n):
    if isinstance(n, dict):
        t = n.get("type")
        if (t == "array" or (isinstance(t, list) and "array" in t)) and "items" not in n:
            n["items"] = {}
        for v in n.values(): fix(v)
    elif isinstance(n, list):
        for i in n: fix(i)
s = subprocess.Popen(SERVER_CMD, stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True, bufsize=1)
def pump():
    for line in sys.stdin:
        s.stdin.write(line); s.stdin.flush()
threading.Thread(target=pump, daemon=True).start()
for line in s.stdout:
    line = line.rstrip("\n")
    if not line: continue
    try: m = json.loads(line)
    except Exception: print(line, flush=True); continue
    r = m.get("result")
    if isinstance(r, dict) and isinstance(r.get("tools"), list):
        for tool in r["tools"]:
            sc = tool.get("inputSchema")
            if isinstance(sc, dict): fix(sc)
    print(json.dumps(m), flush=True)
PY

# 2) (re)start the container
docker rm -f docker-mcp >/dev/null 2>&1 || true
docker run -d --name docker-mcp --restart unless-stopped \
  -p 8811:8811 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /tmp/fix_proxy.py:/fix_proxy.py:ro \
  supercorp/supergateway:uvx \
  --stdio "python3 /fix_proxy.py" \
  --port 8811

echo
echo "Docker MCP lab is up."
echo "VS Code  ->  http://$(hostname -I 2>/dev/null | awk '{print $1}'):8811/sse"
echo "Logs     ->  docker logs -f docker-mcp"