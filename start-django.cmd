@echo off
echo =============================================
echo  Starting Django Task Management API
echo =============================================

cd /d "%~dp0task_management"

:: Add PostgreSQL to PATH
set PATH=%PATH%;C:\Program Files\PostgreSQL\18\bin

echo Django API starting on http://localhost:8000
echo Database : PostgreSQL @ localhost:5008 (taskdb)
echo.

python manage.py runserver 0.0.0.0:8000