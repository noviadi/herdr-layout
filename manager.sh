#!/usr/bin/env bash
# manager.sh — interactive popup menu for the herdr-layout plugin.
#
# Runs inside a Herdr popup pane and operates on the INVOKING tab (the user's
# original tab), whose context is delivered via HERDR_PLUGIN_CONTEXT_JSON. In a
# popup the legacy HERDR_WORKSPACE_ID/HERDR_TAB_ID/HERDR_PANE_ID env vars are
# EMPTY, so the engine resolves workspace/tab/pane from the JSON instead
# (focused_pane_id for the pane). See herdr-layout's resolve_context().
#
# Dependencies: bash + the in-repo engine + standard coreutils. No jq.
set -euo pipefail

# The manager must be invoked as a plugin pane: it needs the invoking-tab
# context to target anything. Standalone invocation is meaningless.
if [[ -z "${HERDR_PLUGIN_CONTEXT_JSON:-}" ]]; then
  echo "herdr-layout manager: this menu must be opened via the Herdr plugin"
  echo "(it needs the invoking-tab context from HERDR_PLUGIN_CONTEXT_JSON)."
  echo "Open it from a Herdr workspace, not from a plain shell."
  exit 1
fi

ENGINE="${HERDR_PLUGIN_ROOT:-$(cd "$(dirname "$0")" && pwd)}/herdr-layout"

# List just the saved layout names (one per line, no prefix), to stdout.
saved_names() {
  "$ENGINE" names 2>/dev/null | grep '^saved:' | cut -d: -f2- || true
}

pause() { read -rp $'\nPress Enter to continue... ' _; }

while true; do
  clear
  cat <<'MENU'
herdr-layout manager
====================
  1) List layouts
  2) Apply built-in review   (then quit)
  3) Apply a saved layout    (then quit)
  4) Save current tab as a layout
  5) Remove a saved layout
  6) Quit
MENU
  printf 'Choice> '
  read -r choice || { echo; break; }
  echo
  case "${choice:-}" in
    1)
      "$ENGINE" list || true
      pause
      ;;
    2)
      "$ENGINE" review -y
      echo
      echo "Review layout applied — closing manager."
      exit 0
      ;;
    3)
      names="$(saved_names)"
      if [[ -z "$names" ]]; then
        echo "No saved layouts yet. Use option 4 to capture one."
        pause
        continue
      fi
      echo "Saved layouts:"
      printf '  %s\n' $names
      printf 'name> '
      read -r name || { echo; continue; }
      if [[ -z "${name:-}" ]]; then
        echo "No name given."
        pause
        continue
      fi
      "$ENGINE" apply "$name" -y
      echo
      echo "Layout '$name' applied — closing manager."
      exit 0
      ;;
    4)
      printf 'name> '
      read -r name || { echo; continue; }
      if [[ -z "${name:-}" ]]; then
        echo "No name given."
        pause
        continue
      fi
      "$ENGINE" save "$name" || true
      pause
      ;;
    5)
      names="$(saved_names)"
      if [[ -z "$names" ]]; then
        echo "No saved layouts to remove."
        pause
        continue
      fi
      echo "Saved layouts:"
      printf '  %s\n' $names
      printf 'name> '
      read -r name || { echo; continue; }
      if [[ -z "${name:-}" ]]; then
        echo "No name given."
        pause
        continue
      fi
      "$ENGINE" rm "$name" || true
      pause
      ;;
    6)
      echo "Bye."
      exit 0
      ;;
    *)
      echo "Invalid choice."
      pause
      ;;
  esac
done
