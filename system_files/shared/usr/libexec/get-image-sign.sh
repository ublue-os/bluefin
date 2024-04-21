#!/usr/bin/bash

IMAGE=$(rpm-ostree status --booted | head -3 | tail -1)
if grep -qv signed <<< "${IMAGE}"; then
	echo "🔒 No"
else
	echo "🔐 Yes"
fi
