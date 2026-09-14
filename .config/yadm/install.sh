#!/usr/bin/env bash
# Public entrypoint; configuration and dependency setup live in bootstrap.
set -euo pipefail
trap 'echo "Installer failed at line $LINENO; fix the error and rerun." >&2' ERR
yes=false
backup=false
for arg in "$@"; do
    case "$arg" in
        --yes) yes=true ;;
        --backup-conflicts) backup=true ;;
        --help) echo 'Usage: install.sh [--yes] [--backup-conflicts]'; exit 0 ;;
        *) echo "Unknown option: $arg" >&2; exit 1 ;;
    esac
done
[[ "${XDG_CONFIG_HOME:-$HOME/.config}" == "$HOME/.config" ]] || {
    echo 'This profile requires XDG_CONFIG_HOME unset or ~/.config.' >&2; exit 1;
}
export PATH="$HOME/.local/bin:$PATH"
unset GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR GIT_INDEX_FILE
export GIT_TERMINAL_PROMPT=0
if ! $yes; then
    read -r -p 'Install dependencies and personal dotfiles? [y/N] ' answer </dev/tty
    [[ "$answer" == y || "$answer" == Y ]] || exit 1
fi
case "$(uname -s)" in
    Darwin)
        for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
            if [[ -x "$brew_bin" ]]; then eval "$("$brew_bin" shellenv)"; break; fi
        done
        command -v brew >/dev/null || { echo 'Install Homebrew from https://brew.sh first.' >&2; exit 1; }
        brew install git yadm
        ;;
    Linux)
        command -v apt-get >/dev/null || { echo 'Linux setup requires Debian/Ubuntu apt-get.' >&2; exit 1; }
        privilege=()
        if [[ $(id -u) != 0 ]]; then command -v sudo >/dev/null; privilege=(sudo); fi
        packages=()
        for package in git yadm curl ca-certificates; do
            [[ $(dpkg-query -W -f='${Status}' "$package" 2>/dev/null || true) == 'install ok installed' ]] || packages+=("$package")
        done
        if ((${#packages[@]})); then
            "${privilege[@]}" apt-get -o Acquire::Retries=2 -o Acquire::http::Timeout=30 update
            "${privilege[@]}" env DEBIAN_FRONTEND=noninteractive apt-get -o Acquire::Retries=2 -o Acquire::http::Timeout=30 install -y --no-install-recommends "${packages[@]}"
        fi
        ;;
    *) echo 'Supported systems: macOS/Homebrew, Debian/Ubuntu.' >&2; exit 1 ;;
esac
repo=https://github.com/moukayz/dotfiles-v2.git
if [[ -d "$(yadm introspect repo)" ]]; then
    case "$(git --git-dir="$(yadm introspect repo)" config --get remote.origin.url)" in
        https://github.com/moukayz/dotfiles-v2.git|git@github.com:moukayz/dotfiles-v2.git) ;;
        *) echo 'Existing yadm origin differs; refusing to modify it.' >&2; exit 1 ;;
    esac
    echo 'Existing yadm checkout preserved; no automatic pull/reset.'
else
    stage=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-install.XXXXXX")
    trap 'rm -rf -- "$stage"' EXIT
    git clone --depth 1 "$repo" "$stage/repo"
    conflicts=()
    while IFS= read -r -d '' file; do
        parent=$(dirname "$HOME/$file")
        while [[ "$parent" != "$HOME" ]]; do
            if [[ -L "$parent" || ( -e "$parent" && ! -d "$parent" ) ]]; then
                echo "Conflicting parent: $parent; resolve manually." >&2; exit 1
            fi
            parent=$(dirname "$parent")
        done
        if [[ -e "$HOME/$file" || -L "$HOME/$file" ]]; then conflicts+=("$file"); fi
    done < <(git -C "$stage/repo" ls-files -z)
    if ((${#conflicts[@]})); then
        printf 'Existing config: %s\n' "${conflicts[@]}"
        if ! $backup; then
            echo 'Configs untouched. Use --backup-conflicts to back up and replace these files.' >&2; exit 1
        fi
        backup_dir=$(mktemp -d "$HOME/dotfiles-backup.XXXXXX")
        for file in "${conflicts[@]}"; do
            mkdir -p "$backup_dir/$(dirname "$file")"
            mv -- "$HOME/$file" "$backup_dir/$file"
        done
        echo "Backup retained at $backup_dir, including if setup fails."
    fi
    # Use the inspected snapshot, not a potentially newer remote checkout.
    yadm clone --no-bootstrap "$stage/repo"
    yadm remote set-url origin "$repo"
fi
bash "$HOME/.config/yadm/bootstrap"
