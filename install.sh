#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain} 必须使用root用户运行此脚本！\n" && exit 1

# 你的仓库
REPO_URL="https://raw.githubusercontent.com/fyue-dotcom/v2node-stable/main"
PACKAGE_FILE="v2node-1.7-linux-amd64.tar.gz"

########################
# 参数解析
########################
API_HOST_ARG=""
NODE_ID_ARG=""
API_KEY_ARG=""

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --api-host)
                API_HOST_ARG="$2"; shift 2 ;;
            --node-id)
                NODE_ID_ARG="$2"; shift 2 ;;
            --api-key)
                API_KEY_ARG="$2"; shift 2 ;;
            *)
                shift ;;
        esac
    done
}

install_base() {
    echo -e "${green}安装依赖...${plain}"
    if command -v apt >/dev/null 2>&1; then
        apt update -y
        apt install -y wget curl tar unzip socat ca-certificates
    elif command -v yum >/dev/null 2>&1; then
        yum install -y wget curl tar unzip socat ca-certificates
    elif command -v apk >/dev/null 2>&1; then
        apk add wget curl tar unzip socat ca-certificates
    fi
}

generate_v2node_config() {
    mkdir -p /etc/v2node >/dev/null 2>&1

    cat >/etc/v2node/config.json <<EOF
{
    "Log": {
        "Level": "warning",
        "Output": "",
        "Access": "none"
    },
    "Nodes": [
        {
            "ApiHost": "${API_HOST_ARG}",
            "NodeID": ${NODE_ID_ARG},
            "ApiKey": "${API_KEY_ARG}",
            "Timeout": 30
        }
    ]
}
EOF
}

install_v2node() {

    echo -e "${green}>>> 清理旧安装...${plain}"
    rm -rf /usr/local/v2node
    mkdir -p /usr/local/v2node
    cd /usr/local/v2node

    echo -e "${green}>>> 下载 v2node 1.7 稳定版${plain}"
    wget -O v2node.tar.gz "${REPO_URL}/${PACKAGE_FILE}"
    if [[ $? -ne 0 ]]; then
        echo -e "${red}下载失败，请检查仓库是否存在：${PACKAGE_FILE}${plain}"
        exit 1
    fi

    tar -xzvf v2node.tar.gz
    rm -f v2node.tar.gz
    chmod +x v2node

    mkdir -p /etc/v2node
    cp geoip.dat /etc/v2node/
    cp geosite.dat /etc/v2node/

cat >/etc/systemd/system/v2node.service <<EOF
[Unit]
Description=v2node Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/v2node/v2node server
WorkingDirectory=/usr/local/v2node/
Restart=always
RestartSec=10
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable v2node
}

# ------- 主流程 -------

parse_args "$@"

if [[ -z "$API_HOST_ARG" || -z "$NODE_ID_ARG" || -z "$API_KEY_ARG" ]]; then
    echo -e "${red}错误：缺少必要参数！${plain}"
    echo "正确示例："
    echo "bash install.sh --api-host https://xxx --node-id 1 --api-key abc123"
    exit 1
fi

install_base
install_v2node
generate_v2node_config

echo -e "${green}>>> 启动服务${plain}"
systemctl restart v2node
sleep 2
systemctl status v2node --no-pager

echo -e "${green}安装完成！${plain}"
echo "查看日志：journalctl -u v2node -f"
echo "查看版本：v2node version"

