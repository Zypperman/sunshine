# ==============================================================================
# Sunshine dotfiles, as a Docker image -- a drop-in replacement for GitHub's
# "personal dotfiles" auto-install (Settings > Codespaces > Automatically
# install dotfiles) for accounts/orgs where that feature is disabled by
# policy. It bakes in everything install.sh installs: starship, neovim +
# this repo's config, ripgrep/fd/fzf/build-essential, zoxide, lazygit, the
# CaskaydiaCove Nerd Font, podman + podman-compose, plus this whole repo at
# ~/dotfiles.
#
# HOW TO USE -- a dedicated repo that IS your dotfiles, instead of a
# per-account setting that applies them
#   1. Push this whole repo -- this Dockerfile plus install.sh,
#      extensions.md, starship.toml, nvim/, etc. -- to a new repository
#      (e.g. under a personal GitHub account not covered by the policy that
#      disabled dotfiles). The build COPYs the whole repo in, so all of it
#      has to travel together, not just this file.
#   2. Open a Codespace on THAT repo (github.com: Code > Codespaces >
#      Create codespace), or locally, VS Code's "Dev Containers: Reopen in
#      Container". No devcontainer.json is required: both GitHub Codespaces
#      and the Dev Containers extension auto-detect and build a root-level
#      Dockerfile when a repo has one and no devcontainer.json. If your
#      setup doesn't pick it up automatically, add a one-line
#      .devcontainer/devcontainer.json containing
#      { "build": { "context": "..", "dockerfile": "../Dockerfile" } }.
#      Both paths are relative to the devcontainer.json file itself, not to
#      each other, so both need the "../" (this Dockerfile lives at the repo
#      root, one level up from .devcontainer/).
#   3. That's the whole setup -- the container comes up with every tool
#      above already installed, and VS Code extensions install themselves
#      in the background the moment a client attaches (see NOTE ON
#      EXTENSIONS below).
#
#   Caveat vs. real dotfiles: the old feature applied to a codespace created
#   on ANY repo you opened. This only applies to codespaces created on THIS
#   repo. To work on some other project with the same tooling, either do
#   that work inside this repo's codespace (clone/pull it in over the
#   terminal), or point that project's own devcontainer.json at this image
#   as a base -- see below.
#
# ALSO USABLE AS A BASE IMAGE for an individual project's own devcontainer,
# if you'd rather keep that project in its own codespace. In the project's
# .devcontainer/devcontainer.json, "context" and "dockerfile" are each
# resolved relative to that devcontainer.json file, not to each other -- so
# if this repo is vendored at, say, "<project-root>/self_config", both paths
# need that prefix:
#   { "build": { "context": "../self_config", "dockerfile": "../self_config/Dockerfile" } }
#   or, once built and pushed to a registry: { "image": "your-registry/sunshine-dev:latest" }
#   In this mode, extensions install more reliably by also copying the
#   "customizations.vscode.extensions" array from this repo's
#   .devcontainer/devcontainer.json into that project's devcontainer.json,
#   rather than relying on the background hook below.
#
# RUN IT WITHOUT VS CODE AT ALL, e.g. to poke around:
#   docker build -t sunshine-dev .
#   docker run -it --rm -v "$PWD":/workspaces/project -w /workspaces/project sunshine-dev
#
# NOTE ON EXTENSIONS
#   VS Code / Codespaces only installs extensions once its "code" CLI is
#   live-connected to a running VS Code Server, and that connection can't
#   exist during `docker build` -- so extensions cannot be baked into image
#   layers (see the comment above install_vscode_extensions() in
#   install.sh). A plain auto-detected Dockerfile also has no
#   postAttachCommand to hook into (that's a devcontainer.json-only field),
#   so instead this image wires `install.sh --extensions-only` into
#   .bashrc, backgrounded, so it runs the moment a client actually attaches
#   and opens a shell. It re-runs (cheaply -- install.sh already skips
#   anything already present) on every new shell, so a transient failure on
#   first attach self-heals on the next terminal you open.
#
# REBUILDING
#   Everything here is baked in at build time via COPY, so after editing
#   install.sh, extensions.md, starship.toml, or nvim/, rebuild -- locally
#   with `docker build`, or on github.com via "Codespaces: Rebuild
#   Container" -- to pick up the change. Nothing here re-reads a live git
#   checkout on its own.
# ==============================================================================

FROM mcr.microsoft.com/devcontainers/base:ubuntu

USER vscode

COPY --chown=vscode:vscode . /home/vscode/dotfiles
WORKDIR /home/vscode/dotfiles

# Everything installable without a live VS Code Server connection -- see the
# NOTE ON EXTENSIONS above for why extensions are handled separately.
RUN bash install.sh --skip-extensions

# Best-effort: pick up VS Code extensions the first time a shell opens after
# a real client (VS Code Desktop or Codespaces) has attached and its "code"
# CLI is live. install.sh's install loop skips anything already installed,
# so re-running this on every new shell is cheap once it has succeeded once.
RUN printf '\n# sunshine dotfiles: install VS Code extensions once a client is attached\nnohup /home/vscode/dotfiles/install.sh --extensions-only >/home/vscode/.dotfiles-extensions.log 2>&1 &\ndisown\n' >> /home/vscode/.bashrc

WORKDIR /home/vscode
