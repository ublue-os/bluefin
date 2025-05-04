#!/usr/bin/env bash

source /usr/lib/ublue/setup-services/libsetup.sh

version-script framework system 1 || exit 0

set -x

# GLOBAL
KARGS=$(rpm-ostree kargs)
NEEDED_KARGS=()
echo "Current kargs: $KARGS"

if [[ $KARGS =~ "nomodeset" ]]; then
	echo "Removing nomodeset"
	NEEDED_KARGS+=("--delete-if-present=nomodeset")
fi

if [[ ":Framework:" =~ :$VEN_ID: ]]; then
	if [[ "GenuineIntel" == "$CPU_VENDOR" ]]; then
		if [[ ! $KARGS =~ "hid_sensor_hub" ]]; then
			echo "Intel Framework Laptop detected, applying needed keyboard fix"
			NEEDED_KARGS+=("--append-if-missing=module_blacklist=hid_sensor_hub")
		fi
	fi
fi

#shellcheck disable=SC2128
if [[ -n "$NEEDED_KARGS" ]]; then
	echo "Found needed karg changes, applying the following: ${NEEDED_KARGS[*]}"
	plymouth display-message --text="Updating kargs - Please wait, this may take a while" || true
	rpm-ostree kargs "${NEEDED_KARGS[*]}" --reboot || exit 1
else
	echo "No karg changes needed"
fi

SYS_ID="$(cat /sys/devices/virtual/dmi/id/product_name)"

# FRAMEWORK 13 AMD FIXES
if [[ ":Framework:" =~ :$VEN_ID: ]]; then
	if [[ $SYS_ID == "Laptop 13 ("* ]]; then
		if [[ "AuthenticAMD" == "$CPU_VENDOR" ]]; then
			if [[ ! -f /etc/modprobe.d/alsa.conf ]]; then
				echo 'Fixing 3.5mm jack'
				tee /etc/modprobe.d/alsa.conf <<<"options snd-hda-intel index=1,0 model=auto,dell-headset-multi"
				echo 0 | tee /sys/module/snd_hda_intel/parameters/power_save
			fi
			if [[ ! -f /etc/udev/rules.d/20-suspend-fixes.rules ]]; then
				echo 'Fixing suspend issue'
				echo "ACTION==\"add\", SUBSYSTEM==\"serio\", DRIVERS==\"atkbd\", ATTR{power/wakeup}=\"disabled\"" >/etc/udev/rules.d/20-suspend-fixes.rules
			fi
		fi
	fi
fi
