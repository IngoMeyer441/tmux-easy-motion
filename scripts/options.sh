# shellcheck shell=bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${CURRENT_DIR}"

# shellcheck source=./helpers.sh
source "${SCRIPTS_DIR}/helpers.sh"


# Default settings
EASY_MOTION_PREFIX_ENABLED_DEFAULT=1
EASY_MOTION_PREFIX_DEFAULT="Space"
EASY_MOTION_COPY_MODE_PREFIX_ENABLED_DEFAULT=1
EASY_MOTION_DIM_STYLE_DEFAULT="fg=colour242"
EASY_MOTION_HIGHLIGHT_STYLE_DEFAULT="fg=colour196,bold"
EASY_MOTION_HIGHLIGHT_2_FIRST_STYLE_DEFAULT="fg=brightyellow,bold"
EASY_MOTION_HIGHLIGHT_2_SECOND_STYLE_DEFAULT="fg=yellow,bold"
EASY_MOTION_TARGET_KEYS_DEFAULT="asdghklqwertyuiopzxcvbnmfj;"
EASY_MOTION_VERBOSE_DEFAULT=0
EASY_MOTION_DEFAULT_KEY_BINDINGS_DEFAULT=1
EASY_MOTION_DEFAULT_MOTION_DEFAULT=""
EASY_MOTION_AUTO_BEGIN_SELECTION_DEFAULT=0
# --- key bindings
EASY_MOTION_BINDING_B_DEFAULT="b"
EASY_MOTION_BINDING_CAPITAL_B_DEFAULT="B"
EASY_MOTION_BINDING_GE_DEFAULT="ge"
EASY_MOTION_BINDING_CAPITAL_GE_DEFAULT="gE"
EASY_MOTION_BINDING_E_DEFAULT="e"
EASY_MOTION_BINDING_CAPITAL_E_DEFAULT="E"
EASY_MOTION_BINDING_W_DEFAULT="w"
EASY_MOTION_BINDING_CAPITAL_W_DEFAULT="W"
EASY_MOTION_BINDING_J_DEFAULT="j"
EASY_MOTION_BINDING_CAPITAL_J_DEFAULT="J"
EASY_MOTION_BINDING_K_DEFAULT="k"
EASY_MOTION_BINDING_CAPITAL_K_DEFAULT="K"
EASY_MOTION_BINDING_F_DEFAULT="f"
EASY_MOTION_BINDING_CAPITAL_F_DEFAULT="F"
EASY_MOTION_BINDING_T_DEFAULT="t"
EASY_MOTION_BINDING_CAPITAL_T_DEFAULT="T"
EASY_MOTION_BINDING_BD_W_DEFAULT=""
EASY_MOTION_BINDING_CAPITAL_BD_W_DEFAULT=""
EASY_MOTION_BINDING_BD_E_DEFAULT=""
EASY_MOTION_BINDING_CAPITAL_BD_E_DEFAULT=""
EASY_MOTION_BINDING_BD_J_DEFAULT=""
EASY_MOTION_BINDING_CAPITAL_BD_J_DEFAULT=""
EASY_MOTION_BINDING_BD_F_DEFAULT="s"
EASY_MOTION_BINDING_BD_F2_DEFAULT=""
EASY_MOTION_BINDING_BD_T_DEFAULT=""
EASY_MOTION_BINDING_CAPITAL_BD_T_DEFAULT=""
EASY_MOTION_BINDING_C_DEFAULT="c"

# Option names
EASY_MOTION_PREFIX_ENABLED_OPTION="@easy-motion-prefix-enabled"
EASY_MOTION_PREFIX_OPTION="@easy-motion-prefix"
EASY_MOTION_COPY_MODE_PREFIX_ENABLED_OPTION="@easy-motion-copy-mode-prefix-enabled"
EASY_MOTION_COPY_MODE_PREFIX_OPTION="@easy-motion-copy-mode-prefix"
EASY_MOTION_DIM_STYLE_OPTION="@easy-motion-dim-style"
EASY_MOTION_HIGHLIGHT_STYLE_OPTION="@easy-motion-highlight-style"
EASY_MOTION_HIGHLIGHT_2_FIRST_STYLE_OPTION="@easy-motion-highlight-2-first-style"
EASY_MOTION_HIGHLIGHT_2_SECOND_STYLE_OPTION="@easy-motion-highlight-2-second-style"
EASY_MOTION_TARGET_KEYS_OPTION="@easy-motion-target-keys"
EASY_MOTION_VERBOSE_OPTION="@easy-motion-verbose"
EASY_MOTION_DEFAULT_KEY_BINDINGS_OPTION="@easy-motion-default-key-bindings"
EASY_MOTION_DEFAULT_MOTION_OPTION="@easy-motion-default-motion"
EASY_MOTION_AUTO_BEGIN_SELECTION_OPTION="@easy-motion-auto-begin-selection"
# --- key bindings
EASY_MOTION_BINDING_B_OPTION="@easy-motion-binding-b"
EASY_MOTION_BINDING_CAPITAL_B_OPTION="@easy-motion-binding-B"
EASY_MOTION_BINDING_GE_OPTION="@easy-motion-binding-ge"
EASY_MOTION_BINDING_CAPITAL_GE_OPTION="@easy-motion-binding-gE"
EASY_MOTION_BINDING_E_OPTION="@easy-motion-binding-e"
EASY_MOTION_BINDING_CAPITAL_E_OPTION="@easy-motion-binding-E"
EASY_MOTION_BINDING_W_OPTION="@easy-motion-binding-w"
EASY_MOTION_BINDING_CAPITAL_W_OPTION="@easy-motion-binding-W"
EASY_MOTION_BINDING_J_OPTION="@easy-motion-binding-j"
EASY_MOTION_BINDING_CAPITAL_J_OPTION="@easy-motion-binding-J"  # end of line
EASY_MOTION_BINDING_K_OPTION="@easy-motion-binding-k"
EASY_MOTION_BINDING_CAPITAL_K_OPTION="@easy-motion-binding-K"  # end of line
EASY_MOTION_BINDING_F_OPTION="@easy-motion-binding-f"
EASY_MOTION_BINDING_CAPITAL_F_OPTION="@easy-motion-binding-F"
EASY_MOTION_BINDING_T_OPTION="@easy-motion-binding-t"
EASY_MOTION_BINDING_CAPITAL_T_OPTION="@easy-motion-binding-T"
EASY_MOTION_BINDING_BD_W_OPTION="@easy-motion-binding-bd-w"  # bd -> bidirectional
EASY_MOTION_BINDING_CAPITAL_BD_W_OPTION="@easy-motion-binding-bd-W"
EASY_MOTION_BINDING_BD_E_OPTION="@easy-motion-binding-bd-e"
EASY_MOTION_BINDING_CAPITAL_BD_E_OPTION="@easy-motion-binding-bd-E"
EASY_MOTION_BINDING_BD_J_OPTION="@easy-motion-binding-bd-j"
EASY_MOTION_BINDING_CAPITAL_BD_J_OPTION="@easy-motion-binding-bd-J"
EASY_MOTION_BINDING_BD_F_OPTION="@easy-motion-binding-bd-f"
EASY_MOTION_BINDING_BD_F2_OPTION="@easy-motion-binding-bd-f2"
EASY_MOTION_BINDING_BD_T_OPTION="@easy-motion-binding-bd-t"
EASY_MOTION_BINDING_CAPITAL_BD_T_OPTION="@easy-motion-binding-bd-T"
EASY_MOTION_BINDING_C_OPTION="@easy-motion-binding-c"  # camelCase or underscore notation


read_options() {
    # shellcheck disable=SC2034
    assign_tmux_bool_option "EASY_MOTION_PREFIX_ENABLED" \
                            "${EASY_MOTION_PREFIX_ENABLED_OPTION}" \
                            "${EASY_MOTION_PREFIX_ENABLED_DEFAULT}" && \
    assign_tmux_option "EASY_MOTION_PREFIX" \
                       "${EASY_MOTION_PREFIX_OPTION}" \
                       "${EASY_MOTION_PREFIX_DEFAULT}" && \
    assign_tmux_bool_option "EASY_MOTION_COPY_MODE_PREFIX_ENABLED" \
                            "${EASY_MOTION_COPY_MODE_PREFIX_ENABLED_OPTION}" \
                            "${EASY_MOTION_COPY_MODE_PREFIX_ENABLED_DEFAULT}" && \
    assign_tmux_option "EASY_MOTION_COPY_MODE_PREFIX" \
                       "${EASY_MOTION_COPY_MODE_PREFIX_OPTION}" \
                       "${EASY_MOTION_PREFIX}" && \
    assign_tmux_option "EASY_MOTION_DIM_STYLE" \
                       "${EASY_MOTION_DIM_STYLE_OPTION}" \
                       "${EASY_MOTION_DIM_STYLE_DEFAULT}" && \
    assign_tmux_option "EASY_MOTION_HIGHLIGHT_STYLE" \
                       "${EASY_MOTION_HIGHLIGHT_STYLE_OPTION}" \
                       "${EASY_MOTION_HIGHLIGHT_STYLE_DEFAULT}" && \
    assign_tmux_option "EASY_MOTION_HIGHLIGHT_2_FIRST_STYLE" \
                       "${EASY_MOTION_HIGHLIGHT_2_FIRST_STYLE_OPTION}" \
                       "${EASY_MOTION_HIGHLIGHT_2_FIRST_STYLE_DEFAULT}" && \
    assign_tmux_option "EASY_MOTION_HIGHLIGHT_2_SECOND_STYLE" \
                       "${EASY_MOTION_HIGHLIGHT_2_SECOND_STYLE_OPTION}" \
                       "${EASY_MOTION_HIGHLIGHT_2_SECOND_STYLE_DEFAULT}" && \
    assign_tmux_option "EASY_MOTION_TARGET_KEYS" \
                       "${EASY_MOTION_TARGET_KEYS_OPTION}" \
                       "${EASY_MOTION_TARGET_KEYS_DEFAULT}" && \
    assign_tmux_bool_option "EASY_MOTION_VERBOSE" \
                            "${EASY_MOTION_VERBOSE_OPTION}" \
                            "${EASY_MOTION_VERBOSE_DEFAULT}" && \
    assign_tmux_bool_option "EASY_MOTION_DEFAULT_KEY_BINDINGS" \
                            "${EASY_MOTION_DEFAULT_KEY_BINDINGS_OPTION}" \
                            "${EASY_MOTION_DEFAULT_KEY_BINDINGS_DEFAULT}" && \
    assign_tmux_option "EASY_MOTION_DEFAULT_MOTION" \
                       "${EASY_MOTION_DEFAULT_MOTION_OPTION}" \
                       "${EASY_MOTION_DEFAULT_MOTION_DEFAULT}" || return
    assign_tmux_bool_option "EASY_MOTION_AUTO_BEGIN_SELECTION" \
                       "${EASY_MOTION_AUTO_BEGIN_SELECTION_OPTION}" \
                       "${EASY_MOTION_AUTO_BEGIN_SELECTION_DEFAULT}" || return

    # key bindings
    # shellcheck disable=SC2034
    if [[ -z "${EASY_MOTION_DEFAULT_MOTION}" ]]; then
        if (( EASY_MOTION_DEFAULT_KEY_BINDINGS )); then
            assign_tmux_option "EASY_MOTION_BINDING_B" \
                               "${EASY_MOTION_BINDING_B_OPTION}" \
                               "${EASY_MOTION_BINDING_B_DEFAULT}" && \
            assign_tmux_option "EASY_MOTION_BINDING_CAPITAL_B" \
                               "${EASY_MOTION_BINDING_CAPITAL_B_OPTION}" \
                               "${EASY_MOTION_BINDING_CAPITAL_B_DEFAULT}" && \
            assign_tmux_option "EASY_MOTION_BINDING_GE" \
                               "${EASY_MOTION_BINDING_GE_OPTION}" \
                               "${EASY_MOTION_BINDING_GE_DEFAULT}" && \
            assign_tmux_option "EASY_MOTION_BINDING_CAPITAL_GE" \
                               "${EASY_MOTION_BINDING_CAPITAL_GE_OPTION}" \
                               "${EASY_MOTION_BINDING_CAPITAL_GE_DEFAULT}" && \
            assign_tmux_option "EASY_MOTION_BINDING_E" \
                               "${EASY_MOTION_BINDING_E_OPTION}" \
                               "${EASY_MOTION_BINDING_E_DEFAULT}" && \
            assign_tmux_option "EASY_MOTION_BINDING_CAPITAL_E" \
                               "${EASY_MOTION_BINDING_CAPITAL_E_OPTION}" \
                               "${EASY_MOTION_BINDING_CAPITAL_E_DEFAULT}" && \
            assign_tmux_option "EASY_MOTION_BINDING_W" \
                               "${EASY_MOTION_BINDING_W_OPTION}" \
                               "${EASY_MOTION_BINDING_W_DEFAULT}" && \
            assign_tmux_option "EASY_MOTION_BINDING_CAPITAL_W" \
                               "${EASY_MOTION_BINDING_CAPITAL_W_OPTION}" \
                               "${EASY_MOTION_BINDING_CAPITAL_W_DEFAULT}" && \
            assign_tmux_option "EASY_MOTION_BINDING_J" \
                               "${EASY_MOTION_BINDING_J_OPTION}" \
                               "${EASY_MOTION_BINDING_J_DEFAULT}" && \
            assign_tmux_option "EASY_MOTION_BINDING_CAPITAL_J" \
                               "${EASY_MOTION_BINDING_CAPITAL_J_OPTION}" \
                               "${EASY_MOTION_BINDING_CAPITAL_J_DEFAULT}" && \
            assign_tmux_option "EASY_MOTION_BINDING_K" \
                               "${EASY_MOTION_BINDING_K_OPTION}" \
                               "${EASY_MOTION_BINDING_K_DEFAULT}" && \
            assign_tmux_option "EASY_MOTION_BINDING_CAPITAL_K" \
                               "${EASY_MOTION_BINDING_CAPITAL_K_OPTION}" \
                               "${EASY_MOTION_BINDING_CAPITAL_K_DEFAULT}" && \
            assign_tmux_option "EASY_MOTION_BINDING_F" \
                               "${EASY_MOTION_BINDING_F_OPTION}" \
                               "${EASY_MOTION_BINDING_F_DEFAULT}" && \
            assign_tmux_option "EASY_MOTION_BINDING_CAPITAL_F" \
                               "${EASY_MOTION_BINDING_CAPITAL_F_OPTION}" \
                               "${EASY_MOTION_BINDING_CAPITAL_F_DEFAULT}" && \
            assign_tmux_option "EASY_MOTION_BINDING_T" \
                               "${EASY_MOTION_BINDING_T_OPTION}" \
                               "${EASY_MOTION_BINDING_T_DEFAULT}" && \
            assign_tmux_option "EASY_MOTION_BINDING_CAPITAL_T" \
                               "${EASY_MOTION_BINDING_CAPITAL_T_OPTION}" \
                               "${EASY_MOTION_BINDING_CAPITAL_T_DEFAULT}" && \
            assign_tmux_option "EASY_MOTION_BINDING_BD_W" \
                               "${EASY_MOTION_BINDING_BD_W_OPTION}" \
                               "${EASY_MOTION_BINDING_BD_W_DEFAULT}" && \
            assign_tmux_option "EASY_MOTION_BINDING_CAPITAL_BD_W" \
                               "${EASY_MOTION_BINDING_CAPITAL_BD_W_OPTION}" \
                               "${EASY_MOTION_BINDING_CAPITAL_BD_W_DEFAULT}" && \
            assign_tmux_option "EASY_MOTION_BINDING_BD_E" \
                               "${EASY_MOTION_BINDING_BD_E_OPTION}" \
                               "${EASY_MOTION_BINDING_BD_E_DEFAULT}" && \
            assign_tmux_option "EASY_MOTION_BINDING_CAPITAL_BD_E" \
                               "${EASY_MOTION_BINDING_CAPITAL_BD_E_OPTION}" \
                               "${EASY_MOTION_BINDING_CAPITAL_BD_E_DEFAULT}" && \
            assign_tmux_option "EASY_MOTION_BINDING_BD_J" \
                               "${EASY_MOTION_BINDING_BD_J_OPTION}" \
                               "${EASY_MOTION_BINDING_BD_J_DEFAULT}" && \
            assign_tmux_option "EASY_MOTION_BINDING_CAPITAL_BD_J" \
                               "${EASY_MOTION_BINDING_CAPITAL_BD_J_OPTION}" \
                               "${EASY_MOTION_BINDING_CAPITAL_BD_J_DEFAULT}" && \
            assign_tmux_option "EASY_MOTION_BINDING_BD_F" \
                               "${EASY_MOTION_BINDING_BD_F_OPTION}" \
                               "${EASY_MOTION_BINDING_BD_F_DEFAULT}" && \
            assign_tmux_option "EASY_MOTION_BINDING_BD_F2" \
                               "${EASY_MOTION_BINDING_BD_F2_OPTION}" \
                               "${EASY_MOTION_BINDING_BD_F2_DEFAULT}" && \
            assign_tmux_option "EASY_MOTION_BINDING_BD_T" \
                               "${EASY_MOTION_BINDING_BD_T_OPTION}" \
                               "${EASY_MOTION_BINDING_BD_T_DEFAULT}" && \
            assign_tmux_option "EASY_MOTION_BINDING_CAPITAL_BD_T" \
                               "${EASY_MOTION_BINDING_CAPITAL_BD_T_OPTION}" \
                               "${EASY_MOTION_BINDING_CAPITAL_BD_T_DEFAULT}" && \
            assign_tmux_option "EASY_MOTION_BINDING_C" \
                               "${EASY_MOTION_BINDING_C_OPTION}" \
                               "${EASY_MOTION_BINDING_C_DEFAULT}"
        else
            assign_tmux_option "EASY_MOTION_BINDING_B" \
                               "${EASY_MOTION_BINDING_B_OPTION}" \
                               "" && \
            assign_tmux_option "EASY_MOTION_BINDING_CAPITAL_B" \
                               "${EASY_MOTION_BINDING_CAPITAL_B_OPTION}" \
                               "" && \
            assign_tmux_option "EASY_MOTION_BINDING_GE" \
                               "${EASY_MOTION_BINDING_GE_OPTION}" \
                               "" && \
            assign_tmux_option "EASY_MOTION_BINDING_CAPITAL_GE" \
                               "${EASY_MOTION_BINDING_CAPITAL_GE_OPTION}" \
                               "" && \
            assign_tmux_option "EASY_MOTION_BINDING_E" \
                               "${EASY_MOTION_BINDING_E_OPTION}" \
                               "" && \
            assign_tmux_option "EASY_MOTION_BINDING_CAPITAL_E" \
                               "${EASY_MOTION_BINDING_CAPITAL_E_OPTION}" \
                               "" && \
            assign_tmux_option "EASY_MOTION_BINDING_W" \
                               "${EASY_MOTION_BINDING_W_OPTION}" \
                               "" && \
            assign_tmux_option "EASY_MOTION_BINDING_CAPITAL_W" \
                               "${EASY_MOTION_BINDING_CAPITAL_W_OPTION}" \
                               "" && \
            assign_tmux_option "EASY_MOTION_BINDING_J" \
                               "${EASY_MOTION_BINDING_J_OPTION}" \
                               "" && \
            assign_tmux_option "EASY_MOTION_BINDING_CAPITAL_J" \
                               "${EASY_MOTION_BINDING_CAPITAL_J_OPTION}" \
                               "" && \
            assign_tmux_option "EASY_MOTION_BINDING_K" \
                               "${EASY_MOTION_BINDING_K_OPTION}" \
                               "" && \
            assign_tmux_option "EASY_MOTION_BINDING_CAPITAL_K" \
                               "${EASY_MOTION_BINDING_CAPITAL_K_OPTION}" \
                               "" && \
            assign_tmux_option "EASY_MOTION_BINDING_F" \
                               "${EASY_MOTION_BINDING_F_OPTION}" \
                               "" && \
            assign_tmux_option "EASY_MOTION_BINDING_CAPITAL_F" \
                               "${EASY_MOTION_BINDING_CAPITAL_F_OPTION}" \
                               "" && \
            assign_tmux_option "EASY_MOTION_BINDING_T" \
                               "${EASY_MOTION_BINDING_T_OPTION}" \
                               "" && \
            assign_tmux_option "EASY_MOTION_BINDING_CAPITAL_T" \
                               "${EASY_MOTION_BINDING_CAPITAL_T_OPTION}" \
                               "" && \
            assign_tmux_option "EASY_MOTION_BINDING_BD_W" \
                               "${EASY_MOTION_BINDING_BD_W_OPTION}" \
                               "" && \
            assign_tmux_option "EASY_MOTION_BINDING_CAPITAL_BD_W" \
                               "${EASY_MOTION_BINDING_CAPITAL_BD_W_OPTION}" \
                               "" && \
            assign_tmux_option "EASY_MOTION_BINDING_BD_E" \
                               "${EASY_MOTION_BINDING_BD_E_OPTION}" \
                               "" && \
            assign_tmux_option "EASY_MOTION_BINDING_CAPITAL_BD_E" \
                               "${EASY_MOTION_BINDING_CAPITAL_BD_E_OPTION}" \
                               "" && \
            assign_tmux_option "EASY_MOTION_BINDING_BD_J" \
                               "${EASY_MOTION_BINDING_BD_J_OPTION}" \
                               "" && \
            assign_tmux_option "EASY_MOTION_BINDING_CAPITAL_BD_J" \
                               "${EASY_MOTION_BINDING_CAPITAL_BD_J_OPTION}" \
                               "" && \
            assign_tmux_option "EASY_MOTION_BINDING_BD_F" \
                               "${EASY_MOTION_BINDING_BD_F_OPTION}" \
                               "" && \
            assign_tmux_option "EASY_MOTION_BINDING_BD_F2" \
                               "${EASY_MOTION_BINDING_BD_F2_OPTION}" \
                               "" && \
            assign_tmux_option "EASY_MOTION_BINDING_BD_T" \
                               "${EASY_MOTION_BINDING_BD_T_OPTION}" \
                               "" && \
            assign_tmux_option "EASY_MOTION_BINDING_CAPITAL_BD_T" \
                               "${EASY_MOTION_BINDING_CAPITAL_BD_T_OPTION}" \
                               "" && \
            assign_tmux_option "EASY_MOTION_BINDING_C" \
                               "${EASY_MOTION_BINDING_C_OPTION}" \
                               ""
        fi
    fi
}
