# violence

Boiler plate dotfiles for setting up github codespaces and other tools.

## How to use

switch branch to set up for a different environment (Windows, Linux, MacOS, Codespace/xxx) where xxx is a one-word association with the project them i.e. ML, Security, etc.

Set up as per [the dotfiles configuration for codespaces](https://docs.github.com/en/codespaces/setting-up-your-project-for-codespaces/adding-a-dev-container-configuration/introduction-to-dev-containers#default-configuration-selection-during-codespace-creation) or as per the new device.

just run the init script, everything else should take care of itself.

## Codespaces

This repo can initialize new codespaces two ways, and both run
[`install.sh`](install.sh), which installs:

- the VS Code extensions listed in [`extensions.md`](extensions.md) (one
  extension id per line — edit that file, not the script)
- [starship](https://starship.rs), configured with this repo's
  [`starship.toml`](starship.toml) (symlinked to `~/.config/starship.toml`)
  and wired into `~/.bashrc`

1. **Codespaces created from this repo** use
   [`.devcontainer/devcontainer.json`](.devcontainer/devcontainer.json),
   which pins the machine to at least 4 cores / 16 GB RAM / 64 GB storage
   via `hostRequirements`, and runs `install.sh` as its `postCreateCommand`.
2. **Any codespace, for any repo**, if this repo is set as your personal
   dotfiles repository under Settings > Codespaces > "Automatically install
   dotfiles" — GitHub clones this repo and runs `install.sh` automatically
   after creation.

## Progress

- [ ] Barebones for co
  - [x] set up base extensions
  - [ ] export settings, shortcuts and viewport preferences
- [ ] tools from MSI summit e16
- [ ] adapt tools for linux
- [ ] adapt tools for MacOS