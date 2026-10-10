"""
Configuration management for the glyphs system.

Handles loading, saving, and default generation of the runtime config file
stored under ``~/.config/snapsos/glyphs/config.json``.
"""

import json
import os


# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

# Root config directory under the user's home
CONFIG_DIR = os.path.expanduser("~/.config/snapsos/glyphs")

# Path to the JSON config file
CONFIG_FILE = os.path.join(CONFIG_DIR, "config.json")

# Directory where individual glyph JSON files are stored
GLYPH_DIR = os.path.join(CONFIG_DIR, "glyphs-data")


# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------

def default_config():
    """Return the default configuration dictionary."""
    return {
        "recording": {"sections": 4},
        "appearance": {
            "ink_width": 3.0,
            "background_rgba": [0.0, 0.0, 0.0, 0.06],
            "dictionary_grid_cols": 8,
            "carousel": {"enabled": True, "height": 70},
            "exec_prefix": "",
            "term_exec": ["ghostty", "-e"],
        },
    }


# ---------------------------------------------------------------------------
# Load / save
# ---------------------------------------------------------------------------

def load_config():
    """Load the config from disk, or return defaults if the file doesn't exist."""
    if not os.path.exists(CONFIG_FILE):
        return default_config()
    with open(CONFIG_FILE) as f:
        return json.load(f)


def save_config(config):
    """Write a *config* dictionary to disk, creating directories as needed."""
    os.makedirs(CONFIG_DIR, exist_ok=True)
    with open(CONFIG_FILE, "w") as f:
        json.dump(config, f, indent=2)
