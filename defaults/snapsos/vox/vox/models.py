"""Data models for the vox voice command graph.

Nodes form a directed graph walked left-to-right by matching utterance
tokens against node trigger words.

- Branch nodes route to child nodes via named connections.
- Action nodes (exec/shell_exec/type) execute a command when reached.
"""

from __future__ import annotations
from dataclasses import dataclass, field
from typing import Optional


@dataclass
class GraphNode:
    """A single node in the command graph.

    Attributes:
        type: ``"root"``, ``"branch"``, ``"exec"``, ``"shell_exec"``, or ``"type"``.
        trigger: The word(s) that must be spoken to reach this node (branch).
        wake_word: Wake word phrase (root nodes only).
        aliases: Alternative wake words (root nodes only).
        command: Shell command (only for action types).  ``{text}`` is
                 substituted with captured utterance text.
        text_capture: If True, capture all remaining utterance tokens
                      after this node's trigger and substitute into ``{text}``.
        connections: List of child node names (branch and root).
        pos_x: Canvas X position (None = auto-layout).
        pos_y: Canvas Y position (None = auto-layout).
    """
    type: str = "branch"
    trigger: str = ""
    wake_word: str = ""
    aliases: list[str] = field(default_factory=list)
    command: str = ""
    text_capture: bool = False
    connections: list[str] = field(default_factory=list)
    pos_x: float | None = None
    pos_y: float | None = None


@dataclass
class ImmediateTrigger:
    """Exact whole-utterance match that fires before any graph walk."""
    word: str
    type: str
    command: str


@dataclass
class AffixRule:
    """A word detected anywhere in the utterance that modifies the matched command."""
    words: list[str]
    prepend: str = ""
    append: str = ""


@dataclass
class Config:
    """Top-level configuration loaded from ``config.json``."""

    terminal: str = "ghostty -e"
    exec_prefix: str = ""
    prefixes: list[AffixRule] = field(default_factory=list)
    suffixes: list[AffixRule] = field(default_factory=list)
    immediate_triggers: list[ImmediateTrigger] = field(default_factory=list)
    tree: dict[str, GraphNode] = field(default_factory=dict)
