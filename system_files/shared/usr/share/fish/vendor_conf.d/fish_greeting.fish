function fish_greeting
    if test ! -e $HOME/.config/no-show-user-motd
        ublue-motd
    end
end
