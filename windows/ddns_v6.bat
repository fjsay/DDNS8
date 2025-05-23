@echo off
setlocal enabledelayedexpansion

:start
echo ���ڸ���DDNS��¼... [%date% %time%]

:: ��ȡ����IPv6��ַ��������24��ͷ�Ĺ�����ַ��
echo ��ȡ24��ͷ�Ĺ���IPv6��ַ...
set "ip="

:: ʹ��ipconfig�����ȡ��������������Ϣ
for /f "tokens=*" %%a in ('ipconfig ^| findstr /i "IPv6 Address"') do (
    set "line=%%a"
    
    :: ��ȡ����IPv6��ַ����������ð�ź�Ĳ��֣�
    for /f "tokens=1* delims=:" %%b in ("!line!") do (
        set "ipv6_candidate=%%c"
        set "ipv6_candidate=!ipv6_candidate: =!"  :: ȥ��ǰ���ո�
        
        :: ��������24��ͷ�ҷ���·���صĵ�ַ
        echo !ipv6_candidate! | findstr /i "^24" | findstr /v /i "fe80" >nul
        if not errorlevel 1 (
            set "ip=!ipv6_candidate!"
            echo [!date! !time!] �ҵ���ЧIPv6��ַ: !ip!
            goto :found_ip  // �ҵ���һ����ַ�������˳�ѭ��
        )
    )
)

:found_ip
:: ����Ƿ��ҵ�����������IPv6��ַ
if "%ip%"=="" (
    echo [!date! !time!] δ�ҵ�24��ͷ�Ĺ���IPv6��ַ����������
) else (
    echo [!date! !time!] ʹ��IPv6��ַ: !ip!
    
    :: ����DDNS��������Я��IPv6��ַ��
    curl -s "https://9517.eu.org/api/ddnsapi.php?token=���API����&domain=�������&ip=!ip!"
    
    echo ��������Ӧ�ѽ���
)

echo ������ɣ���һ�θ��½���5���Ӻ����...
timeout /t 300 /nobreak >nul
goto start