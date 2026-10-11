#!/bin/bash

# Start SSH agent if not already running
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" > /dev/null
    echo "SSH agent started"
else
    echo "SSH agent already running"
fi









