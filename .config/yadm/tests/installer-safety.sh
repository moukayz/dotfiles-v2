#!/usr/bin/env bash
# Destructive test fixtures ONLY in a disposable container, run as root.
set -euo pipefail
[[ -f /.dockerenv && $(id -u) == 0 ]] || { echo 'Run this only in a disposable Docker container as root.' >&2; exit 1; }
installer=$(realpath "$1")
fixture=$(mktemp -d /tmp/dotfiles-safety.XXXXXX)
chmod 755 "$fixture"
test_user=dotfiles-safety
id "$test_user" >/dev/null 2>&1 && { echo 'Test user already exists; use a fresh container.' >&2; exit 1; }
useradd -m -s /bin/bash "$test_user"
test_home=$(getent passwd "$test_user" | cut -d: -f6)
mkdir -p "$fixture/repo/.config/yadm" "$fixture/repo/.config/fish"
printf '#!/bin/bash\nprintf "fixture bootstrap OK\\n"\n' > "$fixture/repo/.config/yadm/bootstrap"
printf '# incoming config\n' > "$fixture/repo/.config/fish/config.fish"
git -C "$fixture/repo" init -b main
git -C "$fixture/repo" add .
git -C "$fixture/repo" -c user.name=Test -c user.email=test@example.invalid commit -m fixture
runuser -u "$test_user" -- git config --global "url.file://$fixture/repo.insteadOf" https://github.com/moukayz/dotfiles-v2.git
runuser -u "$test_user" -- git config --global --add safe.directory "$fixture/repo/.git"
mkdir -p "$test_home/.config/fish"
printf '# original config\n' > "$test_home/.config/fish/config.fish"
printf 'unrelated\n' > "$test_home/keep-me"
chown -R "$test_user:$test_user" "$test_home"
if runuser -u "$test_user" -- bash "$installer" --yes > "$fixture/refusal.log" 2>&1; then
    echo 'ERROR: installer overwrote a conflict without permission'; exit 1
fi
grep -q 'Configs untouched' "$fixture/refusal.log"
grep -q '# original config' "$test_home/.config/fish/config.fish"
runuser -u "$test_user" -- bash "$installer" --yes --backup-conflicts > "$fixture/backup.log" 2>&1
grep -q 'fixture bootstrap OK' "$fixture/backup.log"
grep -q '# incoming config' "$test_home/.config/fish/config.fish"
grep -q '# original config' "$test_home"/dotfiles-backup.*/.config/fish/config.fish
grep -q unrelated "$test_home/keep-me"
printf '# local edit\n' >> "$test_home/.config/fish/config.fish"
runuser -u "$test_user" -- bash "$installer" --yes > "$fixture/rerun.log" 2>&1
grep -q '# local edit' "$test_home/.config/fish/config.fish"
if runuser -u "$test_user" -- env XDG_CONFIG_HOME=/tmp/not-the-config bash "$installer" --yes > "$fixture/xdg.log" 2>&1; then exit 1; fi
grep -q 'requires XDG_CONFIG_HOME' "$fixture/xdg.log"
runuser -u "$test_user" -- yadm remote set-url origin https://example.invalid/other.git
if runuser -u "$test_user" -- bash "$installer" --yes > "$fixture/origin.log" 2>&1; then exit 1; fi
grep -q 'origin differs' "$fixture/origin.log"
echo "Installer safety checks passed: refusal, backup, unrelated files, rerun edits, XDG and origin guards. Logs: $fixture"
