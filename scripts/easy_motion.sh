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
    if [[ -z "${CAPTURE_TMP_DIRECTORY}" ]]; then
        CAPTURE_TMP_DIRECTORY="$(mktemp -d)" || return

        _capture_tmp_directory_cleanup() {
            if [[ -n "${CAPTURE_TMP_DIRECTORY}" ]]; then
                rm -rf "${CAPTURE_TMP_DIRECTORY}" || return
            fi
        }
        trap _capture_tmp_directory_cleanup EXIT
    fi
    capture_current_pane "${CAPTURE_TMP_DIRECTORY}/${CAPTURE_PANE_FILENAME}" && \
    chmod 400 "${CAPTURE_TMP_DIRECTORY}/${CAPTURE_PANE_FILENAME}" && \
    mkfifo "${CAPTURE_TMP_DIRECTORY}/${JUMP_COMMAND_PIPENAME}"
}

easy_motion_setup() {
    local easy_motion_window_and_pane_ids

    EASY_MOTION_CURSOR_POSITION="$(read_cursor_position)" && \
    EASY_MOTION_PANE_SIZE="$(get_current_pane_size)" && \
    EASY_MOTION_ORIGINAL_PANE_ID="$(get_current_pane_id)" && \
    EASY_MOTION_IS_PANE_ZOOMED="$(is_current_pane_zoomed && echo 1 || echo 0)" && \
    easy_motion_create_work_buffer_and_pipe && \
    easy_motion_window_and_pane_ids="$(create_empty_swap_pane "easy-motion")"
    EASY_MOTION_WINDOW_ID=$(cut -d: -f1 <<< "${easy_motion_window_and_pane_ids}") && \
    EASY_MOTION_PANE_ID=$(cut -d: -f2 <<< "${easy_motion_window_and_pane_ids}")
    EASY_MOTION_PANE_ACTIVE=0
}

easy_motion_toggle_pane() {
    if (( EASY_MOTION_PANE_ACTIVE )); then
        if [[ -n "${EASY_MOTION_ORIGINAL_PANE_ID}" ]]; then
            tmux set-window-option key-table root && \
            tmux switch-client -T root && \
            swap_current_pane "${EASY_MOTION_ORIGINAL_PANE_ID}" && \
            if (( EASY_MOTION_IS_PANE_ZOOMED )); then
                zoom_pane "${EASY_MOTION_ORIGINAL_PANE_ID}"
            fi
            EASY_MOTION_PANE_ACTIVE=0
        fi
    else
        if [[ -n "${EASY_MOTION_PANE_ID}" ]]; then
            tmux set-window-option key-table easy-motion-target && \
            tmux switch-client -T easy-motion-target && \
            swap_current_pane "${EASY_MOTION_PANE_ID}" && \
            if (( EASY_MOTION_IS_PANE_ZOOMED )); then
                zoom_pane "${EASY_MOTION_PANE_ID}"
            fi
            EASY_MOTION_PANE_ACTIVE=1
        fi
    fi
}

easy_motion() {
    local motion motion_argument ready_command jump_command jump_cursor_position

    motion="$1"
    motion_argument="$2"
    # Undo escaping of motion arguments
    if [[ "${motion_argument:0:1}" == "\\" ]]; then
        motion_argument="${motion_argument:1}"
    fi
    pane_exec "${EASY_MOTION_PANE_ID}" \
              "${SCRIPTS_DIR}/easy_motion.py" \
              "${EASY_MOTION_DIM_STYLE}" \
              "${EASY_MOTION_HIGHLIGHT_STYLE}" \
              "${EASY_MOTION_HIGHLIGHT_2_FIRST_STYLE}" \
              "${EASY_MOTION_HIGHLIGHT_2_SECOND_STYLE}" \
              "${motion}" \
              "$(escape_double_quotes "${motion_argument}")" \
              "$(escape_double_quotes "${EASY_MOTION_TARGET_KEYS}")" \
              "${EASY_MOTION_CURSOR_POSITION}" \
              "${EASY_MOTION_PANE_SIZE}" \
              "${CAPTURE_TMP_DIRECTORY}/${CAPTURE_PANE_FILENAME}" \
              "${CAPTURE_TMP_DIRECTORY}/${JUMP_COMMAND_PIPENAME}" \
              "${TARGET_KEY_PIPE_TMP_DIRECTORY}/${TARGET_KEY_PIPENAME}" && \

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
        set_cursor_position "${jump_cursor_position}"
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
    read_options && \
    easy_motion_setup && \
    easy_motion "$@"
    easy_motion_cleanup
}

main "$@"
