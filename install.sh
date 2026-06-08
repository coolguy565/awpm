#!/bin/sh
set -e

URL="https://raw.githubusercontent.com/coolguy565/awpm/main/awpm"
INSTALL_DIR="$HOME/.local/bin"

echo "================================"
echo " AWPM Installer"
echo "================================"
echo ""

DOWNLOADER="auto"

# -------------------------
# Parse flags
# -------------------------
while [ $# -gt 0 ]; do
    case "$1" in
        -d)
            DOWNLOADER="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            shift
            ;;
    esac
done

# -------------------------
# Validate downloader
# -------------------------
case "$DOWNLOADER" in
    curl|wget|auto) ;;
    *)
        echo "Invalid downloader: $DOWNLOADER"
        DOWNLOADER="auto"
        ;;
esac

# -------------------------
# Auto-detect
# -------------------------
if [ "$DOWNLOADER" = "auto" ]; then
    if command -v curl >/dev/null 2>&1; then
        DOWNLOADER="curl"
    elif command -v wget >/dev/null 2>&1; then
        DOWNLOADER="wget"
    else
        echo "Error: neither curl nor wget is installed."
        echo "Install one of them and retry."
        exit 1
    fi
fi

echo "Using downloader: $DOWNLOADER"
echo ""

mkdir -p "$INSTALL_DIR"
TMPFILE="$INSTALL_DIR/awpm.tmp"

# -------------------------
# Download
# -------------------------
if [ "$DOWNLOADER" = "curl" ]; then
    curl -fsSL -o "$TMPFILE" "$URL"
else
    wget --no-check-certificate -q -L -O "$TMPFILE" "$URL"
fi

# -------------------------
# Install
# -------------------------
chmod +x "$TMPFILE"
mv "$TMPFILE" "$INSTALL_DIR/awpm"

echo ""
echo "Installed AWPM to:"
echo "  $INSTALL_DIR/awpm"
echo ""

# -------------------------
# PATH check
# -------------------------
case ":$PATH:" in
    *":$INSTALL_DIR:"*)
        echo "PATH is already set."
        ;;
    *)
        echo "WARNING: $INSTALL_DIR is not in PATH"
        echo ""
        echo "Add this to your shell config:"
        echo "export PATH=\$HOME/.local/bin:\$PATH"
        ;;
esac

echo ""
echo "Done."
