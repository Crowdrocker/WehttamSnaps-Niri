# Help System

Built-in help system with searchable topic browser, command reference, and
quick reference lists.

## Commands

| Command | Keybind | Purpose |
|---------|---------|---------|
| `helptui` | SUPER+SHIFT+H | Topic-based help browser |
| `tldrtui` | SUPER+H | Command reference with TLDR previews |
| `documentation` | SUPER+SHIFT+M | Documentation links + reference sheets |

## Structure

| Path | Purpose |
|------|---------|
| `help.sh` | Topic-based help browser (reads `topics/`) |
| `cmd-help.sh` | Command reference with TLDR + man pages |
| `references.sh` | FZF-based quick reference sheets |
| `topics/` | Help topic files (numbered by chapter) |
| `references.list` | MangoWM config options reference |
| `mangodispatchers.list` | MangoWM dispatcher reference |
| `mangoipc.list` | MangoWM IPC command reference |
| `DMSipc.list` | DMS IPC command reference |
| `cmds.list` | Command list for cmd-help.sh |

## Topics

Chapters: 000 (welcome), 100 (UI usage), 200 (terminal basics),
300 (DMS customization), 400 (mango customization), 500 (scripting),
600 (DMS settings reference)
