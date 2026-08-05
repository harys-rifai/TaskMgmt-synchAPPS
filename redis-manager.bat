@echo off

:MENU
cls
echo ====================
echo     REDIS MANAGER
echo ====================
echo.
echo 1. Start Redis
echo 2. Stop Redis
echo 3. Login Redis CLI
echo 4. Exit
echo.

set /p CHOICE=Pilih [1-4]:

if "%CHOICE%"=="1" goto START
if "%CHOICE%"=="2" goto STOP
if "%CHOICE%"=="3" goto LOGIN
if "%CHOICE%"=="4" exit

goto MENU

:START
start "" "C:\redis\redis-server.exe"
echo Redis started.
pause
goto MENU

:STOP
"C:\redis\redis-cli.exe" shutdown
echo Redis stopped.
pause
goto MENU

:LOGIN
"C:\redis\redis-cli.exe" -u redis://localhost:6379/0
goto MENU