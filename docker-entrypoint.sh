#!/bin/bash

BARGS=()
ACTION=""

_exit_trap() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        echo "Error: Script exited with status code: $exit_code"
    fi
    exit $exit_code
}
trap _exit_trap EXIT SIGINT SIGTERM ERR

build_tkglitch_wine() {
    local ARGS=( $@ )
    if [ ! -d $(pwd)/src ]; then
        git clone https://github.com/loopyd/wine-tkg-git.git $(pwd)/src
    fi
    if [ -f $(pwd)/wine-tkg.cfg ]; then
        rm -f $(pwd)/src/wine-tkg-git/customization.cfg
        ln -s $(pwd)/wine-tkg.cfg $(pwd)/src/wine-tkg-git/customization.cfg
    fi
    cd $(pwd)/src/wine-tkg-git
    if [ "${#ARGS[@]}" -ne 0 ]; then
        ./non-makepkg-build.sh ${ARGS[@]}
        return $?
    else
        ./non-makepkg-build.sh
        return $?
    fi
    cd ../..
    return 0
}

run_wine() {
    local ARCH=$1
    if [ "$ARCH" != "32" ] && [ "$ARCH" != "64" ] || [ -z "$ARCH" ] || [ "$ARCH" != "interactive" ]; then
        echo "Error: Invalid architecture. Please specify either 32 or 64."
        return 0
    fi
    shift 1
    local ARGS=( $* )
    if [ ! -d $(pwd)/src ]; then
        echo "Error: wine-tkg-git not found. Please run the build action first."
        exit 1
    fi
    cd $(pwd)/src/wine-tkg-git
    case "$ARCH" in
        32)
            if [ "${#ARGS[@]}" -ne 0 ]; then
                ./wine-tkg-scripts/wine-tkg ${ARGS[@]}
            else
                ./wine-tkg-scripts/wine-tkg
            fi
            ;;
        64)
            if [ "${#ARGS[@]}" -ne 0 ]; then
                ./wine-tkg-scripts/wine64-tkg ${ARGS[@]}
            else
                ./wine-tkg-scripts/wine64-tkg
            fi
            ;;
        interactive)
            if [ "${#ARGS[@]}" -ne 0 ]; then
                ./wine-tkg-scripts/wine-tkg-interactive ${ARGS[@]}
            else
                ./wine-tkg-scripts/wine-tkg-interactive
            fi
            ;;
    esac
}

parse_args() {
    local ARGS=( $@ )
    case "${ARGS[0]}" in
        -h|--help)
            echo "Usage: $0 [action] [args]"
            echo ""
            echo "  Actions:"
            echo ""
            echo "    shell:  Start a /bin/bash shell"
            echo "    build:  Start the build process"
            echo "    wine32: Run wine-tkg 32-bit"
            echo "    wine64: Run wine-tkg 64-bit"
            echo "    wineshell: Run wine-tkg-interactive"
            echo ""
            echo "  Additional Arguments [args]:"
            echo ""
            echo "    Any additional arguments will be passed to the action command's wine-tkg script"
            exit 1
            ;;
        shell)
            BARGS=( ${ARGS[@]:1} )
            echo "Starting Bash Shell"
            ACTION=shell
            ;;
        build)
            BARGS=( ${ARGS[@]:1} )
            echo "Performing Build"
            ACTION=build
            ;;
        wine32)
            BARGS=( ${ARGS[@]:1} )
            echo "Running wine32"
            ACTION=wine32
            ;;
        wine64)
            BARGS=( ${ARGS[@]:1} )
            echo "Running wine64"
            ACTION=wine64
            ;;
        wineshell)
            BARGS=( ${ARGS[@]:1} )
            echo "Running wine-tkg-interactive"
            ACTION=wineshell
            ;;
    esac
}

main() {
    case "$ACTION" in
        shell)
            if [ -z "$BARGS" ]; then
                /bin/bash
            else
                /bin/bash -c "${BARGS[@]}"
            fi
            ;;
        build)
            build_tkglitch_wine "${BARGS[@]}"
            ;;
        wine32)
            run_wine "32" "${BARGS[@]}"
            ;;
        wine64)
            run_wine "64" "${BARGS[@]}"
            ;;
        wineshell)
            run_wine "interactive" "${BARGS[@]}"
            ;;
    esac
}

parse_args "$@"
main
