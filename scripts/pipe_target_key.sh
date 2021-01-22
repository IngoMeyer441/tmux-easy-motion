#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${CURRENT_DIR}"

# shellcheck source=./common_variables.sh
source "${SCRIPTS_DIR}/common_variables.sh"
# shellcheck source=./helpers.sh
source "${SCRIPTS_DIR}/helpers.sh"

write_target_key() {
    local server_pid session_id target_key target_key_pipe_tmp_directory

    server_pid="$1"
    session_id="$2"
    target_key="$3"
    target_key_pipe_tmp_directory=$(get_target_key_pipe_tmp_directory "${server_pid}" "${session_id}")

    echo "${target_key}" >> "${target_key_pipe_tmp_directory}/${TARGET_KEY_PIPENAME}"
}

main() {
    local server_pid session_id parent_directory
    server_pid="$1"
    session_id="$2"

    # The script can be called without a key to only (re)create the target pipe
    if (( $# == 2 )); then
        parent_directory=$(get_target_key_pipe_parent_directory "${server_pid}")
        rm -rf "${parent_directory}" || return
        mkdir -m 700 -p "${parent_directory}"
    else
        ensure_target_key_pipe_exists "${server_pid}" "${session_id}"
        write_target_key "$@"
    fi
}

main "$@"
