# Fastfetch Wrapper

System information display wrapper with ASCII art logos and configurable
display styles.

## Commands

| Command | Purpose |
|---------|---------|
| `fetch` | Run fastfetch with configured logo and config |
| `fetchconf` | TUI to select ASCII art and display config |

## Structure

| Path | Purpose |
|------|---------|
| `fetch.sh` | Main fetch runner (reads `~/.config/fetch.state`) |
| `fetch-conf.sh` | Configurator TUI with fzf |
| `update-files.sh` | Convert images to ASCII art via jp2a |
| `gen/` | Generated ASCII art files |
| `src/` | Source images for ASCII conversion |
| `conf/` | Fastfetch config presets |
