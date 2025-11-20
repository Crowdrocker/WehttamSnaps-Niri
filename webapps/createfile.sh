#!/bin/bash
filenames=("template.webapp" "youtube.webapp" "twitch.webapp" "spotify.webapp" "discord.webapp" "gmail.webapp" "github.webapp" "calendar.webapp" "drive.webapp" "instagram.webapp" "twitter.webapp" "reddit.webapp" "netflix.webapp" "notion.webapp" "chatgpt.webapp")
for name in "${filenames[@]}"; do
  touch "$name"
done
