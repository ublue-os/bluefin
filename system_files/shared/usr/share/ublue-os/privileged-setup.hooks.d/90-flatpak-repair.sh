#!/usr/bin/bash
# Run `flatpak repair --system` once after every Fedora major version change.
# A major rebase can leave stale refs, objects or half-removed deploys in
# /var/lib/flatpak that break apps until the installation is repaired.
# See https://github.com/ublue-os/bluefin/issues/4403

source /usr/lib/ublue/setup-services/libsetup.sh

FEDORA_MAJOR="$(sed -n 's/^VERSION_ID=//p' /usr/lib/os-release | tr -d '"')"
[[ -n "$FEDORA_MAJOR" ]] || exit 0
command -v flatpak >/dev/null || exit 0

# flatpak-preinstall.service installs flatpaks at boot. Don't repair the
# installation while it is still writing to it; try again next login.
for _ in $(seq 60); do
	[[ "$(systemctl show -P ActiveState flatpak-preinstall.service 2>/dev/null)" == "activating" ]] || break
	sleep 10
done
if [[ "$(systemctl show -P ActiveState flatpak-preinstall.service 2>/dev/null)" == "activating" ]]; then
	echo "flatpak-repair: flatpak-preinstall.service still running, will retry next login"
	exit 0
fi

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
	if jq 'del(.version.privileged."flatpak-repair")' "$SETUP_CHECKER_FILE" >"$tmp"; then
		mv "$tmp" "$SETUP_CHECKER_FILE"
	else
		rm -f "$tmp"
	fi
}

version-script flatpak-repair privileged "$FEDORA_MAJOR" || exit 0

# A fresh install has nothing stale to repair. Without a previous (rollback)
# deployment there was no earlier OS version, so only record the baseline.
PREVIOUS_DEPLOYMENTS="$(rpm-ostree status --json 2>/dev/null | jq '[.deployments[] | select((.booted | not) and (.staged | not))] | length' 2>/dev/null)"
if [[ "$PREVIOUS_DEPLOYMENTS" == "0" ]]; then
	echo "flatpak-repair: fresh install on Fedora ${FEDORA_MAJOR}, nothing to repair"
	exit 0
fi

echo "flatpak-repair: Fedora ${FEDORA_MAJOR} detected, repairing the system flatpak installation"
# Not running `flatpak uninstall --unused --system` here: as root it only
# checks root's own per-user installation, so it would remove system runtimes
# that apps in a regular user's --user installation still need.
if timeout 30m nice -n 10 ionice -c 2 -n 7 flatpak repair --system; then
	echo "flatpak-repair: system installation repaired"
else
	echo "flatpak-repair: 'flatpak repair --system' failed (exit $?), will retry next login"
	unrecord
fi
exit 0
