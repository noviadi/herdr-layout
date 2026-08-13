# herdr-layout

Save and replay Herdr pane layouts.

A Herdr plugin that captures the current tab's split tree, per-pane cwd, and
running commands, then replays them later. It ships a built-in **review**
layout (source tree + `lazygit`) and an interactive popup **layout manager**.
The engine behind the plugin, `herdr-layout`, also doubles as a standalone
script — but **plugin mode is the default**: install once, bind a key, and
drive everything from the popup. Think of it as tmux-resurrect beside tmux:
a companion tool, intentionally separate from Herdr core.

## Requirements

- Herdr >= 0.8.0
- bash
- python3
- Optional: `eza` and `lazygit`. The built-in `review` layout falls back to
  `ls` and `git status` when they are missing.
- Platforms: linux and macOS. Not supported on Windows.

## Install

From the marketplace (or GitHub):

```
herdr plugin install noviadi/herdr-layout
```

Local dev link (clone and point Herdr at your checkout):

```
herdr plugin link /path/to/herdr-layout
```

## Quick start (plugin)

1. Add the manager binding to `~/.config/herdr/config.toml`:

   ```toml
   [[keys.command]]
   key = "prefix+shift+l"
   type = "plugin_action"
   command = "noviadi.herdr-layout.manager"
   description = "Open layout manager"
   ```

2. Reload your Herdr config.
3. Press `prefix+shift+l` to open the layout manager popup.
4. From the menu: **save** the current tab, **apply** the built-in `review`
   layout, or **apply** a saved layout. Each operation targets the tab you
   opened the popup from.

Plugin users never need to type `herdr-layout …` in daily use — the popup
menu does it for you.

## Two ways to use this

- **As a plugin (default)** — install once, bind a key, drive via popup.
  See [Plugin usage](docs/plugin-usage.md).
- **As a standalone script** — run `./herdr-layout <subcommand>` directly in
  any Herdr pane (automation, dev, power use). See
  [Script usage](docs/script-usage.md).

## Keybindings

The single recommended binding is the block above: `prefix+shift+l` (capital
L) → `manager` action. It is conflict-free by design — it avoids Herdr's
default `prefix+l` (focus_pane_right) and `prefix+r` (resize_mode). Run
`herdr-layout keys` to print the same block to stdout.

## Behavior at a glance

- Agent panes are **moved** to a new tab (session preserved) on rebuild, not
  killed; `--close-agents` forces them closed instead.
- A confirmation prompt precedes any destructive rebuild; `-y` skips it.
- `review` is a **fixed template** (chat left, source top-right, lazygit
  bottom-right), not a snapshot — the name is reserved.
- Snapshots capture currently-running processes: long-running tools (e.g. a
  live `lazygit`) are replayed; one-shot commands that already exited are
  captured as the idle shell they leave behind.
- Linux and macOS only.

For the full mechanism (capture, replay, storage, contexts, caveats), see
[Script usage — How it works](docs/script-usage.md#how-it-works).

## License

MIT (c) 2026 noviadi. See [LICENSE](LICENSE).
