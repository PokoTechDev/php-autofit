#!/bin/sh
set -e

REPO_URL="https://raw.githubusercontent.com/PokoTechDev/php-autofit/main/phpuse.zsh"
INSTALL_DIR="$HOME/.php-autofit"
SCRIPT_PATH="$INSTALL_DIR/phpuse.zsh"
SOURCE_LINE="source \"$INSTALL_DIR/phpuse.zsh\""
ZSHRC="$HOME/.zshrc"

# Check zsh
if [ -z "$ZSH_VERSION" ] && ! command -v zsh >/dev/null 2>&1; then
  echo "Error: zsh is required." >&2
  exit 1
fi

# Check Homebrew
if ! command -v brew >/dev/null 2>&1; then
  echo "Error: Homebrew is required. Install it from https://brew.sh" >&2
  exit 1
fi

# Download
mkdir -p "$INSTALL_DIR"
echo "Downloading php-autofit..."
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$REPO_URL" -o "$SCRIPT_PATH"
elif command -v wget >/dev/null 2>&1; then
  wget -qO "$SCRIPT_PATH" "$REPO_URL"
else
  echo "Error: curl or wget is required." >&2
  exit 1
fi

# Set secure file permissions
chmod 644 "$SCRIPT_PATH"

# Backup .zshrc before modification
if [ -f "$ZSHRC" ]; then
  cp "$ZSHRC" "${ZSHRC}.bak.$(date +%s)" 2>/dev/null || true
fi

# Add to .zshrc (skip if already present)
if grep -qF "php-autofit/phpuse.zsh" "$ZSHRC" 2>/dev/null; then
  echo "php-autofit is already configured in $ZSHRC"
else
  echo "" >> "$ZSHRC"
  echo "# php-autofit: automatic PHP version switching" >> "$ZSHRC"
  echo "$SOURCE_LINE" >> "$ZSHRC"
  echo "Added source line to $ZSHRC"
fi

echo ""
echo "✓ php-autofit installed successfully!"
echo ""
echo "Run the following to activate:"
echo "  source ~/.zshrc"
