#!/bin/bash

echo "⚠️ 正在卸载 DDNS 脚本..."

# 删除已安装脚本
sudo rm -f /usr/local/bin/ddns

# 删除配置文件
sudo rm -rf /etc/ddns/config.conf

# 删除 IP 缓存
sudo rm -rf /var/lib/ddns/last_ip

# 移除 crontab 中的任务（如果有）
crontab -l | grep -v "/usr/local/bin/ddns" | crontab -

echo "✅ 卸载完成。DDNS 已从系统中移除。"
