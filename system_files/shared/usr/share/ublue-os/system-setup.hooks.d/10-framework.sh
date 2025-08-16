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

# FRAMEWORK 13 FIXES
if [[ "$VEN_ID" == "Framework" && "$SYS_ID" == "Laptop 13 ("* ]]; then
    echo "Framework Laptop 13 detected"

    # 3.5mm jack fix. Framework 13 laptops need a quirk to disable headset presence detection for the 3.5 mm jack. The kernel auto-enables this quirk for most models but coverage is incomplete (as of kernel 6.16, Framework 13 Ryzen AI 300 is missing) so we enable it here explicitly.
    # Kernel quirk: https://github.com/torvalds/linux/blame/v6.16/sound/pci/hda/patch_realtek.c#L11445-L11448
    if [[ ! -f /etc/modprobe.d/alsa.conf ]]; then
        echo "Applying 3.5mm audio jack fix"
        tee /etc/modprobe.d/alsa.conf <<<"options snd-hda-intel index=1,0 model=auto,dell-headset-multi"
        echo 0 | tee /sys/module/snd_hda_intel/parameters/power_save
    fi

    # Suspend fix for Framework 13 Ryzen 7040
    # On BIOS versions >= 3.09, the workaround is not needed
    # (https://knowledgebase.frame.work/framework-laptop-13-bios-and-driver-releases-amd-ryzen-7040-series-r1rXGVL16)
    if [[ "$SYS_ID" == "Laptop 13 (AMD Ryzen 7040Series)" && "$(printf '%s\n' 03.08 "$BIOS_VERSION" | sort -V | tail -n1)" == "03.08" ]]; then
        # BIOS is older, apply workaround
        if [[ ! -f /etc/udev/rules.d/20-suspend-fixes.rules ]]; then
            echo "Framework 13 Ryzen 7040 with BIOS $BIOS_VERSION < 3.09 — applying suspend workaround"
            echo 'ACTION=="add", SUBSYSTEM=="serio", DRIVERS=="atkbd", ATTR{power/wakeup}="disabled"' \
                > /etc/udev/rules.d/20-suspend-fixes.rules
        fi
    else
        # BIOS is >= 3.09, remove workaround if present
        # Older versions of this script also mistakenly applied then
        # workaround to Framework 13 Ryzen AI 300. Will get cleaned up here too.
        if [[ -f /etc/udev/rules.d/20-suspend-fixes.rules ]]; then
            echo "Removing old suspend workaround"
            rm -f /etc/udev/rules.d/20-suspend-fixes.rules
        fi
    fi
fi
