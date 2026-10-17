#!/usr/bin/env bash
#
# SOURCE-LEVEL privacy guard.
#
# Companion to verify-no-network.sh. That one inspects the BUILT artifact and
# is the statement that actually matters, but it needs the Android SDK and a
# completed build. This one needs nothing, so it can run on every push from
# day one and catch the most likely regression: someone deleting the
# tools:node="remove" lines while refactoring the manifest.
#
# Usage: tools/verify-manifest-guards.sh
#
# Exit codes:
#   0  all guards present
#   1  a guard is missing
#   2  could not inspect
#
set -uo pipefail

MANIFEST="app/src/main/AndroidManifest.xml"
RULES="app/src/main/res/xml/data_extraction_rules.xml"

REQUIRED_REMOVALS=(
  "android.permission.INTERNET"
  "android.permission.ACCESS_NETWORK_STATE"
  "android.permission.ACCESS_WIFI_STATE"
  "android.permission.CHANGE_NETWORK_STATE"
)

red()   { printf '\033[31m%s\033[0m\n' "$*" >&2; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }

[ -f "$MANIFEST" ] || { red "not found: $MANIFEST (run from the repo root)"; exit 2; }
[ -f "$RULES" ]    || { red "not found: $RULES"; exit 2; }

failures=0

# --- 1. every forbidden permission must be explicitly removed --------------
# Collapse whitespace first: the uses-permission element spans several lines.
flat="$(tr '\n' ' ' < "$MANIFEST" | tr -s ' ')"

for perm in "${REQUIRED_REMOVALS[@]}"; do
  if printf '%s' "$flat" | grep -qF -- "android:name=\"$perm\" tools:node=\"remove\""; then
    echo "  ok      removal present: $perm"
  else
    red   "  MISSING removal: $perm"
    failures=$((failures + 1))
  fi
done

# --- 2. the app must never DECLARE a network permission --------------------
# i.e. the same name appearing without tools:node="remove" next to it.
for perm in "${REQUIRED_REMOVALS[@]}"; do
  count_total="$(printf '%s' "$flat" | grep -oF -- "android:name=\"$perm\"" | wc -l)"
  count_removed="$(printf '%s' "$flat" | grep -oF -- "android:name=\"$perm\" tools:node=\"remove\"" | wc -l)"
  if [ "$count_total" -ne "$count_removed" ]; then
    red "  DECLARED without removal: $perm"
    failures=$((failures + 1))
  fi
done

# --- 3. backups must stay off ----------------------------------------------
for guard in 'android:allowBackup="false"' 'android:dataExtractionRules='; do
  if printf '%s' "$flat" | grep -qF -- "$guard"; then
    echo "  ok      backup guard present: $guard"
  else
    red   "  MISSING backup guard: $guard"
    failures=$((failures + 1))
  fi
done

# --- 4. extraction rules must exclude, not include -------------------------
if grep -qF '<include' "$RULES"; then
  red "  <include> found in $RULES - extraction rules must only exclude"
  failures=$((failures + 1))
else
  echo "  ok      extraction rules contain no <include>"
fi

# --- result ----------------------------------------------------------------
echo
if [ "$failures" -gt 0 ]; then
  red "FAILED: $failures privacy guard(s) missing.

These lines are the project's central claim, not boilerplate.
See ARCHITECTURE.md §13.3 before changing them."
  exit 1
fi

green "PASSED: all source-level privacy guards present."
