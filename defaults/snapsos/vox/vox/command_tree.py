"""Graph-based voice command matching engine with node-triggered actions.

Each node has a trigger word. Walking starts at root (virtual), then at each
step the utterance tokens are matched against the trigger words of the current
node's children. When a match is found, we move to that child node. If the
child is an action node (exec/shell_exec/type), its command executes.

Multi-word triggers (e.g. "search for") are matched greedily (longest first).
Non-matching tokens are silently skipped.
"""

from __future__ import annotations
from .models import Config, GraphNode

ACTION_TYPES = {"exec", "shell_exec", "type"}

# Punctuation that Vosk sometimes inserts (commas, periods, etc.)
_PUNCTUATION = ",.!?;:"


def strip_punctuation(text: str) -> str:
    """Remove common punctuation characters that Vosk sometimes inserts."""
    for ch in _PUNCTUATION:
        text = text.replace(ch, "")
    return text.strip()


def strip_wake_word(config: Config, text: str) -> tuple[str, str | None]:
    """If *text* starts with any root node's wake word or alias, strip it.

    Returns ``(stripped_text, root_name)`` where *root_name* is the
    name of the root node whose wake word matched, or ``None``.
    """
    lower = text.lower()
    words = lower.split()
    for root_name, node in config.tree.items():
        if node.type != "root":
            continue
        for ww in [node.wake_word] + node.aliases:
            ww_tokens = ww.lower().split()
            if not ww_tokens:
                continue
            if words[:len(ww_tokens)] == ww_tokens:
                rest = " ".join(text.split()[len(ww_tokens):])
                return rest, root_name
    return text, None


class MatchResult:
    """Holds the result of a successful graph walk."""

    def __init__(
        self,
        action_type: str,
        command: str,
        text: str | None = None,
        prefix: str = "",
        suffix: str = "",
    ):
        self.action_type = action_type
        self.command = command
        self.text = text
        self.prefix = prefix
        self.suffix = suffix


def match(config: Config, utterance: str, root_name: str | None = None) -> list[MatchResult]:
    """Match a wake-word-stripped utterance against the command graph.

    If *root_name* is not given, auto-detect via ``strip_wake_word``.

    Processing order:
    1. Immediate triggers (scanned as token-sequence anywhere in utterance).
    2. Scan every token for prefix/suffix rules.
    3. Walk the graph, matching node triggers against tokens.

    Returns a list of ``MatchResult`` (may be empty).
    """
    text, detected = strip_wake_word(config, utterance)
    root_name = root_name or detected
    if root_name is None:
        return []
    root = config.tree.get(root_name)
    if root is None or root.type != "root":
        return []
    _path, results = _walk_graph(config, text, root.connections)
    return results


def trace_path(config: Config, utterance: str, root_name: str | None = None
               ) -> tuple[list[str], list[MatchResult]]:
    """Like :func:`match` but also returns the list of node names visited.

    If *root_name* is not given, auto-detect via ``strip_wake_word``.

    Returns ``(path, results)`` where *path* is the ordered list of node names
    the walker entered (including root-connection branches and final action
    nodes), and *results* is the list of ``MatchResult`` objects that would be
    executed.
    """
    text, detected = strip_wake_word(config, utterance)
    root_name = root_name or detected
    if root_name is None:
        return [], []
    root = config.tree.get(root_name)
    if root is None or root.type != "root":
        return [], []
    return _walk_graph(config, text, root.connections)


def _walk_graph(config: Config, utterance: str,
                start_connections: list[str] | None = None
                ) -> tuple[list[str], list[MatchResult]]:
    """Internal walker shared by :func:`match` and :func:`trace_path`.

    *start_connections* is the list of child node names to start walking
    from (typically a root node's connections).
    """
    text = utterance.strip()
    if not text or not start_connections:
        return [], []

    tokens = text.lower().split()
    original_tokens = text.split()

    # Immediate triggers: token-sequence match anywhere in utterance.
    for trigger in config.immediate_triggers:
        tt = trigger.word.lower().split()
        for i in range(len(tokens) - len(tt) + 1):
            if tokens[i:i + len(tt)] == tt:
                return [], [MatchResult(trigger.type, trigger.command)]

    # Prefix/suffix scanning — identify trigger word positions.
    prefix_prepend = ""
    suffix_append = ""
    skip_indices: set[int] = set()
    for i, token_lower in enumerate(tokens):
        for rule in config.prefixes:
            if any(w.lower() == token_lower for w in rule.words):
                skip_indices.add(i)
                if rule.prepend:
                    prefix_prepend = rule.prepend
                if rule.append:
                    suffix_append = rule.append
        for rule in config.suffixes:
            if any(w.lower() == token_lower for w in rule.words):
                skip_indices.add(i)
                if rule.append:
                    suffix_append = rule.append
                if rule.prepend:
                    prefix_prepend = rule.prepend

    nodes = config.tree
    path: list[str] = []

    def _result(child: GraphNode, pos: int) -> MatchResult:
        cmd = child.command
        captured = None
        if child.text_capture and pos < len(original_tokens):
            kept = [t for i, t in enumerate(original_tokens[pos:], start=pos)
                    if i not in skip_indices]
            captured = " ".join(kept) if kept else None
        return MatchResult(
            child.type, cmd, text=captured,
            prefix=prefix_prepend, suffix=suffix_append,
        )

    def _action_results(names: list[str], pos: int) -> list[MatchResult]:
        return [
            _result(nodes[n], pos)
            for n in names
            if nodes.get(n) and nodes[n].type in ACTION_TYPES
        ]

    pos = 0
    current = list(start_connections)

    while pos < len(tokens):
        best_name: str | None = None
        best_len = 0

        # Pass 1: match branch node triggers (higher priority).
        branch_candidates = sorted(
            current,
            key=lambda name: -len(nodes.get(name).trigger.split())
            if nodes.get(name) else 0,
        )
        for child_name in branch_candidates:
            child = nodes.get(child_name)
            if child is None or child.type in ACTION_TYPES:
                continue
            kt = child.trigger.lower().split()
            if tokens[pos:pos + len(kt)] == kt:
                best_name = child_name
                best_len = len(kt)
                break

        if best_name is None:
            # Pass 2: no branch matched — execute all action nodes.
            results = _action_results(current, pos)
            if results:
                path.extend(current)
                return path, results

        if best_name is None:
            # No child matched — skip this token.
            pos += 1
            continue

        pos += best_len
        path.append(best_name)
        child = nodes[best_name]

        if child.type in ACTION_TYPES:
            # Action node reached — execute.
            return path, [_result(child, pos)]

        # Branch node — continue walking from its children.
        current = list(child.connections)
        continue

    # Tokens exhausted — execute all action nodes at current level.
    results = _action_results(current, pos)
    if results:
        path.extend(current)
    return path, results
