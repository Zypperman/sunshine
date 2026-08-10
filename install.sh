#!/usr/bin/env bash
# Bootstrap script for GitHub Codespaces.
#
# Runs in two situations:
#   1. As the postCreateCommand for the devcontainer defined in this repo
#      (.devcontainer/devcontainer.json), when a codespace is created from
#      this repo directly.
#   2. Automatically by GitHub, after cloning this repo, when it is set as
#      your personal dotfiles repository (Settings > Codespaces >
#      "Automatically install dotfiles"). In that case it runs inside every
#      new codespace regardless of which repo it was created from.
#
# See: https://docs.github.com/en/codespaces/setting-up-your-project-for-codespaces/personalizing-github-codespaces-for-your-account#dotfiles
set -uo pipefail

dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
extensions_file="$dotfiles_dir/extensions.md"
starship_config_file="$dotfiles_dir/starship.toml"
nvim_config_dir="$dotfiles_dir/nvim"

install_vscode_extensions() {
  local code_bin=""
  for candidate in code code-insiders; do
    if command -v "$candidate" >/dev/null 2>&1; then
      code_bin="$candidate"
      break
    fi
  done

  if [ -z "$code_bin" ]; then
    echo "install.sh: no 'code' CLI on PATH, skipping VS Code extension install"
    return 0
  fi

  if [ ! -f "$extensions_file" ]; then
    echo "install.sh: $extensions_file not found, skipping VS Code extension install"
    return 0
  fi

  echo "install.sh: installing VS Code extensions with '$code_bin'"
  local failed=()
  while IFS= read -r ext || [ -n "$ext" ]; do
    ext="$(echo "$ext" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    [ -z "$ext" ] && continue
    case "$ext" in \#*) continue ;; esac
    echo "  - $ext"
    "$code_bin" --install-extension "$ext" --force >/dev/null 2>&1 || failed+=("$ext")
  done < "$extensions_file"

  if [ "${#failed[@]}" -gt 0 ]; then
    echo "install.sh: failed to install ${#failed[@]} extension(s): ${failed[*]}"
  fi
}

install_starship() {
  if command -v starship >/dev/null 2>&1; then
    echo "install.sh: starship already installed, skipping"
  else
    echo "install.sh: installing starship"
    if ! curl -sS https://starship.rs/install.sh | sh -s -- -y; then
      echo "install.sh: starship install failed, skipping config/init"
      return 0
    fi
  fi

  if [ -f "$starship_config_file" ]; then
    mkdir -p "$HOME/.config"
    ln -sf "$starship_config_file" "$HOME/.config/starship.toml"
    echo "install.sh: linked starship.toml"
  else
    echo "install.sh: $starship_config_file not found, skipping starship config"
  fi

  local init_line='eval "$(starship init bash)"'
  local bashrc="$HOME/.bashrc"
  if [ -f "$bashrc" ] && grep -qF "starship init bash" "$bashrc"; then
    return 0
  fi
  echo "$init_line" >> "$bashrc"
  echo "install.sh: added starship init to $bashrc"
}

install_neovim() {
  if command -v nvim >/dev/null 2>&1; then
    echo "install.sh: nvim already installed, skipping"
  else
    echo "install.sh: installing neovim"
    local tmp
    tmp="$(mktemp -d)"
    if ! curl -fsSL -o "$tmp/nvim.tar.gz" \
        https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz; then
      echo "install.sh: neovim download failed, skipping config"
      rm -rf "$tmp"
      return 0
    fi

    mkdir -p "$HOME/.local" "$HOME/.local/bin"
    tar -C "$HOME/.local" -xzf "$tmp/nvim.tar.gz"
    rm -rf "$HOME/.local/nvim"
    mv "$HOME/.local/nvim-linux-x86_64" "$HOME/.local/nvim"
    ln -sf "$HOME/.local/nvim/bin/nvim" "$HOME/.local/bin/nvim"
    rm -rf "$tmp"

    local bashrc="$HOME/.bashrc"
    if [ ! -f "$bashrc" ] || ! grep -qF '$HOME/.local/bin' "$bashrc"; then
      echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$bashrc"
      echo "install.sh: added ~/.local/bin to PATH in $bashrc"
    fi
    export PATH="$HOME/.local/bin:$PATH"
  fi

  if [ ! -d "$nvim_config_dir" ]; then
    echo "install.sh: $nvim_config_dir not found, skipping neovim config"
    return 0
  fi

  mkdir -p "$HOME/.config"
  if [ -e "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
    mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak.$(date +%s)"
    echo "install.sh: backed up existing ~/.config/nvim"
  fi
  ln -sfn "$nvim_config_dir" "$HOME/.config/nvim"
  echo "install.sh: linked nvim config"
}

install_vscode_extensions
install_starship
install_neovim

echo "install.sh: done"
