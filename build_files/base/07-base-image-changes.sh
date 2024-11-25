#!/usr/bin/bash

set -ouex pipefail

if [[ "${BASE_IMAGE_NAME}" = "kinoite" ]]; then
    # Branding for flatpak manager
    sed -i 's/Bluefin/Aurora/' /usr/libexec/ublue-flatpak-manager

    # Restore x11 for Nvidia Images
    if [[ "${FEDORA_MAJOR_VERSION}" -eq "40" ]]; then
        rpm-ostree install plasma-workspace-x11
    fi

    # Branding for Images
    ln -sf ../places/distributor-logo.svg /usr/share/icons/hicolor/scalable/apps/start-here.svg
    ln -sf /usr/share/wallpapers/aurora-wallpaper-1/contents/images/15392x8616.jpg /usr/share/backgrounds/default.png
    ln -sf /usr/share/wallpapers/aurora-wallpaper-1/contents/images/15392x8616.jpg /usr/share/backgrounds/default-dark.png
    ln -sf aurora.xml /usr/share/backgrounds/default.xml

    # Favorites in Kickoff
    sed -i '/<entry name="launchers" type="StringList">/,/<\/entry>/ s/<default>[^<]*<\/default>/<default>preferred:\/\/browser,applications:org.gnome.Ptyxis.desktop,applications:org.kde.discover.desktop,preferred:\/\/filemanager<\/default>/' /usr/share/plasma/plasmoids/org.kde.plasma.taskmanager/contents/config/main.xml
    sed -i '/<entry name="favorites" type="StringList">/,/<\/entry>/ s/<default>[^<]*<\/default>/<default>preferred:\/\/browser,systemsettings.desktop,org.kde.dolphin.desktop,org.kde.kate.desktop,org.gnome.Ptyxis.desktop,org.kde.discover.desktop<\/default>/' /usr/share/plasma/plasmoids/org.kde.plasma.kickoff/contents/config/main.xml

    # Ptyxis Terminal
    sed -i 's@\[Desktop Action new-window\]@\[Desktop Action new-window\]\nX-KDE-Shortcuts=Ctrl+Alt+T@g' /usr/share/applications/org.gnome.Ptyxis.desktop
    sed -i 's@Exec=ptyxis@Exec=kde-ptyxis@g' /usr/share/applications/org.gnome.Ptyxis.desktop
    sed -i 's@Keywords=@Keywords=konsole;console;@g' /usr/share/applications/org.gnome.Ptyxis.desktop
    cp /usr/share/applications/org.gnome.Ptyxis.desktop /usr/share/kglobalaccel/org.gnome.Ptyxis.desktop
    sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nNoDisplay=true@g' /usr/share/applications/org.kde.konsole.desktop

    # Rebrand to Aurora
    sed -i 's@Bluefin@Aurora@g' /usr/share/applications/system-update.desktop
    sed -i 's@Bluefin@Aurora@g' /usr/share/ublue-os/motd/tips/10-tips.md
    sed -i 's@Bluefin@Aurora@g' /usr/libexec/ublue-flatpak-manager

    rm -f /etc/profile.d/gnome-ssh-askpass.{csh,sh} # This shouldn't be pulled in
    rm -f /usr/share/kglobalaccel/org.kde.konsole.desktop
    systemctl enable kde-sysmonitor-workaround.service
    systemctl enable usr-share-sddm-themes.mount

    # Get Default Font since font fallback doesn't work
    curl --retry 3 --output-dir /tmp -LO https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip
    mkdir -p /usr/share/fonts/fira-nf
    unzip /tmp/FiraCode.zip -d /usr/share/fonts/fira-nf
    fc-cache -f /usr/share/fonts/fira-nf

    # Test aurora gschema override for errors. If there are no errors, proceed with compiling aurora gschema, which includes setting overrides.
    mkdir -p /tmp/aurora-schema-test
    find /usr/share/glib-2.0/schemas/ -type f ! -name "*.gschema.override" -exec cp {} /tmp/aurora-schema-test/ \;
    cp /usr/share/glib-2.0/schemas/zz0-aurora-modifications.gschema.override /tmp/aurora-schema-test/
    echo "Running error test for aurora gschema override. Aborting if failed."
    glib-compile-schemas --strict /tmp/aurora-schema-test
    echo "Compiling gschema to include aurora setting overrides"
    glib-compile-schemas /usr/share/glib-2.0/schemas &>/dev/null

elif [[ "${BASE_IMAGE_NAME}" = "silverblue" ]]; then

    # Remove desktop entries
    if [[ -f /usr/share/applications/gnome-system-monitor.desktop ]]; then
        sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nHidden=true@g' /usr/share/applications/gnome-system-monitor.desktop
    fi
    if [[ -f /usr/share/applications/org.gnome.SystemMonitor.desktop ]]; then
        sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nHidden=true@g' /usr/share/applications/org.gnome.SystemMonitor.desktop
    fi

    # Add Mutter experimental-features
    MUTTER_EXP_FEATS="'scale-monitor-framebuffer', 'xwayland-native-scaling'"
    if [[ "${IMAGE_NAME}" =~ nvidia ]]; then
        MUTTER_EXP_FEATS="'kms-modifiers', ${MUTTER_EXP_FEATS}"
    fi
    tee /usr/share/glib-2.0/schemas/zz1-bluefin-modifications-mutter-exp-feats.gschema.override << EOF
[org.gnome.mutter]
experimental-features=[${MUTTER_EXP_FEATS}]
EOF

    # GNOME Terminal is replaced with Ptyxis in F41+
    # Make schema valid on GNOME <47 which do not contain the accent-color key or xwayland-native-scaling mutter feature
    if [[ "${FEDORA_MAJOR_VERSION}" -lt "41" ]]; then
        sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nNoDisplay=true@g' /usr/share/applications/org.gnome.Terminal.desktop
        sed -i 's@accent-color="slate"@@g' /usr/share/glib-2.0/schemas/zz0-bluefin-modifications.gschema.override
        sed -i 's@'", "\''xwayland-native-scaling'\''@@g' /usr/share/glib-2.0/schemas/zz1-bluefin-modifications-mutter-exp-feats.gschema.override
    fi

    # Create symlinks from old to new wallpaper names for backwards compatibility
    ln -s "/usr/share/backgrounds/bluefin/01-bluefin.xml" "/usr/share/backgrounds/bluefin/bluefin-winter-dynamic.xml"
    ln -s "/usr/share/backgrounds/bluefin/04-bluefin.xml" "/usr/share/backgrounds/bluefin/bluefin-spring-dynamic.xml"
    ln -s "/usr/share/backgrounds/bluefin/08-bluefin.xml" "/usr/share/backgrounds/bluefin/bluefin-summer-dynamic.xml"
    ln -s "/usr/share/backgrounds/bluefin/11-bluefin.xml" "/usr/share/backgrounds/bluefin/bluefin-autumn-dynamic.xml"
    ln -s "/usr/share/backgrounds/xe_clouds.jxl" "/usr/share/backgrounds/xe_clouds.jpeg"
    ln -s "/usr/share/backgrounds/xe_foothills.jxl" "/usr/share/backgrounds/xe_foothills.jpeg"
    ln -s "/usr/share/backgrounds/xe_space_needle.jxl" "/usr/share/backgrounds/xe_space_needle.jpeg"
    ln -s "/usr/share/backgrounds/xe_sunset.jxl" "/usr/share/backgrounds/xe_sunset.jpeg"

    # Test bluefin gschema override for errors. If there are no errors, proceed with compiling bluefin gschema, which includes setting overrides.
    mkdir -p /tmp/bluefin-schema-test
    find /usr/share/glib-2.0/schemas/ -type f ! -name "*.gschema.override" -exec cp {} /tmp/bluefin-schema-test/ \;
    cp /usr/share/glib-2.0/schemas/zz0-bluefin-modifications.gschema.override /tmp/bluefin-schema-test/
    cp /usr/share/glib-2.0/schemas/zz1-bluefin-modifications-mutter-exp-feats.gschema.override /tmp/bluefin-schema-test/
    echo "Running error test for bluefin gschema override. Aborting if failed."
    # We should ideally refactor this to handle multiple GNOME version schemas better
    glib-compile-schemas --strict /tmp/bluefin-schema-test
    echo "Compiling gschema to include bluefin setting overrides"
    glib-compile-schemas /usr/share/glib-2.0/schemas &>/dev/null
fi

# Watermark for Plymouth
cp /usr/share/plymouth/themes/spinner/{"$BASE_IMAGE_NAME"-,}watermark.png
