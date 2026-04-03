#!/usr/bin/env bash
# Select optimal gaccode relay node based on network latency

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

BEST_NODE=""
BEST_LATENCY=999999

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

measure_latencies() {
  fping -C 3 "${NODES[@]}" 2>&1 || true
}

print_json_result() {
  cat <<EOF
{
  "best_node": "$BEST_NODE",
  "latency_ms": "$BEST_LATENCY",
  "recommended_url": "https://$BEST_NODE/api/v1",
  "base_url": "https://$BEST_NODE"
}
EOF
}

require_bin fping
require_bin bc

while IFS= read -r line; do
  node=$(echo "$line" | awk -F' : ' 'NF > 1 { print $1 }')
  latency=$(echo "$line" | awk -F' : ' 'NF > 1 { print $2 }' | average_values)

  if [[ -n "$node" && -n "$latency" ]]; then
    if [[ "$(echo "$latency < $BEST_LATENCY" | bc)" -eq 1 ]]; then
      BEST_LATENCY=$latency
      BEST_NODE="$node"
    fi
  fi
done < <(measure_latencies)

if [[ -n "$BEST_NODE" ]]; then
  print_json_result
else
  echo "No reachable nodes found" >&2
  exit 1
fi
