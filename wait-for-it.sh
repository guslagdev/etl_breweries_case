#!/bin/bash
# wait-for-it.sh

TIMEOUT=15
QUIET=0
WAITFORIT_COMMAND=""

echoerr() {
  if [ "$QUIET" -ne 1 ]; then printf "%s\n" "$*" 1>&2; fi
}

usage() {
  exit 1
}

wait_for_port() {
  local host="$1"
  local port="$2"
  local timeout="$3"
  local start_ts=$(date +%s)
  echoerr "Waiting for $host:$port to be available..."
  while :
  do
    (echo > dev/tcp/$host/$port) >/dev/null 2>&1
    local result=$?
    if [ $result -eq 0 ]; then
      echoerr "$host:$port is available after $(( $(date +%s) - $start_ts ))s"
      break
    fi
    sleep 1
    timeout=$((timeout - 1))
    if [ $timeout -le 0 ]; then
      echoerr "Operation timed out after $(( $(date +%s) - $start_ts ))s"
      return 1
    fi
  done
  return 0
}

while [ $# -gt 0 ]
do
  case "$1" in
    *:* )
    HOST_PORT=("$1")
    shift
    ;;
    -t)
    TIMEOUT="$2"
    if [ "$TIMEOUT" == "" ]; then usage; fi
    shift 2
    ;;
    --)
    shift
    WAITFORIT_COMMAND=("$@")
    break
    ;;
    * )
    usage
  esac
done

if [ "$HOST_PORT" == "" ]; then
  echoerr "Error: host:port argument is required."
  usage
fi

host=$(echo "$HOST_PORT" | cut -d: -f1)
port=$(echo "$HOST_PORT" | cut -d: -f2)

wait_for_port "$host" "$port" "$TIMEOUT"

RESULT=$?
if [ $RESULT -ne 0 ]; then
  exit $RESULT
fi

if [ "$WAITFORIT_COMMAND" != "" ]; then
  exec "$WAITFORIT_COMMAND"
fi