#!/bin/env bash
# list programs and save them to a file for future reference

saveDir=$HOME/.config/current

save_programs() {
	flatpak --columns=app list --app > $saveDir/flatpaks.list
	paru -Q > $saveDir/archpkgs.list
}

save_programs
