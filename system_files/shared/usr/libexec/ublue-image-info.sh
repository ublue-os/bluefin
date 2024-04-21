#!/usr/bin/bash

echo -n "$(jq -r '\"\\(.[\"image-name\"]):\\(.[\"image-tag\"])\"'  < /usr/share/ublue-os/image-info.json)"

if [[ $(rpm-ostree status --booted) =~ "signed" ]]; then
	echo -n "🔐"
else
	echo -n "🔒"
fi