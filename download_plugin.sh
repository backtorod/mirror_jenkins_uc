#!/bin/bash

URL="$1"
LOG_FILE="$2"
LOCK_FILE="$3"

function write_log() {
  while [[ -e ${LOCK_FILE} ]]; do
    sleep 1
  done

  trap "rm -f ${LOCK_FILE}" EXIT && touch ${LOCK_FILE}
  echo "# [$(date +"%Y%m%d%H%M%S")] ${1}" >> ${LOG_FILE}
}

wget -m -q -nH -np ${URL}

if [[ "$?" != "0" ]]; then
  write_log "There was an error while checking/downloading ${URL}"
else
  write_log "Successfully checked/downloaded ${URL}"
fi