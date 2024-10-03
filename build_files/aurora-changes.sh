#!/usr/bin/bash

set -ouex pipefail

if [[ "${BASE_IMAGE_NAME}" = "kinoite" ]]; then
    ln -sf ../places/distributor-logo.svg /usr/share/icons/hicolor/scalable/apps/start-here.svg
    ln -sf jonatan-pie-aurora.png /usr/share/backgrounds/default.png
    ln -sf greg-rakozy-aurora.png /usr/share/backgrounds/default-dark.png
    ln -sf aurora.xml /usr/share/backgrounds/default.xml
    sed -i '/<entry name="launchers" type="StringList">/,/<\/entry>/ s/<default>[^<]*<\/default>/<default>preferred:\/\/browser,applications:org.gnome.Ptyxis.desktop,applications:org.kde.discover.desktop,preferred:\/\/filemanager<\/default>/' /usr/share/plasma/plasmoids/org.kde.plasma.taskmanager/contents/config/main.xml
    sed -i '/<entry name="favorites" type="StringList">/,/<\/entry>/ s/<default>[^<]*<\/default>/<default>preferred:\/\/browser,systemsettings.desktop,org.kde.dolphin.desktop,org.kde.kate.desktop,org.gnome.Ptyxis.desktop,org.kde.discover.desktop<\/default>/' /usr/share/plasma/plasmoids/org.kde.plasma.kickoff/contents/config/main.xml
    sed -i 's@\[Desktop Action new-window\]@\[Desktop Action new-window\]\nX-KDE-Shortcuts=Ctrl+Alt+T@g' /usr/share/applications/org.gnome.Ptyxis.desktop
    sed -i 's@Exec=ptyxis@Exec=kde-ptyxis@g' /usr/share/applications/org.gnome.Ptyxis.desktop
    sed -i 's@Keywords=@Keywords=konsole;console;@g' /usr/share/applications/org.gnome.Ptyxis.desktop
    cp /usr/share/applications/org.gnome.Ptyxis.desktop /usr/share/kglobalaccel/org.gnome.Ptyxis.desktop
    sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nNoDisplay=true@g' /usr/share/applications/org.kde.konsole.desktop
    sed -i 's@Bluefin@Aurora@g' /usr/share/applications/system-update.desktop
    sed -i 's@Bluefin@Aurora@g' /usr/share/ublue-os/motd/tips/10-tips.md
    sed -i 's@Bluefin@Aurora@g' /usr/libexec/ublue-flatpak-manager
    rm -f /etc/profile.d/gnome-ssh-askpass.{csh,sh} # This shouldn't be pulled in
    rm -f /usr/share/kglobalaccel/org.kde.konsole.desktop
    systemctl enable kde-sysmonitor-workaround.service
    # Test aurora gschema override for errors. If there are no errors, proceed with compiling aurora gschema, which includes setting overrides.
    mkdir -p /tmp/aurora-schema-test
    find /usr/share/glib-2.0/schemas/ -type f ! -name "*.gschema.override" -exec cp {} /tmp/aurora-schema-test/ \;
    cp /usr/share/glib-2.0/schemas/zz0-aurora-modifications.gschema.override /tmp/aurora-schema-test/
    echo "Running error test for aurora gschema override. Aborting if failed."
    glib-compile-schemas --strict /tmp/aurora-schema-test
    echo "Compiling gschema to include aurora setting overrides"
    glib-compile-schemas /usr/share/glib-2.0/schemas &>/dev/null    
fi
