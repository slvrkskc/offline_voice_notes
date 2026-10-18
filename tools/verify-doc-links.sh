#!/usr/bin/env bash
#
# Checks that every relative link between tracked Markdown files resolves.
#
# This already bit us once: a doc was removed from the repo and a link to it
# was left behind. Cheap to check, embarrassing to leave broken in a public
# repository.
#
# External links (http/https) and in-page anchors (#...) are not checked.
#
# Usage: tools/verify-doc-links.sh
#
set -uo pipefail

red()   { printf '\033[31m%s\033[0m\n' "$*" >&2; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }

failures=0
checked=0

while IFS= read -r file; do
  dir="$(dirname "$file")"
  # Pull the target out of ](...) , then drop any #anchor.
  while IFS= read -r target; do
    [ -n "$target" ] || continue
    case "$target" in
      http://*|https://*|mailto:*|'#'*) continue ;;
    esac
    path="${target%%#*}"
    [ -n "$path" ] || continue
    checked=$((checked + 1))
    if [ ! -e "$dir/$path" ]; then
      red "  BROKEN  $file -> $target"
      failures=$((failures + 1))
    fi
  done < <(grep -oE '\]\([^)]+\)' "$file" | sed -E 's/^\]\(//; s/\)$//')
done < <(git ls-files '*.md')

echo
echo "checked $checked relative link(s)"
if [ "$failures" -gt 0 ]; then
  red "FAILED: $failures broken link(s)."
  exit 1
fi
green "PASSED: no broken relative links."
