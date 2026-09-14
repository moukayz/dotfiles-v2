#!/usr/bin/env bash
# Run only inside the disposable test container, after bootstrap.
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"
for command in git yadm fish tmux delta fzf fd rg bat lazygit nvim tree-sitter cc; do
    command -v "$command"
done
fish -ic 'functions -q lnvim; or exit 1; command -q fd; or exit 1; command -q nvim; or exit 1'
# shellcheck disable=SC2088
[[ $(git config --global --get-all include.path | grep -Fxc '~/.config/git/delta.gitconfig') == 1 ]]
for plugin in tpm tmux-resurrect tmux-continuum tmux-battery tmux-power; do
    [[ -d "$HOME/.tmux/plugins/$plugin/.git" ]]
done
test_tmp=$(mktemp -d)
cleanup() { tmux -S "$test_tmp/tmux.sock" kill-server 2>/dev/null || true; rm -rf -- "$test_tmp"; }
trap cleanup EXIT
tmux -S "$test_tmp/tmux.sock" -f "$HOME/.tmux.conf" new-session -d -s check 'sleep 60'
tmux -S "$test_tmp/tmux.sock" source-file "$HOME/.tmux.conf"
[[ $(tmux -S "$test_tmp/tmux.sock" show-option -gv prefix) == C-y ]]
[[ $(tmux -S "$test_tmp/tmux.sock" show-option -gv default-shell) == "$(command -v fish)" ]]
env NVIM_APPNAME=nvim-lite nvim --headless -i NONE -u NONE \
    +'lua local p=vim.fn.stdpath("config"); vim.env.MYVIMRC=p .. "/init.lua"; local ok,err=pcall(function() dofile(vim.env.MYVIMRC); dofile(p .. "/tests/smoke.lua") end); if not ok then print(err); vim.cmd("cq") end'
echo 'Container checks passed: commands, Fish alias/PATH, Delta include, TPM plugins, tmux config, Neovim reload.'
