@echo Off

:: BatchGotAdmin
REM  --> Check for permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params = %*:"=""
    echo UAC.ShellExecute "cmd.exe", "/c %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"



for /f "tokens=2 delims=[]" %%a in ('ping -4 -n 1 adb.gotdns.ch ^| findstr [') do set DNSIP=%%a
echo --------------------------------------------------------
::set DNSIP=
echo DNS IP = %DNSIP%
echo --------------------------------------------------------
::pause



:: SetDNS
for /f "skip=3 tokens=3,4*" %%a in ('netsh interface ipv4 show interfaces') do (
    Call :UseNetworkAdapter %%a %%b "%%c"
)
exit /B

:UseNetworkAdapter
:: %1 = MTU
:: %2 = State
:: %3 = Name (quoted); %~3 = Name (unquoted)
echo Adapter = %3
echo State   = %2
echo MTU     = %1
::pause

::if %2==connected (
	if 10000 GEQ %1 (
		netsh interface ip del dns name=%3 addr=all
		netsh interface ip add dns name=%3 addr=%DNSIP% index=1
		netsh interface ip add dns name=%3 addr=1.1.1.1 index=2
		echo DNS Server %DNSIP% fuer %3 gesetzt!
	)
::)

echo --------------------------------------------------------
::pause
exit /B
