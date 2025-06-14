#!/usr/bin/env bash

source /usr/lib/ublue/setup-services/libsetup.sh

version-script framework system 2 || exit 0

set -x

CPU_VENDOR=$(grep "vendor_id" "/proc/cpuinfo" | uniq | awk -F": " '{ print $2 }')
VEN_ID="$(cat /sys/devices/virtual/dmi/id/chassis_vendor)"
BIOS_VERSION="$(cat /sys/devices/virtual/dmi/id/bios_version 2>/dev/null)"

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
if [[ "$VEN_ID" == "Framework" && "$SYS_ID" == "Laptop 13 ("* && "$CPU_VENDOR" == "AuthenticAMD" ]]; then
    echo "Framework Laptop 13 AMD detected"

    # 3.5mm jack fix
    if [[ ! -f /etc/modprobe.d/alsa.conf ]]; then
        echo "Applying 3.5mm audio jack fix"
        tee /etc/modprobe.d/alsa.conf <<<"options snd-hda-intel index=1,0 model=auto,dell-headset-multi"
        echo 0 | tee /sys/module/snd_hda_intel/parameters/power_save
    fi

    # Suspend fix — apply or remove depending on BIOS version
	# On BIOS versions >= 3.09, the workaround is not needed
	# (https://knowledgebase.frame.work/framework-laptop-13-bios-and-driver-releases-amd-ryzen-7040-series-r1rXGVL16)
    if [[ "$(printf '%s\n' 03.09 "$BIOS_VERSION" | sort -V | head -n1)" == "03.09" ]]; then
        # BIOS is >= 3.09, remove workaround if present
        if [[ -f /etc/udev/rules.d/20-suspend-fixes.rules ]]; then
            echo "BIOS $BIOS_VERSION >= 3.09 — removing old suspend workaround"
            rm -f /etc/udev/rules.d/20-suspend-fixes.rules
        fi
    else
        # BIOS is older, apply workaround
        if [[ ! -f /etc/udev/rules.d/20-suspend-fixes.rules ]]; then
            echo "BIOS $BIOS_VERSION < 3.09 — applying suspend workaround"
            echo 'ACTION=="add", SUBSYSTEM=="serio", DRIVERS=="atkbd", ATTR{power/wakeup}="disabled"' \
                > /etc/udev/rules.d/20-suspend-fixes.rules
        fi
    fi
fi
