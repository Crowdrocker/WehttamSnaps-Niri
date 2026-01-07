# Makefile: regenerate Niri cheatsheet
KDL = dots/.config/niri/snaps/10-wiri_keybinds.kdl
SCRIPT = generate_niri_cheatsheet.py
OUT = docs/10-wiri_keybinds-cheatsheet.md

.PHONY: cheatsheet watch

cheatsheet:
	@mkdir -p $(dir $(OUT))
	python3 $(SCRIPT) $(KDL) -o $(OUT) --group --strict-header
	@echo "Wrote $(OUT)"

# watch requires inotifywait (from inotify-tools) on Linux.
watch:
	@echo "Watching $(KDL) for changes. Requires inotifywait."
	@while inotifywait -e close_write $(KDL); do make cheatsheet; done