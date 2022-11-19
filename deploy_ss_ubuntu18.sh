#!/bin/bash
# DEFAULT VALUES
ip=""
port="55555"
method="aes-256-gcm"
password=`tr -dc '_A-Za-z0-9' </dev/urandom | head -c 16`
plugin_opts=""
config_file="/etc/shadowsocks.json"
baseurl="https://github.com"
plugin_install_path="/usr/local/bin/v2ray-plugin"
ssserver_service_file="/etc/systemd/system/ssserver.service"

[[ "$1" == "-debug" ]] && set -x && shift

self="$(basename "$0")"

function usage() {
    cat <<EOI
$self [--ip IP] [--port PORT] [--method METHOD] [--plugin_opts OPTIONS] [--password PASSWORD] 

Deploy and start Shadowsocks server 
 --ip           Server IP Shadowsocks listen, default use first non-loopback IP
 --port         Server Port, default 55555 
 --method       Encryption method for traffic, default aes-256-gcm 
 --password     Password for server
 --plugin_opts  Plugin options, only v2ray-plugin is supported
 --help | -h    Print this text

Example:
  1. deploy proxy server with v2ray plugin  
    # deploy.sh --plugin_opts "server;host=ec2-3-115-18-45.ap-northeast-1.compute.amazonaws.com"
  2. deploy proxy server with ip 192.168.0.1 and port 12321
    # deploy.sh --ip 192.168.0.1 --port 12321
EOI
}

function root_check() {
    if [[ $EUID -ne 0 ]]; then
        echo "Error:This script must be run as root!" 1>&2
        exit 1
    fi
}

function die() {
    local exit_code=0
    [[ -n "$1" ]] && exit_code="$1" && shift
    [[ $# -gt 0 ]] && echo "$self: $*" 1>&2
    exit "$exit_code"
}

function download_shadowsock() {
    echo "
========== 1. Downloading ShadowSocks ==========
"
    apt update
    apt -y install shadowsocks-libev 
}

function download_v2ray() {
    echo "
========== 2. Downloading v2ray       ==========
" 
    v2raylink=`curl -o - $baseurl/shadowsocks/v2ray-plugin/releases |grep "linux-amd64" |grep "a href" |grep -o '".*"' |awk '{print $1}'|sed -e s/\"//g`
    mkdir ./tmp_download
    wget $baseurl$v2raylink -P ./tmp_download/
    sleep 1
    tar zxvf ./tmp_download/*.tar.gz
    rm -rf ./tmp_download
    mv v2ray-plugin* $plugin_install_path
    v2ray-plugin --version 
}

function generate_config() {
echo "
========== 3. Auto configuration      ==========
"
    if [[ $ip == "" ]];
    then
	ip=`ip addr show |grep "inet " |grep -v 127.0.0. |head -n 1 |awk '{print $2}' |awk -F\/ '{print $1}'`
    fi
    
    if [[ $plugin_opts == "" ]];
    then
	plugin=""
    else
    plugin="v2ray-plugin"
    fi
    echo '{
    "server":"'$ip'",
    "server_port":'$port',
    "local_address": "127.0.0.1",
    "local_port":1080,
    "password":"'$password'",
    "timeout":300,
    "method":"'$method'",
    "fast_open": false,
    "plugin":"'$plugin'",
    "plugin_opts":"'$plugin_opts'"
}' > $config_file
    echo $config_file
}

function start_ssserver() {
echo "
========== 4. Activate Services       ==========
"
    echo '[Unit]
Description=ShadowSock Server
After=network.target
StartLimitIntervalSec=0
[Service]
Type=simple
Restart=always
RestartSec=1
User=root
ExecStart=/usr/bin/ss-server -c '$config_file'
[Install]
WantedBy=multi-user.target
'>  $ssserver_service_file
    systemctl daemon-reload
    sleep 1
    service ssserver stop
    sleep 1
    service ssserver start
    sleep 1
    service ssserver status
}

function post_check() {
    echo "
========== 5. PostCheck               ==========
"
    if [ `netstat -anp |grep $port | grep tcp |grep -i listen | wc -l` -eq 0 ];
    then
        die 1 "No process listening on $port"
    fi
    echo "All good!"
}

function finish() {
    echo "
All Done! Make sure your client configure server's
"
    cat $config_file
}

############ MAIN ############

# Handle options
args=()
while (( $# > 0 )); do
    case "$1" in
	("--ip")
	    ip="$2"
	    shift 2
	    ;;
        ("--port")
            port="$2"
            shift 2
            ;;
        ("--method")
            method="$2"
            shift 2
            ;;
        ("--password")
            password="$2"
            shift 2
            ;;
	("--plugin_opts")
	    plugin_opts="$2"
	    shift 2
	    ;;
        ("-h"|"--help")
            usage
            die 0
            ;;
        --)
            shift
            args+=( "$@" )
            break
            ;;
        -*)
            usage
            die 1 "Invalid option: $1"
            ;;
        *)
            args+=( "$1" )
            shift
            ;;
    esac
done

root_check
download_shadowsock
download_v2ray
generate_config
start_ssserver
post_check
finish
