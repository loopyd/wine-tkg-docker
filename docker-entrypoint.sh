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

build_wine() {
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
    local ARCH="$1"
    if [ "$ARCH" != "32" ] && [ "$ARCH" != "64" ] && [ "$ARCH" != "interactive" ] && [ -z "$ARCH" ]; then
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

usage() {
    local MYACTION="$1"
    echo "wine-tkg-docker - A Docker container for building and running wine-tkg"
    echo ""
    echo "Usage: $0 [action] [args]"
    echo ""
    if [ -z "$MYACTION" ]; then
        echo "  Actions:"
        echo ""
        echo "    shell:  Start a /bin/bash shell"
        echo "    build:  Start the build process"
        echo "    wine32: Run wine-tkg 32-bit"
        echo "    wine64: Run wine-tkg 64-bit"
        echo "    wineshell: Run wine-tkg-interactive"
        echo ""
    fi
    if [ "$MYACTION" == "shell" ]; then
        echo "  Options (using shell action):"
        echo ""
        echo "    [command]: Command to run in the shell"
        echo ""
    fi
    if [ "$MYACTION" == "build" ]; then
        echo "  Optiions (using build action):"
        echo ""
        echo "    [args]: Arguments to pass to the build script"
        echo ""
    fi
    if [ "$MYACTION" == "wine32" ] || [ "$MYACTION" == "wine64" ] || [ "$MYACTION" == "wineshell" ]; then
        echo "  Options (using $MYACTION action):"
        echo ""
        echo "    [args]: Arguments to pass to wine-tkg or wine-tkg-interactive"
        echo ""
    fi
    exit 1
}

parse_args() {
    if [[ ! "$1" =~ ^shell|build|wine32|wine64|wineshell|$ ]]; then
        echo "Unknown action: $1"
        usage
    else 
        ACTION=$1
        shift 1
    fi
    case "$ACTION" in
        shell)
            while [ $# -gt 0 ]; do
                case "$1" in
                    -h|--help)
                        usage shell
                        ;;
                    *)
                        BARGS+=("$1")
                        ;;
                esac
                shift 1
            done
            ;;
        build)
            while [ $# -gt 0 ]; do
                case "$1" in
                    -h|--help)
                        usage build
                        ;;
                    *)
                        BARGS+=("$1")
                        ;;
                esac
                shift 1
            done
            ;;
        wine32)
            while [ $# -gt 0 ]; do
                case "$1" in
                    -h|--help)
                        usage wine32
                        ;;
                    *)
                        BARGS+=("$1")
                        ;;
                esac
                shift 1
            done
            ;;
        wine64)
            while [ $# -gt 0 ]; do
                case "$1" in
                    -h|--help)
                        usage wine64
                        ;;
                    *)
                        BARGS+=("$1")
                        ;;
                esac
                shift 1
            done
            ;;
        wineshell)
            while [ $# -gt 0 ]; do
                case "$1" in
                    -h|--help)
                        usage wineshell
                        ;;
                    *)
                        BARGS+=("$1")
                        ;;
                esac
                shift 1
            done
            ;;
        *)
            usage
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
            build_wine "${BARGS[@]}"
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
