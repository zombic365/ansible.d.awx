#!/bin/bash

# doc
# https://docs.docker.com/engine/install/ubuntu/

SCRIPT_DIR=$(dirname $(realpath $0))

for _FILE in $(ls ${SCRIPT_DIR}/lib); do
    source ${SCRIPT_DIR}/lib/${_FILE}
done

function help_usage() {
    cat <<EOF
Usage: $0 [Options]
Options:
-i, --install   : Install docker
-r, --remove    : Remove docker
EOF
    exit 0
}

function set_opts() {
    arguments=$(getopt --options irh \
    --longoptions install,remove,help \
    --name $(basename $0) \
    -- "$@")

    eval set -- "${arguments}"

    while true; do
        case "$1" in
            -i | --install ) MODE="install" ; shift   ;;
            -r | --remove )  MODE="remove"  ; shift   ;;
            -h | --help ) help_usage                  ;;
            --) shift ; break                         ;;
            *) help_usage                             ;;
        esac
    done

    shift $((OPTIND-1))
}


function uninstall_docker() {
    for _pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
        remove_pkg "${_pkg}"
        if [ $? -eq 1 ]; then
            exit 1
        fi
    done
}

function install_docker_pre() {
    check_pkg "ca-certificates" "curl"
    if [ $? -eq 0 ]; then
        _cmd_list=(
            "install -m 0755 -d /etc/apt/keyrings"
            "curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc"
            "chmod a+r /etc/apt/keyrings/docker.asc"
        )
        for ((_idx=0 ; _idx < ${#_cmd_list[@]} ; _idx++)); do
            run_cmd "${_cmd_list[${_idx}]}"
            if [ $? -eq 0 ]; then
                continue
            else
                exit 1
            fi
        done
    else
        exit 1
    fi

    if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
        run_cmd "cat <<EOF >/etc/apt/sources.list.d/docker.list
deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable
EOF"
    else
        exit 1
    fi

    run_cmd "apt-get update"
    if [ $? -eq 0 ]; then
        return 0
    else
        exit 1
    fi
}

function install_docker() {
    check_pkg "docker-ce" "docker-ce-cli" "containerd.io" "docker-buildx-plugin" "docker-compose-plugin"
    if [ $? -eq 0 ]; then
        enable_svc "docker"
        if [ $? -eq 0 ]; then
            return 0
        else
            exit 1
        fi
    else
        exit 1
    fi
}

main() {
    [ $# -eq 0 ] && help_usage
    set_opts "$@"

    if [ ${MODE} == "install" ]; then
        install_docker_pre
        if [ $? -eq 0 ]; then
            install_docker
        fi

    elif [ ${MODE} == "renmove" ]; then
        remove_docker
    else
        log_msg "ERROR" "Bug abort."
        exit 1
    fi
}
main $*