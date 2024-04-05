# Vim's easy-motion for tmux

## Demo

![tmux-easy-motion demo](https://raw.githubusercontent.com/IngoMeyer441/tmux-easy-motion/master/demo.gif)

## Introduction

This plugin brings Vim's [easy-motion](https://github.com/easymotion/vim-easymotion) navigation plugin to tmux. There
are already some other plugins with similar functionality:

- [tmux-jump](https://github.com/schasse/tmux-jump): Implements the seek operation of easy-motion.
- [tmux-easymotion](https://github.com/ddzero2c/tmux-easymotion): Also implements the seek operation.
- [tmux-fingers](https://github.com/Morantron/tmux-fingers): Copy text by selecting a hint marker.
- [tmux-thumbs](https://github.com/fcsonline/tmux-thumbs): Alternative to tmux-fingers.

However, none of the already-existing plugins implement other movements than seeking. Therefore, I started my own
implementation which adds much more easy-motion movements. All standard vi motions (`b`, `B`,
`w`, `W`, `e`, `E`, `ge`, `gE`, `j`, `k`, `f`, `F`, `t`, `T`) and these vim-easy-motion movements are supported:

- `J` (`j` + move to end of line)
- `K` (`k` + move to end of line)
- `bd-w` (`bd-*` -> bidirectional motion)
- `bd-W`
- `bd-e`
- `bd-E`
- `bd-j`
- `bd-J`
- `bd-f`
- `bd-f2` (search for 2 characters)
- `bd-t`
- `bd-T`
- `c` (target camelCase or underscore notations)

By default, only the standard vim motions, `J`, `K` and `c` are bound to the keyboard. If you would like to use a
bidirectional motions, you need to configure a key binding for it. See the [key-bindings
section](https://github.com/IngoMeyer441/tmux-easy-motion#key-bindings) of this README for more details.

Special thanks to the authors of the [tmux-fingers](https://github.com/Morantron/tmux-fingers) project. Reading their
source code helped a lot to understand how an easy-motion plugin can be implemented for tmux.

## Requirements

This plugin needs at least tmux 3.1 and Python 2.7 or 3.3+. You can check your installed tmux version with

```bash
tmux -V
```

and your installed Python version with

```bash
python --version
```

If you are using a quite recent Linux distribution or macOS, an appropriate Python version should already be installed.

## Installation

### Using tpm

1. Add `set -g @plugin 'IngoMeyer441/tmux-easy-motion'` to your `.tmux.conf`.

2. Configure a prefix key for easy-motion movements, the default is `Space`:

   ```
   set -g @easy-motion-prefix "Space"
   ```

   By default, the `Space` key changes layouts in tmux (non-copy mode) or sets the beginning of a selection (copy mode).
   Therefore, you should configure other keys for these actions if you would like to use `Space` as easy-motion prefix
   key, for example:

   ```
   bind-key v next-layout
   bind-key -T copy-mode-vi v send-keys -X begin-selection
   ```

   You can also configure another key binding for copy mode by setting `@easy-motion-copy-mode-prefix`.

### Manual

1. Clone this repository and add

   ```
   run-shell <clone-location>/easy_motion.tmux
   ```

   to `.tmux.conf`.

2. Configure prefix keys like explained above.

## Usage

Press the tmux prefix key followed by the configured easy-motion prefix key (by default `Ctrl-b Space`) to enter the
easy-motion mode. Enter a vi motion command and possible jump targets will be highlighted by red and yellow letters.
Press one of the highlighted letters to enter tmux copy-mode and jump to the corresponding position directly.

This plugin also works in tmux copy-mode. In copy-mode you don't need to press the tmux prefix key.

### Grouping

If more jump targets exist than configured target keys, targets will be grouped and a second key press is needed to
determine the jump target (see the [demo](#demo) for an example). Groups always contain a preview of the next key which
is needed to reach the target position. The grouping works exactly like the grouping mechanism in Vim's easy-motion
plugin.

The grouping algorithm works recursively, so grouping is repeated if necessary. However, that case should only occur if
a small set of target keys was configured.

## Configuration

### Key bindings

You can set a prefix key for tmux-easy-motion with the `@easy-motion-prefix` option. It will be bound on the prefix and
the copy-mode-vi key table. If you don't want to use the same prefix key for both modes, you can set another key binding
for copy mode with the `@easy-motion-copy-mode-prefix` option or you can disable the key bindings by setting
`@easy-motion-prefix-enabled` and/or `@easy-motion-copy-mode-prefix-enabled` to `false` (or `no`, `off`, `disabled`,
`deactivated`, `0`).

By default, tmux-easy-motion creates default key bindings for all standard vim motions, `J`, `K` and `c`. If you would
like to remove, change or add a single key bindings, change the corresponding option (see the list below).
Alternatively, you can set `@easy-motion-default-key-bindings` to `false` (or `off`, `disabled`, `no`, `deactivated`,
`0`) and configure all easy-motion key binding options yourself.

Available key binding options:

- `@easy-motion-binding-b`
- `@easy-motion-binding-B`
- `@easy-motion-binding-ge`
- `@easy-motion-binding-gE`
- `@easy-motion-binding-e`
- `@easy-motion-binding-E`
- `@easy-motion-binding-w`
- `@easy-motion-binding-W`
- `@easy-motion-binding-j`
- `@easy-motion-binding-J`
- `@easy-motion-binding-k`
- `@easy-motion-binding-K`
- `@easy-motion-binding-f`
- `@easy-motion-binding-F`
- `@easy-motion-binding-t`
- `@easy-motion-binding-T`
- `@easy-motion-binding-bd-w`
- `@easy-motion-binding-bd-W`
- `@easy-motion-binding-bd-e`
- `@easy-motion-binding-bd-E`
- `@easy-motion-binding-bd-j`
- `@easy-motion-binding-bd-J`
- `@easy-motion-binding-bd-f`
- `@easy-motion-binding-bd-f2`
- `@easy-motion-binding-bd-t`
- `@easy-motion-binding-bd-T`
- `@easy-motion-binding-c`

If you only want to use a single easy-motion movement, you can configure it as the default motion which is activated
directly after pressing the easy-motion prefix key and save one key press (`@easy-motion-default-motion`).

Example:

```
set -g @easy-motion-default-motion "bd-w"
```

This setting will cause the highlight of all word beginnings (bidirectional) after pressing the configured easy-motion
prefix key.

### Target keys

The target keys can be configured with the `@easy-motion-target-keys` option. The default is taken from the
Vim default configuration value (`"asdghklqwertyuiopzxcvbnmfj;"`)

You can configure as many keys as you want (minimum two keys).

Example:

```
set -g @easy-motion-target-keys "asdfghjkl;"
```

### Colors

The color of dimmed and highlighted text can be configured by setting four style options. These are the default
settings (taken from the easy-motion Vim plugin):

```
set -g @easy-motion-dim-style "fg=colour242"
set -g @easy-motion-highlight-style "fg=colour196,bold"
set -g @easy-motion-highlight-2-first-style "fg=brightyellow,bold"
set -g @easy-motion-highlight-2-second-style "fg=yellow,bold"
```

Possible style values are described in the [tmux man page](https://man7.org/linux/man-pages/man1/tmux.1.html#STYLES).

These settings were used in the demo:

```
set -g @easy-motion-dim-style "fg=colour242"
set -g @easy-motion-highlight-style "fg=colour196,bold"
set -g @easy-motion-highlight-2-first-style "fg=#ffb400,bold"
set -g @easy-motion-highlight-2-second-style "fg=#b98300,bold"
```

### Verbose mode

By setting

```
set -g @easy-motion-verbose "true"
```

tmux-easy-motion operates in verbose mode which displays messages when easy-motion is activated and a motion was
selected.


### Auto selection

By setting
```
set -g @easy-motion-auto-begin-selection "true"
```

you can enable the automatic start of selection

## Other plugins

If you like this plugin and use zsh, please also try my easy-motion port for zsh:
[zsh-easy-motion](https://github.com/IngoMeyer441/zsh-easy-motion).
