"""Load and save vox configuration from/to JSON files."""

from __future__ import annotations
import json
from pathlib import Path
from .models import Config, GraphNode, ImmediateTrigger, AffixRule

INSTALL_DIR = Path.home() / ".config" / "snapsos" / "vox"


def default_config_path() -> Path:
    return INSTALL_DIR / "config.json"


def models_dir() -> Path:
    d = INSTALL_DIR / "models"
    d.mkdir(exist_ok=True)
    return d


def load_config(path: Path | None = None) -> Config:
    path = path or default_config_path()
    with open(path) as f:
        data = json.load(f)
    return _parse_config(data)


def save_config(config: Config, path: Path | None = None) -> None:
    path = path or default_config_path()
    data = _serialize_config(config)
    with open(path, "w") as f:
        json.dump(data, f, indent=2)


def _parse_node(data: dict) -> GraphNode:
    return GraphNode(
        type=data.get("type", "branch"),
        trigger=data.get("trigger", ""),
        wake_word=data.get("wake_word", ""),
        aliases=data.get("aliases", []),
        command=data.get("command", ""),
        text_capture=data.get("text_capture", False),
        connections=data.get("connections", []),
        pos_x=data.get("pos_x"),
        pos_y=data.get("pos_y"),
    )


def _serialize_node(node: GraphNode) -> dict:
    d: dict = {"type": node.type}
    if node.type == "root":
        d["wake_word"] = node.wake_word
        if node.aliases:
            d["aliases"] = list(node.aliases)
    else:
        d["trigger"] = node.trigger
        if node.command:
            d["command"] = node.command
        d["text_capture"] = node.text_capture
    if node.connections:
        d["connections"] = list(node.connections)
    if node.pos_x is not None:
        d["pos_x"] = node.pos_x
    if node.pos_y is not None:
        d["pos_y"] = node.pos_y
    return d


def _parse_affix_rules(items: list[dict]) -> list[AffixRule]:
    return [
        AffixRule(
            words=item.get("words", []),
            prepend=item.get("prepend", ""),
            append=item.get("append", ""),
        )
        for item in items
    ]


def _parse_triggers(items: list[dict]) -> list[ImmediateTrigger]:
    return [
        ImmediateTrigger(
            word=item["word"],
            type=item["type"],
            command=item["command"],
        )
        for item in items
    ]


def _migrate_old_format(data: dict) -> dict:
    """Detect and convert old-format config to the trigger-on-node format.

    Handles two possible old formats:
    1. Edge-based format (connections as list of dicts with target/trigger).
    2. Pre-edge format (nodes with ``type`` and ``command`` but no ``trigger``).
    """
    tree_data = data.get("tree", {})
    if not isinstance(tree_data, dict):
        return data
    old_nodes = tree_data.get("nodes", {})

    # Detect format: if any non-root node is missing the "trigger" key, migrate.
    needs_migrate = any(
        isinstance(v, dict) and "trigger" not in v and v.get("type") != "root"
        for v in old_nodes.values()
    )
    if not needs_migrate:
        return data

    new_nodes = {}
    for name, ndata in old_nodes.items():
        if not isinstance(ndata, dict):
            continue
        # Extract base fields.
        base_type = ndata.get("type", "branch")
        command = ndata.get("command", "")
        text_capture = ndata.get("text_capture", False)
        pos_x = ndata.get("pos_x")
        pos_y = ndata.get("pos_y")

        # Connections could be list of Edge dicts or list of strings.
        raw_cons = ndata.get("connections", [])
        if raw_cons and isinstance(raw_cons[0], dict):
            connections = [e.get("target", "") for e in raw_cons]
            trigger = ""
        else:
            connections = raw_cons
            trigger = ""

        # Preserve existing trigger if the node already has one.
        existing_trigger = ndata.get("trigger", None)
        if existing_trigger is not None:
            trigger = existing_trigger
        elif base_type not in ("exec", "shell_exec", "type"):
            # Only branch nodes need a trigger word — derive from name.
            if raw_cons and isinstance(raw_cons[0], dict):
                trigger = raw_cons[0].get("trigger", name) if raw_cons else name
            elif connections:
                trigger = name
            else:
                trigger = name

        new_node: dict = {
            "trigger": trigger,
            "type": base_type,
        }
        if command:
            new_node["command"] = command
        if text_capture:
            new_node["text_capture"] = True
        if connections:
            new_node["connections"] = connections
        if pos_x is not None:
            new_node["pos_x"] = pos_x
        if pos_y is not None:
            new_node["pos_y"] = pos_y
        new_nodes[name] = new_node

    # Migrate old single root to a root-type node named "default".
    old_root = tree_data.get("root", [])
    if isinstance(old_root, list) and old_root:
        if isinstance(old_root[0], dict):
            root_cons = [e.get("target", "") for e in old_root]
        else:
            root_cons = list(old_root)
        wake = data.get("wake_word", "system command")
        aliases = data.get("wake_word_aliases", [])
        root_node: dict = {
            "type": "root",
            "wake_word": wake,
            "connections": root_cons,
        }
        if aliases:
            root_node["aliases"] = aliases
        new_nodes["default"] = root_node

    result = dict(data)
    result["tree"] = {"nodes": new_nodes}
    return result


def _parse_config(data: dict) -> Config:
    data = _migrate_old_format(data)
    tree_data = data.get("tree", {})
    nodes = {}
    for name, ndata in tree_data.get("nodes", {}).items():
        nodes[name] = _parse_node(ndata)
    return Config(
        terminal=data.get("terminal", "ghostty -e"),
        exec_prefix=data.get("exec_prefix", ""),
        prefixes=_parse_affix_rules(data.get("prefixes", [])),
        suffixes=_parse_affix_rules(data.get("suffixes", [])),
        immediate_triggers=_parse_triggers(data.get("immediate_triggers", [])),
        tree=nodes,
    )


def _serialize_config(config: Config) -> dict:
    nodes = {}
    for name, node in sorted(config.tree.items()):
        nodes[name] = _serialize_node(node)
    return {
        "terminal": config.terminal,
        "exec_prefix": config.exec_prefix,
        "prefixes": [
            {"words": r.words, "prepend": r.prepend, "append": r.append}
            for r in config.prefixes
        ],
        "suffixes": [
            {"words": r.words, "prepend": r.prepend, "append": r.append}
            for r in config.suffixes
        ],
        "immediate_triggers": [
            {"word": t.word, "type": t.type, "command": t.command}
            for t in config.immediate_triggers
        ],
        "tree": {
            "nodes": nodes,
        },
    }
