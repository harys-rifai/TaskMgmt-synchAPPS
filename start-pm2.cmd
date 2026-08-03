@echo off
echo =============================================
echo  Starting n8n via PM2
echo =============================================

cd /d "%~dp0"

:: Tambahkan PostgreSQL ke PATH
set PATH=%PATH%;C:\Program Files\PostgreSQL\18\bin

set DB_TYPE=postgresdb
set DB_POSTGRESDB_HOST=localhost
set DB_POSTGRESDB_PORT=5008
set DB_POSTGRESDB_DATABASE=n8n
set DB_POSTGRESDB_USER=postgres
set DB_POSTGRESDB_PASSWORD=Password09!
set N8N_HOST=localhost
set N8N_PORT=5678
set N8N_PROTOCOL=http
set N8N_SECURE_COOKIE=false
set GENERIC_TIMEZONE=Asia/Jakarta

echo Checking PM2...
pm2 --version >nul 2>&1
if errorlevel 1 (
    echo PM2 not found. Installing...
    npm install pm2 -g
)

echo Starting n8n with PM2...
pm2 start n8n --name "n8n"

echo Saving PM2 config...
pm2 save

echo.
echo =============================================
echo  n8n started via PM2
echo  URL: http://localhost:5678
echo =============================================
echo.
echo Useful PM2 commands:
echo   pm2 status       - Check status
echo   pm2 logs n8n     - View logs
echo   pm2 restart n8n  - Restart n8n
echo   pm2 stop n8n     - Stop n8n
echo   pm2 startup      - Enable auto-start on boot
