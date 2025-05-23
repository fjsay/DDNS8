#!/bin/bash

echo "🚀 正在安装 DDNS 脚本..."

INSTALL_DIR="/etc/ddns"
BIN_FILE="/usr/local/bin/ddns"
CACHE_DIR="/var/lib/ddns"
CRON_LINE="* * * * * /usr/local/bin/ddns >> /var/log/ddns.log 2>&1"
CONFIG_FILE="$INSTALL_DIR/config.conf"

# 创建目录
sudo mkdir -p "$INSTALL_DIR" "$CACHE_DIR"
sudo chmod 777 "$CACHE_DIR"  # 确保缓存目录可写

# 安装主脚本
sudo cp ddns.sh "$BIN_FILE"
sudo chmod +x "$BIN_FILE"

# 检查配置文件是否存在，不存在则创建
if [ ! -f "$CONFIG_FILE" ]; then
    echo "🛠️ 开始配置 DDNS..."
    
    # 获取用户输入
    read -p "请输入您的域名 (例如: example.com): " DOMAIN
    read -p "请输入您的 API 令牌: " TOKEN
    
    # 验证输入
    if [ -z "$DOMAIN" ] || [ -z "$TOKEN" ]; then
        echo "❌ 配置不完整，安装已取消。"
        exit 1
    fi
    
    # 生成配置文件
echo "# DDNS 配置文件" | sudo tee "$CONFIG_FILE" >/dev/null
echo "# 域名" | sudo tee -a "$CONFIG_FILE" >/dev/null  # 使用 -a 追加而非覆盖
echo "DOMAIN=$DOMAIN" | sudo tee -a "$CONFIG_FILE" >/dev/null
echo "# API令牌" | sudo tee -a "$CONFIG_FILE" >/dev/null  # 使用 -a 追加而非覆盖
echo "TOKEN=$TOKEN" | sudo tee -a "$CONFIG_FILE" >/dev/null
    
    # 设置安全权限
    sudo chmod 777 "$CONFIG_FILE"
    
    echo "✅ 配置文件已创建: $CONFIG_FILE"
else
    echo "ℹ️ 配置文件已存在，跳过创建步骤"
fi

# 添加到 crontab（避免重复）
(crontab -l 2>/dev/null | grep -Fv "$BIN_FILE" ; echo "$CRON_LINE") | crontab -

echo "✅ 安装完成！"
echo "👉 配置文件路径: $CONFIG_FILE"
echo "🕒 已添加计划任务，每分钟检查一次 IP 是否变化"
echo "📂 缓存文件: $CACHE_DIR/last_ip"
echo "📝 日志文件: /var/log/ddns.log"