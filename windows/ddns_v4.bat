@echo off
setlocal enabledelayedexpansion

:start
echo ���ڸ���DDNS��¼... [%date% %time%]

curl -s "https://9517.eu.org/api/ddnsapi.php?token=���API����&domain=�������"

echo ������ɣ���һ�θ��½���5���Ӻ����...
timeout /t 300 /nobreak >nul

goto start