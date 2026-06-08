#!/bin/sh
set -e

APP="awpm"
INSTALL_DIR="$HOME/.local/bin"

echo "Installing AWPM (Awesome Package Manager)..."

mkdir -p "$INSTALL_DIR"

# download latest linux build (you will replace this URL later with releases)
curl -L -o "$INSTALL_DIR/awpm" \
"https://your-domain-or-github-releases/awpm-linux-amd64"

chmod +x "$INSTALL_DIR/awpm"

echo "Installed to $INSTALL_DIR/awpm"

# PATH hint
if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
    echo ""
    echo "WARNING: $INSTALL_DIR is not in PATH"
    echo "Add this to your shell config:"
    echo "export PATH=\$HOME/.local/bin:\$PATH"
fi

echo "Done."
