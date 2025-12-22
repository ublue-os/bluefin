# vim: set ft=make :

# Install Swift development environment
[group('Developer')]
swift:
    #!/usr/bin/bash
    echo 'Installing Swift development environment...'
    if brew bundle --file=/usr/share/ublue-os/homebrew/swift.Brewfile; then
        echo 'Swift development environment installed!'
        echo 'Run "swiftly install latest" to install the Swift compiler'
    else
        echo 'Failed to install Swift development environment. Please check the output above for details.' >&2
        exit 1
    fi
