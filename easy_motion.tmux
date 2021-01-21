#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${CURRENT_DIR}/scripts"

# shellcheck source=./scripts/helpers.sh
source "${SCRIPTS_DIR}/helpers.sh"
# shellcheck source=./scripts/options.sh
source "${SCRIPTS_DIR}/options.sh"


EASY_MOTION_VALID_SINGLE_MOTION_KEYS="bBeEwWjJkKc"
EASY_MOTION_VALID_SINGLE_MOTION_KEYS_G="eE"
EASY_MOTION_VALID_MOTION_KEYS_WITH_ARGUMENT="fFtTs"


check_version() {
    if ! is_tmux_version_greater_or_equal "3.0"; then
        display_message "tmux-easy-motion needs tmux version 3.0 or newer."
        return 1
    fi
}

create_target_key_pipe() {
    local server_pid

    server_pid="$1"
    # The script can be called without arguments to only create the target pipe
    "${SCRIPTS_DIR}/pipe_target_key.sh" "${server_pid}"
}

setup_bindings() {
    local server_pid key target_key tmux_key

    server_pid="$1"

    tmux bind-key "${EASY_MOTION_KEY}" switch-client -T easy-motion
    tmux bind-key -T copy-mode-vi "${EASY_MOTION_KEY}" switch-client -T easy-motion
    while read -N1 key; do
        tmux bind-key -T easy-motion "${key}" run-shell -b "${SCRIPTS_DIR}/easy_motion.sh '${server_pid}' '${key}'"
    done < <(echo -n "${EASY_MOTION_VALID_SINGLE_MOTION_KEYS}")
    tmux bind-key -T easy-motion "g" switch-client -T easy-motion-g
    tmux bind-key -T easy-motion "Escape" switch-client -T root
    while read -N1 key; do
        tmux bind-key -T easy-motion-g "${key}" run-shell -b "${SCRIPTS_DIR}/easy_motion.sh '${server_pid}' 'g${key}'"
    done < <(echo -n "${EASY_MOTION_VALID_SINGLE_MOTION_KEYS_G}")
    tmux bind-key -T easy-motion-g "Escape" switch-client -T root
    while read -N1 key; do
        # `tmux source` allows to use the { } form for commands
        # Set a temporary variable to avoid escaping issues of quotes
        # See https://github.com/tmux/tmux/issues/2528 for details
        tmux source - <<-EOF
			bind-key -T easy-motion "${key}" command-prompt -1 -p "character:" {
			    set -g @tmp-easy-motion-argument "%%%"
			    run-shell -b '${SCRIPTS_DIR}/easy_motion.sh "${server_pid}" "${key}" "#{q:@tmp-easy-motion-argument}"'
			}
		EOF
    done < <(echo -n "${EASY_MOTION_VALID_MOTION_KEYS_WITH_ARGUMENT}")
    while read -N1 key; do
        case "${key}" in
            \;)
                tmux_key="\\${key}"
                ;;
            *)
                tmux_key="${key}"
                ;;
        esac
        case "${key}" in
            \"|\`)
                target_key="\\${key}"
                ;;
            *)
                target_key="${key}"
                ;;
        esac
        # `easy_motion.sh` switches the key table to `easy-motion-target`
        tmux bind-key -T easy-motion-target "${tmux_key}" run-shell -b "${SCRIPTS_DIR}/pipe_target_key.sh \"${server_pid}\" \"${target_key}\""
    done < <(echo -n "${EASY_MOTION_TARGET_KEYS}")
    tmux bind-key -T easy-motion-target "Escape" run-shell -b "${SCRIPTS_DIR}/pipe_target_key.sh \"${server_pid}\" 'esc'"
}

main() {
    local server_pid
    server_pid="$(get_tmux_server_pid)"

    check_version && \
    read_options && \
    create_target_key_pipe "${server_pid}" && \
    setup_bindings "${server_pid}"
}

main

# vim: ts=4 sts=4 sw=4 et ft=sh tw=120
