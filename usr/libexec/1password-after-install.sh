#!/bin/sh
set -eu

installFiles() {
  CWD=$(pwd)
  cd /usr/1Password/

  # Fill in policy kit file with a list of (the first 10) human users of the system.
  export POLICY_OWNERS
  POLICY_OWNERS="$(cut -d: -f1,3 /etc/passwd | grep -E ':[0-9]{4}$' | cut -d: -f1 | head -n 10 | sed 's/^/unix-user:/' | tr '\n' ' ')"
  eval "cat <<EOF
$(cat ./com.1password.1Password.policy.tpl)
EOF" > ./com.1password.1Password.policy

  # Install policy kit file for system unlock
  install -Dm0644 ./com.1password.1Password.policy -t /usr/share/polkit-1/actions/

  # Install examples
  install -Dm0644 ./resources/custom_allowed_browsers -t /usr/share/doc/1password/examples/

  # chrome-sandbox requires the setuid bit to be specifically set.
  # See https://github.com/electron/electron/issues/17972
  chmod 4755 ./chrome-sandbox

  GROUP_NAME="onepassword"

  # Setup the Core App Integration helper binary with the correct permissions and group
  if [ ! "$(getent group "${GROUP_NAME}")" ]; then
    groupadd "${GROUP_NAME}"
  fi

  HELPER_PATH="./1Password-KeyringHelper"
  BROWSER_SUPPORT_PATH="./1Password-BrowserSupport"

  chgrp "${GROUP_NAME}" $HELPER_PATH
  # The binary requires setuid so it may interact with the Kernel keyring facilities
  chmod u+s $HELPER_PATH
  chmod g+s $HELPER_PATH

  # This gives no extra permissions to the binary. It only hardens it against environmental tampering.
  chgrp "${GROUP_NAME}" $BROWSER_SUPPORT_PATH
  chmod g+s $BROWSER_SUPPORT_PATH

  # Restore previous directory
  cd "$CWD"

  # Register path symlink
  ln -sf /usr/1Password/1password /usr/bin/1password
}

if [ "$(id -u)" -ne 0 ]; then
  echo "You must be running as root to run 1Password's post-installation process"
  exit
fi

installFiles

exit 0
