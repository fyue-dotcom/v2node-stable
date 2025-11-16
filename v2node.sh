#!/bin/bash

SERVICE="v2node"
INSTALL_DIR="/usr/local/v2node"
CONFIG_FILE="/etc/v2node/config.json"

green='\033[0;32m'
red='\033[0;31m'
plain='\033[0m'

menu() {
    echo -e "${green}v2node 管理菜单${plain}"
    echo "---------------------------"
    echo "1) 启动"
    echo "2) 停止"
    echo "3) 重启"
    echo "4) 查看状态"
    echo "5) 日志"
    echo "6) 开机自启"
    echo "7) 禁用开机自启"
    echo "8) 版本"
    echo "9) 编辑配置"
    echo "10) 重新生成配置"
    echo "11) 卸载 v2node"
    echo "---------------------------"
    read -rp "选择操作：" num

    case "$num" in
        1) v2_start ;;
        2) v2_stop ;;
        3) v2_restart ;;
        4) v2_status ;;
        5) v2_log ;;
        6) v2_enable ;;
        7) v2_disable ;;
        8) v2_version ;;
        9) v2_edit_config ;;
        10) v2_generate ;;
        11) v2_uninstall ;;
        *) echo "无效选项" ;;
    esac
}

v2_start() { systemctl start $SERVICE; echo -e "${green}已启动${plain}"; }
v2_stop() { systemctl stop $SERVICE; echo -e "${green}已停止${plain}"; }
v2_restart() { systemctl restart $SERVICE; echo -e "${green}已重启${plain}"; }
v2_status() { systemctl status $SERVICE --no-pager; }
v2_log() { journalctl -u $SERVICE -f; }
v2_enable() { systemctl enable $SERVICE; echo "已设置开机自启"; }
v2_disable() { systemctl disable $SERVICE; echo "已取消开机自启"; }
v2_version() { $INSTALL_DIR/v2node version; }

v2_edit_config() {
    nano $CONFIG_FILE
    echo -e "${green}编辑完成，如需生效： v2node restart${plain}"
}

v2_generate() {
cat >$CONFIG_FILE <<EOF
{
    "Log": { "Level": "warning", "Output": "", "Access": "none" },
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
    echo -e "${green}已生成默认配置${plain}"
    systemctl restart $SERVICE
}

v2_uninstall() {
    echo -e "${red}确认卸载？ (y/N)${plain}"
    read -r ans
    [[ "$ans" != "y" && "$ans" != "Y" ]] && exit 0

    systemctl stop $SERVICE
    systemctl disable $SERVICE
    rm -f /etc/systemd/system/v2node.service
    rm -rf $INSTALL_DIR
    rm -f $CONFIG_FILE
    rm -f /usr/bin/v2node
    systemctl daemon-reload

    echo -e "${green}v2node 已卸载${plain}"
}

# 无参数 → 显示菜单
if [[ $# -eq 0 ]]; then
    menu
else
    case "$1" in
        start) v2_start ;;
        stop) v2_stop ;;
        restart) v2_restart ;;
        status) v2_status ;;
        log) v2_log ;;
        enable) v2_enable ;;
        disable) v2_disable ;;
        version) v2_version ;;
        config) v2_edit_config ;;
        generate) v2_generate ;;
        uninstall) v2_uninstall ;;
        *) menu ;;
    esac
fi
