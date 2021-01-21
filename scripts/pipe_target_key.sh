#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${CURRENT_DIR}"

# shellcheck source=./common_variables.sh
source "${SCRIPTS_DIR}/common_variables.sh"
# shellcheck source=./helpers.sh
source "${SCRIPTS_DIR}/helpers.sh"

create_target_key_pipe() {
    local server_pid recreate target_key_pipe_tmp_directory

    server_pid="$1"
    if [[ "$2" == "recreate" ]]; then
        recreate=1
    else
        recreate=0
    fi

    target_key_pipe_tmp_directory=$(get_target_key_pipe_tmp_directory "${server_pid}")

    [[ -n "${target_key_pipe_tmp_directory}" ]] || return
    if (( recreate )); then
        rm -rf "${target_key_pipe_tmp_directory}" || return
    fi
    if [[ ! -d  "${target_key_pipe_tmp_directory}" ]]; then
        mkdir -p "${target_key_pipe_tmp_directory}" && \
        chmod 700 "${target_key_pipe_tmp_directory}" && \
        mkfifo "${target_key_pipe_tmp_directory}/${TARGET_KEY_PIPENAME}"
    fi
}

write_target_key() {
    local server_pid target_key target_key_pipe_tmp_directory

    server_pid="$1"
    target_key="$2"
    target_key_pipe_tmp_directory=$(get_target_key_pipe_tmp_directory "${server_pid}")

    echo "${target_key}" >> "${target_key_pipe_tmp_directory}/${TARGET_KEY_PIPENAME}"
}

main() {
    local server_pid
    server_pid="$1"

    # The script can be called without a key to only (re)create the target pipe
    if (( $# == 1 )); then
        create_target_key_pipe "${server_pid}" recreate
    else
        create_target_key_pipe "${server_pid}" && \
        write_target_key "$@"
    fi
}

main "$@"
