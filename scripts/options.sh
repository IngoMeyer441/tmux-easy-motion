#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${CURRENT_DIR}"

# shellcheck source=./helpers.sh
source "${SCRIPTS_DIR}/helpers.sh"


EASY_MOTION_KEY_DEFAULT="Space"
EASY_MOTION_DIM_STYLE_DEFAULT="fg=colour242"
EASY_MOTION_HIGHLIGHT_STYLE_DEFAULT="fg=colour196,bold"
EASY_MOTION_HIGHLIGHT_2_FIRST_STYLE_DEFAULT="fg=brightyellow,bold"
EASY_MOTION_HIGHLIGHT_2_SECOND_STYLE_DEFAULT="fg=yellow,bold"
EASY_MOTION_TARGET_KEYS_DEFAULT="asdghklqwertyuiopzxcvbnmfj;"

EASY_MOTION_KEY_OPTION="@easy-motion-prefix"
EASY_MOTION_DIM_STYLE_OPTION="@easy-motion-dim-style"
EASY_MOTION_HIGHLIGHT_STYLE_OPTION="@easy-motion-highlight-style"
EASY_MOTION_HIGHLIGHT_2_FIRST_STYLE_OPTION="@easy-motion-highlight-2-first-style"
EASY_MOTION_HIGHLIGHT_2_SECOND_STYLE_OPTION="@easy-motion-highlight-2-second-style"
EASY_MOTION_TARGET_KEYS_OPTION="@easy-motion-target-keys"


read_options() {
    EASY_MOTION_KEY="$(get_tmux_option "${EASY_MOTION_KEY_OPTION}" "${EASY_MOTION_KEY_DEFAULT}")" && \
    EASY_MOTION_DIM_STYLE="$(get_tmux_option "${EASY_MOTION_DIM_STYLE_OPTION}" "${EASY_MOTION_DIM_STYLE_DEFAULT}")" && \
    EASY_MOTION_HIGHLIGHT_STYLE="$(get_tmux_option "${EASY_MOTION_HIGHLIGHT_STYLE_OPTION}" "${EASY_MOTION_HIGHLIGHT_STYLE_DEFAULT}")" && \
    EASY_MOTION_HIGHLIGHT_2_FIRST_STYLE="$(get_tmux_option "${EASY_MOTION_HIGHLIGHT_2_FIRST_STYLE_OPTION}" "${EASY_MOTION_HIGHLIGHT_2_FIRST_STYLE_DEFAULT}")" && \
    EASY_MOTION_HIGHLIGHT_2_SECOND_STYLE="$(get_tmux_option "${EASY_MOTION_HIGHLIGHT_2_SECOND_STYLE_OPTION}" "${EASY_MOTION_HIGHLIGHT_2_SECOND_STYLE_DEFAULT}")" && \
    EASY_MOTION_TARGET_KEYS="$(get_tmux_option "${EASY_MOTION_TARGET_KEYS_OPTION}" "${EASY_MOTION_TARGET_KEYS_DEFAULT}")"
}