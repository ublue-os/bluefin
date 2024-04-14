#!/usr/bin/bash

set -oue pipefail

if [[ "${BASE_IMAGE_NAME}" = "kinoite" ]]; then
    ln -sf ../places/distributor-logo.svg /usr/share/icons/hicolor/scalable/apps/start-here.svg
    sed -i 's@ColorScheme=BreezeLight@ColorScheme=BreezeDark@' /usr/share/plasma/look-and-feel/org.fedoraproject.fedora.desktop/contents/defaults
    sed -i 's@Image=Fedora@Image=/usr/share/wallpapers/jonaton-pie-aurora.jpg@' /usr/share/plasma/look-and-feel/org.fedoraproject.fedora.desktop/contents/defaults
    sed -i '/<entry name="launchers" type="StringList">/,/<\/entry>/ s/<default>[^<]*<\/default>/<default>preferred:\/\/browser,applications:org.gnome.Ptyxis.desktop,applications:org.kde.discover.desktop,preferred:\/\/filemanager<\/default>/' /usr/share/plasma/plasmoids/org.kde.plasma.taskmanager/contents/config/main.xml
    sed -i '/<entry name="favorites" type="StringList">/,/<\/entry>/ s/<default>[^<]*<\/default>/<default>preferred:\/\/browser,systemsettings.desktop,org.kde.dolphin.desktop,org.kde.kate.desktop,org.gnome.Ptyxis.desktop,org.kde.discover.desktop<\/default>/' /usr/share/plasma/plasmoids/org.kde.plasma.kickoff/contents/config/main.xml
    sed -i 's@Exec=ptyxis@Exec=kde-ptyxis@g' /usr/share/applications/org.gnome.Ptyxis.desktop
    sed -i 's@Keywords=@Keywords=konsole;console;@g' /usr/share/applications/org.gnome.Ptyxis.desktop
    cp /usr/share/applications/org.gnome.Ptyxis.desktop /usr/share/kglobalaccel/org.gnome.Ptyxis.desktop
    sed -i 's@\[Desktop Action new-window\]@\[Desktop Action new-window\]\nX-KDE-Shortcuts=Ctrl+Alt+T@g' /usr/share/applications/org.gnome.Ptyxis.desktop
    sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nNoDisplay=true@g' /usr/share/applications/org.kde.konsole.desktop
    rm -f /usr/share/kglobalaccel/org.kde.konsole.desktop
    systemctl enable kde-sysmonitor-workaround.service
fi
