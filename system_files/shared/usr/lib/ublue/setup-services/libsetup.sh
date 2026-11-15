#!/usr/bin/env bash

SETUP_CHECKER_FILE="${SETUP_CHECKER_FILE:-$HOME/.local/share/ublue/setup_versioning.json}"

# Meant to be used at the start of any setup service script. Will version your script accordingly on $SETUP_CHECKER_FILE
# :target_versioning_name: Whatever you want to name your versioning tag. Please keep it always the same
# :type_of_service: Must be either `user`, `privileged`, or `system`
# :version: Target version to check/apply to your file
#
# Meant to be used as follows (or similar):
# version-script tailscale user 1 || exit 0
function version-script() {
  TARGET_VERSIONING_NAME=$1
  TYPE_OF_SERVICE=$2
  VERSION=$3
  shift
  shift
  shift

  if [ ! -e "${SETUP_CHECKER_FILE}" ] ; then
    mkdir -p "$(dirname "${SETUP_CHECKER_FILE}")"
    echo "{}" > "${SETUP_CHECKER_FILE}"
  fi

  if [ "$(jq -r -c ".version.${TYPE_OF_SERVICE}.\"${TARGET_VERSIONING_NAME}\"" "${SETUP_CHECKER_FILE}")" == "${VERSION}" ] ; then
    echo "Exiting as current version (${VERSION}) for ${TYPE_OF_SERVICE}-${TARGET_VERSIONING_NAME} is the same as latest version recorded on ${SETUP_CHECKER_FILE}"
    return 1
  fi
  ANNOYING_JQ_WORKAROUND=$(mktemp)
  jq ".version.${TYPE_OF_SERVICE}.\"${TARGET_VERSIONING_NAME}\" = \"${VERSION}\"" "${SETUP_CHECKER_FILE}" >"${ANNOYING_JQ_WORKAROUND}"
  mv "${ANNOYING_JQ_WORKAROUND}" "${SETUP_CHECKER_FILE}"
  set +x
  return 0
}
