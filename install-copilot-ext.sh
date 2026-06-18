#!/usr/bin/env bash
set -euo pipefail

cd ~

echo "Installing GitHub Copilot VSIX..."
curl -L -o github-copilot.vsix.gz \
"https://marketplace.visualstudio.com/_apis/public/gallery/publishers/GitHub/vsextensions/copilot/latest/vspackage"

gunzip -f github-copilot.vsix.gz

code-server --install-extension ~/github-copilot.vsix


echo "Installing compatible GitHub Copilot Chat VSIX..."
curl -L -o github-copilot-chat-0.33.0.vsix.gz \
"https://marketplace.visualstudio.com/_apis/public/gallery/publishers/GitHub/vsextensions/copilot-chat/0.33.0/vspackage"

gunzip -f github-copilot-chat-0.33.0.vsix.gz

code-server --install-extension ~/github-copilot-chat-0.33.0.vsix


echo "Installed extensions:"
code-server --list-extensions | grep -i copilot || true


echo "Restarting code-server..."
sudo systemctl restart code-server@ubuntu || true

echo "Done."
echo "Now reopen code-server in the browser."