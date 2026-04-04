#!/usr/bin/env bash

set -euo pipefail

require_bin() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required binary: $1" >&2
    exit 1
  fi
}

[[ $# -eq 0 ]] || {
  echo "Unknown argument: $1" >&2
  exit 1
}

NODES=(
  "gaccode.com"
  "api.gaccode.com"
  "relay01.gaccode.com"
  "relay03.gaccode.com"
  "relay05.gaccode.com"
  "relay07.gaccode.com"
  "relay08.gaccode.com"
)

FPING_COUNT=3
FPING_PERIOD_MS=200
FPING_TIMEOUT_MS=500

BEST_NODE=""
BEST_LATENCY="999999"

average_values() {
  awk '
    {
      for (i = 1; i <= NF; i++) {
        if ($i != "-") {
          sum += $i
          count++
        }
      }
    }
    END {
      if (count > 0) {
        printf "%.3f", sum / count
      }
    }
  '
}

measure_nodes() {
  fping -C "$FPING_COUNT" -p "$FPING_PERIOD_MS" -t "$FPING_TIMEOUT_MS" "${NODES[@]}" 2>&1 || true
}

print_result() {
  cat <<EOF
Best node: $BEST_NODE
Latency: $BEST_LATENCY ms
Base URL: https://$BEST_NODE
Recommended URL: https://$BEST_NODE/api/v1
EOF
}

require_bin fping
require_bin bc

while IFS= read -r line; do
  node=$(echo "$line" | awk -F' : ' 'NF > 1 { print $1 }')
  latency=$(echo "$line" | awk -F' : ' 'NF > 1 { print $2 }' | average_values)

  if [[ -n "$node" && -n "$latency" ]]; then
    if [[ "$(echo "$latency < $BEST_LATENCY" | bc)" -eq 1 ]]; then
      BEST_LATENCY="$latency"
      BEST_NODE="$node"
    fi
  fi
done < <(measure_nodes)

if [[ -n "$BEST_NODE" ]]; then
  print_result
else
  echo "No reachable nodes found" >&2
  exit 1
fi
