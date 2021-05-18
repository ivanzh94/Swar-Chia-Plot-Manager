#!/bin/bash

# Get version
function GetVersion(){
    if [[ -s /etc/redhat-release ]];then
        grep -oE  "[0-9.]+" /etc/redhat-release
    else
        grep -oE  "[0-9.]+" /etc/issue
    fi
}

# CentOS version
function CentosVersion(){
    local code=$1
    local version="`GetVersion`"
    local main_ver=${version%%.*}
    if [ $main_ver == $code ];then
        return 0
    else
        return 1
    fi
}

check_sys(){
    local checkType=$1
    local value=$2

    local release=''
    local systemPackage=''

    if [[ -f /etc/redhat-release ]]; then
        release='centos'
        systemPackage='yum'
    elif grep -Eqi 'debian|raspbian' /etc/issue; then
        release='debian'
        systemPackage='apt'
    elif grep -Eqi 'ubuntu' /etc/issue; then
        release='ubuntu'
        systemPackage='apt'
    elif grep -Eqi 'centos|red hat|redhat' /etc/issue; then
        release='centos'
        systemPackage='yum'
    elif grep -Eqi 'debian|raspbian' /proc/version; then
        release='debian'
        systemPackage='apt'
    elif grep -Eqi 'ubuntu' /proc/version; then
        release='ubuntu'
        systemPackage='apt'
    elif grep -Eqi 'centos|red hat|redhat' /proc/version; then
        release='centos'
        systemPackage='yum'
    fi

    if [[ "${checkType}" == 'sysRelease' ]]; then
        if [ "${value}" == "${release}" ]; then
            return 0
        else
            return 1
        fi
    elif [[ "${checkType}" == 'packageManager' ]]; then
        if [ "${value}" == "${systemPackage}" ]; then
            return 0
        else
            return 1
        fi
    fi
}

install_check(){
    if check_sys packageManager yum || check_sys packageManager apt; then
        if centosversion 5; then
            return 1
        elif centosversion 6; then
            return 1
        fi
        return 0
    else
        return 1
    fi
}

install_dependencies(){
    if ! install_check; then
        echo -e "[${red}Error${plain}] Your OS is not supported to run it!"
        echo 'Please change to CentOS 7+/Ubuntu 16+ and try again.'
        exit 1
    fi

    clear
    if check_sys packageManager yum;then
        if CentosVersion 8;then
            yum -y install python38 git
            ln -s /usr/bin/python3.8 /usr/bin/python3
        else
            yum -y install python3 git
        fi

    elif check_sys packageManager apt;then
        apt-get install python3.8 git
        ln -s /usr/bin/python3.8 /usr/bin/python3
    fi
    PythonBin="/usr/bin/python3"
}

install_chia_block(){
    echo "Starting install chia-blockchain"
    git submodule update --init chia-blockchain
    cd chia-blockchain
    /bin/bash install.sh
    source ./activate
    chia init
    deactivate
    cd ..
    echo "done."
}


install_swar(){
    echo "Starting install swar"
    $PythonBin -m venv venv
    ln -s venv/bin/activate .
    source ./activate
    pip install -r requirements.txt
    deactivate
    echo "done."
}

install_dependencies
install_chia_block
install_swar
