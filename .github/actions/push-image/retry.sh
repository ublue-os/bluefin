#!/usr/bin/env bash

# Function to retry a command up to a specified number of times
retry() {
  local retries=$1
  shift
  local count=0
  local success=false

  until [ "$count" -ge "$retries" ]; do
    "$@" && success=true && break
    count=$((count + 1))
    echo "Retry $count/$retries failed, retrying..."
    sleep 1
  done

  if [ "$success" = false ]; then
    echo "Command failed after $retries attempts"
    return 1
  fi

  return 0
}

# Call the retry function with the arguments passed to the script
retry "$@"
