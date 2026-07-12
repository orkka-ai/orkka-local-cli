#!/usr/bin/env bash
# Orkka Local installer (Linux/macOS) — downloads the latest orkka-local binary and puts
# it on your PATH. Usage:
#   curl -fsSL https://raw.githubusercontent.com/ruanpelissoli/orkka-local-cli/main/install.sh | bash
# Then:
#   orkka-local start

set -euo pipefail

repo="ruanpelissoli/orkka-local-cli"
install_dir="$HOME/.orkka/bin"

case "$(uname -s)-$(uname -m)" in
  Linux-x86_64)          rid="linux-x64" ;;
  Linux-aarch64)         rid="linux-arm64" ;;
  Darwin-arm64)          rid="osx-arm64" ;;
  Darwin-x86_64)         rid="osx-x64" ;;
  *) echo "Unsupported platform: $(uname -s) $(uname -m)" >&2; exit 1 ;;
esac

echo "Resolving the latest Orkka Local release..."
tag="$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" | grep -o '"tag_name": *"[^"]*"' | cut -d'"' -f4)"
[[ -n "$tag" ]] || { echo "Could not resolve the latest release of $repo." >&2; exit 1; }

echo "Downloading $tag ($rid)..."
mkdir -p "$install_dir"
curl -fsSL "https://github.com/$repo/releases/download/$tag/orkka-local-$rid.tar.gz" \
  | tar -xz -C "$install_dir"
chmod +x "$install_dir/orkka-local"

# Put the install dir on PATH if it isn't already.
if ! command -v orkka-local >/dev/null 2>&1; then
  shell_rc="$HOME/.bashrc"
  [[ "${SHELL:-}" == */zsh ]] && shell_rc="$HOME/.zshrc"
  if ! grep -q '.orkka/bin' "$shell_rc" 2>/dev/null; then
    echo 'export PATH="$HOME/.orkka/bin:$PATH"' >> "$shell_rc"
    echo "Added $install_dir to PATH via $shell_rc (open a new terminal or 'source' it)."
  fi
fi

echo ""
echo "Orkka Local $tag installed."
echo "Prerequisites: Docker running, and the Claude CLI logged in ('claude /login')."
echo "Start everything with:  orkka-local start"
