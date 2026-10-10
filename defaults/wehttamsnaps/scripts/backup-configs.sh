#!/bin/bash

# Configuration
BACKUP_DIR="$HOME/Documents/Backups/WehttamSnaps-Dots"
GIT_REMOTE="https://github.com/Crowdrocker/WehttamSnaps-SwayFx.git" # Your repo

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"
cd "$BACKUP_DIR"

# Initialize git if not already done
if [ ! -d ".git" ]; then
    git init
    git remote add origin "$GIT_REMOTE"
fi

# Sync files from your system to the backup folder
echo "Syncing configurations..."
rsync -av --delete "$HOME/.config/sway/" "$BACKUP_DIR/sway/"
rsync -av --delete "$HOME/.config/wehttamsnaps/" "$BACKUP_DIR/wehttamsnaps/"
rsync -av --delete "$HOME/.config/waybar/" "$BACKUP_DIR/waybar/"

# Commit and Push
git add .
git commit -m "Backup: Config update on $(date +'%Y-%m-%d %H:%M:%S')"
git push origin main

notify-send "Backup Complete" "Your configs have been pushed to GitHub." -i security-high
