#!/usr/bin/env python
# -*- coding: utf-8 -*-

from __future__ import absolute_import
from __future__ import division
from __future__ import print_function
from __future__ import unicode_literals

import codecs
import os
import re
import sys
import termios
import time

PY2 = sys.version_info.major < 3  # is needed for correct mypy checking

if PY2:
    from itertools import izip_longest as zip_longest
else:
    from itertools import zip_longest

try:
    from typing import (  # noqa: F401  # pylint: disable=unused-import
        cast,
        Any,
        AnyStr,
        Callable,
        Dict,
        IO,
        Iterable,
        Iterator,
        Generator,
        List,
        Optional,
        Tuple,
        Union,
    )
except ImportError:
    cast = lambda t, x: x  # type: ignore  # noqa: E731

if PY2:
    str = unicode

VALID_MOTIONS = frozenset(("b", "B", "ge", "gE", "e", "E", "w", "W", "j", "J", "k", "K", "f", "F", "t", "T", "s", "c"))
MOTIONS_WITH_ARGUMENT = frozenset(("f", "F", "t", "T", "s"))
FORWARD_MOTIONS = frozenset(("e", "E", "w", "W", "j", "J", "f", "t", "s", "c"))
BACKWARD_MOTIONS = frozenset(("b", "B", "ge", "gE", "k", "K", "F", "T", "s", "c"))
LINEWISE_MOTIONS = frozenset(("j", "J", "k", "K"))
VIOPP_INCREMENT_CURSOR_MOTIONS = frozenset(("e", "E", "ge", "gE", "f", "t"))
VIOPP_INCREMENT_CURSOR_ON_FORWARD_MOTIONS = frozenset(("s"))
MOTION_TO_REGEX = {
    "b": r"\b(\w)",
    "B": r"(?:^|\s)(\S)",
    "ge": r"(\w)\b",
    "gE": r"(\S)(?:\s|$)",
    "e": r"(\w)\b",
    "E": r"(\S)(?:\s|$)",
    "w": r"\b(\w)",
    "W": r"\s(\S)",
    "j": r"^(?:\s*)(\S)",
    "J": r"(\S)(?:\s*)$",
    "k": r"^(?:\s*)(\S)",
    "K": r"(\S)(?:\s*)$",
    "f": r"({})",
    "F": r"({})",
    "t": r"(.){}",
    "T": r"{}(.)",
    "s": r"({})",
    "c": r"(?:_(\w))|(?:[a-z]([A-Z]))",
}


class MissingDimStyleError(Exception):
    pass


class InvalidDimStyleError(Exception):
    pass


class MissingHighlightStyleError(Exception):
    pass


class InvalidHighlightStyleError(Exception):
    pass


class MissingHighlight2FirstStyleError(Exception):
    pass


class InvalidHighlight2FirstStyleError(Exception):
    pass


class MissingHighlight2SecondStyleError(Exception):
    pass


class InvalidHighlight2SecondStyleError(Exception):
    pass


class MissingMotionError(Exception):
    pass


class InvalidMotionError(Exception):
    pass


class MissingTargetKeysError(Exception):
    pass


class MissingCursorPositionError(Exception):
    pass


class InvalidCursorPositionError(Exception):
    pass


class MissingPaneSizeError(Exception):
    pass


class InvalidPaneSizeError(Exception):
    pass


class MissingCaptureBufferFilepathError(Exception):
    pass


class MissingJumpCommandPipeFilepathError(Exception):
    pass


class MissingTargetKeyPipeFilepathError(Exception):
    pass


class InvalidMotionError(Exception):
    pass


class InvalidTargetError(Exception):
    pass


class ReadState(object):
    MOTION_ARGUMENT = 0
    TARGET = 1
    HIGHLIGHT = 2


class TerminalCodes(object):
    class Style(object):
        BLINK = "\033[5m"
        BOLD = "\033[1m"
        DIM = "\033[2m"
        ITALIC = "\033[3m"
        UNDERLINE = "\033[4m"
        REVERSE = "\033[7m"
        CONCEAL = "\033[8m"
        OVERLINE = "\033[53m"
        STRIKE = "\033[9m"
        DOUBLE_UNDERLINE = "\033[4:2m"
        CURLY_UNDERLINE = "\033[4:3m"
        DOTTED_UNDERLINE = "\033[4:4m"
        DASHED_UNDERLINE = "\033[4:5m"
        RESET = "\033[0m"

        @classmethod
        def color16(cls, name, bg=False):
            # type: (str, bool) -> str
            name_to_index = {
                "black": 0,
                "red": 1,
                "green": 2,
                "yellow": 3,
                "blue": 4,
                "magenta": 5,
                "cyan": 6,
                "white": 7,
                "brightblack": 8,
                "brightred": 9,
                "brightgreen": 10,
                "brightyellow": 11,
                "brightblue": 12,
                "brightmagenta": 13,
                "brightcyan": 14,
                "brightwhite": 15,
            }  # type: Dict[str, int]
            if name not in name_to_index:
                raise KeyError(
                    '"{}" is not a valid color name. Valid color names are: "{}"'.format(
                        name, '", "'.join(name_to_index.keys())
                    )
                )
            color_index = name_to_index[name]
            ansi_code = 30 + color_index
            if color_index > 7:
                ansi_code += 60 - 8
            if bg:
                ansi_code += 10
            return "\033[{:d}m".format(ansi_code)

        @classmethod
        def color256(cls, color_index, bg=False):
            # type: (int, bool) -> str
            if not 0 <= color_index < 256:
                raise IndexError("The color index must be an integer between 0 and 255.")
            return "\033[{:d};5;{:d}m".format(48 if bg else 38, color_index)

        @classmethod
        def truecolor(cls, r, g, b, bg=False):
            # type: (int, int, int, bool) -> str
            if not all(0 <= c < 256 for c in (r, g, b)):
                raise IndexError("The color indices must be integers between 0 and 255.")
            return "\033[{:d};2;{:d};{:d};{:d}m".format(48 if bg else 38, r, g, b)

        @classmethod
        def parse_style(cls, style):
            # type: (str) -> str
            def color_to_code(color, bg=False):
                # type: (str, bool) -> str
                color = color.strip().lower()
                color256_regex = re.compile(r"^colou?r(\d+)$")
                truecolor_regex = re.compile(r"^#([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})$")
                color256_match = color256_regex.match(color)
                if color256_match:
                    return cls.color256(int(color256_match.group(1)), bg)
                truecolor_match = truecolor_regex.match(color)
                if truecolor_match:
                    return cls.truecolor(*[int(c, base=16) for c in truecolor_match.groups()], bg=bg)
                return cls.color16(color, bg)

            style_to_code = {
                "none": cls.RESET,
                "bold": cls.BOLD,
                "bright": cls.BOLD,
                "dim": cls.DIM,
                "underscore": cls.UNDERLINE,
                "blink": cls.BLINK,
                "reverse": cls.REVERSE,
                "hidden": cls.CONCEAL,
                "italics": cls.ITALIC,
                "overline": cls.OVERLINE,
                "double-underscore": cls.DOUBLE_UNDERLINE,
                "curly-underscore": cls.CURLY_UNDERLINE,
                "dotted-underscore": cls.DOTTED_UNDERLINE,
                "dashed-underscore": cls.DASHED_UNDERLINE,
                "fg=": lambda x: color_to_code(x, bg=False),
                "bg=": lambda x: color_to_code(x, bg=True),
            }  # type: Dict[str, Union[str, Callable[[str], str]]]
            style_parts = [part for part in re.split(r"(?:\s+)|(?:\s*,\s*)", style.lower()) if part]
            style_codes = []
            for style_part in style_parts:
                if "=" in style_part:
                    style_split = style_part.split("=")
                    style_key = style_split[0] + "="
                    style_argument = "=".join(style_split[1:])
                else:
                    style_key = style_part
                    style_argument = style_part
                style_code = style_to_code[style_key]
                if isinstance(style_code, str):
                    style_codes.append(style_code)
                else:
                    style_codes.append(style_code(style_argument))
            return "".join(style_codes)

    CLEAR_SCREEN = "\033[H\033[J"
    POSITION_CURSOR = "\033[{:d};{:d}H"


class JumpTarget(object):
    DIRECT = 0
    GROUP = 1
    PREVIEW = 2


def parse_arguments():
    # type: () -> Tuple[str, str, str, str, str, str, Tuple[int, int], Tuple[int, int], str, str, str]
    if PY2:
        argv = [arg.decode("utf-8") for arg in sys.argv]
    else:
        argv = list(sys.argv)
    # Remove program name from argument vector
    argv.pop(0)
    # Extract dim style
    if not argv:
        raise MissingDimStyleError("No dim style given.")
    try:
        dim_style = argv.pop(0)
        dim_style_code = TerminalCodes.Style.parse_style(dim_style)
    except (IndexError, KeyError):
        raise InvalidDimStyleError('"{}" is not a valid style.'.format(dim_style))
    # Extract highlight style
    if not argv:
        raise MissingHighlightStyleError("No highlight style given.")
    try:
        highlight_style = argv.pop(0)
        highlight_style_code = TerminalCodes.Style.parse_style(highlight_style)
    except (IndexError, KeyError):
        raise InvalidHighlightStyleError('"{}" is not a valid style.'.format(highlight_style))
    # Extract highlight 2 first style
    if not argv:
        raise MissingHighlight2FirstStyleError("No highlight 2 first style given.")
    try:
        highlight_2_first_style = argv.pop(0)
        highlight_2_first_style_code = TerminalCodes.Style.parse_style(highlight_2_first_style)
    except (IndexError, KeyError):
        raise InvalidHighlight2FirstStyleError('"{}" is not a valid style.'.format(highlight_2_first_style))
    # Extract highlight 2 second style
    if not argv:
        raise MissingHighlight2SecondStyleError("No highlight 2 second style given.")
    try:
        highlight_2_second_style = argv.pop(0)
        highlight_2_second_style_code = TerminalCodes.Style.parse_style(highlight_2_second_style)
    except (IndexError, KeyError):
        raise InvalidHighlight2SecondStyleError('"{}" is not a valid style.'.format(highlight_2_second_style))
    # Extract motion
    if not argv:
        raise MissingMotionError("No motion given.")
    if argv[0] not in VALID_MOTIONS:
        raise InvalidMotionError('The string "{}" is not in a valid motion.'.format(argv[0]))
    motion = argv.pop(0)
    # Extract target keys
    if not argv:
        raise MissingTargetKeysError("No target keys given.")
    target_keys = argv.pop(0)
    if len(target_keys) < 2:
        raise MissingTargetKeysError("At least two target keys are needed.")
    # Extract cursor position
    if not argv:
        raise MissingCursorPositionError("No cursor position given.")
    cursor_pos_match = re.match(r"(\d+):(\d+)", argv[0])
    if not cursor_pos_match:
        raise InvalidCursorPositionError('The cursor position "{}" is not in the format "<row>:<col>".'.format(argv[0]))
    cursor_position_row_col = (int(cursor_pos_match.group(1)), int(cursor_pos_match.group(2)))
    argv.pop(0)
    # Extract pane size
    if not argv:
        raise MissingPaneSizeError("No pane size given.")
    pane_size_match = re.match(r"(\d+):(\d+)", argv[0])
    if not pane_size_match:
        raise InvalidPaneSizeError('The pane size "{}" is not in the format "<width>:<height>".'.format(argv[0]))
    pane_size = (int(pane_size_match.group(1)), int(pane_size_match.group(2)))
    argv.pop(0)
    # Extract capture buffer filepath
    if not argv:
        raise MissingCaptureBufferFilepathError("No tmux capture buffer filepath given.")
    capture_buffer_filepath = argv.pop(0)
    # Extract jump command pipe filepath
    if not argv:
        raise MissingJumpCommandPipeFilepathError("No jump command pipe filepath given.")
    command_pipe_filepath = argv.pop(0)
    # Extract target key pipe filepath
    if not argv:
        raise MissingTargetKeyPipeFilepathError("No target key pipe filepath given.")
    target_key_pipe_filepath = argv.pop(0)
    return (
        dim_style_code,
        highlight_style_code,
        highlight_2_first_style_code,
        highlight_2_second_style_code,
        motion,
        target_keys,
        cursor_position_row_col,
        pane_size,
        capture_buffer_filepath,
        command_pipe_filepath,
        target_key_pipe_filepath,
    )


def convert_row_col_to_text_pos(row, col, text):
    # type: (int, int, str) -> int
    lines = text.split("\n")
    # Limit `row` and `col` to the existing text
    row = min(row, len(lines) - 1)
    row_line = lines[row]
    col = min(col, len(row_line) - 1)

    cursor_position = sum(len(line) for line in lines[:row]) + col
    cursor_position += row  # add `row` newline characters

    return cursor_position


def convert_text_pos_to_row_col(textpos, text):
    # type: (int, str) -> Tuple[int, int]
    lines = text.split("\n")
    current_textpos = 0
    row, col = 0, 0
    for line in lines:
        line_length = len(line)
        if current_textpos + line_length > textpos:
            col = textpos - current_textpos
            break
        row += 1
        current_textpos += line_length + 1
    else:
        raise IndexError('The text position "{:d}" is out of range.'.format(textpos))

    return (row, col)


def find_first_line_end(cursor_position, text):
    # type: (int, str) -> int
    first_line_end = re.match(r".*($)", text[cursor_position:], flags=re.MULTILINE)
    assert first_line_end is not None
    return first_line_end.end(1)


def find_latest_line_start(cursor_position, text):
    # type: (int, str) -> int
    latest_line_start = re.match(r"(?:.*)(^)", text[: cursor_position + 1], flags=re.MULTILINE | re.DOTALL)
    assert latest_line_start is not None
    return latest_line_start.start(1)


def adjust_text(cursor_position, text, is_forward_motion, motion):
    # type: (int, str, bool, str) -> Tuple[str, int]
    indices_offset = 0
    if is_forward_motion:
        if motion in LINEWISE_MOTIONS:
            first_line_end_index = find_first_line_end(cursor_position, text)
            text = text[cursor_position + first_line_end_index :]
            indices_offset = cursor_position + first_line_end_index
        else:
            text = text[cursor_position + 1 :]
            indices_offset = cursor_position + 1
    else:
        if motion in LINEWISE_MOTIONS:
            latest_line_start_index = find_latest_line_start(cursor_position, text)
            text = text[:latest_line_start_index]
        else:
            text = text[:cursor_position]
    return text, indices_offset


def motion_to_indices(cursor_position, text, motion, motion_argument):
    # type: (int, str, str, Optional[str]) -> Iterable[int]
    indices_offset = 0
    if motion in FORWARD_MOTIONS and motion in BACKWARD_MOTIONS:
        # Split the motion into the forward and backward motion and handle these recursively
        forward_motion_indices = motion_to_indices(cursor_position, text, motion + ">", motion_argument)
        backward_motion_indices = motion_to_indices(cursor_position, text, motion + "<", motion_argument)
        # Create a generator which yields the indices round-robin
        indices = (
            index
            for index_pair in zip_longest(forward_motion_indices, backward_motion_indices)
            for index in index_pair
            if index is not None
        )
    else:
        is_forward_motion = motion in FORWARD_MOTIONS or motion.endswith(">")
        if motion.endswith(">") or motion.endswith("<"):
            motion = motion[:-1]
        text, indices_offset = adjust_text(cursor_position, text, is_forward_motion, motion)
        if motion_argument is None:
            regex = re.compile(MOTION_TO_REGEX[motion], flags=re.MULTILINE)
        else:
            regex = re.compile(MOTION_TO_REGEX[motion].format(re.escape(motion_argument)), flags=re.MULTILINE)
        matches = regex.finditer(text)
        if not is_forward_motion:
            matches = reversed(list(matches))
        indices = (
            match_obj.start(i) + indices_offset
            for match_obj in matches
            for i in range(1, regex.groups + 1)
            if match_obj.start(i) >= 0
        )
    return indices


def group_indices(indices, group_length):
    # type: (Iterable[int], int) -> List[Any]

    def group(indices, group_length):
        # type: (Iterable[int], int) -> Union[List[Any], int]
        def find_required_slot_sizes(num_indices, group_length):
            # type: (int, int) -> List[int]
            if num_indices <= group_length:
                slot_sizes = num_indices * [1]
            else:
                slot_sizes = group_length * [1]
                next_increase_slot = group_length - 1
                while sum(slot_sizes) < num_indices:
                    slot_sizes[next_increase_slot] *= group_length
                    next_increase_slot = (next_increase_slot - 1 + group_length) % group_length
                previous_increase_slot = (next_increase_slot + 1) % group_length
                # Always fill rear slots first
                slot_sizes[previous_increase_slot] -= sum(slot_sizes) - num_indices
            return slot_sizes

        indices_as_tuple = tuple(indices)
        num_indices = len(indices_as_tuple)
        if num_indices == 1:
            return indices_as_tuple[0]
        slot_sizes = find_required_slot_sizes(num_indices, group_length)
        slot_start_indices = [0]
        for slot_size in slot_sizes[:-1]:
            slot_start_indices.append(slot_start_indices[-1] + slot_size)
        grouped_indices = [
            group(indices_as_tuple[slot_start_index : slot_start_index + slot_size], group_length)
            for slot_start_index, slot_size in zip(slot_start_indices, slot_sizes)
        ]
        return grouped_indices

    grouped_indices = group(indices, group_length)
    if isinstance(grouped_indices, int):
        return [grouped_indices]
    else:
        return grouped_indices


def generate_jump_targets(grouped_indices, target_keys):
    # type: (Iterable[Any], str) -> Generator[Tuple[int, int, str], None, None]
    def find_leaves(group_or_index):
        # type: (Union[Iterable[Any], int]) -> Iterator[int]
        if isinstance(group_or_index, int):
            yield group_or_index
        else:
            for sub_group_or_index in group_or_index:
                for leave in find_leaves(sub_group_or_index):
                    yield leave

    for target_key, group_or_index in zip(target_keys, grouped_indices):
        if isinstance(group_or_index, int):
            yield (JumpTarget.DIRECT, group_or_index, target_key)
        else:
            for preview_key, sub_group_or_index in zip(target_keys, group_or_index):
                for leave in find_leaves(sub_group_or_index):
                    yield (JumpTarget.GROUP, leave, target_key)
                    yield (JumpTarget.PREVIEW, leave + 1, preview_key)


def position_cursor(row, col):
    # type: (int, int) -> None
    sys.stdout.write(TerminalCodes.POSITION_CURSOR.format(row + 1, col + 1))
    sys.stdout.flush()


def print_text(capture_buffer):
    # type: (str) -> None
    sys.stdout.write(TerminalCodes.CLEAR_SCREEN)
    sys.stdout.write(capture_buffer.rstrip())
    sys.stdout.flush()


def print_text_with_targets(
    capture_buffer,
    grouped_indices,
    dim_style_code,
    highlight_style_code,
    highlight_2_first_style_code,
    highlight_2_second_style_code,
    target_keys,
    terminal_width,
):
    # type: (str, Iterable[Any], str, str, str, str, str, int) -> None
    target_type_to_color = {
        JumpTarget.DIRECT: highlight_style_code,
        JumpTarget.GROUP: highlight_2_first_style_code,
        JumpTarget.PREVIEW: highlight_2_second_style_code,
    }
    jump_targets = sorted(generate_jump_targets(grouped_indices, target_keys), key=lambda x: x[1])
    out_buffer_parts = []
    previous_text_pos = -1
    for target_type, text_pos, target_key in jump_targets:
        append_to_buffer = False
        append_extra_newline = False
        if capture_buffer[text_pos] != "\n":
            append_to_buffer = True
        else:
            # The (preview) target will be printed in an extra column at the line ending
            # -> Check if there is one additional column available, otherwise skip this preview
            append_extra_newline = True
            previous_newline_index = capture_buffer.rfind("\n", text_pos - terminal_width, text_pos)
            if previous_newline_index != 0:
                append_to_buffer = True
        if append_to_buffer:
            out_buffer_parts.extend(
                [
                    dim_style_code,
                    capture_buffer[previous_text_pos + 1 : text_pos],
                    TerminalCodes.Style.RESET,
                    target_type_to_color[target_type],
                    target_key,
                    TerminalCodes.Style.RESET,
                ]
            )
        if append_extra_newline:
            out_buffer_parts.append("\n")
        previous_text_pos = text_pos
    rest_of_capture_buffer = capture_buffer[previous_text_pos + 1 :].rstrip()
    if rest_of_capture_buffer:
        out_buffer_parts.extend([dim_style_code, rest_of_capture_buffer, TerminalCodes.Style.RESET])
    sys.stdout.write(TerminalCodes.CLEAR_SCREEN)
    sys.stdout.write("".join(out_buffer_parts).rstrip())
    sys.stdout.flush()


def print_ready(command_pipe):
    # type: (IO[str]) -> None
    print("ready", file=command_pipe)
    command_pipe.flush()


def print_jump_target(row, col, command_pipe):
    # type: (int, int, IO[str]) -> None
    print("jump {:d}:{:d}".format(row, col), file=command_pipe)
    command_pipe.flush()


def handle_user_input(
    dim_style_code,
    highlight_style_code,
    highlight_2_first_style_code,
    highlight_2_second_style_code,
    motion,
    target_keys,
    cursor_position_row_col,
    pane_size,
    capture_buffer_filepath,
    command_pipe_filepath,
    target_key_pipe_filepath,
):
    # type: (str, str, str, str, str, str, Tuple[int, int], Tuple[int, int], str, str, str) -> None
    fd = sys.stdin.fileno()

    def read_capture_buffer():
        # type: () -> str
        with codecs.open(capture_buffer_filepath, "r", encoding="utf-8") as f:
            capture_buffer = f.read()
        return capture_buffer

    def setup_terminal():
        # type: () -> List[Union[int, List[bytes]]]
        old_term_settings = termios.tcgetattr(fd)
        new_term_settings = termios.tcgetattr(fd)
        new_term_settings[3] = (
            cast(int, new_term_settings[3]) & ~termios.ICANON & ~termios.ECHO
        )  # unbuffered and no echo
        termios.tcsetattr(fd, termios.TCSADRAIN, new_term_settings)
        return old_term_settings

    def reset_terminal(old_term_settings):
        # type: (List[Union[int, List[bytes]]]) -> None
        termios.tcsetattr(fd, termios.TCSADRAIN, old_term_settings)

    old_term_settings = setup_terminal()

    if motion in MOTIONS_WITH_ARGUMENT:
        read_state = ReadState.MOTION_ARGUMENT
    else:
        read_state = ReadState.HIGHLIGHT
    motion_argument = None
    target = None
    grouped_indices = None
    first_highlight = True
    try:
        with codecs.open(command_pipe_filepath, "w", encoding="utf-8") as command_pipe:
            capture_buffer = read_capture_buffer()
            row, col = cursor_position_row_col
            pane_width, pane_height = pane_size
            cursor_position = convert_row_col_to_text_pos(row, col, capture_buffer)
            while True:
                if read_state != ReadState.HIGHLIGHT:
                    # Reopen the named pipe each time because the open operation blocks till the sender also reopens
                    # the pipe
                    with codecs.open(target_key_pipe_filepath, "r", encoding="utf-8") as target_key_pipe:
                        next_key = target_key_pipe.readline().rstrip("\n\r")
                    if next_key == "esc":
                        break
                if read_state == ReadState.MOTION_ARGUMENT:
                    motion_argument = next_key
                    read_state = ReadState.HIGHLIGHT
                elif read_state == ReadState.TARGET:
                    target = next_key
                    if target not in target_keys:
                        raise InvalidTargetError('The key "{}" is no valid target.'.format(target))
                    read_state = ReadState.HIGHLIGHT
                elif read_state == ReadState.HIGHLIGHT:
                    if grouped_indices is None:
                        indices = motion_to_indices(cursor_position, capture_buffer, motion, motion_argument)
                        grouped_indices = group_indices(indices, len(target_keys))
                    else:
                        try:
                            # pylint: disable=unsubscriptable-object
                            grouped_indices = grouped_indices[target_keys.index(target)]
                        except IndexError:
                            raise InvalidTargetError('The key "{}" is no valid target.'.format(target))
                    if not isinstance(grouped_indices, int):
                        if not grouped_indices:  # if no targets found
                            break
                        print_text_with_targets(
                            capture_buffer,
                            grouped_indices,
                            dim_style_code,
                            highlight_style_code,
                            highlight_2_first_style_code,
                            highlight_2_second_style_code,
                            target_keys,
                            pane_width,
                        )
                        position_cursor(row, col)
                        if first_highlight:
                            print_ready(command_pipe)
                            first_highlight = False
                        read_state = ReadState.TARGET
                    else:
                        # The user selected a leave target, we can break now
                        found_index = grouped_indices
                        print_jump_target(
                            *convert_text_pos_to_row_col(found_index, capture_buffer), command_pipe=command_pipe
                        )
                        break
    finally:
        reset_terminal(old_term_settings)


def main():
    # type: () -> None
    exit_code = 0
    try:
        (
            dim_style_code,
            highlight_style_code,
            highlight_2_first_style_code,
            highlight_2_second_style_code,
            motion,
            target_keys,
            cursor_position_row_col,
            pane_size,
            capture_buffer_filepath,
            command_pipe_filepath,
            target_key_pipe_filepath,
        ) = parse_arguments()
        handle_user_input(
            dim_style_code,
            highlight_style_code,
            highlight_2_first_style_code,
            highlight_2_second_style_code,
            motion,
            target_keys,
            cursor_position_row_col,
            pane_size,
            capture_buffer_filepath,
            command_pipe_filepath,
            target_key_pipe_filepath,
        )
    except (
        MissingDimStyleError,
        InvalidDimStyleError,
        MissingHighlightStyleError,
        InvalidHighlightStyleError,
        MissingHighlight2FirstStyleError,
        InvalidHighlight2FirstStyleError,
        MissingHighlight2SecondStyleError,
        InvalidHighlight2SecondStyleError,
        MissingMotionError,
        InvalidMotionError,
        MissingTargetKeysError,
        MissingCursorPositionError,
        InvalidCursorPositionError,
        MissingPaneSizeError,
        InvalidPaneSizeError,
        MissingCaptureBufferFilepathError,
        MissingJumpCommandPipeFilepathError,
        MissingTargetKeyPipeFilepathError,
        InvalidMotionError,
        InvalidTargetError,
    ):
        exit_code = 1
    # Wait a moment before returning to Bash to avoid flicker
    time.sleep(1)
    sys.exit(exit_code)


if __name__ == "__main__":
    main()
