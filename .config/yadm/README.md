# dotfiles-v2

Personal configuration managed with yadm. Files live at their normal home-directory paths.

## Install

Install yadm and authenticate with GitHub, then inspect existing files before cloning:

```sh
yadm clone --no-bootstrap git@github.com:moukayz/dotfiles-v2.git
yadm bootstrap
```

Bootstrap adds the Delta include to the untracked local `.gitconfig` and clones
the separate private `moukayz/nvim-lite` repository only if its directory is absent.
It requires GitHub SSH access. It does not update existing Neovim checkouts.

Plain bootstrap installs missing `fzf` and `fd` using Homebrew or Debian/Ubuntu
`apt-get` (using sudo when needed). For Debian's `fdfind` executable, it creates
`~/.local/bin/fd` without overwriting existing files. Keep `~/.local/bin` on your
shell PATH. Existing commands are preserved; repeated runs skip installation.
On other systems, missing picker dependencies produce an explicit error.

On Homebrew machines, `~/.config/yadm/bootstrap --packages` also installs the broader
command-line toolset. On Linux, install other tools through the OS package manager.
The Neovim profile requires Neovim 0.12 and language servers appropriate to your projects.
Ghostty and Hack Nerd Font Mono are separate terminal/font prerequisites.

Install Fish first. Bootstrap installs missing Oh My Fish at `~/.local/share/omf`
(or `$XDG_DATA_HOME/omf`) and restores packages with `omf install`. It preserves
existing installations and does not change the login shell. GitHub access is
required for missing framework/packages; failures stop bootstrap for retry.
Its package list is `.config/omf/bundle`, and the selected theme is `rider`.
Install Fisher following https://github.com/jorgebucaran/fisher and run `fisher update`
to restore `.config/fish/fish_plugins` (currently Fisher itself).
The Fish config also references optional local Rust, Ruby, NVM and CLI installations;
adjust machine-specific paths as needed before using it on another host.
Tmux installs TPM and declared plugins when first loaded; network access is required.

## Contents

- Fish configuration, Oh My Fish initialization, package/theme lists and custom functions.
- Shared aliases in `.config/moukayz/custom_alias`, sourced by Oh My Fish.
- Tmux config, themes, and the `tmux-ssh-split` helper used by prefix + S.
- Ghostty, Lazygit, and bat preferences.
- Delta-only Git configuration in `.config/git/delta.gitconfig`.

The shared alias definitions are preserved as-is; later duplicate definitions win.
Some aliases rely on Zsh/Oh My Zsh helpers. For Zsh, add this to your local `.zshrc`:

```sh
source ~/.config/moukayz/custom_alias
```

Work-specific `.gitconfig`, `.config/git/ignore`, shell profiles, `work_alias`,
credentials, history, `fish_variables`, caches, installed plugins and backups are excluded.
The optional `work_alias` remains local. `nvim-lite` is independently versioned.
The existing local Delta definitions may remain in `.gitconfig`; the added include
provides the shared definitions without uploading or removing work settings.

## Maintain

```sh
yadm status
yadm diff
yadm add .config/moukayz/custom_alias
yadm commit -m 'Update aliases'
yadm push
```

Stage explicit paths. Review the staged diff before committing. Use `yadm pull`
on another machine; rerun bootstrap only when its setup actions are needed.
