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

install_vscode_extensions

echo "install.sh: done"
