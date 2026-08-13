#!/usr/bin/env bash
# herdr-layout smoke test — exercises the engine outside a live Herdr session.
#
# The help / list / invalid-name checks must NOT require a Herdr session.
# The apply-not-found check is non-destructive (it errors before doing anything)
# but does call require_herdr, so it is gated on HERDR_ENV == 1.
set -u

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$REPO_DIR/herdr-layout"
MANAGER="$REPO_DIR/manager.sh"

pass=0
fail=0

ok()   { printf 'PASS: %s\n' "$1"; pass=$((pass + 1)); }
faild(){ printf 'FAIL: %s\n' "$1"; fail=$((fail + 1)); }

# 1. --help exits 0
if "$SCRIPT" --help >/dev/null 2>&1; then
  ok "--help exits 0"
else
  faild "--help did not exit 0"
fi

# 2. list exits 0 (no Herdr session required)
if "$SCRIPT" list >/dev/null 2>&1; then
  ok "list exits 0"
else
  faild "list did not exit 0"
fi

# 3. save with an invalid invocation returns nonzero (no Herdr required:
# argument validation runs regardless of the require_herdr outcome).
if "$SCRIPT" save bogus name >/dev/null 2>&1; then
  faild "save bogus name unexpectedly succeeded"
else
  ok "save bogus name rejected (nonzero)"
fi

# 4. apply nope — non-destructive "not found" path, but it routes through
# require_herdr, so only run it when actually inside Herdr.
if [[ "${HERDR_ENV:-}" == "1" ]]; then
  if "$SCRIPT" apply nope >/dev/null 2>&1; then
    faild "apply nope unexpectedly succeeded"
  else
    ok "apply nope rejected (nonzero)"
  fi
else
  printf 'SKIP: apply nope (not inside Herdr; HERDR_ENV != 1)\n'
fi

# 5. names exits 0 and prints at least builtin:review
names_out="$("$SCRIPT" names 2>/dev/null || true)"
if [[ -n "$names_out" ]] && grep -q '^builtin:review$' <<<"$names_out"; then
  ok "names prints builtin:review"
else
  faild "names did not print builtin:review"
fi

# 6. manager.sh is syntactically valid
if bash -n "$MANAGER" 2>/dev/null; then
  ok "manager.sh syntactically valid (bash -n)"
else
  faild "manager.sh failed bash -n"
fi

# 7. keys exits 0 and prints the fully-qualified review action id.
keys_out="$("$SCRIPT" keys 2>/dev/null || true)"
if [[ -n "$keys_out" ]] && grep -q 'noviadi.herdr-layout.review' <<<"$keys_out"; then
  ok "keys prints noviadi.herdr-layout.review"
else
  faild "keys did not print noviadi.herdr-layout.review"
fi

printf -- '----\n'
printf 'smoke: %d passed, %d failed\n' "$pass" "$fail"
(( fail == 0 ))
