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
implementation which adds much more easy-motion movements. Currently, the following motions are supported: `b`, `B`,
`w`, `W`, `e`, `E`, `ge`, `gE`, `j`, `J`, `k`, `K` `f`, `F`, `t`, `T`, `c` (camelCase).

Special thanks to the authors of the [tmux-fingers](https://github.com/Morantron/tmux-fingers) project. Reading their
source code helped a lot to understand how an easy-motion plugin can be implemented for tmux.

## Requirements

This plugin needs Python 2.7 or 3.3+. You can check your installed Python version with

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

## Other plugins

If you like this plugin and use zsh, please also try my easy-motion port for zsh:
[zsh-easy-motion](https://github.com/IngoMeyer441/zsh-easy-motion).
