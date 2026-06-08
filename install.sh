#!/bin/sh
set -e

URL="https://raw.githubusercontent.com/coolguy565/awpm/main/awpm"

echo "AWPM installer"

# choose downloader
DOWNLOADER=""

if command -v curl >/dev/null 2>&1; then
    HAS_CURL=1
else
    HAS_CURL=0
fi

if command -v wget >/dev/null 2>&1; then
    HAS_WGET=1
else
    HAS_WGET=0
fi

if [ "$HAS_CURL" -eq 1 ] && [ "$HAS_WGET" -eq 1 ]; then
    echo "Both curl and wget are available."
    echo "Choose download method:"
    echo "  1) curl"
    echo "  2) wget (no-check-certificate)"
    printf "> "
    read choice

    if [ "$choice" = "2" ]; then
        DOWNLOADER="wget"
    else
        DOWNLOADER="curl"
    fi

elif [ "$HAS_CURL" -eq 1 ]; then
    DOWNLOADER="curl"
elif [ "$HAS_WGET" -eq 1 ]; then
    DOWNLOADER="wget"
else
    echo "Error: neither curl nor wget found"
    exit 1
fi

echo "Using: $DOWNLOADER"

mkdir -p "$HOME/.local/bin"

if [ "$DOWNLOADER" = "curl" ]; then
    curl -L -o awpm "$URL"
else
    wget --no-check-certificate -q -L -O awpm "$URL"
fi

chmod +x awpm
mv awpm "$HOME/.local/bin/"

echo "Installed AWPM to ~/.local/bin/awpm"

echo "Make sure ~/.local/bin is in your PATH"
