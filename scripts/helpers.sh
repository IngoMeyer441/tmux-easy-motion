# shellcheck shell=bash
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${CURRENT_DIR}"

# shellcheck source=./common_variables.sh
source "${SCRIPTS_DIR}/common_variables.sh"

get_target_key_pipe_tmp_directory() {
    local server_pid

    server_pid="$1"

    echo "${TMPDIR}/tmux-easy-motion-target-key-pipe_$(id -un)_${server_pid}"
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

capture_current_pane() {
    local capture_filepath

    capture_filepath="$1"

    tmux capture-pane -p > "${capture_filepath}"
}

get_current_pane_id() {
    tmux list-panes -F "#{pane_id}:#{?pane_active,active,inactive}" | awk -F':' '$2 == "active" { print $1 }'
}

get_current_pane_size() {
    tmux list-panes -F "#{pane_width}:#{pane_height}:#{?pane_active,active,inactive}" | awk -F':' '$3 == "active" { printf "%d:%d\n", $1, $2 }'
}

get_current_window_size() {
    tmux list-windows -F "#{window_width}:#{window_height}:#{?window_active,active,inactive}" | awk -F':' '$3 == "active" { printf "%d:%d\n", $1, $2 }'
}

is_current_pane_zoomed() {
    [[ "$(tmux list-panes -F "#{?window_zoomed_flag,zoomed,not_zoomed}:#{?pane_active,active,inactive}" | awk -F':' '$2 == "active" { print $1 }')" == "zoomed" ]]
}

swap_current_pane() {
    local target_pane_id source_pane_id

    target_pane_id="$1"
    source_pane_id=$(get_current_pane_id)

    tmux swap-pane -s "${source_pane_id}" -t "${target_pane_id}"
}

zoom_pane() {
    local pane_id

    pane_id="$1"
    tmux resize-pane -Z -t "${pane_id}"
}

# Based on https://github.com/Morantron/tmux-fingers/blob/1.0.1/scripts/tmux-fingers.sh#L10
create_empty_swap_pane() {
    local name swap_window_and_pane_ids swap_window_id swap_pane_id
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

    name="$1"

    swap_window_and_pane_ids="$(tmux new-window -F "#{window_id}:#{pane_id}" -P -d -n "[${name}]" "$(init_pane_cmd)")"
    IFS=':' read -r swap_window_id swap_pane_id <<< "${swap_window_and_pane_ids}"
    IFS=':' read -r current_pane_width current_pane_height <<< "$(get_current_pane_size)"
    IFS=':' read -r current_window_width current_window_height <<< "$(get_current_window_size)"

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

is_active_pane_in_copy_mode() {
    [[ "$(tmux list-panes -F "#{?pane_in_mode,copy,nocopy}:#{?pane_active,active,inactive}" | awk -F':' '$2 == "active" { print $1 }')" == "copy" ]]
}

read_cursor_position() {
    local cursor_type

    if is_active_pane_in_copy_mode; then
        cursor_type="copy_cursor"
    else
        cursor_type="cursor"
    fi
    tmux list-panes -F "#{?pane_active,active,inactive}:#{${cursor_type}_y}:#{${cursor_type}_x}" | \
        awk -F':' '$1 == "active" { printf "%d:%d\n", $2, $3 }'
}

set_cursor_position() {
    local row_col row col old_row old_col rel_row

    row_col="$1"
    IFS=':' read -r row col <<< "${row_col}"
    IFS=':' read -r old_row old_col <<< "$(read_cursor_position)"
    rel_row="$(( row - old_row ))"
    tmux copy-mode
    if (( rel_row < 0 )); then
        tmux send-keys -X -N "$(( -rel_row ))" cursor-up
    elif (( rel_row > 0 )); then
        tmux send-keys -X -N "$(( rel_row ))" cursor-down
    fi
    # Relative colum positioning does not work since tmux can change the column
    # while moving the cursor up or down (like in vim).
    tmux send-keys -X start-of-line
    tmux send-keys -X -N "$(( col ))" cursor-right
}
