#!/bin/sh
set -e

URL="https://raw.githubusercontent.com/coolguy565/awpm/main/awpm"

echo "AWPM installer"

# choose downloader
DOWNLOADER=""

while [ -z "$DOWNLOADER" ]; do
    echo "Choose download method:"
    echo "  1) curl"
    echo "  2) wget"
    printf "> "
    read choice

    case "$choice" in
        1)
            if command -v curl >/dev/null 2>&1; then
                DOWNLOADER="curl"
            else
                echo "curl is not installed on this system."
                echo ""
            fi
            ;;
        2)
            if command -v wget >/dev/null 2>&1; then
                DOWNLOADER="wget"
            else
                echo "wget is not installed on this system."
                echo ""
            fi
            ;;
        *)
            echo "Invalid option. Try again."
            echo ""
            ;;
    esac
done

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
