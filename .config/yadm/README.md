# dotfiles-v2

Personal shell/editor configuration managed with yadm. Neovim remains a separate
public repository: https://github.com/moukayz/nvim-lite.

## Fresh-machine install

Review the entrypoint before executing downloaded code:

```sh
curl -fsSL https://raw.githubusercontent.com/moukayz/dotfiles-v2/main/.config/yadm/install.sh -o /tmp/dotfiles-install.sh
bash /tmp/dotfiles-install.sh
```

Or, for the one-command form:

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/moukayz/dotfiles-v2/main/.config/yadm/install.sh)"
```

Requires Bash and curl to start, internet access, and either:
- macOS with Homebrew and Xcode Command Line Tools already installed; or
- Debian/Ubuntu Linux, ARM64 or x86_64, with root or sudo package-install access.

No GitHub login or SSH key is needed. The installer installs Git/yadm first,
inspects a public HTTPS clone, checks for conflicting config paths, then checks
out that exact snapshot and runs bootstrap. Non-default XDG_CONFIG_HOME and
symlinked/conflicting config parents are rejected rather than written through.

Existing config files are never silently overwritten. To explicitly move
conflicting files to a timestamp-independent unique backup directory first:

```sh
bash /tmp/dotfiles-install.sh --backup-conflicts
```

Add `--yes` to skip the initial setup confirmation (sudo may still prompt).
It does **not** imply permission to overwrite config files. Backups live in
`~/dotfiles-backup.XXXXXX` and remain available even if setup later fails.

## What bootstrap does

Plain `yadm bootstrap` now ensures the core setup; the old `--packages` argument
is accepted for compatibility but no longer required.

- CLI tools: Git, yadm, Fish, tmux, Delta, fzf, fd, ripgrep, bat, Lazygit, Neovim.
- SSH for the tmux SSH helper, Python for OMF's bass bridge, and the less pager.
- Tree-sitter CLI, compiler and download/build prerequisites.
- OMF and the tracked bundle/themes; verifies the `lnvim` alias loads.
- TPM plus missing declared tmux plugins, even when TPM already exists.
  Installation uses a private temporary tmux server, never your live sessions.
- Delta include in the local, untracked global Git configuration.
- Separate Neovim checkout if absent; plugin downloads, configured parser
  installation, and the profile's smoke/reload tests.

Linux installs use apt for system prerequisites and the **latest stable official
GitHub release** for missing/too-old Neovim, fzf, Tree-sitter and tmux, and missing
Delta/Lazygit. Release downloads are checked against GitHub's SHA-256 asset digest.
If an asset/checksum is unavailable, setup fails explicitly. GitHub API rate limits,
proxy restrictions, unsupported glibc versions and network failures can also stop setup.
New release compatibility is not guaranteed; the version/health checks must pass.

Minimum enforced versions: Neovim 0.12, fzf 0.60, tmux 3.5, Tree-sitter CLI 0.26.1.
Versioned Linux tools live in `~/.local/share/dotfiles-tools`, with links in
`~/.local/bin`; unrelated user-owned executables are never replaced. Fish adds
that bin directory to PATH in subsequent sessions.

Reruns preserve compatible commands, existing OMF/plugins, local Neovim edits,
and the existing yadm checkout. They do not pull/reset repositories or upgrade
every package. The installer rejects an existing yadm repository with another origin.
Repair an incomplete download/checkout before rerunning; failures name the stage.

## After installation

Start a new Fish shell, then tmux and the editor:

```sh
fish
tmux
lnvim
```

Login shell changes, terminal app, Nerd Font, language servers, Fisher, agent CLIs
(Codex/OpenCode), authentication, Ruby/Rust/NVM environments and work-specific
tools are optional/manual. `<Space>cc` needs an installed/authenticated agent;
`tmux-dev-layout` defaults to the separately installed `opencode2` command.

## Maintain

```sh
yadm status
yadm diff
yadm add .config/moukayz/custom_alias
yadm commit -m 'Update aliases'
yadm push
```

Stage explicit paths and review the staged diff. Use `yadm pull` for ordinary
updates; rerun bootstrap when dependency setup is needed. After a history rewrite,
resynchronize existing clones deliberately rather than blindly pulling.

Tracked configuration includes Fish/OMF, personal aliases, tmux and its helpers,
Ghostty, Lazygit, bat, and Delta-only Git settings. Work-specific Git configuration,
credentials, work_alias, history, caches and generated fish_variables are excluded.
The optional work_alias stays local; some shared aliases depend on other shells' helpers.
