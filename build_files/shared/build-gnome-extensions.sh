#!/usr/bin/bash

set -eoux pipefail

echo "::group:: ===$(basename "$0")==="

# Install tooling
dnf5 -y install glib2-devel meson sassc cmake dbus-devel

# Build Extensions

# AppIndicator Support
glib-compile-schemas --strict /usr/share/gnome-shell/extensions/appindicatorsupport@rgcjonas.gmail.com/schemas

# Bazaar Companion
mv /usr/share/gnome-shell/extensions/tmp/bazaar-integration@kolunmi.github.io/src/ /usr/share/gnome-shell/extensions/bazaar-integration@kolunmi.github.io/

# Blur My Shell
make -C /usr/share/gnome-shell/extensions/blur-my-shell@aunetx
unzip -o /usr/share/gnome-shell/extensions/blur-my-shell@aunetx/build/blur-my-shell@aunetx.shell-extension.zip -d /usr/share/gnome-shell/extensions/blur-my-shell@aunetx
glib-compile-schemas --strict /usr/share/gnome-shell/extensions/blur-my-shell@aunetx/schemas
rm -rf /usr/share/gnome-shell/extensions/blur-my-shell@aunetx/build

# Caffeine
# Caffeine is built/packaged into a temporary subdirectory (tmp/caffeine/caffeine@patapon.info). Its `make build`
# target runs `gnome-extensions pack --podir=locale`, which compiles the extension's .po catalogues into
# locale/<lang>/LC_MESSAGES/<domain>.mo (a bare copy would ship unreadable .po source and gettext would find
# nothing); the zip lands one directory up, so unpack it into the standard extensions directory so GNOME Shell
# can detect it.
make -C /usr/share/gnome-shell/extensions/tmp/caffeine build
unzip -o /usr/share/gnome-shell/extensions/tmp/caffeine/caffeine@patapon.info.zip -d /usr/share/gnome-shell/extensions/caffeine@patapon.info
glib-compile-schemas --strict /usr/share/gnome-shell/extensions/caffeine@patapon.info/schemas

# Dash to Dock
make -C /usr/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com
glib-compile-schemas --strict /usr/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com/schemas

# Gradia Capture
bash /usr/share/gnome-shell/extensions/gradia-integration@alexandervanhee.github.io/build.sh
unzip -o /usr/share/gnome-shell/extensions/gradia-integration@alexandervanhee.github.io/gradia-integration@alexandervanhee.github.io.shell-extension.zip -d /usr/share/gnome-shell/extensions/gradia-integration@alexandervanhee.github.io
rm -f /usr/share/gnome-shell/extensions/gradia-integration@alexandervanhee.github.io/gradia-integration@alexandervanhee.github.io.shell-extension.zip
glib-compile-schemas --strict /usr/share/gnome-shell/extensions/gradia-integration@alexandervanhee.github.io/schemas

# GSConnect (commented out until G49 support)
meson setup --prefix=/usr /usr/share/gnome-shell/extensions/gsconnect@andyholmes.github.io /usr/share/gnome-shell/extensions/gsconnect@andyholmes.github.io/_build
meson install -C /usr/share/gnome-shell/extensions/gsconnect@andyholmes.github.io/_build --skip-subprojects
# GSConnect installs schemas to /usr/share/glib-2.0/schemas and meson compiles them automatically

# Logo Menu
# xdg-terminal-exec is required for this extension as it opens up terminals using that script
install -Dpm0755 -t /usr/bin /usr/share/gnome-shell/extensions/logomenu@aryan_k/distroshelf-helper
install -Dpm0755 -t /usr/bin /usr/share/gnome-shell/extensions/logomenu@aryan_k/missioncenter-helper
glib-compile-schemas --strict /usr/share/gnome-shell/extensions/logomenu@aryan_k/schemas

# Translations
# Several vendored extensions (AppIndicator, Dash to Dock, Logo Menu) ship only .po sources, which gettext cannot read.
# GNOME Shell binds the "gettext-domain" from an extension's metadata.json to <extension>/locale when that directory
# exists, so compile every po/*.po or locale/*.po into locale/<lang>/LC_MESSAGES/<domain>.mo. Extensions without a
# gettext-domain (GSConnect installs its own catalogues to /usr/share/locale) and extensions whose own build already
# compiled them (Blur My Shell, Caffeine) are skipped. One broken catalogue must not fail the image: if msgfmt rejects
# a file (e.g. duplicate entries), retry once after de-duplicating it with msguniq, otherwise skip that language with
# a warning.
for ext in /usr/share/gnome-shell/extensions/*/; do
    ext="${ext%/}"
    [[ -f "${ext}/metadata.json" ]] || continue
    if compgen -G "${ext}/locale/*/LC_MESSAGES/*.mo" >/dev/null; then
        continue
    fi
    domain="$(jq -r '."gettext-domain" // empty' "${ext}/metadata.json")"
    [[ -n "${domain}" ]] || continue
    for po in "${ext}"/po/*.po "${ext}"/locale/*.po; do
        [[ -f "${po}" ]] || continue
        lang="$(basename "${po}" .po)"
        mo="${ext}/locale/${lang}/LC_MESSAGES/${domain}.mo"
        mkdir -p "$(dirname "${mo}")"
        if ! msgfmt -o "${mo}" "${po}" 2>/dev/null; then
            if ! msguniq --use-first "${po}" | msgfmt -o "${mo}" -; then
                echo "::warning::Skipping ${lang} translation for $(basename "${ext}"): msgfmt could not compile ${po}"
                rm -f "${mo}"
            fi
        fi
    done
done

rm /usr/share/glib-2.0/schemas/gschemas.compiled
glib-compile-schemas /usr/share/glib-2.0/schemas

# Cleanup
dnf5 -y remove glib2-devel meson sassc cmake dbus-devel
rm -rf /usr/share/gnome-shell/extensions/tmp

echo "::endgroup::"
