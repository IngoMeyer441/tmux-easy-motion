#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${CURRENT_DIR}/scripts"

# shellcheck source=./scripts/helpers.sh
source "${SCRIPTS_DIR}/helpers.sh"

easy_motion_key_default="Space"
easy_motion_key_option="@easy_motion_key"

easy_motion_key() {
    get_tmux_option "${easy_motion_key_option}" "${easy_motion_key_default}"
}

setup_bindings() {
    tmux bind-key "$(easy_motion_key)" run-shell -b "${SCRIPTS_DIR}/easy_motion.sh"
    if is_tmux_version_greater_or_equal "2.4"; then
        tmux bind-key -T copy-mode-vi "$(easy_motion_key)" run-shell -b "${SCRIPTS_DIR}/easy_motion.sh"
    else
        tmux bind-key -t vi-copy "$(easy_motion_key)" run-shell -b "${SCRIPTS_DIR}/easy_motion.sh"
    fi
}

main() {
    setup_bindings
}

main
