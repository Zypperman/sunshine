#!/usr/bin/env bash
# Regenerates the customizations.vscode.extensions array in
# .devcontainer/devcontainer.json from extensions.md, in place, without
# touching anything else in the file (hostRequirements, settings, etc).
#
# Run this after editing extensions.md so codespaces created directly from
# this repo (which read devcontainer.json's extensions list, not
# install.sh's) stay in sync with the personal-dotfiles install path.
set -uo pipefail

dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
extensions_file="$dotfiles_dir/extensions.md"
devcontainer_file="$dotfiles_dir/.devcontainer/devcontainer.json"

awk -v mdfile="$extensions_file" '
BEGIN {
  n = 0
  while ((getline line < mdfile) > 0) {
    gsub(/^[ \t]+|[ \t]+$/, "", line)
    if (line == "" || line ~ /^#/) continue
    n++
    ext[n] = line
  }
  close(mdfile)
}
{
  trimmed = $0
  gsub(/^[ \t]+|[ \t]+$/, "", trimmed)

  if (state == 0 && trimmed == "\"extensions\": [") {
    print $0
    for (i = 1; i <= n; i++) {
      comma = (i < n) ? "," : ""
      printf("        \"%s\"%s\n", ext[i], comma)
    }
    state = 1
    next
  }

  if (state == 1) {
    if (trimmed == "],") {
      print $0
      state = 2
    }
    next
  }

  print $0
}
END {
  print "sync-extensions.sh: wrote " n " extensions into " target > "/dev/stderr"
}
' target="$devcontainer_file" "$devcontainer_file" > "$devcontainer_file.tmp"

mv "$devcontainer_file.tmp" "$devcontainer_file"
