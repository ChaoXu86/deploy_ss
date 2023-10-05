# deploy_ss
Script to install and deploy shadowsocks and v2ray-plugin on ubuntu.

# Usage of script
```
# deploy_ss_ubuntu.sh --help
Deploy and start Shadowsocks server 
 --ip           Server IP Shadowsocks listen, default use first non-loopback IP. 
 --port         Server Port, default 55555 
 --method       Encryption method for traffic, default xchacha20-ietf-poly1305 
 --password     Password for server
 --plugin_opts  Plugin options, only v2ray-plugin is supported
 --help | -h    Print this text
```


# Example
The script is only tested and verified on ubuntu 18 and 22. By default, it will starts shadowsocks services on port 55555 of the first available IPv4 address. It's recommended to deploy the v2ray-plugin along with the server to avoid blocked by GFW. One ssserver service will also be added to system to ensure the proxy server will always running. 

## 1. deploy proxy server default options
NOT recommended! Below command will start everything with default settings.
```
# chomd +x deploy_ss_ubunt.sh
# sudo deploy_ss_ubuntu.sh
```
## 2. deploy proxy server with v2ray-plugin options
Recommended way. Below command will create server with v2ray-plugin. The hostname is "host=" is the DNS name of your host. For AWS server, you could get your host name from the console. IP is the internal backend IP of your server, normally it's the eth0's IP addresses. 
```
# deploy_ss_ubuntu.sh \
--ip 172.31.16.122 \
--port 33333 \
--password bij98324lj \
--plugin_opts "server;host=ec2-3-115-18-88.ap-northeast-1.compute.amazonaws.com"
```

# Client
## resources
* Windows https://github.com/shadowsocks/shadowsocks-windows/releases
* Android https://github.com/shadowsocks/shadowsocks-android/releases
* v2ray-plugin https://github.com/shadowsocks/v2ray-plugin/releases
## configuration
After successfully deployed on server, the script will show the configuration on server. Make sure set the same value on client 
* server_port
* password
* method
* plugin
* plugin_opts

NOTE: On client configuration, the server IP is the float IP you get from AWS. Not the internal eth0's IP of the server!
