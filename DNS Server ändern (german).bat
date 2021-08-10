@echo off

set DNS1IP=1.1.1.1
set DNS2IP=8.8.8.8

:: -----------------------------------------------------------------------------------------------------------------
REM Alternativ kann die IP auch aus einer Domäne bezogen werden, hier ein Beispiel dafür.
::for /f "tokens=2 delims=[]" %%a in ('ping -4 -n 1 google.com ^| findstr [') do set DNS1IP=%%a
::for /f "tokens=2 delims=[]" %%a in ('ping -4 -n 1 google.com ^| findstr [') do set DNS2IP=%%a
:: -----------------------------------------------------------------------------------------------------------------

>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

if '%errorlevel%' NEQ '0' (
    echo Anfrage nach Admin Rechten...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params = %*:"=""
    echo UAC.ShellExecute "cmd.exe", "/c %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /b

:gotAdmin
    pushd "%CD%"
    CD /d "%~dp0"

:dialog
	echo *****************************************************************************
	echo * 1 = DNS Server fuer alle Netzwerkadapter setzen. (Schutz aktivieren)      * 
	echo * 2 = DNS Server fuer alle Netzwerkadapter entfernen. (Schutz deaktivieren) *
	echo * 3 = Exit                                                                  *
	echo *****************************************************************************
	echo.
	set /p input="Wie geht es weiter? (1,2,3) : "

	if %input% NEQ 1 if %input% NEQ 2 if %input% NEQ 3 (
		cls
		goto dialog
	)

	if %input% EQU 1 (
	goto 1.1
	)

	if %input% EQU 2 (
	goto 2
	)

	if %input% EQU 3 (
	goto 3
	)

	:1.1
		cls
		echo *****************************************************************************
		echo * 1 = Alle Adapter (empfohlen)                                              * 
		echo * 2 = Nur verbundene Adapter                                                *
		echo * 3 = ...                                                                   *
		echo *****************************************************************************
		echo.
		set /p input1.1="Fuer wellche Netzwerkadapter soll der DNS Eintrag erfolgen? (1,2) : "

		if %input1.1% NEQ 1 if %input1.1% NEQ 2 if %input1.1% NEQ 3 (
			cls
			goto dialog
		)

		if %input1.1% EQU 1 (
			goto 1.1.1
		)

		if %input1.1% EQU 2 (
			goto 1.1.2
		)

		if %input1.1% EQU 3 (
			cls
			goto dialog
		)

		:1.1.1
			cls
			echo **************************
			echo DNS 1 = %DNS1IP%
			echo DNS 2 = %DNS2IP%
			echo **************************

			for /f "skip=3 tokens=3,4*" %%a in ('netsh interface ipv4 show interfaces') do (
				Call :UseNetworkAdapter %%a %%b "%%c"
			)
			goto end

			:UseNetworkAdapter
			:: %1 = MTU
			:: %2 = State
			:: %3 = Name (quoted); %~3 = Name (unquoted)
			echo.
			echo **************************************************************
			echo Adapter = %3
			echo State   = %2
			echo MTU     = %1		

			if %1 LSS 10000 (
				netsh interface ip del dns name=%3 addr=all | echo off
				netsh interface ip add dns name=%3 addr=%DNS1IP% index=1 | echo off
				netsh interface ip add dns name=%3 addr=%DNS2IP% index=2 | echo off
				echo --------------------------------------------------------------
				echo DNS 1 = %DNS1IP% fuer %3 gesetzt!
				echo DNS 2 = %DNS2IP% fuer %3 gesetzt!
				echo **************************************************************
			) else (
			echo --------------------------------------------------------------
			echo DNS Server fuer %3 nicht gesetzt!
			echo **************************************************************
			)
			exit /b

		:1.1.2
			cls
			echo **************************
			echo DNS 1 = %DNS1IP%
			echo DNS 2 = %DNS2IP%
			echo **************************

			for /f "skip=3 tokens=3,4*" %%a in ('netsh interface ipv4 show interfaces') do (
				Call :UseNetworkAdapter %%a %%b "%%c"
			)
			goto end

			:UseNetworkAdapter
			:: %1 = MTU
			:: %2 = State
			:: %3 = Name (quoted); %~3 = Name (unquoted)
			echo.
			echo **************************************************************
			echo Adapter = %3
			echo State   = %2
			echo MTU     = %1		

			if %2==connected (
				if %1 LSS 10000 (
					netsh interface ip del dns name=%3 addr=all | echo off
					netsh interface ip add dns name=%3 addr=%DNS1IP% index=1 | echo off
					netsh interface ip add dns name=%3 addr=%DNS2IP% index=2 | echo off
					echo --------------------------------------------------------------
					echo DNS 1 = %DNS1IP% fuer %3 gesetzt!
					echo DNS 2 = %DNS2IP% fuer %3 gesetzt!
					echo **************************************************************
				) else (
					echo --------------------------------------------------------------
					echo DNS Server fuer %3 nicht gesetzt!
					echo **************************************************************
					)
			) else (
				echo --------------------------------------------------------------
				echo DNS Server fuer %3 nicht gesetzt!
				echo **************************************************************
				)
			exit /b

		:2
			cls
			for /f "skip=3 tokens=3,4*" %%a in ('netsh interface ipv4 show interfaces') do (
				Call :UseNetworkAdapter %%a %%b "%%c"
			)
			goto end
			
			:UseNetworkAdapter
			:: %1 = MTU
			:: %2 = State
			:: %3 = Name (quoted); %~3 = Name (unquoted)
			echo.
			echo **************************************************************
			echo Adapter = %3
			echo State   = %2
			echo MTU     = %1

			if %1 LSS 10000 (
				netsh interface ip del dns name=%3 addr=all | echo off
				echo --------------------------------------------------------------
				echo Alle DNS Server fuer %3 entfernt!
				echo **************************************************************
			) else (
			echo --------------------------------------------------------------
			echo DNS Server von %3 nicht entfernt!
			echo **************************************************************
			)
			exit /b

		:3
			if %input% EQU 3 (
				cls
				echo *****************************************************************************
				echo *                                                                           *
				echo *                                    Bye                                    *
				echo *                                                                           *
				echo *****************************************************************************
			)
:end
	echo.
	echo.
	pause

exit
