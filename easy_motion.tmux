#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${CURRENT_DIR}/scripts"

# shellcheck source=./scripts/helpers.sh
source "${SCRIPTS_DIR}/helpers.sh"
# shellcheck source=./scripts/options.sh
source "${SCRIPTS_DIR}/options.sh"


check_version() {
    if ! is_tmux_version_greater_or_equal "3.0"; then
        display_message "tmux-easy-motion needs tmux version 3.0 or newer."
        return 1
    fi
}

setup_bindings() {
    local server_pid key_table key target_key tmux_key prefix_for_key_table

    server_pid="$1"

    if [[ -z "${EASY_MOTION_DEFAULT_MOTION}" ]]; then
        if (( EASY_MOTION_VERBOSE )); then
            if (( EASY_MOTION_PREFIX_ENABLED )); then
                tmux source - <<-EOF
					bind-key "${EASY_MOTION_PREFIX}" {
						switch-client -T easy-motion
						display-message "tmux-easy-motion activated, please type a motion command."
					}
				EOF
            fi
            if (( EASY_MOTION_COPY_MODE_PREFIX_ENABLED )); then
                tmux source - <<-EOF
					bind-key -T copy-mode-vi "${EASY_MOTION_COPY_MODE_PREFIX}" {
						switch-client -T easy-motion
						display-message "tmux-easy-motion activated, please type a motion command."
					}
				EOF
            fi
        else
            if (( EASY_MOTION_PREFIX_ENABLED )); then
                tmux bind-key "${EASY_MOTION_PREFIX}" switch-client -T easy-motion
            fi
            if (( EASY_MOTION_COPY_MODE_PREFIX_ENABLED )); then
                tmux bind-key -T copy-mode-vi "${EASY_MOTION_COPY_MODE_PREFIX}" switch-client -T easy-motion
            fi
        fi

        tmux bind-key -T easy-motion "g" switch-client -T easy-motion-g
        tmux bind-key -T easy-motion "Escape" switch-client -T root
        tmux bind-key -T easy-motion-g "Escape" switch-client -T root

        setup_single_key_binding "${server_pid}" "${EASY_MOTION_BINDING_B}" "b"
        setup_single_key_binding "${server_pid}" "${EASY_MOTION_BINDING_CAPITAL_B}" "B"
        setup_single_key_binding "${server_pid}" "${EASY_MOTION_BINDING_GE}" "ge"
        setup_single_key_binding "${server_pid}" "${EASY_MOTION_BINDING_CAPITAL_GE}" "gE"
        setup_single_key_binding "${server_pid}" "${EASY_MOTION_BINDING_E}" "e"
        setup_single_key_binding "${server_pid}" "${EASY_MOTION_BINDING_CAPITAL_E}" "E"
        setup_single_key_binding "${server_pid}" "${EASY_MOTION_BINDING_W}" "w"
        setup_single_key_binding "${server_pid}" "${EASY_MOTION_BINDING_CAPITAL_W}" "W"
        setup_single_key_binding "${server_pid}" "${EASY_MOTION_BINDING_J}" "j"
        setup_single_key_binding "${server_pid}" "${EASY_MOTION_BINDING_CAPITAL_J}" "J"  # end of line
        setup_single_key_binding "${server_pid}" "${EASY_MOTION_BINDING_K}" "k"
        setup_single_key_binding "${server_pid}" "${EASY_MOTION_BINDING_CAPITAL_K}" "K"  # end of line
        setup_single_key_binding_with_argument "${server_pid}" "${EASY_MOTION_BINDING_F}" "f"
        setup_single_key_binding_with_argument "${server_pid}" "${EASY_MOTION_BINDING_CAPITAL_F}" "F"
        setup_single_key_binding_with_argument "${server_pid}" "${EASY_MOTION_BINDING_T}" "t"
        setup_single_key_binding_with_argument "${server_pid}" "${EASY_MOTION_BINDING_CAPITAL_T}" "T"
        setup_single_key_binding "${server_pid}" "${EASY_MOTION_BINDING_BD_W}" "bd-w"  # bd -> bidirectional
        setup_single_key_binding "${server_pid}" "${EASY_MOTION_BINDING_CAPITAL_BD_W}" "bd-W"
        setup_single_key_binding "${server_pid}" "${EASY_MOTION_BINDING_BD_E}" "bd-e"
        setup_single_key_binding "${server_pid}" "${EASY_MOTION_BINDING_CAPITAL_BD_E}" "bd-E"
        setup_single_key_binding "${server_pid}" "${EASY_MOTION_BINDING_BD_J}" "bd-j"
        setup_single_key_binding "${server_pid}" "${EASY_MOTION_BINDING_CAPITAL_BD_J}" "bd-J"
        setup_single_key_binding_with_argument "${server_pid}" "${EASY_MOTION_BINDING_BD_F}" "bd-f"
        setup_single_key_binding_with_argument "${server_pid}" "${EASY_MOTION_BINDING_BD_T}" "bd-t"
        setup_single_key_binding_with_argument "${server_pid}" "${EASY_MOTION_BINDING_CAPITAL_BD_T}" "bd-T"
        setup_single_key_binding "${server_pid}" "${EASY_MOTION_BINDING_C}" "c"  # camelCase or underscore notation
    else
        case "${EASY_MOTION_DEFAULT_MOTION}" in
            b|B|ge|gE|e|E|w|W|j|J|k|K|bd-w|bd-W|bd-e|bd-E|bd-j|bd-J|c)
                for key_table in "prefix" "copy-mode-vi"; do
                    if ! get_prefix_enabled_for_key_table "${key_table}"; then
                        continue
                    fi
                    prefix_for_key_table=$(get_prefix_for_key_table "${key_table}")
                    tmux bind-key -T "${key_table}" "${prefix_for_key_table}" run-shell -b \
                        "${SCRIPTS_DIR}/easy_motion.sh '${server_pid}' '#{session_id}' '#{window_id}' '#{pane_id}' '${EASY_MOTION_DEFAULT_MOTION}'"
                done
                ;;
            f|F|t|T|bd-f|bd-t|bd-T)
                for key_table in "prefix" "copy-mode-vi"; do
                    if ! get_prefix_enabled_for_key_table "${key_table}"; then
                        continue
                    fi
                    prefix_for_key_table=$(get_prefix_for_key_table "${key_table}")
                    tmux bind-key -T "${key_table}" "${prefix_for_key_table}" run-shell -b \
                        "${SCRIPTS_DIR}/easy_motion.sh '${server_pid}' '#{session_id}' '#{window_id}' '#{pane_id}' '${EASY_MOTION_DEFAULT_MOTION}'"
                    tmux source - <<-EOF
						bind-key -T "${key_table}" "${prefix_for_key_table}" command-prompt -1 -p "character:" {
						    set -g @tmp-easy-motion-argument "%%%"
						    run-shell -b '${SCRIPTS_DIR}/easy_motion.sh "${server_pid}" "\#{session_id}" "#{window_id}" "#{pane_id}" "${EASY_MOTION_DEFAULT_MOTION}" "#{q:@tmp-easy-motion-argument}"'
						}
					EOF
                done
                ;;
            *)
                display_message "The motion \"${EASY_MOTION_DEFAULT_MOTION}\" is not a valid motion."
                exit 1
                ;;
        esac
    fi

    while read -n1 key; do
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
        tmux bind-key -T easy-motion-target "${tmux_key}" run-shell -b "${SCRIPTS_DIR}/pipe_target_key.sh '${server_pid}' '#{session_id}' '${target_key}'"
    done < <(echo -n "${EASY_MOTION_TARGET_KEYS}")
    tmux bind-key -T easy-motion-target "Escape" run-shell -b "${SCRIPTS_DIR}/pipe_target_key.sh '${server_pid}' '#{session_id}' 'esc'"
}

main() {
    local server_pid
    server_pid="$(get_tmux_server_pid)"

    check_version && \
    read_options && \
    install_target_key_pipe_cleanup_hook "${server_pid}" && \
    setup_bindings "${server_pid}"
}

main
