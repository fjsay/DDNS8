#!/bin/bash
# 支持IPv4/IPv6自动检测的DDNS脚本

CONFIG_FILE="/etc/ddns/config.conf"
LAST_IPV4=""
LAST_IPV6=""

# 从配置文件中提取上次的IP地址
if [ -f "$CONFIG_FILE" ]; then
    LAST_IPV4=$(grep '^LAST_IPV4=' "$CONFIG_FILE" | cut -d'=' -f2-)
    LAST_IPV6=$(grep '^LAST_IPV6=' "$CONFIG_FILE" | cut -d'=' -f2-)
    V46_MODE=$(grep '^v46=' "$CONFIG_FILE" | cut -d'=' -f2-)
else
    echo "[$(date)] ❌ 配置文件未找到: $CONFIG_FILE"
    exit 1
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
source "$CONFIG_FILE"

# 检查配置完整性
if [[ -z "$DOMAIN" || -z "$TOKEN" || -z "$V46_MODE" ]]; then
    echo "[$(date)] ❌ 配置不完整，已取消更新"
    echo "DOMAIN=${DOMAIN:-<空>}, TOKEN=${TOKEN:-<空>}, v46=${V46_MODE:-<空>}"
    exit 1
fi

# 获取公网IP函数（支持指定版本）
get_public_ip() {
    local service="$1"
    local version="$2"
    local retries=3
    local attempt=0
    local timeout=8
    local curl_param="-${version}"
    local ip_regex=""
    
    # 设置IP正则表达式
    if [ "$version" -eq 4 ]; then
        ip_regex='([0-9]{1,3}\.){3}[0-9]{1,3}'
    elif [ "$version" -eq 6 ]; then
        ip_regex='([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}'
    fi
    
    while [ $attempt -lt $retries ]; do
        attempt=$((attempt+1))
        local ip=$(curl $curl_param -s --max-time "$timeout" "$service" | grep -Eo "$ip_regex")
        
        if [ -n "$ip" ]; then
            # 验证IPv6格式（简单过滤链路本地地址）
            if [ "$version" -eq 6 ] && [[ ! $ip =~ ^fe80 ]]; then
                echo "$ip"
                return 0
            elif [ "$version" -eq 4 ]; then
                echo "$ip"
                return 0
            fi
        fi
        
        if [ $attempt -eq $retries ]; then
            echo "[$(date)] ⚠️ 服务 $service 无法获取IP$version（已重试$retries次）" >&2
        fi
        sleep 1
    done
    return 1
}

# 根据配置执行对应IP版本的更新
update_ip() {
    local version="$1"
    local last_ip=""
    local CURRENT_IP=""
    
    # 获取上次的IP
    if [ "$version" -eq 4 ]; then
        last_ip="$LAST_IPV4"
        echo "[$(date)] 🔍 开始获取公网IPv4..."
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
    else
        last_ip="$LAST_IPV6"
        echo "[$(date)] 🔍 开始获取公网IPv6..."
        IP_SERVICES=(
            "https://api64.ipify.org"
            "https://icanhazip.com"
            "https://ifconfig.co/ip"
            "https://api.ip.sb/ip"
            "https://ident.me"
            "https://v6.ident.me"
            "https://ipv6.icanhazip.com"
            "https://ip6.seeip.org"
            "https://ip6only.me/api/"
        )
    fi
    
    # 尝试从服务列表获取IP
    for SERVICE in "${IP_SERVICES[@]}"; do
        echo "[$(date)] 正在尝试: $SERVICE..."
        CURRENT_IP=$(get_public_ip "$SERVICE" "$version")
        
        if [ -n "$CURRENT_IP" ]; then
            echo "[$(date)] ✅ 成功从 $SERVICE 获取IP$version: $CURRENT_IP"
            break
        fi
    done
    
    if [ -z "$CURRENT_IP" ]; then
        echo "[$(date)] ❌ 无法从任何服务中获取公网 IP$version"
        return 1
    fi
    
    # 比较是否需要更新
    if [ "$CURRENT_IP" != "$last_ip" ]; then
        # 构建更新URL（根据版本设置记录类型）
        if [ "$version" -eq 4 ]; then
            UPDATE_URL="http://9517.eu.org/api/ddnsapi.php?token=${TOKEN}&domain=${DOMAIN}&addr=${CURRENT_IP}"
            CONF_IP="LAST_IPV4"
        else
            UPDATE_URL="http://9517.eu.org/api/ddnsapi.php?token=${TOKEN}&domain=${DOMAIN}&addr=${CURRENT_IP}"
            CONF_IP="LAST_IPV6"
        fi
        
        RESPONSE=$(curl -s --max-time 10 "$UPDATE_URL")
        echo "[$(date)] 🌐 服务器响应: $RESPONSE"
        
        # 判断更新成功的条件
        if echo "$RESPONSE" | grep -q "upddns_record_success" || echo "$RESPONSE" | grep -q "DNS记录已是最新，无需更新"; then
            echo "[$(date)] ✅ 更新成功: $last_ip → $current_ip"
            
            # 更新配置文件
            TEMP_FILE="/tmp/config.conf.tmp"
            grep -v "^$CONF_IP=" "$CONFIG_FILE" > "$TEMP_FILE"
            echo "$CONF_IP=$current_ip" >> "$TEMP_FILE"
            
            if [ -f "$TEMP_FILE" ]; then
                mv "$TEMP_FILE" "$CONFIG_FILE"
                chmod 600 "$CONFIG_FILE"
                echo "[$(date)] 💾 已更新配置文件: $CONFIG_FILE"
            else
                echo "[$(date)] ⚠️ 无法更新配置文件，但更新已成功"
            fi
        else
            echo "[$(date)] ❌ 更新失败，IP$version 未更新"
            print_error_message "$RESPONSE"
            echo "[$(date)] 🐞 调试信息: URL=${UPDATE_URL}"
            return 1
        fi
    else
        echo "[$(date)] ⏸️  IP$version 未变化: $current_ip，无需更新"
    fi
    
    return 0
}

# 根据配置执行更新
case "$V46_MODE" in
    4)
        update_ip 4
        ;;
    6)
        update_ip 6
        ;;
    *)
        echo "[$(date)] ❌ 无效的IP版本配置: $V46_MODE"
        echo "[$(date)] 💡 请在 $CONFIG_FILE 中设置 v46=4（仅IPv4）或 v46=6（仅IPv6）"
        exit 1
        ;;
esac
