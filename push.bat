@echo off
setlocal enabledelayedexpansion

set GIT_EMAIL=harysrifai@gmail.com
set GIT_NAME=Haris Rifai

echo =============================================
echo  Push to GitHub - TaskMgmt-synchAPPS
echo =============================================
echo.

REM Check if git is available
git --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Git is not installed or not in PATH.
    pause
    exit /b 1
)

REM Configure git user if not set
git config user.name >nul 2>&1
if errorlevel 1 (
    echo Setting git user.name to "%GIT_NAME%"...
    git config --global user.name "%GIT_NAME%"
) else (
    echo Git user.name already configured: %GIT_NAME%
)

git config user.email >nul 2>&1
if errorlevel 1 (
    echo Setting git user.email to "%GIT_EMAIL%"...
    git config --global user.email "%GIT_EMAIL%"
) else (
    echo Git user.email already configured: %GIT_EMAIL%
)

REM Check if we are in a git repository
git rev-parse --git-dir >nul 2>&1
if errorlevel 1 (
    echo Initializing git repository...
    git init
) else (
    echo Git repository already initialized.
)

REM Check if remote origin already exists
git remote | findstr /C:"origin" >nul
if errorlevel 1 (
    echo Adding remote origin...
    git remote add origin https://github.com/harys-rifai/TaskMgmt-synchAPPS.git
) else (
    echo Remote origin already exists. Updating URL...
    git remote set-url origin https://github.com/harys-rifai/TaskMgmt-synchAPPS.git
)

REM Check if there are changes to commit
git diff-index --quiet HEAD -- 2>nul
if errorlevel 1 (
    echo Staging changes...
    git add .
    
    echo Committing changes...
    git commit -m "Update Task Management - n8n, Django, Redis, ClickUp integration"
) else (
    echo No changes to commit.
)

REM Get current branch
set CURRENT_BRANCH=
for /f "delims=" %%i in ('git branch --show-current') do set CURRENT_BRANCH=%%i

if "%CURRENT_BRANCH%"=="main" (
    echo Branch is already 'main'.
) else (
    echo Renaming branch to main...
    git branch -M main
)

echo Pushing to GitHub...
git push -u origin main

if errorlevel 1 (
    echo.
    echo ERROR: Push failed. Please check your GitHub credentials and try again.
) else (
    echo.
    echo =============================================
    echo  Push completed successfully!
    echo =============================================
)

pause
