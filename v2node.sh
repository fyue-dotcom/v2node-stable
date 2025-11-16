#!/bin/bash

case "$1" in
    start)
        systemctl start v2node
        ;;
    stop)
        systemctl stop v2node
        ;;
    restart)
        systemctl restart v2node
        ;;
    status)
        systemctl status v2node --no-pager
        ;;
    log)
        journalctl -u v2node -f
        ;;
    enable)
        systemctl enable v2node
        ;;
    disable)
        systemctl disable v2node
        ;;
    version)
        /usr/local/v2node/v2node version
        ;;
    generate)
        echo "生成配置：/etc/v2node/config.json"
cat >/etc/v2node/config.json <<EOF
{
    "Log": {
        "Level": "warning",
        "Output": "",
        "Access": "none"
    },
    "Nodes": [
        {
            "ApiHost": "",
            "NodeID": 1,
            "ApiKey": "",
            "Timeout": 30
        }
    ]
}
EOF
        systemctl restart v2node
        ;;
    *)
        echo "v2node 使用帮助："
        echo "--------------------------------"
        echo "v2node start        - 启动 v2node"
        echo "v2node stop         - 停止 v2node"
        echo "v2node restart      - 重启 v2node"
        echo "v2node status       - 查看状态"
        echo "v2node enable       - 开机自启"
        echo "v2node disable      - 取消开机自启"
        echo "v2node log          - 查看日志"
        echo "v2node version      - 查看版本"
        echo "v2node generate     - 生成配置"
        echo "--------------------------------"
        ;;
esac
