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
local_bin="$HOME/.local/bin"
apt_updated=0

mkdir -p "$local_bin"
export PATH="$local_bin:$PATH"

# So tools installed to ~/.local/bin this run are still on PATH next login.
ensure_local_bin_on_path() {
  local bashrc="$HOME/.bashrc"
  if [ ! -f "$bashrc" ] || ! grep -qF '.local/bin' "$bashrc"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$bashrc"
    echo "install.sh: added ~/.local/bin to PATH in $bashrc"
  fi
}

# apt lists are stripped from devcontainer base images to save space, so
# `apt-get install` needs an `update` first -- but only once per run.
apt_install() {
  if [ "$apt_updated" -eq 0 ]; then
    sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq
    apt_updated=1
  fi
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$@"
}

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

    mkdir -p "$HOME/.local"
    tar -C "$HOME/.local" -xzf "$tmp/nvim.tar.gz"
    rm -rf "$HOME/.local/nvim"
    mv "$HOME/.local/nvim-linux-x86_64" "$HOME/.local/nvim"
    ln -sf "$HOME/.local/nvim/bin/nvim" "$local_bin/nvim"
    rm -rf "$tmp"
    ensure_local_bin_on_path
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

install_cli_tools() {
  local missing=()
  command -v rg >/dev/null 2>&1 || missing+=("ripgrep")
  { command -v fd >/dev/null 2>&1 || command -v fdfind >/dev/null 2>&1; } || missing+=("fd-find")
  command -v fzf >/dev/null 2>&1 || missing+=("fzf")
  command -v gcc >/dev/null 2>&1 || missing+=("build-essential")

  if [ "${#missing[@]}" -gt 0 ]; then
    echo "install.sh: installing via apt: ${missing[*]}"
    apt_install "${missing[@]}" || echo "install.sh: apt install failed for: ${missing[*]}"
  fi

  # Ubuntu's fd-find package ships the binary as 'fdfind' (name clash with
  # an unrelated 'fd' package), so it needs its own fd symlink on PATH.
  if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
    ln -sf "$(command -v fdfind)" "$local_bin/fd"
  fi
}

install_zoxide() {
  if command -v zoxide >/dev/null 2>&1; then
    echo "install.sh: zoxide already installed, skipping"
  else
    echo "install.sh: installing zoxide"
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh \
      | sh -s -- --bin-dir "$local_bin" || echo "install.sh: zoxide install failed"
  fi

  local bashrc="$HOME/.bashrc"
  if [ ! -f "$bashrc" ] || ! grep -qF "zoxide init bash" "$bashrc"; then
    echo 'eval "$(zoxide init bash)"' >> "$bashrc"
    echo "install.sh: added zoxide init to $bashrc"
  fi
}

install_lazygit() {
  if command -v lazygit >/dev/null 2>&1; then
    echo "install.sh: lazygit already installed, skipping"
    return 0
  fi

  echo "install.sh: installing lazygit"
  local version
  version="$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
    | grep -Po '"tag_name":\s*"v\K[^"]+')"
  if [ -z "$version" ]; then
    echo "install.sh: could not resolve latest lazygit version, skipping"
    return 0
  fi

  local tmp
  tmp="$(mktemp -d)"
  if ! curl -fsSL -o "$tmp/lazygit.tar.gz" \
      "https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_Linux_x86_64.tar.gz"; then
    echo "install.sh: lazygit download failed"
    rm -rf "$tmp"
    return 0
  fi

  tar -C "$tmp" -xzf "$tmp/lazygit.tar.gz" lazygit
  mv "$tmp/lazygit" "$local_bin/lazygit"
  chmod +x "$local_bin/lazygit"
  rm -rf "$tmp"
}

install_nerd_font() {
  local font_dir="$HOME/.local/share/fonts/CaskaydiaCoveNerdFont"
  if [ -d "$font_dir" ] && [ -n "$(ls -A "$font_dir" 2>/dev/null)" ]; then
    echo "install.sh: CaskaydiaCove Nerd Font already installed, skipping"
    return 0
  fi

  if ! command -v unzip >/dev/null 2>&1; then
    apt_install unzip || { echo "install.sh: unzip unavailable, skipping nerd font"; return 0; }
  fi

  echo "install.sh: installing CaskaydiaCove Nerd Font"
  local tmp
  tmp="$(mktemp -d)"
  if ! curl -fsSL -o "$tmp/font.zip" \
      "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip"; then
    echo "install.sh: nerd font download failed"
    rm -rf "$tmp"
    return 0
  fi

  mkdir -p "$font_dir"
  unzip -qo "$tmp/font.zip" -d "$font_dir"
  rm -rf "$tmp"
  command -v fc-cache >/dev/null 2>&1 && fc-cache -f "$font_dir" >/dev/null 2>&1

  echo "install.sh: NOTE - this only installs the font inside the container." \
       "Codespaces renders VS Code's UI (editor, terminal) on the client," \
       "so CaskaydiaCove Nerd Font must also be installed on the machine" \
       "running VS Code (desktop app or the OS behind your browser)."
}

install_vscode_extensions
install_starship
install_neovim
install_cli_tools
install_zoxide
install_lazygit
install_nerd_font

echo "install.sh: done"
