#!/usr/bin/env bash

shopt -s extglob
set -Eeo pipefail

# Set global variables
DEBUG=${DEBUG:-false}
ACTION=${ACTION:-}
WORKDIR=${WORKDIR:-}
LANG=${LANG:-}
TIMEZONE=${TIMEZONE:-}
NODE_VERSION=${NODE_VERSION:-}
GOSU_VERSION=${GOSU_VERSION:-}
PYTHON_VERSION=${PYTHON_VERSION:-}
BARGS=""

function _exit_trap() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        echo "Error: Process exited with status code: $exit_code"
    fi
    unset BUILDKIT_PROGRESS
    set -x
    exit $exit_code
}

trap _exit_trap EXIT SIGINT SIGTERM ERR

function __run() {
    echo "Running command: $*"
    eval "$*" || {
        echo "Process exited with status code: $?"
        exit $?
    }
}

function usage() {
    echo "Deity Build System"
    echo ""
    echo "Usage: $0 [action] [options] [args]"
    echo ""
    echo "  Actions:"
    echo ""
    echo "    init:   Initialize the winebuilder container"
    echo "    shell:  Start a shell in the winebuilder container"
    echo "    build:  Start the build process in the winebuilder container"
    echo "    wine32: Run wine32 in the container"
    echo "    wine64: Run wine64 in the container"
    echo "    wineshell: Run wine-tkg-interactive in the container"
    echo ""
    echo "  Options:"
    echo "    -w, --workdir:  The working directory to mount in the container"
    echo "    -h, --help:     Show this help message"
    echo "    -d, --debug:    Enable debug mode (prints a lot of spam used for debugging purposes"
    echo "                    use with caution)"
    echo ""
    echo "  Extra Build Image Features (only for init action):"
    echo ""
    echo "    -l, --language:         The locale language"
    echo "    -t, --timezone:         The timezone"
    echo "    -n, --node-version:     The node version to use"
    echo "    -g, --gosu-version:     The gosu version to use"
    echo "    -p, --python-version:   The python version (using pyenv)"
    echo ""
    echo "  Additional Arguments [args]:"
    echo ""
    echo "    Any additional arguments will be passed to the action command's wine-tkg script"
    exit 1
}

function parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                usage
                break
                ;;
            shell|build|init|wine32|wine64|wineshell)
                ACTION=$1
                shift
                ;;
            -w|--workdir)
                WORKDIR=$2
                shift 2
                ;;
            -l|--language)
                LANG=$2
                shift 2
                ;;
            -t|--timezone)
                TIMEZONE=$2
                shift 2
                ;;
            -n|--node-version)
                NODE_VERSION=$2
                shift 2
                ;;
            -g|--gosu-version)
                GOSU_VERSION=$2
                shift 2
                ;;
            -p|--python-version)
                PYTHON_VERSION=$2
                shift 2
                ;;
            -d|--debug)
                DEBUG=true
                shift
                ;;
            *)
                BARGS+=( "$1" )
                shift
                ;;
        esac
    done
    if [ -z "$ACTION" ] || [ -z "$WORKDIR" ]; then
        echo "Missing required arguments: <action>, -w|--workdir"
        echo ""
        usage
    fi
}

function __build_arg() {
    local ARG_NAME="$1"
    local ARG_VALUE="$2"
    if [ -n "$ARG_VALUE" ]; then
        echo "--build-arg ${ARG_NAME}=${ARG_VALUE}"
    fi
}

function __build_args() {
    local ARGS=()
    ARGS+=("$(__build_arg APP_USER ${USER})")
    ARGS+=("$(__build_arg APP_DIR /app)")
    ARGS+=("$(__build_arg LANG ${LANG})")
    ARGS+=("$(__build_arg TZ ${TIMEZONE})")
    ARGS+=("$(__build_arg NODE_VERSION ${NODE_VERSION})")
    ARGS+=("$(__build_arg GOSU_VERSION ${GOSU_VERSION})")
    ARGS+=("$(__build_arg PYTHON_VERSION ${PYTHON_VERSION})")
    echo "${ARGS[@]}"
}

function main() {
    if [ "$DEBUG" = true ]; then
        export BUILDKIT_PROGRESS=plain
    fi
    case $ACTION in
        init)
            docker system prune --force
            docker image build                                      \
                $(__build_args)                                     \
                --file Dockerfile                                   \
                --tag winebuilder:latest .
            ;;
        shell)
            docker container run                                    \
                --volume ${WORKDIR}:/app                            \
                --user $(id -u ${APP_USER}):$(id -g ${APP_USER})    \
                --rm -it --name wine_builder winebuilder:latest     \
                shell ${BARGS[@]}
            ;;
        build)
            docker container run                                    \
                --volume ${WORKDIR}:/app                            \
                --user $(id -u ${APP_USER}):$(id -g ${APP_USER})    \
                --rm -it --name wine_builder winebuilder:latest     \
                build ${BARGS[@]}
            ;;
        wine32)
            docker container run                                    \
                --volume ${WORKDIR}:/app                            \
                --user $(id -u ${APP_USER}):$(id -g ${APP_USER})    \
                --rm -it --name wine_builder winebuilder:latest     \
                wine32 ${BARGS[@]}
            ;;
        wine64)
            docker container run                                    \
                --volume ${WORKDIR}:/app                            \
                --user $(id -u ${APP_USER}):$(id -g ${APP_USER})    \
                --rm -it --name wine_builder winebuilder:latest     \
                wine64 ${BARGS[@]}
            ;;
        wineshell)
            docker container run                                    \
                --volume ${WORKDIR}:/app                            \
                --user $(id -u ${APP_USER}):$(id -g ${APP_USER})    \
                --rm -it --name wine_builder winebuilder:latest     \
                wineshell ${BARGS[@]}
            ;;
        *)
            echo "Unknown action: $ACTION"
            exit 1
            ;;
    esac
}

parse_args "$@"
main 