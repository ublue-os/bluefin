#!/usr/bin/fish
#shellcheck disable=all
if status --is-interactive
    if [ -d /home/linuxbrew/.linuxbrew ]
        if [ -w /home/linuxbrew/.linuxbrew ]
            if  [ ! -L /home/linuxbrew/.linuxbrew/share/fish/vendor_completions.d/brew]
                /home/linuxbrew/.linuxbrew/bin/brew completions link > /dev/null
            end
        end
        set -p fish_complete_path /home/linuxbrew/.linuxbrew/share/fish/vendor_completions.d
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    end
    if systemctl --quiet is-active var-home-linuxbrew.mount
        set -gx HOMEBREW_NO_AUTO_UPDATE 1
    end
end
