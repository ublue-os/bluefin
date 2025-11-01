#!/usr/bin/env bash

source /usr/lib/ublue/setup-services/libsetup.sh

version-script theming user 1 || exit 0

set -xeuo pipefail

VEN_ID="$(cat /sys/devices/virtual/dmi/id/chassis_vendor)"

if [[ ":Framework:" =~ :$VEN_ID: ]]; then
	echo 'Setting Framework logo menu'
	dconf write /org/gnome/shell/extensions/Logo-menu/symbolic-icon true
	dconf write /org/gnome/shell/extensions/Logo-menu/menu-button-icon-image 31
	echo 'Setting touch scroll type'
	dconf write /org/gnome/desktop/peripherals/mouse/natural-scroll true
	if [[ $SYS_ID == "Laptop ("* ]]; then
		echo 'Applying font fix for Framework 13'
		dconf write /org/gnome/desktop/interface/text-scaling-factor 1.25
	fi
fi

SYS_ID="$(cat /sys/devices/virtual/dmi/id/product_name)"

if [[ ":Thelio Astra:" =~ :$SYS_ID: ]]; then
	echo 'Setting Ampere Logo'
 	dconf write /org/gnome/shell/extensions/Logo-menu/symbolic-icon true
	dconf write /org/gnome/shell/extensions/Logo-menu/menu-button-icon-image 32
 fi
