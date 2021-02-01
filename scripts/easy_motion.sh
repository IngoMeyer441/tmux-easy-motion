#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${CURRENT_DIR}"

CAPTURE_PANE_FILENAME="capture.out"
JUMP_COMMAND_PIPENAME="jump.pipe"

# shellcheck source=./common_variables.sh
source "${SCRIPTS_DIR}/common_variables.sh"
# shellcheck source=./helpers.sh
source "${SCRIPTS_DIR}/helpers.sh"
# shellcheck source=./scripts/options.sh
source "${SCRIPTS_DIR}/options.sh"


easy_motion_create_work_buffer_and_pipe() {
    local pane_id

    pane_id="$1"

    if [[ -z "${CAPTURE_TMP_DIRECTORY}" ]]; then
        CAPTURE_TMP_DIRECTORY="$(mktemp -d)" || return

        _capture_tmp_directory_cleanup() {
            if [[ -n "${CAPTURE_TMP_DIRECTORY}" ]]; then
                rm -rf "${CAPTURE_TMP_DIRECTORY}" || return
            fi
        }
        trap _capture_tmp_directory_cleanup EXIT
    fi
    capture_pane "${pane_id}" "${CAPTURE_TMP_DIRECTORY}/${CAPTURE_PANE_FILENAME}" && \
    chmod 400 "${CAPTURE_TMP_DIRECTORY}/${CAPTURE_PANE_FILENAME}" && \
    mkfifo "${CAPTURE_TMP_DIRECTORY}/${JUMP_COMMAND_PIPENAME}"
}

easy_motion_setup() {
    local session_id window_id pane_id easy_motion_window_and_pane_ids

    session_id="$1"
    window_id="$2"
    pane_id="$3"

    tmux copy-mode -t "${pane_id}" && \
    EASY_MOTION_CURSOR_POSITION="$(read_cursor_position "${pane_id}")" && \
    EASY_MOTION_PANE_SIZE="$(get_pane_size "${pane_id}")" && \
    EASY_MOTION_ORIGINAL_SESSION_ID="${session_id}" && \
    EASY_MOTION_ORIGINAL_WINDOW_ID="${window_id}" && \
    EASY_MOTION_ORIGINAL_PANE_ID="${pane_id}" && \
    EASY_MOTION_IS_PANE_ZOOMED="$(is_pane_zoomed "${pane_id}" && echo 1 || echo 0)" && \
    easy_motion_create_work_buffer_and_pipe "${pane_id}" && \
    easy_motion_window_and_pane_ids="$(create_empty_swap_pane "${session_id}" "${window_id}" "${pane_id}" "easy-motion")"
    EASY_MOTION_WINDOW_ID=$(cut -d: -f1 <<< "${easy_motion_window_and_pane_ids}") && \
    EASY_MOTION_PANE_ID=$(cut -d: -f2 <<< "${easy_motion_window_and_pane_ids}")
    EASY_MOTION_PANE_ACTIVE=0
}

easy_motion_toggle_pane() {
    if (( EASY_MOTION_PANE_ACTIVE )); then
        if [[ -n "${EASY_MOTION_ORIGINAL_PANE_ID}" ]]; then
            tmux set-window-option -t "${EASY_MOTION_ORIGINAL_PANE_ID}" key-table root && \
            tmux switch-client -t "${EASY_MOTION_ORIGINAL_PANE_ID}" -T root && \
            if (( EASY_MOTION_IS_PANE_ZOOMED )); then
                swap_window "${EASY_MOTION_ORIGINAL_WINDOW_ID}" "${EASY_MOTION_WINDOW_ID}" || return
            else
                swap_pane "${EASY_MOTION_ORIGINAL_PANE_ID}" "${EASY_MOTION_PANE_ID}" || return
            fi
            EASY_MOTION_PANE_ACTIVE=0
        fi
    else
        if [[ -n "${EASY_MOTION_PANE_ID}" ]]; then
            tmux set-window-option -t "${EASY_MOTION_PANE_ID}" key-table easy-motion-target && \
            tmux switch-client -t "${EASY_MOTION_PANE_ID}" -T easy-motion-target && \
            if (( EASY_MOTION_IS_PANE_ZOOMED )); then
                swap_window "${EASY_MOTION_WINDOW_ID}" "${EASY_MOTION_ORIGINAL_WINDOW_ID}" || return
            else
                swap_pane "${EASY_MOTION_PANE_ID}" "${EASY_MOTION_ORIGINAL_PANE_ID}" || return
            fi
            EASY_MOTION_PANE_ACTIVE=1
        fi
    fi
}

easy_motion() {
    local server_pid session_id window_id pane_id motion motion_argument
    local ready_command jump_command jump_cursor_position
    local target_key_pipe_tmp_directory

    server_pid="$1"
    session_id="$2"
    window_id="$3"
    pane_id="$4"
    motion="$5"
    motion_argument="$6"

    # Undo escaping of motion arguments
    if [[ "${motion_argument:0:1}" == "\\" ]]; then
        motion_argument="${motion_argument:1}"
    fi
    ensure_target_key_pipe_exists "${server_pid}" "${session_id}" && \
    target_key_pipe_tmp_directory=$(get_target_key_pipe_tmp_directory "${server_pid}" "${session_id}") && \
    if (( EASY_MOTION_VERBOSE )); then
        if [[ -z "${motion_argument}" ]]; then
            display_message "Showing targets for motion \"${motion}\"."
        else
            display_message "Showing targets for motion \"${motion}\", motion argument \"${motion_argument}\"."
        fi
    fi
    pane_exec "${EASY_MOTION_PANE_ID}" \
              "${SCRIPTS_DIR}/easy_motion.py" \
              "${EASY_MOTION_DIM_STYLE}" \
              "${EASY_MOTION_HIGHLIGHT_STYLE}" \
              "${EASY_MOTION_HIGHLIGHT_2_FIRST_STYLE}" \
              "${EASY_MOTION_HIGHLIGHT_2_SECOND_STYLE}" \
              "${motion}" \
              "$(escape_double_quotes_and_backticks "${motion_argument}")" \
              "$(escape_double_quotes_and_backticks "${EASY_MOTION_TARGET_KEYS}")" \
              "${EASY_MOTION_CURSOR_POSITION}" \
              "${EASY_MOTION_PANE_SIZE}" \
              "${CAPTURE_TMP_DIRECTORY}/${CAPTURE_PANE_FILENAME}" \
              "${CAPTURE_TMP_DIRECTORY}/${JUMP_COMMAND_PIPENAME}" \
              "${target_key_pipe_tmp_directory}/${TARGET_KEY_PIPENAME}" && \
    {
        read -r ready_command && \
        if [[ "${ready_command}" == "ready" ]]; then
            easy_motion_toggle_pane || return
        elif [[ "${ready_command}" != "single-target" ]]; then
            return 1
        fi
        read -r jump_command && \
        [[ "$(awk '{ print $1 }' <<< "${jump_command}")" == "jump" ]] || return
        jump_cursor_position="$(awk '{ print $2 }' <<< "${jump_command}")" && \
        if [[ "${ready_command}" != "single-target" ]]; then
            easy_motion_toggle_pane || return
        fi
        set_cursor_position "${pane_id}" "${jump_cursor_position}"
    } < "${CAPTURE_TMP_DIRECTORY}/${JUMP_COMMAND_PIPENAME}"
}

easy_motion_cleanup() {
    if (( EASY_MOTION_PANE_ACTIVE )); then
        easy_motion_toggle_pane
    fi
    if [[ -n "${EASY_MOTION_WINDOW_ID}" ]]; then
        tmux kill-window -t "${EASY_MOTION_WINDOW_ID}"
    fi
}

main() {
    local session_id window_id pane_id
    session_id="$2"
    window_id="$3"
    pane_id="$4"

    read_options && \
    easy_motion_setup "${session_id}" "${window_id}" "${pane_id}" && \
    easy_motion "$@"
    easy_motion_cleanup
}

main "$@"
