#!/usr/bin/env bash
# Usage: page_timings.sh CURRENT.tsv [BASELINE.tsv]
# Markdown table of `page<TAB>seconds` rows, slowest first, with Δ against the baseline.
set -euo pipefail
cur=$1 base=${2:-/dev/null}
printf '## Docs build time per page\n\n| page | seconds | main | Δ |\n|---|---:|---:|---:|\n'
sort -t$'\t' -k2 -gr "$cur" |
  awk -F'\t' 'FILENAME != "-" { base[$1] = $2; next }
    { d = "—"; m = ($1 in base) ? base[$1] : "—"
      if (m != "—" && m + 0 > 0) d = sprintf("%+.2f (%+.0f%%)", $2 - m, 100 * ($2 - m) / m)
      printf "| %s | %s | %s | %s |\n", $1, $2, m, d }' "$base" -
