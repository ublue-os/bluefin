#!/bin/sh 
 
if test ! -f "/run/user/${UID}/container-entry" && test -n "$PS1"; then  
    touch "/run/user/${UID}/container-entry"  
    exec /usr/bin/distrobox-enter bluefin-cli 
fi