#!/bin/sh
set -e

URL="https://raw.githubusercontent.com/coolguy565/awpm/main/awpm"
INSTALL_DIR="$HOME/.local/bin"

echo "================================"
echo " AWPM Installer"
echo "================================"
echo ""

mkdir -p "$INSTALL_DIR"

DOWNLOADER=""

while [ -z "$DOWNLOADER" ]; do
    echo "Choose download method:"
    echo "  1) curl"
    echo "  2) wget"
    echo "  3) auto (recommended)"
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
        3)
            if command -v curl >/dev/null 2>&1; then
                DOWNLOADER="curl"
            elif command -v wget >/dev/null 2>&1; then
                DOWNLOADER="wget"
            else
                echo "No supported downloader found (curl or wget required)."
                echo ""
            fi
            ;;
        *)
            echo "Invalid option. Try again."
            echo ""
            ;;
    esac
done

echo ""
echo "Using: $DOWNLOADER"
echo ""

TMPFILE="$INSTALL_DIR/awpm.tmp"

if [ "$DOWNLOADER" = "curl" ]; then
    curl -L -o "$TMPFILE" "$URL"
else
    wget --no-check-certificate -q -L -O "$TMPFILE" "$URL"
fi

chmod +x "$TMPFILE"
mv "$TMPFILE" "$INSTALL_DIR/awpm"

echo ""
echo "Installed AWPM to:"
echo "  $INSTALL_DIR/awpm"
echo ""

# PATH check
case ":$PATH:" in
    *":$INSTALL_DIR:"*)
        echo "PATH is already configured."
        ;;
    *)
        echo "WARNING: $INSTALL_DIR is not in PATH"
        echo ""
        echo "Add this to your shell config:"
        echo ""
        echo "export PATH=\$HOME/.local/bin:\$PATH"
        ;;
esac

echo ""
echo "Done."
