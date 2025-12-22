# vim: set ft=make :

# Install Swift development environment
[group('Developer')]
swift:
    #!/usr/bin/bash
    echo 'Installing Swift development environment...'
    brew bundle --file=/usr/share/ublue-os/homebrew/swift.Brewfile
    echo 'Swift development environment installed!'
    echo 'Run "swiftly install latest" to install the Swift compiler'
