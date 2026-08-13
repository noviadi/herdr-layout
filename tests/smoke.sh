#!/usr/bin/env bash
# herdr-layout smoke test — exercises the engine outside a live Herdr session.
#
# The help / list / invalid-name checks must NOT require a Herdr session.
# The apply-not-found check is non-destructive (it errors before doing anything)
# but does call require_herdr, so it is gated on HERDR_ENV == 1.
set -u

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$REPO_DIR/herdr-layout"

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

printf -- '----\n'
printf 'smoke: %d passed, %d failed\n' "$pass" "$fail"
(( fail == 0 ))
