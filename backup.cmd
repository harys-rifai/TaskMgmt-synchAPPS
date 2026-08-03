@echo off
echo =============================================
echo  Backup Database n8n
echo =============================================

cd /d "%~dp0"

:: Tambahkan PostgreSQL ke PATH
set PATH=%PATH%;C:\Program Files\PostgreSQL\18\bin

:: Buat folder backup jika belum ada
if not exist "backup" mkdir backup

:: Nama file backup dengan timestamp
for /f "tokens=1-4 delims=/ " %%a in ('date /t') do set DATESTAMP=%%d%%b%%c
for /f "tokens=1-2 delims=: " %%a in ('time /t') do set TIMESTAMP=%%a%%b
set BACKUPFILE=backup\n8n_backup_%DATESTAMP%_%TIMESTAMP%.sql

echo Backup ke: %BACKUPFILE%
echo.

pg_dump -h localhost -p 5008 -U postgres -d n8n > "%BACKUPFILE%"

if errorlevel 1 (
    echo [ERROR] Backup gagal!
) else (
    echo [OK] Backup berhasil: %BACKUPFILE%
)

echo.
pause
