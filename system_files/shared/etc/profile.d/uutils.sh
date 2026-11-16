#!/usr/bin/env bash
if [[ -d "/home/linuxbrew/.linuxbrew/opt/uutils-coreutils/libexec/uubin" && $- == *i* ]] ; then
  PATH="/home/linuxbrew/.linuxbrew/opt/uutils-coreutils/libexec/uubin:$PATH" 
  PATH="/home/linuxbrew/.linuxbrew/opt/uutils-diffutils/libexec/uubin:$PATH"
  PATH="/home/linuxbrew/.linuxbrew/opt/uutils-findutils/libexec/uubin:$PATH"
  export PATH
  # Fix compatibility issue with atuin - use GNU stty instead of uutils stty
  # uutils stty has format compatibility issues with GNU stty's saved state
  alias stty='/usr/bin/stty'
fi
