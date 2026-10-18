#!/usr/bin/env bash
#
# S2 GATE - proof P1/P2 in ARCHITECTURE.md §13.3
#
# Asserts that a BUILT artifact declares no network permission. Source-level
# absence is not enough: library manifests are merged into ours, so a
# dependency can reintroduce INTERNET without any change to our own manifest.
# This script inspects the compiled APK/AAB, which is the only statement that
# matters.
#
# Usage:
#   tools/verify-no-network.sh <path-to-apk-or-aab>
#   tools/verify-no-network.sh app/build/outputs/apk/release/app-release.apk
#
# Exit codes:
#   0  clean - no forbidden permission found
#   1  FORBIDDEN PERMISSION FOUND (fail the build)
#   2  could not inspect (missing tool / bad path) - also fails the build,
#      because "we could not check" must never be reported as "it is fine"
#
set -uo pipefail

FORBIDDEN=(
  "android.permission.INTERNET"
  "android.permission.ACCESS_NETWORK_STATE"
  "android.permission.ACCESS_WIFI_STATE"
  "android.permission.CHANGE_NETWORK_STATE"
)

die()  { printf '\n\033[31m%s\033[0m\n' "$*" >&2; exit 2; }
fail() { printf '\n\033[31m%s\033[0m\n' "$*" >&2; exit 1; }
ok()   { printf '\n\033[32m%s\033[0m\n' "$*"; }

ARTIFACT="${1:-}"
[ -n "$ARTIFACT" ] || die "usage: $0 <path-to-apk-or-aab>"
[ -f "$ARTIFACT" ] || die "not a file: $ARTIFACT"

# --- locate a tool that can dump permissions -------------------------------
# apkanalyzer ships with the Android SDK cmdline-tools; aapt2 with build-tools.
PERMS=""
TOOL=""

if command -v apkanalyzer >/dev/null 2>&1; then
  TOOL="apkanalyzer"
  PERMS="$(apkanalyzer manifest permissions "$ARTIFACT" 2>/dev/null)" || PERMS=""
elif [ -n "${ANDROID_HOME:-}" ] && [ -x "${ANDROID_HOME}/cmdline-tools/latest/bin/apkanalyzer" ]; then
  TOOL="apkanalyzer"
  PERMS="$("${ANDROID_HOME}/cmdline-tools/latest/bin/apkanalyzer" manifest permissions "$ARTIFACT" 2>/dev/null)" || PERMS=""
elif command -v aapt2 >/dev/null 2>&1; then
  TOOL="aapt2"
  PERMS="$(aapt2 dump permissions "$ARTIFACT" 2>/dev/null)" || PERMS=""
fi

[ -n "$TOOL" ]  || die "neither apkanalyzer nor aapt2 found. Install Android SDK cmdline-tools and set ANDROID_HOME."
[ -n "$PERMS" ] || die "$TOOL produced no output for $ARTIFACT (wrong file type?)"

# --- assert ----------------------------------------------------------------
echo "Artifact : $ARTIFACT"
echo "Inspected with: $TOOL"
echo "--- declared permissions ---"
echo "$PERMS"
echo "---------------------------"

violations=0
for perm in "${FORBIDDEN[@]}"; do
  if printf '%s\n' "$PERMS" | grep -qF "$perm"; then
    printf '  VIOLATION: %s is present\n' "$perm" >&2
    violations=$((violations + 1))
  fi
done

if [ "$violations" -gt 0 ]; then
  fail "FAILED: $violations forbidden permission(s) in the built artifact.

The app must not be able to reach the network at all. A dependency most
likely merged this in. To find the culprit, read the merger report:

  app/build/outputs/logs/manifest-merger-release-report.txt

then add an explicit removal in app/src/main/AndroidManifest.xml:

  <uses-permission android:name=\"<the permission>\" tools:node=\"remove\" />

See ARCHITECTURE.md §13.3 and ADR-004."
fi

ok "PASSED: no network permission in the built artifact."
