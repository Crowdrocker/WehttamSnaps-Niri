#!/bin/bash
pactl load-module module-null-sink sink_name=Discord sink_properties=device.description="Discord"
pactl load-module module-null-sink sink_name=Game sink_properties=device.description="Game"
pactl load-module module-null-sink sink_name=Music sink_properties=device.description="Music"

