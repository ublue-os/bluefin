#!/usr/bin/fish
if status --is-interactive
    [ -d /home/linuxbrew/.linuxbrew ] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    if systemctl --quiet is-active var-home-linuxbrew.mount
        set -x HOMEBREW_NO_AUTO_UPDATE 1
    end
end