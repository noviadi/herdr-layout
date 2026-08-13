# Plugin usage

Using `herdr-layout` as a Herdr plugin — the intended, default mode. You
install it once, bind a single key, and drive everything from the layout
manager popup. Plugin users never type `herdr-layout …` in daily use.

See the [README](../README.md) for the overview, or [Script usage](script-usage.md)
for the standalone CLI and internals.

## Install

From the marketplace (or GitHub):

```
herdr plugin install noviadi/herdr-layout
```

Local dev link (clone the repo, then point Herdr at your checkout so edits
are picked up live):

```
herdr plugin link /path/to/herdr-layout
```

### Updating, reinstalling, switching sources

The plugin id is `noviadi.herdr-layout`. To switch between a marketplace
install and a local dev link:

```
# Pull a fresh copy from the marketplace.
herdr plugin uninstall noviadi.herdr-layout
herdr plugin install noviadi/herdr-layout

# Switch to a local checkout for development.
herdr plugin uninstall noviadi.herdr-layout
herdr plugin link /path/to/herdr-layout

# Detach the dev link and go back to the marketplace build.
herdr plugin unlink noviadi.herdr-layout
herdr plugin install noviadi/herdr-layout
```

Verify what's installed and enabled with `herdr plugin list`.

## The layout manager popup

The popup is the heart of plugin mode. Open it with `prefix+shift+l` from any
workspace pane; it appears as a 70% x 60% popup and **targets the tab you
opened it from** (the invoking tab, not the popup itself). Its menu:

1. **List layouts** — print built-in and saved layouts, with the root cwd of
   each saved one.
2. **Apply built-in review** — apply the `review` template to the invoking
   tab, then close the popup.
3. **Apply a saved layout** — pick a name from your saved layouts, apply it
   to the invoking tab, then close the popup.
4. **Save current tab as a layout** — capture the invoking tab's split tree,
   per-pane cwd, and running commands under a name you choose.
5. **Remove a saved layout** — delete a saved layout file.
6. **Quit** — close the popup without doing anything.

Options 2 and 3 close the popup after applying because the layout rebuild
happens in the invoking tab, not the popup. Options 1, 4, and 5 return you
to the menu so you can keep working.

## The review action

Besides the menu, the built-in `review` layout is also exposed as its own
plugin action — handy if you want to bind it directly or invoke it without
the popup:

```
herdr plugin action invoke review --plugin noviadi.herdr-layout
```

This runs `herdr-layout review -y` in the focused workspace context: chat
pane on the left, `eza --tree` top-right, `lazygit` bottom-right. `review`
needs no separate keybinding by default — it's menu option 2 inside the
manager popup.

## Keybindings in depth

Plugin actions are qualified as `<plugin_id>.<action_id>` and bound with
`type = "plugin_action"`. The single recommended binding puts the `manager`
action on `prefix+shift+l`:

```toml
[[keys.command]]
key = "prefix+shift+l"
type = "plugin_action"
command = "noviadi.herdr-layout.manager"
description = "Open layout manager"
```

### Why `prefix+shift+l`?

The capital-L key was chosen specifically to avoid clobbering two of Herdr's
default bindings:

| Binding           | Herdr default      | Status    |
|-------------------|--------------------|-----------|
| `prefix+l`        | `focus_pane_right` | taken     |
| `prefix+r`        | `resize_mode`      | taken     |
| `prefix+shift+l`  | —                  | free (used here) |

### Why an action and not a pane binding?

Herdr's keybinding types are `popup`, `pane`, `shell`, and `plugin_action`.
There is **no** `plugin_pane` keybinding type — keybindings cannot directly
target a plugin-defined pane surface. So the popup is reached via this
bindable `manager` action, whose command runs:

```
"$HERDR_BIN_PATH" plugin pane open --plugin noviadi.herdr-layout --entrypoint manager
```

Run `herdr-layout keys` to print the binding block to stdout. The manager is
always reachable via the plugin's pane entry regardless of bindings.

## Troubleshooting

- **The popup doesn't appear.** Confirm the plugin is installed and enabled
  with `herdr plugin list`. If it's listed but disabled, enable it per your
  Herdr version's instructions.
- **The binding doesn't fire.** Verify it shows up in the keybinding help
  (`prefix+?`), and that you reloaded your config after editing
  `~/.config/herdr/config.toml`.
- **The manager says it needs plugin context.** `manager.sh` only works when
  invoked **as a plugin pane** — it reads the invoking-tab context from
  `HERDR_PLUGIN_CONTEXT_JSON`. Running it bare from a shell fails by design.
  Open it via the binding or `herdr plugin action invoke manager …`, not by
  executing `./manager.sh` directly.

## Going deeper

For the engine's CLI surface (commands, flags, examples), storage rules,
runtime contexts, and the full capture/replay mechanism, see
[Script usage](script-usage.md). That same engine is what the plugin runs
under the hood.
