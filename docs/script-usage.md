# Script usage

Using `herdr-layout` as a standalone script — running the engine directly in
any Herdr pane, outside the plugin popup.

Reach for the standalone script for **automation** (replay a layout from a
script or session hook), **development** (exercising the engine while
hacking on this repo), or **non-plugin Herdr setups** (you haven't installed
the plugin but still want snapshot/restore). Note that this script **is the
engine the plugin runs** — everything below also describes what happens under
the hood in [plugin mode](plugin-usage.md). See the [README](../README.md)
for the project overview.

## Getting and running it

The script is `herdr-layout` at the repo root. Run it from your checkout:

```
./herdr-layout <subcommand>
```

or copy/symlink it somewhere on your `PATH` (e.g. `~/.local/bin/herdr-layout`)
and call it as `herdr-layout`. It must be run from inside a Herdr-managed
pane for any command that touches a live session (`save`, `apply`, `review`).

## Commands reference

Engine subcommands (`herdr-layout <subcommand>`):

| Subcommand          | Description                                                         |
|---------------------|---------------------------------------------------------------------|
| `save <name>`       | Capture the current tab's split tree + per-pane cwd + commands.     |
| `apply <name>`      | Replay a saved layout or a built-in. Built-in: `review`.            |
| `review`            | Apply the built-in review layout.                                   |
| `list`              | List built-in and saved layouts.                                    |
| `show <name>`       | Print a saved layout's JSON.                                        |
| `rm <name>`         | Delete a saved layout.                                              |
| `names`             | Machine-readable names (`builtin:<n>` / `saved:<n>`), one per line. |
| `keys`              | Print the recommended keybinding TOML block for the manager action. |
| `-h` / `--help`     | Show help.                                                          |

## Flags reference

| Flag                | Applies to            | Description                                               |
|---------------------|-----------------------|-----------------------------------------------------------|
| `-f` / `--force`    | `save`                | Overwrite an existing layout without prompting.           |
| `-y` / `--yes`      | `apply`, `review`     | Skip the confirmation prompt before rebuild.              |
| `--cwd PATH`        | `apply`, `review`     | Stamp the layout onto a different project path.           |
| `--no-commands`     | `apply`               | Replay topology + cwd only; skip all command replay.      |
| `--close-agents`    | `apply`, `review`     | Force-close agent panes instead of moving them to a tab.  |

`-y` and `--close-agents` are global and may appear anywhere after the
subcommand.

## Examples

```bash
# Apply the built-in review layout: chat pane on the left, source tree
# (top-right), lazygit (bottom-right).
herdr-layout review -y

# Capture the current tab's layout under a name.
herdr-layout save debug-session

# Replay it later (same window, same project).
herdr-layout apply debug-session -y

# Replay topology + cwd only, no command re-run.
herdr-layout apply debug-session -y --no-commands

# Stamp a saved layout onto a different project path.
herdr-layout apply debug-session -y --cwd /path/to/other-project

# List, inspect, delete.
herdr-layout list
herdr-layout show debug-session
herdr-layout rm debug-session
```

## Storage

Layouts are saved as `<name>.json` under the first of these that is set:

1. `$HERDR_PLUGIN_STATE_DIR` — when run as a plugin (the default plugin
   path).
2. `~/.config/herdr-layout/` — when run standalone (XDG config default).
3. `$HERDR_LAYOUT_DIR` — an explicit override that **always wins** if set.

## Contexts and environment

The engine works in three runtime contexts, and resolves the target
workspace/tab/pane from the best available source:

1. **Plugin action** — runs in the focused pane; context comes from the
   Herdr plugin runtime via `HERDR_PLUGIN_CONTEXT_JSON`.
2. **Plugin popup pane** (the manager) — context also comes from
   `HERDR_PLUGIN_CONTEXT_JSON`; the legacy env vars below are empty in a
   popup, so the JSON is required.
3. **Standalone** in any Herdr pane — context resolves from the legacy
   caller-context env vars: `HERDR_WORKSPACE_ID`, `HERDR_TAB_ID`,
   `HERDR_PANE_ID`.

Relevant environment variables:

- `HERDR_PLUGIN_CONTEXT_JSON` — plugin context blob. Flat shape carrying
  `focused_pane_id` (used for pane resolution; there is no `pane_id` key);
  may also carry `workspace_id` / `tab_id` at the top level, or nested
  `workspace{id}` / `tab{id}` / `pane{id}` objects.
- `HERDR_WORKSPACE_ID` / `HERDR_TAB_ID` / `HERDR_PANE_ID` — legacy
  caller-context env vars, the standalone fallback.
- `HERDR_BIN_PATH` — the Herdr binary to drive. Plugin runtime sets this to
  the exact running binary; standalone usage falls back to whatever `herdr`
  is on `PATH`.

## How it works

**Capture (`save`).** Reads the current tab's split tree via
`herdr pane layout --pane <id>` (deliberately not `--current`, which is
broken upstream — see Herdr issue #2297), plus each pane's cwd and
foreground process. The tree is stored as JSON: a recursively nested
`split`/`leaf` structure with direction, ratio, cwd, and captured command
per leaf.

**Replay (`apply`).** Re-splits the anchor pane (the pane you invoke from,
which is preserved) following the saved ratios, restores each pane's cwd,
and re-runs captured commands — with two exceptions: coding-agent
invocations (`claude`, `codex`, `cursor`, `opencode`, `aider`, `amp`, etc.)
are captured for reference but **never** re-run, and idle shells are left
as shells. `--no-commands` skips command replay entirely and just rebuilds
topology + cwd.

**Making room.** Extra panes in the current tab are cleared before rebuild:
panes hosting a running coding agent are **moved to a new tab** (session
preserved) unless `--close-agents` is given; plain panes are closed. A
confirmation prompt precedes any destructive action; `-y` skips it.

**Built-in `review`.** A fixed template (not a snapshot): chat pane on the
left, `eza --tree` top-right, `lazygit` bottom-right. The name `review` is
reserved — you cannot `save` over it; saved layouts use their own names.

## Caveats

- **Herdr #2297.** Uses `pane layout --pane <id>` deliberately because
  `pane layout --current` is broken upstream.
- **Snapshot fidelity.** `save` is a snapshot of currently-running
  processes: long-running tools (e.g. a live `lazygit`) are captured and
  replayed; one-shot commands that have already exited (e.g. `eza`) are
  captured as the idle shell they leave behind. For a reliable
  eza + lazygit template, use the built-in `review` rather than
  snapshotting one by hand.
- **Platforms.** Linux and macOS only (bash-based). Not supported on
  Windows.
- **Companion-tool philosophy.** This is a companion tool, intentionally
  separate from Herdr core — the same philosophy as tmux-resurrect beside
  tmux.

For the plugin experience (popup, bindings, manifest actions), see
[Plugin usage](plugin-usage.md).
