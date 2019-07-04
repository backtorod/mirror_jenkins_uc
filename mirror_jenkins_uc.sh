#!/usr/bin/env bash

set -eu
#set -eou pipefail

PARALLEL_JOBS_MAX=30

if [ $# -lt 1 ]; then

  echo ""
  echo "===> Usage : $0 <local_mirror_path> <custom_jenkins_update_center_fqdn>"
  echo ""
  echo "===> Example: $0 /jenkins-ci-updates jenkins.example.com"
  echo ""
  exit 1

else

  function clean_logs() {
    LOG_FILES_NR="$(ls $LOG_PATH/*.log.gz | wc -l)"
    if [[ ${LOG_FILES_NR} -gt 30 ]]; then
      ls $LOG_PATH/*.log.gz | sort | head -n $((${LOG_FILE_NR} - 30)) | xargs rm -f
    fi
  }

  function kill_all_jobs() {
    RUNNING_JOBS="$(jobs | cut -d'[' -f2 | cut -d']' -f1)"
    while IFS= read -r line; do
      kill %${line}
    done <<< "${RUNNING_JOBS}"
    gzip ${LOG_FILE}
    clean_logs
  }

  SYNC_TIMESTAMP=$(date +"%Y%m%d%H%M%S")
  SCRIPT_PATH=$(dirname $0)
  MIRRORS_PATH="${1}"
  LOG_PATH="${SCRIPT_PATH}/logs"
  LOG_FILE="${LOG_PATH}/${SYNC_TIMESTAMP}_sync_mirror.log"
  UC_FQDN="${2}"
  UC_SRC="rsync://rsync.osuosl.org/jenkins/updates/"

  # Check if local mirror directory exists
  #
  if [ ! -d "${MIRRORS_PATH}" ]; then
    mkdir -p "${MIRRORS_PATH}"
  fi

  # Check if log path directory exists
  #
  if [ ! -d "${LOG_PATH}" ]; then
    mkdir -p "${LOG_PATH}"
  fi

  if [ ! -e "${LOG_FILE}" ]; then
    touch "${LOG_FILE}"
  fi

  pushd ${MIRRORS_PATH}

  #
  # Rsync update-center information from ${UC_SRC}
  #
  rsync -az --log-file=${LOG_FILE} --no-owner --no-group --no-perms ${UC_SRC} ${MIRRORS_PATH}

  #
  # Get update-center versions
  #
  REPO_VERSIONS=$(ls -d */ | grep -v updates | grep -v experimental | grep -v download | sed 's/\///g')

  #
  # Prepare update-center with custom URL
  #
  for version in ${REPO_VERSIONS}; do

    sed -i.bak "s/http:\/\/updates.jenkins-ci.org/http:\/\/${UC_FQDN}/g" "${MIRRORS_PATH}/${version}/update-center.json"
    if [[ "$?" == "0" ]]; then
      echo "# Successfully modified ${MIRRORS_PATH}/${version}/update-center.json" >> ${LOG_FILE}
    else
      echo "# There was an error while modifying ${MIRRORS_PATH}/${version}/update-center.json" >> ${LOG_FILE}
    fi

  done

  #
  # Get list of available plugins
  #
  AVAILABLE_PLUGINS=$(curl -SsL http://updates.jenkins-ci.org/download/plugins | grep href | sed 's/.*href="//' | sed 's/".*//' | sed 's/\///' | grep '^[a-zA-Z].*' | grep -v download | sort -n)

  trap "kill_all_jobs" EXIT
  #
  # Get list of available plugin versions and locally sync them
  #
  for plugin in ${AVAILABLE_PLUGINS[@]}; do

    # grep -E "^[0-9\S]+" to avoid any non-numeric versions
    PLUGIN_VERSIONS=$(curl -SsL http://updates.jenkins-ci.org/download/plugins/${plugin} | awk -F "/download/plugins/${plugin}/" "{print \$2}" | grep -E "^[0-9\S]+" | awk -F "/${plugin}.hpi'>[0-9]" "{ print \$1 }" | sed "s/'//g" | awk 'NF > 0' | sort -n)

    for version in ${PLUGIN_VERSIONS[@]}; do

      RUNNING_JOBS="$(jobs | grep "Running" |  wc -l)"
      until [[ $RUNNING_JOBS -lt $PARALLEL_JOBS_MAX ]]; do
        sleep 5
        RUNNING_JOBS="$(jobs | grep "Running" | wc -l)"
      done

      DOWNLOAD_URL="$(echo "http://updates.jenkins-ci.org/download/plugins/${plugin}/${version}/${plugin}.hpi")"
      ${SCRIPT_PATH}/download_plugin.sh "${DOWNLOAD_URL}" ${LOG_FILE} ${LOG_PATH}/lock_file &

    done

  done

  RUNNING_JOBS="$(jobs | grep "Running" | wc -l)"
  until [[ "$RUNNING_JOBS" -eq 0 ]]; do
    sleep 10
    RUNNING_JOBS="$(jobs | grep "Running" | wc -l)"
  done

  popd

fi