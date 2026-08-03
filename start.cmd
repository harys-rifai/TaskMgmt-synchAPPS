@echo off
echo =============================================
echo  Starting n8n with PostgreSQL
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

echo Database  : PostgreSQL @ localhost:5008
echo n8n URL   : http://localhost:5678
echo.

n8n
