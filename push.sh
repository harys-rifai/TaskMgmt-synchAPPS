#!/bin/bash
set -e

echo "============================================="
echo " Push to GitHub - TaskMgmt-synchAPPS"
echo "============================================="
echo ""

# Check if git is available
if ! command -v git &> /dev/null; then
    echo "ERROR: Git is not installed or not in PATH."
    exit 1
fi

# Check if we are in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Initializing git repository..."
    git init
else
    echo "Git repository already initialized."
fi

# Check if remote origin already exists
if git remote | grep -q "^origin$"; then
    echo "Remote origin already exists. Updating URL..."
    git remote set-url origin https://github.com/harys-rifai/TaskMgmt-synchAPPS.git
else
    echo "Adding remote origin..."
    git remote add origin https://github.com/harys-rifai/TaskMgmt-synchAPPS.git
fi

# Check if there are changes to commit
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo "Staging changes..."
    git add .
    
    echo "Committing changes..."
    git commit -m "Update Task Management - n8n, Django, Redis, ClickUp integration"
else
    echo "No changes to commit."
fi

# Rename branch to main if needed
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "Renaming branch to main..."
    git branch -M main
else
    echo "Branch is already 'main'."
fi

echo "Pushing to GitHub..."
git push -u origin main

echo ""
echo "============================================="
echo " Push completed successfully!"
echo "============================================="
