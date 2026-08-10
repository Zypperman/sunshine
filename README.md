# violence

Boiler plate dotfiles for setting up github codespaces and other tools.

## How to use

switch branch to set up for a different environment (Windows, Linux, MacOS, Codespace/xxx) where xxx is a one-word association with the project them i.e. ML, Security, etc.

Set up as per [the dotfiles configuration for codespaces](https://docs.github.com/en/codespaces/setting-up-your-project-for-codespaces/adding-a-dev-container-configuration/introduction-to-dev-containers#default-configuration-selection-during-codespace-creation) or as per the new device.

just run the init script, everything else should take care of itself.

## Codespaces

This repo can initialize new codespaces two ways:

1. **Codespaces created from this repo** use
   [`.devcontainer/devcontainer.json`](.devcontainer/devcontainer.json),
   which pins the machine to at least 8 cores / 32 GB RAM / 128 GB storage
   via `hostRequirements`, declares `customizations.vscode.extensions` and
   `customizations.vscode.settings` (see below), and runs `install.sh` as
   its `postCreateCommand`.
2. **Any codespace, for any repo**, if this repo is set as your personal
   dotfiles repository under Settings > Codespaces > "Automatically install
   dotfiles" — GitHub clones this repo and runs `install.sh` automatically
   after creation. There's no devcontainer.json on someone else's repo, so
   this path leans entirely on `install.sh`.

`customizations.vscode.extensions`/`.settings` apply on connection
regardless of client (desktop app or browser) and don't depend on Settings
Sync, so they cover a gap `install.sh` can't: a `code --install-extension`
call or a container-side font install only ever reaches things running
*inside* the container, never the client rendering the UI. `settings` sets
`workbench.sideBar.location: right`, `workbench.activityBar.location: top`,
and `editor.fontFamily` / `editor.inlineSuggest.fontFamily` /
`terminal.integrated.fontFamily` to CaskaydiaCove Nerd Font — matching this
repo's actual VS Code Desktop settings. This only covers path 1, though:
path 2 (personal dotfiles on someone else's repo) has no devcontainer.json
to hook into, so the font and layout still need setting up per-client
there.

`extensions.md` stays the single source of truth for the extension list —
`install.sh` reads it directly, but `customizations.vscode.extensions` is a
static JSON copy (a declarative list can't be generated at
container-creation time), so after editing `extensions.md`, run
[`sync-extensions.sh`](sync-extensions.sh) to regenerate that array in
place in `.devcontainer/devcontainer.json`, without touching anything else
in the file (`hostRequirements`, `settings`, etc.).

Both paths run [`install.sh`](install.sh), which installs:

- the VS Code extensions listed in [`extensions.md`](extensions.md) (one
  extension id per line — edit that file, not the script; redundant with
  `customizations.vscode.extensions` for path 1, but it's what path 2 has)
- [starship](https://starship.rs), configured with this repo's
  [`starship.toml`](starship.toml) (symlinked to `~/.config/starship.toml`)
  and wired into `~/.bashrc`
- [neovim](https://neovim.io) (prebuilt binary, unpacked to `~/.local/nvim`,
  `~/.local/bin` added to `PATH`), configured with this repo's
  [`nvim/`](nvim) (symlinked to `~/.config/nvim`) — a `vscode-neovim` setup,
  paired with the `asvetliakov.vscode-neovim` extension in `extensions.md`
- `ripgrep`, `fd`, `fzf` and `build-essential` via `apt` (`fd-find`'s
  `fdfind` binary gets a `fd` symlink, since Ubuntu's package can't use
  that name)
- [`zoxide`](https://github.com/ajeetdsouza/zoxide) (official installer,
  installed to `~/.local/bin`) wired into `~/.bashrc`
- [`lazygit`](https://github.com/jesseduffield/lazygit) (latest GitHub
  release, installed to `~/.local/bin`)
- the [CaskaydiaCove Nerd Font](https://www.nerdfonts.com/font-downloads)
  (Nerd Fonts' patched Cascadia Code), installed under
  `~/.local/share/fonts` *inside the container*

  This last one only helps if something running server-side in the
  container needs the font file on disk — it does **not** make glyphs
  (starship icons, nvim fold/mode indicators, etc.) render correctly by
  itself. For path 1 that's now handled by `customizations.vscode.settings`
  above; for path 2 the font still has to be installed and configured
  (`editor.fontFamily` / `terminal.integrated.fontFamily`) on whichever
  client (desktop app, or the OS behind your browser) you're viewing it on.

## Progress

- [ ] Barebones for co
  - [x] set up base extensions
  - [x] export view/layout preferences (sidebar + activity bar position)
  - [ ] export shortcuts
- [ ] tools from MSI summit e16
- [ ] adapt tools for linux
- [ ] adapt tools for MacOS