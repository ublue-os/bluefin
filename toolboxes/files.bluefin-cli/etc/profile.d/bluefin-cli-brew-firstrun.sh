if test "$(id -u)" -gt "0" && test ! -f /home/linuxbrew/.firstrun && test -d /home/linuxbrew/.linuxbrew/Cellar; then
  touch /home/linuxbrew/.firstrun
  if test -n "$(ls -A /home/linuxbrew/.linuxbrew/Cellar)"; then
    echo "Relinking Homebrew Cellar"
    /home/linuxbrew/.linuxbrew/bin/brew list -1 | while read line
    do
      /home/linuxbrew/.linuxbrew/bin/brew unlink $line
      /home/linuxbrew/.linuxbrew/bin/brew link $line
    done
    echo "Reinstalling explicictly installed Homebrew packages"
    /home/linuxbrew/.linuxbrew/bin/brew leaves | while read line
    do
      /home/linuxbrew/.linuxbrew/bin/brew reinstall $line
    done
  fi
fi