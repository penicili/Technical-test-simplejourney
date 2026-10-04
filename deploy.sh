#!/bin/sh
set -eu

NAME="${NAME:-hello}"
HEALTH_URL="${HEALTH_URL:-http://host.docker.internal:8080/}"
NEW_BIN="$1"
EXPECTED="$2"
BACKUP="$(mktemp)"

chmod +x "$NEW_BIN"
docker cp "$NAME:/app" "$BACKUP"

rollback() {
  echo "!! deploy gagal, rollback ke binary sebelumnya" >&2
  docker cp "$BACKUP" "$NAME:/app"
  docker restart -t 2 "$NAME" >/dev/null
  exit 1
}
trap rollback EXIT

docker cp "$NEW_BIN" "$NAME:/app"
docker restart -t 2 "$NAME" >/dev/null

i=0
while [ "$i" -lt 15 ]; do
  if curl -fsS "$HEALTH_URL" | grep -q "version=$EXPECTED"; then
    trap - EXIT
    rm -f "$BACKUP"
    echo "deploy OK: version=$EXPECTED"
    exit 0
  fi
  i=$((i+1)); sleep 1
done
exit 1