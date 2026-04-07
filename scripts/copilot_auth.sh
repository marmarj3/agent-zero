#!/bin/bash
# GitHub Copilot Authentication Setup for Agent Zero
#
# This script authenticates with GitHub Copilot via LiteLLM's OAuth device flow,
# then stores the resulting token files in usr/.litellm_copilot/ so Docker can
# access them via the volume mount, and sets GITHUB_COPILOT_TOKEN_DIR in usr/.env.
#
# Usage: bash scripts/copilot_auth.sh
# Run this ONCE from the project root before starting the Docker container.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TOKEN_DIR="$PROJECT_DIR/usr/.litellm_copilot"
ENV_FILE="$PROJECT_DIR/usr/.env"
VENV_DIR="$PROJECT_DIR/tmp/.litellm-auth-venv"

# Always clean up the temp venv on exit, even on failure
trap 'rm -rf "$VENV_DIR"' EXIT

echo "=== GitHub Copilot Authentication Setup for Agent Zero ==="
echo ""

# Create temp venv with litellm for the auth flow
echo "Creating a temporary Python environment..."
python3 -m venv "$VENV_DIR"
"$VENV_DIR/bin/pip" install litellm --quiet --disable-pip-version-check

echo ""
echo "Starting GitHub OAuth device flow..."
echo "When prompted, open the URL in your browser and enter the device code."
echo ""

# Trigger the device flow auth - litellm stores tokens at ~/.config/litellm/github_copilot/
"$VENV_DIR/bin/python3" -c "
import litellm, sys, os
try:
    litellm.completion(
        model='github_copilot/gpt-4o',
        messages=[{'role': 'user', 'content': 'Hello'}],
        max_tokens=5
    )
    print('Authentication successful.')
except Exception as e:
    msg = str(e)
    if any(w in msg.lower() for w in ('rate', 'quota', '429', 'token', 'expire')):
        print('Authentication likely succeeded (received API response). ' + msg)
    else:
        print('Error: ' + msg, file=sys.stderr)
        sys.exit(1)
"

# Locate where litellm stored the token files
DEFAULT_TOKEN_DIR="$HOME/.config/litellm/github_copilot"

echo ""
echo "Copying token files to usr/.litellm_copilot/ ..."
mkdir -p "$TOKEN_DIR"
chmod 700 "$TOKEN_DIR"

if [ -d "$DEFAULT_TOKEN_DIR" ] && [ "$(ls -A "$DEFAULT_TOKEN_DIR" 2>/dev/null)" ]; then
    cp -f "$DEFAULT_TOKEN_DIR"/* "$TOKEN_DIR/"
    # Restrict token files to owner-only (no group/world read)
    chmod 600 "$TOKEN_DIR"/*
    echo "Tokens copied from $DEFAULT_TOKEN_DIR"
else
    echo "Warning: Expected token directory not found at $DEFAULT_TOKEN_DIR"
    echo "         LiteLLM may use a different path. Check: $DEFAULT_TOKEN_DIR"
    echo "         If tokens are elsewhere, copy them manually to: $TOKEN_DIR"
fi

# Update usr/.env with the token dir path (Docker container path /a0/usr/.litellm_copilot)
mkdir -p "$(dirname "$ENV_FILE")"
if [ ! -f "$ENV_FILE" ]; then
    touch "$ENV_FILE"
fi

DOCKER_TOKEN_DIR="/a0/usr/.litellm_copilot"
if grep -q "^GITHUB_COPILOT_TOKEN_DIR=" "$ENV_FILE" 2>/dev/null; then
    # Update existing line (BSD/macOS compatible)
    sed -i '' "s|^GITHUB_COPILOT_TOKEN_DIR=.*|GITHUB_COPILOT_TOKEN_DIR=$DOCKER_TOKEN_DIR|" "$ENV_FILE"
else
    printf "\nGITHUB_COPILOT_TOKEN_DIR=%s\n" "$DOCKER_TOKEN_DIR" >> "$ENV_FILE"
fi
echo "GITHUB_COPILOT_TOKEN_DIR set in usr/.env → $DOCKER_TOKEN_DIR"


echo ""
echo "=== Setup complete ==="
echo ""
echo "Next steps:"
echo "  1. Rebuild the Docker image:  docker build -f DockerfileLocal -t agent-zero-local ."
echo "  2. Run with usr/ volume mount:"
echo "       docker run -p 50001:80 -v \"\$(pwd)/usr:/a0/usr\" agent-zero-local"
echo "  3. Open Agent Zero UI → Settings → Models"
echo "       Chat Provider : GitHub Copilot"
echo "       Chat Model    : gpt-4o  (or gpt-4, claude-3.5-sonnet, etc.)"
echo ""
