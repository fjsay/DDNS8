#!/bin/bash

CONFIG_FILE="/etc/ddns/config.conf"
LAST_IP=""

# 从配置文件中提取上次的IP地址
if [ -f "$CONFIG_FILE" ]; then
    LAST_IP=$(grep '^LAST_IP=' "$CONFIG_FILE" | cut -d'=' -f2-)
fi

# 错误码对应的中文提示
print_error_message() {
    local response="$1"

    case "$response" in
        *"ip length err"*) echo "📙 说明：IP 长度错误";;
        *"ip err:"*) echo "📙 说明：IP 格式错误";;
        *"keyid err"*) echo "📙 说明：KeyID 长度错误";;
        *"token err"*) echo "📙 说明：Token 长度错误";;
        *"keyid or token err"*) echo "📙 说明：KeyID 或 Token 错误";;
        *"not recordid"*) echo "📙 说明：记录 ID 错误";;
        *"Submit IP not changed"*) echo "📙 说明：IP 未变化，服务器拒绝重复提交";;
        *"ddns max"*) echo "📙 说明：超出每日更新次数限制";;
        *"upddns_record_fail"*) echo "📙 说明：记录更新失败";;
        *"DNS记录已是最新，无需更新"*) echo "📙 说明：域名已指向当前IP，无需更新";;
        *) echo "📙 说明：未知错误，请检查响应或联系支持";;
    esac
}

# 加载配置
[ -f "$CONFIG_FILE" ] || { echo "[$(date)] ❌ 配置文件未找到: $CONFIG_FILE"; exit 1; }
source "$CONFIG_FILE"

# 检查配置完整性
if [[ -z "$DOMAIN" || -z "$TOKEN" ]]; then
    echo "[$(date)] ❌ 配置不完整，已取消更新"
    echo "DOMAIN=${DOMAIN:-<空>}, TOKEN=${TOKEN:-<空>}"
    exit 1
fi

# 获取公网 IPv4 的服务列表
IP_SERVICES=(
  "https://api.ipify.org"
  "https://icanhazip.com"
  "https://ifconfig.me"
  "https://ipinfo.io/ip"
  "https://checkip.amazonaws.com"
  "https://members.3322.org/dyndns/getip"
  "https://api.ip.sb/ip"
  "https://ip.3322.net"
  "https://myip.ipip.net"
  "https://ident.me"
  "https://ip.cip.cc"
  "https://4.ipw.cn"
)

# 获取公网IPv4函数，添加重试机制
get_public_ip() {
    local service="$1"
    local retries=2
    local attempt=0
    local timeout=5
    
    while [ $attempt -lt $retries ]; do
        attempt=$((attempt+1))
        
        # 尝试获取IP，使用-4参数强制IPv4，增加超时设置
        local ip=$(curl -4 -s --max-time $timeout "$service" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}')
        
        if [ -n "$ip" ]; then
            echo "$ip"
            return 0
        fi
        
        # 如果是最后一次尝试，记录错误
        if [ $attempt -eq $retries ]; then
            echo "[$(date)] ⚠️ 服务 $service 无法获取IPv4（已重试$retries次）" >&2
        fi
        
        # 重试前稍微等待
        sleep 1
    done
    
    return 1
}

CURRENT_IP=""
echo "[$(date)] 🔍 开始获取公网IPv4..."

for SERVICE in "${IP_SERVICES[@]}"; do
    echo "[$(date)] 正在尝试: $SERVICE..."
    CURRENT_IP=$(get_public_ip "$SERVICE")
    
    if [ -n "$CURRENT_IP" ]; then
        echo "[$(date)] ✅ 成功从 $SERVICE 获取IP: $CURRENT_IP"
        break
    fi
done

if [ -z "$CURRENT_IP" ]; then
    echo "[$(date)] ❌ 无法从任何服务中获取公网 IPv4"
    echo "[$(date)] 💡 建议检查网络连接或防火墙设置"
    exit 1
fi

# 比较是否需要更新
if [ "$CURRENT_IP" != "$LAST_IP" ]; then
    # 修正：使用 ${DOMAIN} 而非 {DOMAIN}
    UPDATE_URL="https://9517.eu.org/api/ddnsapi.php?token=${TOKEN}&domain=${DOMAIN}&addr=${CURRENT_IP}"
    RESPONSE=$(curl -s --max-time 10 "$UPDATE_URL")

    echo "[$(date)] 🌐 服务器响应: $RESPONSE"

    # 判断更新成功的条件：包含"upddns_record_success"或者"DNS记录已是最新，无需更新"
    if echo "$RESPONSE" | grep -q "upddns_record_success" || echo "$RESPONSE" | grep -q "DNS记录已是最新，无需更新"; then
        echo "[$(date)] ✅ 更新成功: $LAST_IP → $CURRENT_IP"
        
        # 更新配置文件中的LAST_IP
        TEMP_FILE="/tmp/config.conf.tmp"
        
        # 移除旧的LAST_IP行并添加新的
        grep -v '^LAST_IP=' "$CONFIG_FILE" > "$TEMP_FILE"
        echo "LAST_IP=$CURRENT_IP" >> "$TEMP_FILE"
        
        # 原子性替换配置文件
        if [ -f "$TEMP_FILE" ]; then
            mv "$TEMP_FILE" "$CONFIG_FILE"
            chmod 600 "$CONFIG_FILE"  # 确保配置文件权限安全
            echo "[$(date)] 💾 已更新配置文件: $CONFIG_FILE"
        else
            echo "[$(date)] ⚠️ 无法更新配置文件，但DDNS更新已成功"
        fi
    else
        echo "[$(date)] ❌ 更新失败，IP 未更新"
        echo "[$(date)] 🐞 调试信息: URL=${UPDATE_URL}"
    fi
else
    echo "[$(date)] ⏸️  IP 未变化: $CURRENT_IP，无需更新"
fi