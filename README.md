# herdr-layout

Save and replay Herdr pane layouts.

A Herdr plugin that captures the current tab's split tree, per-pane cwd, and
running commands, then replays them later. Ships a built-in **review** layout
(source tree + `lazygit`) and a popup **layout manager**. Think of it as
tmux-resurrect beside tmux: a companion tool, intentionally separate from Herdr
core, for when you want to snapshot and restore pane arrangements.

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

## Quick start

```bash
# Apply the built-in review layout: chat pane on the left, source tree
# (top-right), lazygit (bottom-right).
herdr-layout review -y

# Capture the current tab's layout under a name.
herdr-layout save debug-session

# Replay it later (same window, same project).
herdr-layout apply debug-session -y

# Open the interactive popup manager (list / apply / save / remove).
# Via the plugin pane, or directly:
./manager.sh
```

## Commands reference

Engine subcommands (`herdr-layout <subcommand>`):

| Subcommand          | Description                                                        |
|---------------------|--------------------------------------------------------------------|
| `save <name>`       | Capture the current tab's split tree + per-pane cwd + commands.    |
| `apply <name>`      | Replay a saved layout or a built-in. Built-in: `review`.           |
| `review`            | Apply the built-in review layout.                                  |
| `list`              | List built-in and saved layouts.                                   |
| `show <name>`       | Print a saved layout's JSON.                                       |
| `rm <name>`         | Delete a saved layout.                                             |
| `names`             | Machine-readable names (`builtin:<n>` / `saved:<n>`), one per line.|
| `keys`              | Print the recommended keybinding TOML block for review + manager.  |
| `-h` / `--help`     | Show help.                                                         |

Flags:

| Flag                | Applies to            | Description                                              |
|---------------------|-----------------------|----------------------------------------------------------|
| `-f` / `--force`    | `save`                | Overwrite an existing layout without prompting.          |
| `-y` / `--yes`      | `apply`, `review`     | Skip the confirmation prompt before rebuild.             |
| `--cwd PATH`        | `apply`, `review`     | Stamp the layout onto a different project path.          |
| `--no-commands`     | `apply`               | Replay topology + cwd only; skip all command replay.     |
| `--close-agents`    | `apply`, `review`     | Force-close agent panes instead of moving them to a tab. |

## Plugin integration

The plugin manifest (`herdr-plugin.toml`) exposes:

- **Action `review`** (id `review`, title "Apply review layout") — runs
  `herdr-layout review -y` in the current workspace context.
- **Action `manager`** (id `manager`, title "Open layout manager") — opens the
  layout-manager popup pane. Implemented as an action (rather than relying on
  `herdr plugin pane open …` typed by hand) specifically so it can be put on a
  key: Herdr's keybinding types are `popup`, `pane`, `shell`, and
  `plugin_action`, and only `plugin_action` can target plugin surfaces, so the
  popup is reached via this bindable action whose command runs
  `"$HERDR_BIN_PATH" plugin pane open --plugin noviadi.herdr-layout --entrypoint manager`.
- **Pane `manager`** (id `manager`, title "Layout manager") — the popup itself
  (`placement = "popup"`, 70% x 60%) running `manager.sh`, the interactive
  menu: list / apply review / apply saved / save / remove / quit.

### Keybindings

Plugin actions are qualified as `<plugin_id>.<action_id>` and bound with
`type = "plugin_action"`. Both `review` and `manager` are actions, so both are
bindable (confirmed syntax — see https://herdr.dev/docs/plugins/ and
https://herdr.dev/docs/configuration/). Paste this into
`~/.config/herdr/config.toml`:

```toml
[[keys.command]]
key = "prefix+r"
type = "plugin_action"
command = "noviadi.herdr-layout.review"
description = "Apply review layout"

[[keys.command]]
key = "prefix+l"
type = "plugin_action"
command = "noviadi.herdr-layout.manager"
description = "Open layout manager"
```

Run `herdr-layout keys` to print this same block to stdout. The manager is
always reachable via the plugin's pane entry regardless.

## How it works

**Capture (`save`).** Reads the current tab's split tree via
`herdr pane layout --pane <id>` (deliberately not `--current`, which is broken
upstream — see Herdr issue #2297), plus each pane's cwd and foreground
process. The tree is stored as JSON: a recursively nested `split`/`leaf`
structure with direction, ratio, cwd, and captured command per leaf.

**Replay (`apply`).** Re-splits the anchor pane (the pane you invoke from,
which is preserved) following the saved ratios, restores each pane's cwd, and
re-runs captured commands — with two exceptions: coding-agent invocations
(`claude`, `codex`, `cursor`, `opencode`, `aider`, `amp`, etc.) are captured
for reference but **never** re-run, and idle shells are left as shells.
`--no-commands` skips command replay entirely and just rebuilds topology +
cwd.

**Making room.** Extra panes in the current tab are cleared before rebuild:
panes hosting a running coding agent are **moved to a new tab** (session
preserved) unless `--close-agents` is given; plain panes are closed. A
confirmation prompt precedes any destructive action; `-y` skips it.

**Built-in `review`.** A fixed template (not a snapshot): chat pane on the
left, `eza --tree` top-right, `lazygit` bottom-right. The name `review` is
reserved — you cannot `save` over it; saved layouts use their own names.

**Storage.** Layouts are saved as `<name>.json` under:

1. `$HERDR_PLUGIN_STATE_DIR` — when run as a plugin (the default), or
2. `~/.config/herdr-layout/` — when run standalone, or
3. `$HERDR_LAYOUT_DIR` — an explicit override that always wins.

**Contexts.** The engine works in three contexts: as a plugin **action**
(runs in the focused pane), as a plugin **popup pane** (the manager, which
targets the invoking tab via `HERDR_PLUGIN_CONTEXT_JSON`), and **standalone**
in any Herdr pane (resolving context from `HERDR_WORKSPACE_ID` /
`HERDR_TAB_ID` / `HERDR_PANE_ID`).

## Caveats

- Uses `pane layout --pane <id>` deliberately because `pane layout --current`
  is broken upstream (Herdr issue #2297).
- `save` is a snapshot of currently-running processes: long-running tools
  (e.g. a live `lazygit`) are captured and replayed; one-shot commands that
  have already exited (e.g. `eza`) are captured as the idle shell they leave
  behind. For a reliable eza + lazygit template, use the built-in `review`
  rather than snapshotting one by hand.
- Platforms: linux and macOS (bash-based). Not supported on Windows.
- This is a companion tool, intentionally separate from Herdr core — the same
  philosophy as tmux-resurrect beside tmux.

## License

MIT (c) 2026 noviadi. See [LICENSE](LICENSE).
