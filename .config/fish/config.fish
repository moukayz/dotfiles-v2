
# Added by `rbenv init` on Tue Aug 26 17:06:25 CST 2025
status --is-interactive; and rbenv init - --no-rehash fish | source

# kimi-code
fish_add_path -g "$HOME/.kimi-code/bin"


# Added by Antigravity CLI installer
set -gx PATH "$HOME/.local/bin" $PATH

# >>> grok installer >>>
fish_add_path $HOME/.grok/bin
# <<< grok installer <<<
