#!/usr/bin/bash
# Run `flatpak repair --user` once after every Fedora major version change.
# A major rebase can leave stale refs, objects or half-removed deploys in
# ~/.local/share/flatpak that break apps until the installation is repaired
# (the documented workaround was `flatpak repair --user && flatpak uninstall --unused`).
# See https://github.com/ublue-os/bluefin/issues/4403

source /usr/lib/ublue/setup-services/libsetup.sh

FEDORA_MAJOR="$(sed -n 's/^VERSION_ID=//p' /usr/lib/os-release | tr -d '"')"
[[ -n "$FEDORA_MAJOR" ]] || exit 0
command -v flatpak >/dev/null || exit 0

# Repair may need to reinstall refs from the remote. Don't record the
# version while offline; try again next login.
if ! nm-online -q --timeout=60; then
	echo "flatpak-repair: no network, will retry next login"
	exit 0
fi

# Forget the recorded version so the next login tries again.
unrecord() {
	local tmp
	tmp="$(mktemp)" || return 0
	if jq 'del(.version.user."flatpak-repair")' "$SETUP_CHECKER_FILE" >"$tmp"; then
		mv "$tmp" "$SETUP_CHECKER_FILE"
	else
		rm -f "$tmp"
	fi
}

version-script flatpak-repair user "$FEDORA_MAJOR" || exit 0

# Nothing to repair if this user has no per-user flatpaks (new users,
# fresh installs). The version is recorded, so this check runs once per release.
if [[ -z "$(flatpak list --user --columns=ref 2>/dev/null)" ]]; then
	echo "flatpak-repair: no per-user flatpaks, nothing to repair"
	exit 0
fi

echo "flatpak-repair: Fedora ${FEDORA_MAJOR} detected, repairing the per-user flatpak installation"
if timeout 30m nice -n 10 ionice -c 2 -n 7 flatpak repair --user; then
	echo "flatpak-repair: per-user installation repaired"
else
	echo "flatpak-repair: 'flatpak repair --user' failed (exit $?), will retry next login"
	unrecord
fi

# Only touches the per-user installation. Runtimes the user installed
# explicitly are pinned by flatpak and are never removed by --unused.
if ! timeout 10m flatpak uninstall --user --unused --noninteractive -y; then
	echo "flatpak-repair: 'flatpak uninstall --user --unused' failed, continuing"
fi
exit 0
