#!/bin/bash
# Select optimal gaccode relay node based on ping latency

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

echo "Testing gaccode relay nodes..."

for node in "${NODES[@]}"; do
  # Ping 3 times and get average latency (macOS/Linux compatible)
  latency=$(ping -c 3 "$node" 2>/dev/null | tail -1 | awk -F '/' '{print $5}')

  if [ -n "$latency" ]; then
    echo "  $node: ${latency}ms"

    # Compare and keep best (use bc for float comparison)
    if [ "$(echo "$latency < $BEST_LATENCY" | bc)" -eq 1 ]; then
      BEST_LATENCY=$latency
      BEST_NODE="$node"
    fi
  else
    echo "  $node: unreachable"
  fi
done

if [ -n "$BEST_NODE" ]; then
  echo ""
  echo "✓ Best node: $BEST_NODE (${BEST_LATENCY}ms avg latency)"
  echo ""
  echo "Recommended baseUrl:"
  echo "  https://$BEST_NODE/api/v1"
  echo ""
  echo "Add to ~/.openclaw/.env:"
  echo "  GACCODE_BASE_URL=https://$BEST_NODE"
  echo ""
  echo "Or update in openclaw.json models.providers.gaccode.baseUrl"

  # Output JSON format for automation
  if [ "$1" == "--json" ]; then
    echo ""
    cat <<EOF
{
  "best_node": "$BEST_NODE",
  "latency_ms": "$BEST_LATENCY",
  "recommended_url": "https://$BEST_NODE/api/v1"
}
EOF
  fi
else
  echo "✗ No reachable nodes found"
  exit 1
fi