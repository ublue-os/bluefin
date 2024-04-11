#!/usr/bin/bash

set -oue pipefail

if [[ "${BASE_IMAGE_NAME}" = "kinoite" ]]; then
    sed -i '/<entry name="launchers" type="StringList">/,/<\/entry>/ s/<default>[^<]*<\/default>/<default>preferred:\/\/browser,applications:org.gnome.Ptyxis.desktop,applications:org.kde.discover.desktop,preferred:\/\/filemanager<\/default>/' /usr/share/plasma/plasmoids/org.kde.plasma.taskmanager/contents/config/main.xml
    sed -i '/<entry name="favorites" type="StringList">/,/<\/entry>/ s/<default>[^<]*<\/default>/<default>preferred:\/\/browser,systemsettings.desktop,org.kde.dolphin.desktop,org.kde.kate.desktop,org.gnome.Ptyxis.desktop,org.kde.discover.desktop<\/default>/' /usr/share/plasma/plasmoids/org.kde.plasma.kickoff/contents/config/main.xml
    sed -i 's@Exec=ptyxis@Exec=kde-ptyxis@g' /usr/share/applications/org.gnome.Ptyxis.desktop
    sed -i 's@Keywords=@Keywords=konsole;@g' /usr/share/applications/org.gnome.Ptyxis.desktop
    cp /usr/share/applications/org.gnome.Ptyxis.desktop /usr/share/kglobalaccel/org.gnome.Ptyxis.desktop
fi
