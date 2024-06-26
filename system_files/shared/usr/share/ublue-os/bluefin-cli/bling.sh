#!/usr/bin/env sh

# ls aliases
alias ll='eza -l --icons=auto --group-directories-first'
alias l.='eza -d .*'
alias ls='eza'
alias l1='eza -1'

# ugrep for grep
alias grep='ug'
alias egrep='ug -E'
alias fgrep='ug -F'
alias xzgrep='ug -z'
alias xzegrep='ug -zE'
alias xzfgrep='ug -zF'

if [ "$(basename "$SHELL")" = "bash" ]; then
    #shellcheck disable=SC1091
    . /usr/share/bash-prexec
    eval "$(atuin init bash)"
    eval "$(zoxide init bash)"
elif [ "$(basename "$SHELL")" = "zsh" ]; then
    eval "$(atuin init zsh)"
    eval "$(zoxide init zsh)"
fi
