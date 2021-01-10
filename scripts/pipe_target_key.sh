#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${CURRENT_DIR}"

# shellcheck source=./common_variables.sh
source "${SCRIPTS_DIR}/common_variables.sh"


create_target_key_pipe() {
    local recreate

    if [[ "$1" == "recreate" ]]; then
        recreate=1
    else
        recreate=0
    fi

    [[ -n "${TARGET_KEY_PIPE_TMP_DIRECTORY}" ]] || return
    if (( recreate )); then
        rm -rf "${TARGET_KEY_PIPE_TMP_DIRECTORY}" || return
    fi
    if [[ ! -d  "${TARGET_KEY_PIPE_TMP_DIRECTORY}" ]]; then
        mkdir -p "${TARGET_KEY_PIPE_TMP_DIRECTORY}" && \
        chmod 700 "${TARGET_KEY_PIPE_TMP_DIRECTORY}" && \
        mkfifo "${TARGET_KEY_PIPE_TMP_DIRECTORY}/${TARGET_KEY_PIPENAME}"
    fi
}

write_target_key() {
    local target_key

    target_key="$1"
    echo "${target_key}" >> "${TARGET_KEY_PIPE_TMP_DIRECTORY}/${TARGET_KEY_PIPENAME}"
}

main() {
    # The script can be called without arguments to only (re)create the target pipe
    if (( $# == 0 )); then
        create_target_key_pipe recreate
    else
        create_target_key_pipe && \
        write_target_key "$@"
    fi
}

main "$@"
