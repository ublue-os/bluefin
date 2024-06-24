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

if status is-interactive
    eval "$(atuin init fish)"
    eval "$(zoxide init fish)"
end
