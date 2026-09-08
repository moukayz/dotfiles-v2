#!/usr/bin/env bash

CONF_NAME="yz-theme.conf"
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

main() {
  tmux source-file "$CURRENT_DIR/$CONF_NAME"
}

main
