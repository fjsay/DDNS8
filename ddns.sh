#!/bin/bash
# 强制触发IP更新的DDNS脚本（支持IPv4/IPv6，每次运行均尝试更新）

CONFIG_FILE="/etc/ddns/config.conf"
LAST_IPV4=""
LAST_IPV6=""

# 从配置文件中提取配置（强制清空历史IP）
if [ -f "$CONFIG_FILE" ]; then
    V46_MODE=$(grep '^v46=' "$CONFIG_FILE" | cut -d'=' -f2-)
    API_URL=$(grep '^api_url=' "$CONFIG_FILE" | cut -d'=' -f2-)
    DOMAIN=$(grep '^domain=' "$CONFIG_FILE" | cut -d'=' -f2-)
    TOKEN=$(grep '^token=' "$CONFIG_FILE" | cut -d'=' -f2-)
    sed -i '/^LAST_IPV4=/d;/^LAST_IPV6=/d' "$CONFIG_FILE"  # 清空历史IP
else
    echo "[$(date)] ❌ 配置文件未找到: $CONFIG_FILE"
    exit 1
fi

# 加载配置
source "$CONFIG_FILE"

# 检查配置完整性
check_config() {
    if [[ -z "$DOMAIN" || -z "$TOKEN" || -z "$V46_MODE" || -z "$API_URL" ]]; then
        echo "[$(date)] ❌ 配置不完整：DOMAIN=$DOMAIN, TOKEN=***, v46=$V46_MODE, API_URL=$API_URL"
        exit 1
    fi
}

# 获取公网IP
get_public_ip() {
    local service="$1"
    local version="$2"
    local retries=3
    local timeout=8
    local curl_param="-${version}"
    local ip_regex=$([[ $version -eq 4 ]] && echo '([0-9]{1,3}\.){3}[0-9]{1,3}' || echo '([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}')
    
    for ((attempt=1; attempt<=retries; attempt++)); do
        local ip=$(curl -s $curl_param --max-time $timeout "$service" | grep -Eo "$ip_regex")
        if [[ -n "$ip" && ($version -eq 4 || ! "$ip" =~ ^fe80) ]]; then
            echo "$ip"
            return 0
        fi
        sleep 1
    done
    echo "[$(date)] ⚠️ 服务 $service 无法获取IP$version（已重试$retries次）" >&2
    return 1
}

# 从本地接口获取IPv6
get_local_ipv6() {
    local ipv6=$(ip -6 addr show scope global permanent | grep -oP 'inet6 \K[^/]+' | head -1)
    if [[ -n "$ipv6" ]]; then
        echo "[$(date)] ✅ 从本地获取到IPv6地址: $ipv6"
        echo "$ipv6"
        return 0
    else
        echo "[$(date)] ❌ 无法从本地接口获取全局IPv6地址"
        return 1
    fi
}

# 获取IP服务列表（根据版本返回不同列表）
get_ip_services() {
    local version="$1"
    if [[ "$version" -eq 4 ]]; then
        echo "https://ddns8.cn/api/ip.php https://ddns.oray.com/checkip https://api.ipify.org https://icanhazip.com https://ifconfig.me https://ipinfo.io/ip"
    else
        echo "https://api64.ipify.org https://icanhazip.com https://ifconfig.co/ip https://api.ip.sb/ip https://ident.me"
    fi
}

# 执行IP更新
update_ip() {
    local version="$1"
    local current_ip=""
    local use_default=false
    
    # 获取对应版本的服务列表
    local services=$(get_ip_services "$version")
    
    echo "[$(date)] 🔍 开始获取公网IP$version..."
    for service in $services; do
        echo "[$(date)] 正在尝试: $service..."
        current_ip=$(get_public_ip "$service" "$version")
        if [[ -n "$current_ip" ]]; then
            echo "[$(date)] ✅ 成功获取IP$version: $current_ip"
            break
        fi
    done
    
    # IPv6本地获取 fallback
    if [[ $version -eq 6 && -z "$current_ip" ]]; then
        current_ip=$(get_local_ipv6) || return 1
    fi
    
    if [[ -z "$current_ip" ]]; then
        echo "[$(date)] ❌ 无法获取IP$version，更新失败"
        return 1
    fi
    
    # 构建更新URL
    local update_url="${API_URL}?token=${TOKEN}&domain=${DOMAIN}"
    if [[ -n "$current_ip" ]]; then
        update_url+="&addr=$current_ip"
    else
        echo "[$(date)] 🔄 将使用服务器检测的IP地址"
    fi
    
    # 执行更新
    echo "[$(date)] ⚡ 强制更新IP$version，URL: $update_url"
    local response=$(curl -s --max-time 10 "$update_url")
    
    if echo "$response" | grep -q "success"; then
        echo "[$(date)] ✅ 更新成功: $current_ip"
        local conf_ip=LAST_IP${version}
        sed -i "/^$conf_ip=/d" "$CONFIG_FILE"
        echo "$conf_ip=$current_ip" >> "$CONFIG_FILE"
        chmod 600 "$CONFIG_FILE"
    else
        echo "[$(date)] ❌ 更新失败，响应: $response"
        return 1
    fi
}

# 主流程
check_config
case "$V46_MODE" in
    4) update_ip 4 ;;
    6) update_ip 6 ;;
    *) echo "[$(date)] ❌ 无效的IP版本: $V46_MODE，必须为4或6"; exit 1 ;;
esac
