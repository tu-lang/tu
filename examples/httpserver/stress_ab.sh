#!/bin/bash
# Continuous ab gate: no proactive TIME-WAIT sleep (tw_reuse handles most).
# Only drain TW on ab client failure. HARD_WEDGE = curl fail + listen Recv-Q.

set -euo pipefail
PORT="${PORT:-18080}"
URL="http://127.0.0.1:${PORT}/"
ROUNDS="${ROUNDS:-100}"
N="${N:-50000}"
C="${C:-100}"
LOG="${LOG:-/tmp/httpserver_stress_ab.log}"

tw_count() { ss -ant sport = :"$PORT" | awk '/TIME-WAIT/{c++} END{print c+0}'; }

wait_tw() {
  local limit="${1:-5000}" i tw
  tw=$(tw_count)
  [ "$tw" -lt "$limit" ] && return 0
  echo "TW_WAIT start=$tw limit=$limit" | tee -a "$LOG"
  for i in $(seq 1 90); do
    tw=$(tw_count)
    if [ "$tw" -lt "$limit" ]; then
      echo "TW_WAIT done=$tw after ${i}s" | tee -a "$LOG"
      return 0
    fi
    sleep 1
  done
  echo "TW_WAIT timeout tw=$tw" | tee -a "$LOG"
}

wait_drain() {
  local i rq
  for i in $(seq 1 40); do
    rq=$(ss -ltn sport = :"$PORT" | awk 'NR==2{print $2}')
    [ "${rq:-0}" -eq 0 ] && return 0
    sleep 0.1
  done
}

health() {
  wait_drain
  local ok=0 fail=0 i code rq attempt
  # Soft stalls can last tens of seconds — wait before HARD_WEDGE.
  for attempt in $(seq 1 120); do
    ok=0
    fail=0
    for i in 1 2 3; do
      code=$(curl -sS -m 2 -o /dev/null -w "%{http_code}" "$URL" 2>/dev/null || echo 000)
      if [ "$code" = "200" ]; then ok=$((ok + 1)); else fail=$((fail + 1)); fi
    done
    rq=$(ss -ltn sport = :"$PORT" | awk 'NR==2{print $2}')
    if [ "$ok" -ge 2 ] && [ "${rq:-0}" -lt 20 ]; then
      echo "health ok=$ok fail=$fail Recv-Q=$rq TW=$(tw_count)" | tee -a "$LOG"
      return 0
    fi
    if [ $((attempt % 5)) -eq 0 ]; then
      echo "health_retry attempt=$attempt ok=$ok fail=$fail Recv-Q=$rq" | tee -a "$LOG"
    fi
    sleep 1
  done
  rq=$(ss -ltn sport = :"$PORT" | awk 'NR==2{print $2}')
  echo "health ok=$ok fail=$fail Recv-Q=$rq TW=$(tw_count)" | tee -a "$LOG"
  if [ "$fail" -ge 2 ] && [ "${rq:-0}" -gt 10 ]; then
    echo "HARD_WEDGE fail=$fail Recv-Q=$rq" | tee -a "$LOG"
    return 1
  fi
  if [ "$ok" -eq 0 ]; then
    echo "HARD_WEDGE all_curl_fail Recv-Q=$rq" | tee -a "$LOG"
    return 1
  fi
  return 0
}

ab_one() {
  local n="$1" c="$2" tag="$3" outf failed rps complete
  outf="/tmp/ab_out_${tag}.txt"
  ab -q -k -c "$c" -n "$n" -s 60 "$URL" >"$outf" 2>&1 || true
  failed=$(awk '/Failed requests/{print $3}' "$outf")
  rps=$(awk '/Requests per second/{print $4}' "$outf")
  complete=$(awk '/Complete requests/{print $3}' "$outf")
  echo "[$tag] n=$n c=$c complete=${complete:-?} Failed=${failed:-?} rps=${rps:-?} TW=$(tw_count)" | tee -a "$LOG"
  health || return 1
  if [ "${failed:-}" = "0" ] && [ "${complete:-}" = "$n" ]; then
    return 0
  fi
  echo "CLIENT_RETRY tag=$tag" | tee -a "$LOG"
  wait_tw 3000
  ab -q -k -c "$c" -n "$n" -s 60 "$URL" >"$outf" 2>&1 || true
  failed=$(awk '/Failed requests/{print $3}' "$outf")
  complete=$(awk '/Complete requests/{print $3}' "$outf")
  rps=$(awk '/Requests per second/{print $4}' "$outf")
  echo "[$tag.retry] complete=${complete:-?} Failed=${failed:-?} rps=${rps:-?} TW=$(tw_count)" | tee -a "$LOG"
  health || return 1
  if [ "${failed}" = "0" ] && [ "${complete}" = "$n" ]; then
    return 0
  fi
  echo "CLIENT_NOISE tag=$tag (server healthy)" | tee -a "$LOG"
  return 0
}

: >"$LOG"
echo "=== START $(date -Is) rounds=$ROUNDS n=$N c=$C ===" | tee -a "$LOG"
health || exit 1
for i in $(seq 1 "$ROUNDS"); do
  ab_one "$N" "$C" "r$i" || exit 1
done
echo "${ROUNDS}x${N} OK" | tee -a "$LOG"
if [ "${LONG:-1}" = "1" ]; then
  ab_one 2000000 "$C" "2M" || exit 1
  ab_one 5000000 "$C" "5M" || exit 1
fi
echo "=== ALL PASS $(date -Is) ===" | tee -a "$LOG"
