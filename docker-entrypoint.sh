#!/bin/bash

function build_tkglitch_wine() {
    if [ ! -d $(pwd)/src ]; then
        git clone https://github.com/loopyd/wine-tkg-git.git $(pwd)/src
    fi
    if [ -f $(pwd)/wine-tkg.cfg ]; then
        rm -f $(pwd)/src/wine-tkg-git/customization.cfg
        ln -s $(pwd)/wine-tkg.cfg $(pwd)/src/wine-tkg-git/customization.cfg
    fi
    echo "DONE!"
    cd $(pwd)/src/wine-tkg-git
    ./non-makepkg-build.sh
    cd ../..
}

if [ $(id -u) -eq 0 ]; then
    echo "This script must not be run as root"
    exit 1
fi

if [ -z "$1" ]; then
    echo "No action specified"
    exit 1
fi

if [ $1 = "shell" ]; then    
    echo "Starting Bash Shell"
    /bin/bash
elif [ $1 = "build" ]; then
    echo "Performing Build"
    build_tkglitch_wine
fi