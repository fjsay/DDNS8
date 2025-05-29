@echo off
setlocal enabledelayedexpansion

:start
echo 正在更新DDNS记录... [%date% %time%]

:: 获取网卡IPv6地址（仅保留24开头的公网地址）
echo 获取24开头的公网IPv6地址...
set "ip="

:: 使用ipconfig命令获取所有网络配置信息
for /f "tokens=*" %%a in ('ipconfig ^| findstr /i "IPv6 Address"') do (
    set "line=%%a"
    
    :: 提取完整IPv6地址（包括所有冒号后的部分）
    for /f "tokens=1* delims=:" %%b in ("!line!") do (
        set "ipv6_candidate=%%c"
        set "ipv6_candidate=!ipv6_candidate: =!"  :: 去除前导空格
        
        :: 仅保留以24开头且非链路本地的地址
        echo !ipv6_candidate! | findstr /i "^24" | findstr /v /i "fe80" >nul
        if not errorlevel 1 (
            set "ip=!ipv6_candidate!"
            echo [!date! !time!] 找到有效IPv6地址: !ip!
            goto :found_ip  // 找到第一个地址后立即退出循环
        )
    )
)

:found_ip
:: 检查是否找到符合条件的IPv6地址
if "%ip%"=="" (
    echo [!date! !time!] 未找到24开头的公网IPv6地址，跳过更新
) else (
    echo [!date! !time!] 使用IPv6地址: !ip!
    
    :: 发送DDNS更新请求（携带IPv6地址）
    curl -s "https://ddns8.cn/api/ddnsapi.php?token=你的API令牌&domain=你的域名&ip=!ip!"
    
    echo 服务器响应已接收
)

echo 更新完成！下一次更新将在5分钟后进行...
timeout /t 300 /nobreak >nul
goto start
