# Tips System

Random tip display system that shows SNAPS-OS usage tips.

## Triggers

| Trigger | Behavior |
|---------|----------|
| First terminal launch | Auto-shows a random tip |
| `tipme` command | Shows a random tip in terminal |
| SUPER+0 | Shows a random tip via desktop notification |
| `alltips` command | Opens all tips in an FZF browser |

## Files

| File | Purpose |
|------|---------|
| `tips.list` | Collection of tip strings (one per line) |
| `tips.sh` | Tip selection and display script |
