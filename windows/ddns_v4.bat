@echo off
setlocal enabledelayedexpansion

:start
echo 正在更新DDNS记录... [%date% %time%]

curl -s "https://ddns8.cn/api/ddnsapi.php?token=你的API令牌&domain=你的域名"

echo 更新完成！下一次更新将在5分钟后进行...
timeout /t 300 /nobreak >nul

goto start
