@echo off
setlocal enabledelayedexpansion

echo =============================================
echo  Starting Django Task Management API
echo =============================================

cd /d "%~dp0task_management"

:: Add PostgreSQL to PATH
set PATH=%PATH%;C:\Program Files\PostgreSQL\18\bin

:: Start Redis if not running
echo Checking Redis...
"C:\redis\redis-cli.exe" ping >nul 2>&1
if !ERRORLEVEL! NEQ 0 (
    echo Starting Redis...
    start "" "C:\redis\redis-server.exe" --port 6379 --dir "C:\redis"
    timeout /t 2 /nobreak >nul
) else (
    echo Redis already running.
)

echo.
echo Django API starting on http://localhost:8000
echo Database : PostgreSQL @ localhost:5008 (taskdb)
echo Redis   : localhost:6379
echo.

python manage.py runserver 0.0.0.0:8000