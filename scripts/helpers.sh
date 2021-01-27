# shellcheck shell=bash
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${CURRENT_DIR}"

# shellcheck source=./common_variables.sh
source "${SCRIPTS_DIR}/common_variables.sh"

setup_single_key_binding() {
    local server_pid key motion key_table

    server_pid="$1"
    key="$2"
    motion="$3"

    if [[ "${key:0:1}" != "g" ]]; then
        key_table="easy-motion"
    else
        key_table="easy-motion-g"
        key="${key:1}"
    fi

    [[ "${key}" != "" ]] || return

    case "${key}" in
        \;)
            key="\\${key}"
            ;;
        *)
            ;;
    esac

    tmux bind-key -T "${key_table}" "${key}" run-shell -b \
        "${SCRIPTS_DIR}/easy_motion.sh '${server_pid}' '#{session_id}' '#{window_id}' '#{pane_id}' '${motion}'"
}

setup_single_key_binding_with_argument() {
    local server_pid key motion key_table

    server_pid="$1"
    key="$2"
    motion="$3"

    if [[ "${key:0:1}" != "g" ]]; then
        key_table="easy-motion"
    else
        key_table="easy-motion-g"
        key="${key:1}"
    fi

    [[ "${key}" != "" ]] || return

    case "${key}" in
        \;)
            key="\\${key}"
            ;;
        *)
            ;;
    esac

    tmux source - <<-EOF
		bind-key -T "${key_table}" "${key}" command-prompt -1 -p "character:" {
		    set -g @tmp-easy-motion-argument "%%%"
		    run-shell -b '${SCRIPTS_DIR}/easy_motion.sh "${server_pid}" "\#{session_id}" "#{window_id}" "#{pane_id}" "${motion}" "#{q:@tmp-easy-motion-argument}"'
		}
	EOF
}

ensure_target_key_pipe_exists() {
    local server_pid session_id target_key_pipe_tmp_directory

    server_pid="$1"
    session_id="$2"

    target_key_pipe_tmp_directory=$(get_target_key_pipe_tmp_directory "${server_pid}" "${session_id}" create) && \
    if [[ ! -p "${target_key_pipe_tmp_directory}/${TARGET_KEY_PIPENAME}" ]]; then
        mkfifo "${target_key_pipe_tmp_directory}/${TARGET_KEY_PIPENAME}"
    fi
}

install_target_key_pipe_cleanup_hook() {
    local server_pid

    server_pid="$1"

    # Check if the hook is already installed
    if tmux show-hooks -g | grep -q '^session-closed.*tmux-easy-motion'; then
        return 0
    fi

    tmux set-hook -ga "session-closed" \
        "run-shell 'session_id=\"\#{hook_session}\"; \
                    rm -rf \"$(get_target_key_pipe_parent_directory "${server_pid}")/\${session_id:1}\"; \
                    rmdir \"$(get_target_key_pipe_parent_directory "${server_pid}")\" 2>/dev/null; \
                    true'"  # Ignore error codes from `rmdir` if the directory is not empty
}

get_target_key_pipe_parent_directory() {
    local server_pid

    server_pid="$1"

    echo "${TMPDIR}/tmux-easy-motion-target-key-pipe_$(id -un)_${server_pid}"
}

get_target_key_pipe_tmp_directory() {
    local server_pid session_id create parent_dir target_key_pipe_tmp_directory

    server_pid="$1"
    session_id="$2"
    if [[ "${session_id}" =~ \$(.*) ]]; then
        session_id="${BASH_REMATCH[1]}"
    fi
    if [[ "$3" == "create" ]]; then
        create=1
    else
        create=0
    fi

    parent_dir=$(get_target_key_pipe_parent_directory "${server_pid}")
    target_key_pipe_tmp_directory="${parent_dir}/${session_id}"

    if (( create )); then
        if [[ ! -d "${parent_dir}" ]]; then
            mkdir -m 700 -p "${parent_dir}" || return
        fi
        if [[ ! -d "${target_key_pipe_tmp_directory}" ]]; then
            mkdir -m 700 -p "${target_key_pipe_tmp_directory}" || return
        fi
    fi

    echo "${target_key_pipe_tmp_directory}"
}

get_tmux_server_pid() {
    [[ "${TMUX}" =~ .*,(.*),.* ]] && echo "${BASH_REMATCH[1]}"
}

escape_double_quotes() {
    local unescaped_string

    unescaped_string="$1"
    echo "${unescaped_string//\"/\\\"}"
}

escape_double_quotes_and_backticks() {
    local unescaped_string escaped_double_quotes

    unescaped_string="$1"
    escaped_double_quotes="$(escape_double_quotes "${unescaped_string}")"
    echo "${escaped_double_quotes//\`/\\\`}"
}

is_tmux_version_greater_or_equal() {
    local version

    version="$1"
    [[ -n "${version}" ]] || return
    [[ "$(echo "$(tmux -V | sed 's/next-//g' | cut -d" " -f2);${version}" | tr ";" "\n" | sort -g -t "." -k 1,1 -k 2,2 | head -1)" == "${version}" ]]
}

display_message() {
    tmux display-message "$1"
}

get_tmux_option() {
    local option default_value option_value

    option="$1"
    default_value="$2"

    option_value="$(tmux show-option -gqv "${option}")"
    if [[ -z "${option_value}" ]]; then
        echo "${default_value}"
    else
        echo "${option_value}"
    fi
}

get_tmux_bool_option() {
    local option default_value option_value

    option="$1"
    default_value="$2"

    option_value="$(get_tmux_option "${option}" "${default_value}" | awk '{ print tolower($0) }')"
    case "${option_value}" in
        1|yes|on|enabled|activated)
            echo "1"
            ;;
        *)
            echo "0"
            ;;
    esac
}

capture_pane() {
    local session_id window_id pane_id capture_filepath
    local current_pane_scroll_start current_pane_scroll_end

    session_id="$1"
    window_id="$2"
    pane_id="$3"
    capture_filepath="$4"

    IFS=':' read -r current_pane_scroll_start current_pane_scroll_end <<< \
        "$(get_pane_scroll_range "${session_id}" "${window_id}" "${pane_id}")"
    tmux capture-pane -t "${session_id}:${window_id}.${pane_id}" \
                      -p \
                      -S "${current_pane_scroll_start}" \
                      -E "${current_pane_scroll_end}" \
                      > "${capture_filepath}"
}

get_pane_scroll_range() {
    local session_id window_id pane_id
    local current_pane_scroll_position current_pane_height

    session_id="$1"
    window_id="$2"
    pane_id="$3"

    IFS=':' read -r current_pane_scroll_position current_pane_height <<< \
        "$(tmux display-message -p -t "${session_id}:${window_id}.${pane_id}" -F "#{scroll_position}:#{pane_height}")"

    echo "$(( - current_pane_scroll_position )):$(( - current_pane_scroll_position + current_pane_height - 1 ))"
}

get_pane_size() {
    local session_id window_id pane_id

    session_id="$1"
    window_id="$2"
    pane_id="$3"

    tmux display-message -p -t "${session_id}:${window_id}.${pane_id}" -F "#{pane_width}:#{pane_height}"
}

get_window_size() {
    local session_id window_id

    session_id="$1"
    window_id="$2"

    tmux display-message -p -t "${session_id}:${window_id}" "#{window_width}:#{window_height}"
}

is_pane_zoomed() {
    local session_id window_id pane_id

    session_id="$1"
    window_id="$2"
    pane_id="$3"

    [[ "$(tmux display-message -p -t "${session_id}:${window_id}.${pane_id}" -F "#{?window_zoomed_flag,zoomed,not_zoomed}")" == "zoomed" ]]
}

swap_pane() {
    local target_pane_id source_pane_id

    target_pane_id="$1"
    source_pane_id="$2"

    tmux swap-pane -s "${source_pane_id}" -t "${target_pane_id}"
}

zoom_pane() {
    local pane_id

    pane_id="$1"
    tmux resize-pane -Z -t "${pane_id}"
}

# Based on https://github.com/Morantron/tmux-fingers/blob/1.0.1/scripts/tmux-fingers.sh#L10
create_empty_swap_pane() {
    local name session_id window_id pane_id
    local swap_window_and_pane_ids swap_window_id swap_pane_id
    local current_pane_width current_pane_height
    local current_window_width current_window_height
    local split_width split_height

    running_shell() {
        grep -o "\w*$" <<< "${SHELL}"
    }

    init_pane_cmd() {
        local init_bash set_env

        init_bash="bash --norc --noprofile"
        if [[ $(running_shell) == "fish" ]]; then
            set_env="set -x HISTFILE /dev/null; "
        else
            set_env="HISTFILE=/dev/null "
        fi

        echo "${set_env} ${init_bash}"
    }

    session_id="$1"
    window_id="$2"
    pane_id="$3"
    name="$4"

    swap_window_and_pane_ids="$(tmux new-window -t "${session_id}" -F "#{window_id}:#{pane_id}" -P -d -n "[${name}]" "$(init_pane_cmd)")"
    IFS=':' read -r swap_window_id swap_pane_id <<< "${swap_window_and_pane_ids}"
    IFS=':' read -r current_pane_width current_pane_height <<< "$(get_pane_size "${session_id}" "${window_id}" "${pane_id}")"
    IFS=':' read -r current_window_width current_window_height <<< "$(get_window_size "${session_id}" "${window_id}")"

    split_width="$(( current_window_width - current_pane_width - 1 ))"
    split_height="$(( current_window_height - current_pane_height - 1 ))"

    if (( split_width >= 0 )); then
        tmux split-window -d -t "${swap_pane_id}" -h -l "${split_width}" "/bin/nop"
    fi
    if (( split_height >= 0 )); then
        tmux split-window -d -t "${swap_pane_id}" -l "${split_height}" "/bin/nop"
    fi

    echo "${swap_window_id}:${swap_pane_id}"
}

pane_exec() {
    local pane_id pane_command

    pane_id=$1
    shift
    pane_command="$1"
    shift
    # Quote arguments
    while [[ -n "$*" ]]; do
        pane_command="${pane_command} \"$1\""
        shift
    done

    tmux send-keys -t "${pane_id}" "${pane_command[@]}"
    tmux send-keys -t "${pane_id}" Enter
}

is_pane_in_copy_mode() {
    local session_id window_id pane_id

    session_id="$1"
    window_id="$2"
    pane_id="$3"

    [[ "$(tmux list-panes -t "${session_id}:${window_id}.${pane_id}" -F "#{?pane_in_mode,copy,nocopy}")" == "copy" ]]
}

read_cursor_position() {
    local session_id window_id pane_id

    session_id="$1"
    window_id="$2"
    pane_id="$3"

    local cursor_type

    if is_pane_in_copy_mode "${session_id}" "${window_id}" "${pane_id}"; then
        cursor_type="copy_cursor"
    else
        cursor_type="cursor"
    fi
    tmux display-message -t "${session_id}:${window_id}.${pane_id}" -p -F "#{${cursor_type}_y}:#{${cursor_type}_x}"
}

set_cursor_position() {
    local session_id window_id pane_id row_col
    local row col old_row old_col rel_row

    session_id="$1"
    window_id="$2"
    pane_id="$3"
    row_col="$4"

    IFS=':' read -r row col <<< "${row_col}"
    IFS=':' read -r old_row old_col <<< "$(read_cursor_position "${session_id}" "${window_id}" "${pane_id}")"
    rel_row="$(( row - old_row ))"
    tmux copy-mode -t "${session_id}:${window_id}.${pane_id}"
    if (( rel_row < 0 )); then
        tmux send-keys -t "${session_id}:${window_id}.${pane_id}" -X -N "$(( -rel_row ))" cursor-up
    elif (( rel_row > 0 )); then
        tmux send-keys -t "${session_id}:${window_id}.${pane_id}" -X -N "$(( rel_row ))" cursor-down
    fi
    # Relative colum positioning does not work since tmux can change the column
    # while moving the cursor up or down (like in vim).
    tmux send-keys -t "${session_id}:${window_id}.${pane_id}" -X start-of-line
    tmux send-keys -t "${session_id}:${window_id}.${pane_id}" -X -N "$(( col ))" cursor-right
}
