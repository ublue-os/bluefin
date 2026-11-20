#!/usr/bin/bash

source /usr/lib/ublue/setup-services/libsetup.sh

# Installing extensions needs the network. Don't record the version while
# offline; try again at the next login.
if ! nm-online -q --timeout=60; then
	echo "vscode: no network, will retry next login"
	exit 0
fi

# Version 2: on Fedora 45 every extension install failed (vsce-sign could not
# find libssl.so.3) but version 1 was still recorded. Run once more for them.
version-script vscode user 2 || exit 1

set -x

# Setup VSCode
if test ! -e "$HOME"/.config/Code/User/settings.json; then
	mkdir -p "$HOME"/.config/Code/User
	cp -f /etc/skel/.config/Code/User/settings.json "$HOME"/.config/Code/User/settings.json
fi

failed=0
for extension in \
	ms-vscode-remote.remote-containers \
	ms-vscode-remote.remote-ssh \
	ms-azuretools.vscode-containers; do
	code --install-extension "$extension" || failed=1
done

if [[ "$failed" -ne 0 ]]; then
	# Forget the recorded version so this is retried at the next login
	tmp="$(mktemp)"
	jq 'del(.version.user.vscode)' "$SETUP_CHECKER_FILE" >"$tmp" && mv "$tmp" "$SETUP_CHECKER_FILE"
	exit 1
fi
