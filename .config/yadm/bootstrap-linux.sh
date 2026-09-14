# Sourced by bootstrap. Download official latest stable releases into ~/.local.
# shellcheck disable=SC2154
command -v apt-get >/dev/null || { echo 'Linux setup requires Debian/Ubuntu apt-get.' >&2; exit 1; }
case "$(uname -m)" in
    aarch64|arm64) arch=arm64; rust_arch=aarch64; ts_arch=arm64; fzf_arch=arm64 ;;
    x86_64) arch=x86_64; rust_arch=x86_64; ts_arch=x64; fzf_arch=amd64 ;;
    *) echo 'Supported Linux architectures: ARM64 and x86_64.' >&2; exit 1 ;;
esac
privilege=()
if [[ $(id -u) != 0 ]]; then command -v sudo >/dev/null; privilege=(sudo); fi
packages=()
for package in git yadm openssh-client python3 less ca-certificates curl jq tar gzip xz-utils unzip build-essential pkg-config \
    libevent-dev libncurses-dev bison fish tmux bc fd-find ripgrep bat locales ncurses-term; do
    [[ $(dpkg-query -W -f='${Status}' "$package" 2>/dev/null || true) == 'install ok installed' ]] || packages+=("$package")
done
if ((${#packages[@]})); then
    "${privilege[@]}" apt-get -o Acquire::Retries=2 -o Acquire::http::Timeout=30 update
    "${privilege[@]}" env DEBIAN_FRONTEND=noninteractive apt-get -o Acquire::Retries=2 -o Acquire::http::Timeout=30 install -y --no-install-recommends "${packages[@]}"
fi
tools_root="$HOME/.local/share/dotfiles-tools"
mkdir -p "$tools_root"
link_tool() {
    local src="$1" dest="$HOME/.local/bin/$2"
    if [[ -e "$dest" || -L "$dest" ]]; then
        if [[ -L "$dest" ]]; then
            [[ "$(readlink "$dest")" == "$src" ]] && return 0
            case "$(readlink "$dest")" in
                "$tools_root"/*) ln -sfn "$src" "$dest"; return ;;
            esac
        fi
        echo "Refusing to overwrite $dest; move it aside and rerun." >&2; exit 1
    fi
    ln -s "$src" "$dest"
}
command -v fd >/dev/null || link_tool "$(command -v fdfind)" fd
command -v bat >/dev/null || link_tool "$(command -v batcat)" bat
release() {
    curl -fsSL --retry 3 "https://api.github.com/repos/$1/releases/latest" -o "$task_tmp/release.json"
    release_version=$(jq -er '.tag_name | ltrimstr("v")' "$task_tmp/release.json")
}
download() {
    local asset="$1" output="$2" url digest
    url=$(jq -er --arg name "$asset" '.assets[] | select(.name == $name) | .browser_download_url' "$task_tmp/release.json")
    digest=$(jq -er --arg name "$asset" '.assets[] | select(.name == $name) | .digest | select(startswith("sha256:"))' "$task_tmp/release.json")
    curl -fsSL --retry 3 "$url" -o "$output"
    printf '%s  %s\n' "${digest#sha256:}" "$output" | sha256sum -c -
}
if ! command -v nvim >/dev/null || ! version_at_least "$(tool_version nvim)" 0.12.0; then
    release neovim/neovim
    download "nvim-linux-$arch.tar.gz" "$task_tmp/nvim.tgz"
    mkdir "$task_tmp/nvim"
    tar -xzf "$task_tmp/nvim.tgz" -C "$task_tmp/nvim" --strip-components=1
    [[ -e "$tools_root/nvim-$release_version" ]] || mv "$task_tmp/nvim" "$tools_root/nvim-$release_version"
    link_tool "$tools_root/nvim-$release_version/bin/nvim" nvim
fi
if ! command -v fzf >/dev/null || ! version_at_least "$(tool_version fzf)" 0.60.0; then
    release junegunn/fzf
    download "fzf-$release_version-linux_$fzf_arch.tar.gz" "$task_tmp/fzf.tgz"
    tar -xzf "$task_tmp/fzf.tgz" -C "$task_tmp" fzf
    install -m 755 "$task_tmp/fzf" "$tools_root/fzf-$release_version"
    link_tool "$tools_root/fzf-$release_version" fzf
fi
if ! command -v delta >/dev/null; then
    release dandavison/delta
    delta_dir="delta-$release_version-$rust_arch-unknown-linux-gnu"
    download "$delta_dir.tar.gz" "$task_tmp/delta.tgz"
    tar -xzf "$task_tmp/delta.tgz" -C "$task_tmp"
    install -m 755 "$task_tmp/$delta_dir/delta" "$tools_root/delta-$release_version"
    link_tool "$tools_root/delta-$release_version" delta
fi
if ! command -v lazygit >/dev/null; then
    release jesseduffield/lazygit
    download "lazygit_${release_version}_linux_$arch.tar.gz" "$task_tmp/lazygit.tgz"
    tar -xzf "$task_tmp/lazygit.tgz" -C "$task_tmp" lazygit
    install -m 755 "$task_tmp/lazygit" "$tools_root/lazygit-$release_version"
    link_tool "$tools_root/lazygit-$release_version" lazygit
fi
if ! command -v tree-sitter >/dev/null || ! version_at_least "$(tool_version tree-sitter)" 0.26.1; then
    release tree-sitter/tree-sitter
    download "tree-sitter-linux-$ts_arch.gz" "$task_tmp/tree-sitter.gz"
    gzip -d "$task_tmp/tree-sitter.gz"
    install -m 755 "$task_tmp/tree-sitter" "$tools_root/tree-sitter-$release_version"
    link_tool "$tools_root/tree-sitter-$release_version" tree-sitter
fi
if ! version_at_least "$(tmux -V | cut -d' ' -f2)" 3.5; then
    release tmux/tmux
    download "tmux-$release_version.tar.gz" "$task_tmp/tmux.tgz"
    tar -xzf "$task_tmp/tmux.tgz" -C "$task_tmp"
    (cd "$task_tmp/tmux-$release_version" || exit; ./configure --prefix="$tools_root/tmux-$release_version"; make -j2; make install)
    link_tool "$tools_root/tmux-$release_version/bin/tmux" tmux
fi
hash -r
