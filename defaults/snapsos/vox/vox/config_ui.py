"""GTK graphical configuration editor for vox — trigger-on-node graph model.

Provides:
- :class:`SettingsDialog` — global settings (wake word, aliases, terminal, filters, triggers).
- :class:`ConfigUI` — main editor window with a flowchart view, node property editor,
  and daemon launch/stop button.
"""

from __future__ import annotations
import subprocess
import copy
from pathlib import Path

import gi
gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gtk, Gdk, GLib, Pango

from .models import GraphNode, ImmediateTrigger, AffixRule

ACTION_TYPES = {"exec", "shell_exec", "type"}
from .config_manager import load_config, save_config
from .flowchart_view import FlowchartView

_HELP_TEXTS: dict[str, tuple[str, str]] = {
    "node_types": (
        "Node types",
        "branch      — Routes to connected child nodes.\n"
        "exec        — Runs a shell command in the background (text capture auto-enabled).\n"
        "shell_exec  — Opens a terminal and runs the command inside (text capture auto-enabled).\n"
        "type        — Types text via ydotool (Wayland & X11) (text capture auto-enabled).",
    ),
    "text_capture": (
        "Text capture ({text})",
        "For action nodes (exec/shell_exec/type), all remaining words in the utterance\n"
        "after the trigger are captured and substituted into ``{text}`` in the command.",
    ),
    "prefixes": (
        "Prefix rules",
        "When any trigger word appears ANYWHERE in the utterance,\n"
        "the prepend string is added before the matched command.",
    ),
    "suffixes": (
        "Suffix rules",
        "When any trigger word appears ANYWHERE in the utterance,\n"
        "the append string is added after the matched command.",
    ),
    "triggers": (
        "Immediate triggers",
        "Exact whole-utterance matches that fire BEFORE the graph is walked.",
    ),
    "terminal": (
        "Terminal",
        "The terminal emulator used by shell_exec actions.",
    ),
    "flowchart": (
        "Flowchart view",
        "Visual graph editor:\n"
        "\u2022 Colour-coded node types (exec=green, type=blue, shell_exec=orange, branch=grey).\n"
        "\u2022 Node label shows the trigger word that must be spoken.\n"
        "\u2022 Click to select, drag body to move, right-click for menu.\n"
        "\u2022 Drag from right port to left port to create a connection.\n"
        "\u2022 Drag empty space to pan, scroll to zoom.",
    ),
}


class SettingsDialog(Gtk.Dialog):
    """Modal dialog with three settings tabs: Terminal, Filters, Triggers."""

    def __init__(self, parent: Gtk.Window, config):
        super().__init__(title="Settings", parent=parent, flags=0,
                         buttons=(Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
                                  Gtk.STOCK_OK, Gtk.ResponseType.OK))
        self.set_default_size(550, 500)

        notebook = Gtk.Notebook()
        self.get_content_area().pack_start(notebook, True, True, 0)

        # ── Tab 1: Terminal ─────────────────────────────────────────────────
        tab1 = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8, margin=12)
        notebook.append_page(tab1, Gtk.Label(label="Terminal"))

        row = Gtk.Box(spacing=6)
        row.pack_start(Gtk.Label(label="Terminal command:", xalign=0), False, False, 0)
        self._term_entry = Gtk.Entry()
        self._term_entry.set_tooltip_text("Terminal emulator for shell_exec actions")
        self._term_entry.set_text(config.terminal)
        row.pack_start(self._term_entry, True, True, 0)
        row.pack_start(ConfigUI._make_help_button("terminal"), False, False, 0)
        tab1.pack_start(row, False, False, 0)

        help_lbl = Gtk.Label(label="Used by shell_exec actions.\n"
                              "Examples: gnome-terminal, konsole, alacritty, kitty",
                             xalign=0, justify=Gtk.Justification.LEFT)
        help_lbl.set_opacity(0.6)
        tab1.pack_start(help_lbl, False, False, 0)

        row2 = Gtk.Box(spacing=6, margin_top=8)
        row2.pack_start(Gtk.Label(label="Exec prefix:", xalign=0), False, False, 0)
        self._exec_prefix_entry = Gtk.Entry()
        self._exec_prefix_entry.set_tooltip_text(
            "Prepended to all exec actions (e.g. \"mmsg dispatch spawn_shell,\")"
        )
        self._exec_prefix_entry.set_text(config.exec_prefix)
        row2.pack_start(self._exec_prefix_entry, True, True, 0)
        tab1.pack_start(row2, False, False, 0)

        tab1.pack_start(Gtk.Label(), True, True, 0)

        # ── Tab 2: Filters ──────────────────────────────────────────────────
        tab2 = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6, margin=12)
        notebook.append_page(tab2, Gtk.Label(label="Filters"))

        row = Gtk.Box(spacing=4)
        row.pack_start(Gtk.Label(label="Prefixes (word \u2192 prepend to command):",
                         xalign=0, margin_top=6), False, False, 0)
        row.pack_start(ConfigUI._make_help_button("prefixes"), False, False, 0)
        tab2.pack_start(row, False, False, 0)
        self._prefix_store = Gtk.ListStore(str, str)
        self._prefix_view = self._make_affix_view(self._prefix_store, ["Words", "Prepend"])
        sw = Gtk.ScrolledWindow()
        sw.set_min_content_height(80)
        sw.add(self._prefix_view)
        tab2.pack_start(sw, True, True, 0)

        bar = Gtk.Box(spacing=4)
        btn = Gtk.Button(label="+ Add prefix")
        btn.connect("clicked", lambda _: self._add_affix_row(self._prefix_store))
        bar.pack_start(btn, False, False, 0)
        btn = Gtk.Button(label="\u2212 Remove selected")
        btn.connect("clicked", lambda _: self._remove_selected(self._prefix_view))
        bar.pack_start(btn, False, False, 0)
        tab2.pack_start(bar, False, False, 0)

        for p in config.prefixes:
            self._prefix_store.append([", ".join(p.words), p.prepend])

        row = Gtk.Box(spacing=4)
        row.pack_start(Gtk.Label(label="Suffixes (word \u2192 append to command):",
                         xalign=0, margin_top=8), False, False, 0)
        row.pack_start(ConfigUI._make_help_button("suffixes"), False, False, 0)
        tab2.pack_start(row, False, False, 0)
        self._suffix_store = Gtk.ListStore(str, str)
        self._suffix_view = self._make_affix_view(self._suffix_store, ["Words", "Append"])
        sw = Gtk.ScrolledWindow()
        sw.set_min_content_height(80)
        sw.add(self._suffix_view)
        tab2.pack_start(sw, True, True, 0)

        bar = Gtk.Box(spacing=4)
        btn = Gtk.Button(label="+ Add suffix")
        btn.connect("clicked", lambda _: self._add_affix_row(self._suffix_store))
        bar.pack_start(btn, False, False, 0)
        btn = Gtk.Button(label="\u2212 Remove selected")
        btn.connect("clicked", lambda _: self._remove_selected(self._suffix_view))
        bar.pack_start(btn, False, False, 0)
        tab2.pack_start(bar, False, False, 0)

        for s in config.suffixes:
            self._suffix_store.append([", ".join(s.words), s.append])

        # ── Tab 4: Immediate Triggers ───────────────────────────────────────
        tab3 = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6, margin=12)
        notebook.append_page(tab3, Gtk.Label(label="Triggers"))

        row = Gtk.Box(spacing=4)
        row.pack_start(
            Gtk.Label(label="Immediate triggers fire on exact word match, bypassing the graph.",
                      xalign=0), False, False, 0)
        row.pack_start(ConfigUI._make_help_button("triggers"), False, False, 0)
        tab3.pack_start(row, False, False, 0)

        self._trigger_store = Gtk.ListStore(str, str, str)
        self._trigger_view = Gtk.TreeView(model=self._trigger_store)
        self._trigger_view.set_headers_visible(True)
        for i, title in enumerate(["Trigger word", "Type", "Command"]):
            render = Gtk.CellRendererText()
            col = Gtk.TreeViewColumn(title, render, text=i)
            col.set_resizable(True)
            if i == 2:
                col.set_expand(True)
            self._trigger_view.append_column(col)

        sw = Gtk.ScrolledWindow()
        sw.set_min_content_height(120)
        sw.add(self._trigger_view)
        tab3.pack_start(sw, True, True, 0)

        bar = Gtk.Box(spacing=4)
        btn = Gtk.Button(label="+ Add trigger")
        btn.connect("clicked", lambda _: self._add_trigger())
        bar.pack_start(btn, False, False, 0)
        btn = Gtk.Button(label="\u2212 Remove selected")
        btn.connect("clicked", lambda _: self._remove_selected(self._trigger_view))
        bar.pack_start(btn, False, False, 0)
        tab3.pack_start(bar, False, False, 0)

        for t in config.immediate_triggers:
            self._trigger_store.append([t.word, t.type, t.command])

        self.show_all()

    def _make_affix_view(self, store, titles: list[str]) -> Gtk.TreeView:
        view = Gtk.TreeView(model=store)
        view.set_headers_visible(True)
        for i, title in enumerate(titles):
            render = Gtk.CellRendererText()
            render.set_property("editable", True)
            render.connect("edited", self._on_affix_edited, store, i)
            col = Gtk.TreeViewColumn(title, render, text=i)
            col.set_resizable(True)
            if i == 0:
                col.set_expand(True)
            view.append_column(col)
        return view

    def _on_affix_edited(self, render, path_str, new_text, store, col_idx):
        store[path_str][col_idx] = new_text

    def _add_affix_row(self, store):
        store.append(["", ""])

    def _remove_selected(self, view):
        sel = view.get_selection()
        model, tree_iter = sel.get_selected()
        if tree_iter is not None:
            model.remove(tree_iter)

    def _add_trigger(self):
        dialog = Gtk.Dialog(title="New trigger", parent=self, flags=0,
                            buttons=(Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
                                     Gtk.STOCK_OK, Gtk.ResponseType.OK))
        box = dialog.get_content_area()
        grid = Gtk.Grid(column_spacing=6, row_spacing=6, margin=8)
        grid.attach(Gtk.Label(label="Word:", xalign=0), 0, 0, 1, 1)
        word_e = Gtk.Entry()
        grid.attach(word_e, 1, 0, 1, 1)
        grid.attach(Gtk.Label(label="Type:", xalign=0), 0, 1, 1, 1)
        type_c = Gtk.ComboBoxText()
        for t in ("exec", "shell_exec", "type"):
            type_c.append_text(t)
        type_c.set_active(0)
        grid.attach(type_c, 1, 1, 1, 1)
        grid.attach(Gtk.Label(label="Command:", xalign=0), 0, 2, 1, 1)
        cmd_e = Gtk.Entry()
        grid.attach(cmd_e, 1, 2, 1, 1)
        box.add(grid)
        dialog.show_all()

        if dialog.run() == Gtk.ResponseType.OK:
            w = word_e.get_text().strip()
            t = type_c.get_active_text()
            c = cmd_e.get_text().strip()
            if w:
                self._trigger_store.append([w, t, c])
        dialog.destroy()

    def apply(self, config) -> None:
        config.terminal = self._term_entry.get_text().strip()
        config.exec_prefix = self._exec_prefix_entry.get_text().strip()

        config.prefixes = []
        for row in self._prefix_store:
            words = [w.strip() for w in row[0].split(",") if w.strip()]
            prepend = row[1].strip()
            if words:
                config.prefixes.append(AffixRule(words=words, prepend=prepend))

        config.suffixes = []
        for row in self._suffix_store:
            words = [w.strip() for w in row[0].split(",") if w.strip()]
            append = row[1].strip()
            if words:
                config.suffixes.append(AffixRule(words=words, append=append))

        config.immediate_triggers = []
        for row in self._trigger_store:
            word, typ, cmd = row[0].strip(), row[1].strip(), row[2].strip()
            if word and typ and cmd:
                config.immediate_triggers.append(
                    ImmediateTrigger(word=word, type=typ, command=cmd)
                )


def run_config_ui(config_path: Path) -> None:
    ConfigUI(config_path)
    Gtk.main()


class ConfigUI:
    """Main configuration editor for the trigger-on-node command graph.

    Layout::

        ┌──────────────────────────────────────────────────────────────┐
        │  Toolbar: Save | Settings | New Node | Validate | Daemon     │
        ├───────────────────────────┬──────────────────────────────────┤
        │  Flowchart View           │  Node Properties                │
        │  (colour-coded,           │  Trigger: [______________]       │
        │   drag to connect)        │  Name: [______________]          │
        │                           │  Type: [branch  v]  [?]         │
        │                           │  Command: [______________]       │
        │                           │  [+ Add node]  [Delete node]    │
        ├───────────────────────────┴──────────────────────────────────┤
        │  Root connections: [child1] [−] [+]                          │
        └──────────────────────────────────────────────────────────────┘
    """

    def __init__(self, config_path: Path):
        self.config_path = config_path
        self.config = load_config(config_path)
        self._selected_name: str | None = None
        self._ignore_edits = False
        self._daemon_running = False
        self._clipboard: tuple[str, GraphNode] | None = None
        self._build_ui()
        self._clear_panel()
        self._flowchart_set_config()
        self.window.show_all()

    # ── UI Build ──────────────────────────────────────────────────────────────

    def _build_ui(self) -> None:
        self.window = Gtk.Window(title=f"vox config \u2014 {self.config_path.name}")
        self.window.set_default_size(1050, 700)
        self.window.connect("destroy", lambda _: self._on_destroy())
        self.window.connect("key-press-event", self._on_key_press)

        css = b"""
        treeview.view {
            font-family: "Fira Code", "Noto Sans Mono", monospace;
            font-size: 13px;
        }
        treeview.view:selected {
            font-weight: bold;
        }
        .node-badge {
            font-size: 10px;
            padding: 1px 5px;
            border-radius: 3px;
            font-weight: bold;
        }
        """
        provider = Gtk.CssProvider()
        provider.load_from_data(css)
        Gtk.StyleContext.add_provider_for_screen(
            self.window.get_screen(), provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        self.window.add(vbox)

        self._build_toolbar(vbox)

        paned = Gtk.Paned(orientation=Gtk.Orientation.VERTICAL)
        vbox.pack_start(paned, True, True, 0)

        self._build_tree_panel(paned)
        self._build_editor_panel(paned)

    def _build_toolbar(self, parent: Gtk.Box) -> None:
        bar = Gtk.Toolbar()
        bar.set_style(Gtk.ToolbarStyle.BOTH)

        btn_save = Gtk.ToolButton.new_from_stock(Gtk.STOCK_SAVE)
        btn_save.set_tooltip_text("Save config")
        btn_save.connect("clicked", lambda _: self._on_save())
        bar.insert(btn_save, 0)

        sep1 = Gtk.SeparatorToolItem()
        bar.insert(sep1, 1)

        btn_settings = Gtk.ToolButton(label="Settings")
        btn_settings.set_icon_name("preferences-system-symbolic")
        btn_settings.set_tooltip_text("Global config: terminal, filters, triggers")
        btn_settings.connect("clicked", lambda _: self._on_settings())
        bar.insert(btn_settings, 2)

        btn_new = Gtk.ToolButton.new_from_stock(Gtk.STOCK_NEW)
        btn_new.set_tooltip_text("Add a new node to the graph")
        btn_new.connect("clicked", lambda _: self._on_add_node())
        bar.insert(btn_new, 3)

        btn_validate = Gtk.ToolButton.new_from_stock(Gtk.STOCK_YES)
        btn_validate.set_tooltip_text("Validate config")
        btn_validate.connect("clicked", lambda _: self._on_validate())
        bar.insert(btn_validate, 4)

        btn_autolayout = Gtk.ToolButton(label="Auto-layout")
        btn_autolayout.set_icon_name("view-grid-symbolic")
        btn_autolayout.set_tooltip_text("Reset all node positions to auto-layout")
        btn_autolayout.connect("clicked", lambda _: self._on_auto_layout())
        bar.insert(btn_autolayout, 5)

        btn_test = Gtk.ToolButton(label="Test")
        btn_test.set_icon_name("media-playback-start-symbolic")
        btn_test.set_tooltip_text("Test a spoken string against the graph")
        btn_test.connect("clicked", lambda _: self._on_test_string())
        bar.insert(btn_test, 6)

        btn_help = Gtk.ToolButton.new_from_stock(Gtk.STOCK_HELP)
        btn_help.set_tooltip_text("Help overview")
        btn_help.connect("clicked", lambda _: self._show_help_dialog("flowchart"))
        bar.insert(btn_help, 7)

        sep2 = Gtk.SeparatorToolItem()
        bar.insert(sep2, 8)

        self.btn_daemon = Gtk.ToolButton(label="Launch daemon")
        self.btn_daemon.set_icon_name("media-playback-start-symbolic")
        self.btn_daemon.set_tooltip_text("Start vox daemon (background voice listener)")
        self.btn_daemon.connect("clicked", lambda _: self._on_toggle_daemon())
        bar.insert(self.btn_daemon, 9)

        self.daemon_status = Gtk.Label(label="")
        self.daemon_status.set_margin_left(8)
        ti = Gtk.ToolItem()
        ti.add(self.daemon_status)
        bar.insert(ti, 10)

        parent.pack_start(bar, False, False, 0)

    def _build_tree_panel(self, paned: Gtk.Paned) -> None:
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        scrolled.set_min_content_width(380)

        self.flowchart = FlowchartView()
        self.flowchart.set_callbacks(
            on_select=self._on_flowchart_select,
            on_context=self._on_flowchart_context,
            on_graph_changed=self._on_flowchart_changed,
        )
        scrolled.add(self.flowchart)
        paned.pack1(scrolled, resize=True, shrink=False)

    def _on_flowchart_select(self, name: str) -> None:
        self._selected_name = name
        self._display_node(name)

    def _on_flowchart_context(self, name: str, event: Gdk.EventButton) -> None:
        self._selected_name = name
        self._show_context_menu(event)

    def _on_flowchart_changed(self) -> None:
        if self._selected_name and self._selected_name in self.config.tree:
            self._display_node(self._selected_name)

    def _build_editor_panel(self, paned: Gtk.Paned) -> None:
        frame = Gtk.Frame(label="Node Properties")
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6, margin=8)
        frame.add(box)

        # ── Trigger (branch only) ──────────────────────────────────────────
        self._trig_row = Gtk.Box(spacing=4)
        self._trig_row.pack_start(Gtk.Label(label="Trigger", xalign=0), False, False, 0)
        self.trigger_entry = Gtk.Entry()
        self.trigger_entry.set_tooltip_text(
            "The spoken keyword to reach this node (e.g. \"open\", \"search for\")"
        )
        self.trigger_entry.connect("changed", lambda _: self._on_edit())
        self._trig_row.pack_start(self.trigger_entry, True, True, 0)
        box.pack_start(self._trig_row, False, False, 0)

        # ── Name (action only) ─────────────────────────────────────────────
        self._name_row = Gtk.Box(spacing=4)
        self._name_row.pack_start(Gtk.Label(label="Name", xalign=0), False, False, 0)
        self.name_entry = Gtk.Entry()
        self.name_entry.set_tooltip_text("The name of this node (unique identifier)")
        self.name_entry.connect("changed", lambda _: self._on_edit())
        self._name_row.pack_start(self.name_entry, True, True, 0)
        box.pack_start(self._name_row, False, False, 0)

        # ── Type combo + help ──────────────────────────────────────────────
        row = Gtk.Box(spacing=4)
        row.pack_start(Gtk.Label(label="Type", xalign=0), False, False, 0)
        self.type_combo = Gtk.ComboBoxText()
        self.type_combo.set_tooltip_text("What happens when this node is reached")
        for t in ("branch", "exec", "shell_exec", "type"):
            self.type_combo.append(t, t)
        self.type_combo.set_active(0)
        self.type_combo.connect("changed", lambda _: self._on_type_changed())
        row.pack_start(self.type_combo, True, True, 0)
        row.pack_start(self._make_help_button("node_types"), False, False, 0)
        box.pack_start(row, False, False, 0)

        # ── Wake word (root only) ──────────────────────────────────────────
        self._wake_row = Gtk.Box(spacing=4)
        self._wake_row.pack_start(Gtk.Label(label="Wake word", xalign=0), False, False, 0)
        self.wake_entry = Gtk.Entry()
        self.wake_entry.set_tooltip_text("Phrase that activates this root's command tree")
        self.wake_entry.connect("changed", lambda _: self._on_edit())
        self._wake_row.pack_start(self.wake_entry, True, True, 0)
        box.pack_start(self._wake_row, False, False, 0)

        # ── Aliases (root only) ────────────────────────────────────────────
        self._aliases_row = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        self._aliases_row.pack_start(
            Gtk.Label(label="Aliases (one per line):", xalign=0), False, False, 0)
        self._aliases_buf = Gtk.TextBuffer()
        self._aliases_buf.connect("changed", lambda: self._on_edit())
        tv = Gtk.TextView(buffer=self._aliases_buf)
        tv.set_halign(Gtk.Align.FILL)
        sw = Gtk.ScrolledWindow()
        sw.set_min_content_height(60)
        sw.set_size_request(-1, 60)
        sw.add(tv)
        self._aliases_row.pack_start(sw, True, True, 0)
        box.pack_start(self._aliases_row, True, True, 0)

        # ── Command / String (action only) ─────────────────────────────────
        self._cmd_row = Gtk.Box(spacing=4)
        self._cmd_label = Gtk.Label(label="Command", xalign=0)
        self._cmd_row.pack_start(self._cmd_label, False, False, 0)
        self.command_entry = Gtk.Entry()
        self.command_entry.set_tooltip_text(
            "The shell command (for exec/shell_exec/type). Use {text} for captured text."
        )
        self.command_entry.connect("changed", lambda _: self._on_edit())
        self._cmd_row.pack_start(self.command_entry, True, True, 0)
        self._cmd_help = self._make_help_button("text_capture")
        self._cmd_row.pack_start(self._cmd_help, False, False, 0)
        box.pack_start(self._cmd_row, False, False, 0)

        # ── Node action buttons ────────────────────────────────────────────
        sep = Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL)
        sep.set_margin_top(6)
        box.pack_start(sep, False, False, 0)

        btn_row = Gtk.Box(spacing=4, margin_top=4)
        self._btn_add_node = Gtk.Button(label="+ Add node")
        self._btn_add_node.set_tooltip_text(
            "Add a new downstream node (auto-connected to this branch)")
        self._btn_add_node.connect("clicked", lambda _: self._on_add_node())
        btn_row.pack_start(self._btn_add_node, True, True, 0)
        btn_del_node = Gtk.Button(label="Delete node")
        btn_del_node.set_tooltip_text("Delete this node (with confirmation)")
        btn_del_node.connect("clicked", lambda _: self._on_delete_node())
        btn_row.pack_start(btn_del_node, True, True, 0)
        box.pack_start(btn_row, False, False, 0)

        paned.pack2(frame, resize=False, shrink=False)

    # ── Help button helpers ─────────────────────────────────────────────────

    @staticmethod
    def _make_help_button(topic: str) -> Gtk.Button:
        btn = Gtk.Button(label="?")
        btn.set_tooltip_text(f"Help: {_HELP_TEXTS[topic][0]}")
        style = btn.get_style_context()
        style.add_class("node-badge")
        btn.set_size_request(22, 22)
        btn.set_relief(Gtk.ReliefStyle.NONE)
        btn.connect("clicked", lambda _: ConfigUI._show_help_dialog(topic))
        return btn

    @staticmethod
    def _show_help_dialog(topic: str) -> None:
        title, body = _HELP_TEXTS.get(topic, ("Help", "No help available."))
        dialog = Gtk.MessageDialog(
            parent=None,
            flags=Gtk.DialogFlags.MODAL,
            type=Gtk.MessageType.INFO,
            buttons=Gtk.ButtonsType.OK,
            message_format=body,
        )
        dialog.set_title(f"Help \u2014 {title}")
        dialog.run()
        dialog.destroy()

    # ── Data helpers ──────────────────────────────────────────────────────────

    def _flowchart_set_config(self) -> None:
        self.flowchart.set_config(self.config)

    def _find_node(self, name: str) -> GraphNode | None:
        return self.config.tree.get(name)

    # ── Node editor signals ───────────────────────────────────────────────────

    def _display_node(self, name: str) -> None:
        node = self._find_node(name)
        if node is None:
            return
        self._ignore_edits = True

        is_root = node.type == "root"
        is_action = node.type in ("exec", "shell_exec", "type")

        self._trig_row.set_visible(not is_root and not is_action)
        self._trig_row.set_sensitive(True)
        self.trigger_entry.set_text(node.trigger if not is_root else "")
        self.trigger_entry.set_sensitive(not is_root)

        self._name_row.set_visible(not is_root and is_action)
        self._name_row.set_sensitive(True)
        self.name_entry.set_text(name)
        self.name_entry.set_sensitive(not is_root)

        self._wake_row.set_visible(is_root)
        self._wake_row.set_sensitive(True)
        self.wake_entry.set_text(node.wake_word)
        self.wake_entry.set_sensitive(True)

        self._aliases_row.set_visible(is_root)
        self._aliases_buf.set_text("\n".join(node.aliases))

        self.type_combo.set_sensitive(not is_root)
        self.type_combo.set_active_id(node.type)

        self._cmd_row.set_visible(not is_root and is_action)
        self._cmd_row.set_sensitive(True)
        self.command_entry.set_text(node.command)
        self.command_entry.set_sensitive(is_action)
        if node.type == "type":
            self._cmd_label.set_text("String")
        else:
            self._cmd_label.set_text("Command")

        self._btn_add_node.set_visible(is_root or not is_action)

        self._ignore_edits = False

    def _clear_panel(self) -> None:
        self._ignore_edits = True
        self._selected_name = None
        self._trig_row.set_visible(True)
        self.trigger_entry.set_text("")
        self.trigger_entry.set_sensitive(False)
        self._name_row.set_visible(True)
        self.name_entry.set_text("")
        self.name_entry.set_sensitive(False)
        self._wake_row.set_visible(False)
        self.wake_entry.set_text("")
        self._aliases_row.set_visible(False)
        self._aliases_buf.set_text("")
        self.type_combo.set_active(-1)
        self._cmd_row.set_visible(False)
        self.command_entry.set_text("")
        self.command_entry.set_sensitive(False)
        self._cmd_label.set_text("Command")
        self._ignore_edits = False

    def _on_type_changed(self) -> None:
        if self._ignore_edits or self._selected_name is None:
            return
        node = self._find_node(self._selected_name)
        if node is None:
            return
        typ = self.type_combo.get_active_id() or "branch"
        if node.type == "root" or typ == "root":
            return
        is_action = typ in ("exec", "shell_exec", "type")

        self._trig_row.set_visible(not is_action)
        self._name_row.set_visible(is_action)
        self._cmd_row.set_visible(is_action)

        if is_action:
            self._cmd_label.set_text("String" if typ == "type" else "Command")

        self._on_edit()

    def _on_edit(self) -> None:
        if self._ignore_edits or self._selected_name is None:
            return
        node = self._find_node(self._selected_name)
        if node is None:
            return

        new_name = self.name_entry.get_text().strip()
        old_name = self._selected_name

        # Rename (only for non-root nodes; root nodes renamed via the flowchart).
        if node.type != "root" and new_name and new_name != old_name:
            if new_name in self.config.tree:
                self._show_message(f"Node '{new_name}' already exists.")
                return
            if old_name in self.config.tree:
                del self.config.tree[old_name]
            self.config.tree[new_name] = node
            for other in self.config.tree.values():
                other.connections = [
                    new_name if c == old_name else c for c in other.connections
                ]
            self._selected_name = new_name

        if node.type == "root":
            node.wake_word = self.wake_entry.get_text().strip()
            aliases_text = self._aliases_buf.get_text(
                self._aliases_buf.get_start_iter(),
                self._aliases_buf.get_end_iter(), True
            )
            node.aliases = [a.strip() for a in aliases_text.split("\n") if a.strip()]
        else:
            node.trigger = self.trigger_entry.get_text().strip()
            node.type = self.type_combo.get_active_id() or "branch"
            node.command = self.command_entry.get_text().strip()
            node.text_capture = "{text}" in node.command or "{url_text}" in node.command

        self.flowchart.rebuild()

    def _on_add_connection(self) -> None:
        if self._selected_name is None:
            return
        dialog = Gtk.Dialog(
            title="New connection",
            parent=self.window,
            flags=0,
        )
        dialog.add_buttons(Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
                           Gtk.STOCK_OK, Gtk.ResponseType.OK)
        dialog.set_default_size(280, 120)

        box = dialog.get_content_area()
        lbl = Gtk.Label(label="Target node name:")
        lbl.set_margin_top(12)
        box.pack_start(lbl, False, False, 0)
        entry = Gtk.Entry()
        entry.set_margin_left(12)
        entry.set_margin_right(12)
        entry.set_margin_bottom(12)
        entry.set_placeholder_text("e.g. \"firefox\"")
        box.pack_start(entry, False, False, 0)
        dialog.show_all()

        if dialog.run() == Gtk.ResponseType.OK:
            target = entry.get_text().strip()
            if target:
                self._conn_store.append([target])
                self._on_edit()
        dialog.destroy()

    def _on_remove_connection(self) -> None:
        sel = self._conn_view.get_selection()
        model, it = sel.get_selected()
        if it is not None:
            model.remove(it)
            self._on_edit()

    def _rebuild_view(self) -> None:
        if self._selected_name:
            self._display_node(self._selected_name)
        self.flowchart.rebuild()

    # ── Context menu ──────────────────────────────────────────────────────────

    def _show_context_menu(self, event: Gdk.EventButton) -> None:
        menu = Gtk.Menu()

        item_add = Gtk.MenuItem(label="Add node")
        item_add.connect("activate", lambda _: self._on_add_node())
        menu.append(item_add)

        item_del = Gtk.MenuItem(label="Delete node")
        item_del.connect("activate", lambda _: self._on_delete_node())
        menu.append(item_del)

        menu.show_all()
        menu.popup(None, None, None, None, event.button, event.time)

    # ── Actions ───────────────────────────────────────────────────────────────

    def _on_add_node(self) -> None:
        dialog = Gtk.Dialog(
            title="New node",
            parent=self.window,
            flags=0,
        )
        dialog.add_buttons(Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
                           Gtk.STOCK_OK, Gtk.ResponseType.OK)
        dialog.set_default_size(360, 260)

        box = dialog.get_content_area()
        grid = Gtk.Grid(column_spacing=6, row_spacing=6, margin=8)

        # Type selector
        grid.attach(Gtk.Label(label="Type", xalign=0), 0, 0, 1, 1)
        type_combo = Gtk.ComboBoxText()
        for t in ("root", "branch", "exec", "shell_exec", "type"):
            type_combo.append(t, t)
        type_combo.set_active_id("branch")
        grid.attach(type_combo, 1, 0, 1, 1)

        # Wake word (root only)
        wake_lbl = Gtk.Label(label="Wake word", xalign=0)
        grid.attach(wake_lbl, 0, 1, 1, 1)
        wake_entry = Gtk.Entry()
        wake_entry.set_placeholder_text("activation phrase, e.g. \"computer\"")
        grid.attach(wake_entry, 1, 1, 1, 1)

        # Trigger (branch only)
        trig_lbl = Gtk.Label(label="Trigger", xalign=0)
        grid.attach(trig_lbl, 0, 2, 1, 1)
        trig_entry = Gtk.Entry()
        trig_entry.set_placeholder_text("spoken keyword, e.g. \"open\"")
        grid.attach(trig_entry, 1, 2, 1, 1)

        # Name (action only)
        name_lbl = Gtk.Label(label="Name", xalign=0)
        grid.attach(name_lbl, 0, 3, 1, 1)
        name_entry = Gtk.Entry()
        name_entry.set_placeholder_text("unique identifier, e.g. \"firefox_exec\"")
        grid.attach(name_entry, 1, 3, 1, 1)

        # Command / String (action only)
        cmd_lbl = Gtk.Label(label="Command", xalign=0)
        grid.attach(cmd_lbl, 0, 4, 1, 1)
        cmd_entry = Gtk.Entry()
        cmd_entry.set_placeholder_text("shell command or text, use {text} for capture")
        grid.attach(cmd_entry, 1, 4, 1, 1)

        def _on_type_changed(cb):
            typ = cb.get_active_id() or "branch"
            is_root = typ == "root"
            is_action = typ in ("exec", "shell_exec", "type")
            wake_lbl.set_visible(is_root)
            wake_entry.set_visible(is_root)
            trig_lbl.set_visible(not is_root and not is_action)
            trig_entry.set_visible(not is_root and not is_action)
            name_lbl.set_visible(not is_root and is_action)
            name_entry.set_visible(not is_root and is_action)
            cmd_lbl.set_visible(not is_root and is_action)
            cmd_entry.set_visible(not is_root and is_action)
            if typ == "type":
                cmd_lbl.set_text("String")
            else:
                cmd_lbl.set_text("Command")

        box.add(grid)
        dialog.show_all()

        # Default: branch
        wake_lbl.set_visible(False)
        wake_entry.set_visible(False)
        name_lbl.set_visible(False)
        name_entry.set_visible(False)
        cmd_lbl.set_visible(False)
        cmd_entry.set_visible(False)

        type_combo.connect("changed", lambda cb: _on_type_changed(cb))
        type_combo.set_active_id("branch")

        if dialog.run() == Gtk.ResponseType.OK:
            typ = type_combo.get_active_id() or "branch"
            name = name_entry.get_text().strip()
            trigger = trig_entry.get_text().strip()
            command = cmd_entry.get_text().strip()
            wake = wake_entry.get_text().strip()
            is_root = typ == "root"
            is_action = typ in ("exec", "shell_exec", "type")

            if is_root and not wake:
                self._show_message("Root node needs a wake word.")
                dialog.destroy()
                return
            if is_action and not name:
                self._show_message("Action node needs a name.")
                dialog.destroy()
                return
            if not is_root and not is_action and not trigger:
                self._show_message("Branch node needs a trigger word.")
                dialog.destroy()
                return

            if is_root:
                node_name = wake.replace(" ", "_")
            else:
                node_name = name if is_action else trigger.replace(" ", "_")
            if node_name in self.config.tree:
                self._show_message(f"Node '{node_name}' already exists.")
                dialog.destroy()
                return

            node = GraphNode(
                type=typ, trigger=trigger, command=command, wake_word=wake,
            )
            # Give new node a visible position.
            max_y = max((n.pos_y or 0) for n in self.config.tree.values()) if self.config.tree else 0
            node.pos_x = 60.0
            node.pos_y = max_y + 80.0
            self.config.tree[node_name] = node
            # Auto-connect from parent (root or branch).
            if (self._selected_name
                  and self.config.tree.get(self._selected_name)):
                parent = self.config.tree[self._selected_name]
                if parent.type not in ACTION_TYPES:
                    parent.connections.append(node_name)
            self._selected_name = node_name
            self._rebuild_view()
        dialog.destroy()

    def _on_delete_node(self) -> None:
        if self._selected_name is None:
            return
        name = self._selected_name
        dialog = Gtk.MessageDialog(
            parent=self.window,
            flags=Gtk.DialogFlags.MODAL,
            type=Gtk.MessageType.QUESTION,
            buttons=Gtk.ButtonsType.YES_NO,
            message_format=f"Delete node '{name}'?\n"
                           "All connections TO this node will also be removed.",
        )
        if dialog.run() == Gtk.ResponseType.YES:
            if name in self.config.tree:
                del self.config.tree[name]
            for node in self.config.tree.values():
                node.connections = [c for c in node.connections if c != name]
            self._selected_name = None
            self._rebuild_view()
        dialog.destroy()

    # ── Keyboard shortcuts ───────────────────────────────────────────────────

    def _on_key_press(self, _w, event: Gdk.EventKey) -> bool:
        # Let text-entry widgets handle their own key events (paste, copy, etc.).
        focused = self.window.get_focus()
        if isinstance(focused, (Gtk.Entry, Gtk.TextView)):
            return False

        ctrl = event.state & Gdk.ModifierType.CONTROL_MASK

        if event.keyval == Gdk.KEY_Delete or event.keyval == Gdk.KEY_KP_Delete:
            self._on_delete_node()
            return True

        if ctrl and event.keyval in (Gdk.KEY_c, Gdk.KEY_C):
            self._on_copy_node()
            return True

        if ctrl and event.keyval in (Gdk.KEY_v, Gdk.KEY_V):
            self._on_paste_node()
            return True

        return False

    def _on_copy_node(self) -> None:
        if self._selected_name is None:
            return
        src = self.config.tree.get(self._selected_name)
        if src is None:
            return
        self._clipboard = (self._selected_name, copy.deepcopy(src))

    def _on_paste_node(self) -> None:
        if self._clipboard is None:
            return
        orig_name, node = self._clipboard

        new_name = orig_name + " copy"
        if new_name in self.config.tree:
            i = 2
            while f"{orig_name} copy {i}" in self.config.tree:
                i += 1
            new_name = f"{orig_name} copy {i}"

        new_node = copy.deepcopy(node)

        if new_node.pos_x is not None:
            new_node.pos_x += 40
        if new_node.pos_y is not None:
            new_node.pos_y += 40

        new_node.connections = []

        self.config.tree[new_name] = new_node
        self._selected_name = new_name
        self._rebuild_view()

    def _on_save(self) -> None:
        save_config(self.config, self.config_path)
        self._show_message("Config saved.")

    def _on_validate(self) -> None:
        errors = []

        for name, node in self.config.tree.items():
            if node.type not in ("root", "branch", "exec", "shell_exec", "type"):
                errors.append(f"Unknown type '{node.type}' in node '{name}'")
            if node.type == "root" and not node.wake_word:
                errors.append(f"Root node '{name}' has no wake word")
            if node.type in ("exec", "shell_exec", "type") and not node.command:
                errors.append(f"Empty command in action node '{name}'")
            if node.type in ("exec", "shell_exec", "type") and node.connections:
                errors.append(f"Action node '{name}' has outgoing connections (must be terminal)")
            for conn in node.connections:
                if conn not in self.config.tree:
                    errors.append(
                        f"Broken connection: '{name}' \u2192 '{conn}' (does not exist)"
                    )

        if errors:
            self._show_message("\n".join(errors[:15]))
        else:
            self._show_message("Config is valid \u2713")

    # ── Auto-layout ────────────────────────────────────────────────────────────

    def _on_auto_layout(self) -> None:
        self.flowchart.run_auto_layout()
        self._on_flowchart_changed()

    # ── String tester ──────────────────────────────────────────────────────────

    def _on_test_string(self) -> None:
        """Open a dialog to test a spoken string against the graph."""
        from .command_tree import trace_path, strip_punctuation, strip_wake_word

        dialog = Gtk.Dialog(
            title="Test string",
            parent=self.window,
            flags=0,
        )
        dialog.add_buttons(Gtk.STOCK_CLOSE, Gtk.ResponseType.CLOSE)
        dialog.set_default_size(480, 400)

        vbox = dialog.get_content_area()
        vbox.set_spacing(6)

        row = Gtk.Box(spacing=4, margin=8, margin_bottom=0)
        lbl = Gtk.Label(label="Full utterance (with optional wake word):")
        row.pack_start(lbl, False, False, 0)
        vbox.pack_start(row, False, False, 0)

        row = Gtk.Box(spacing=4, margin=8, margin_top=0)
        entry = Gtk.Entry()
        entry.set_hexpand(True)
        entry.set_placeholder_text(
            "e.g. \"computer launch firefox\" or \"system command open calc\"")
        row.pack_start(entry, True, True, 0)
        run_btn = Gtk.Button(label="Run")
        row.pack_start(run_btn, False, False, 0)
        vbox.pack_start(row, False, False, 0)

        scrolled = Gtk.ScrolledWindow()
        scrolled.set_min_content_height(220)

        buf = Gtk.TextBuffer()
        tv = Gtk.TextView(buffer=buf)
        tv.set_editable(False)
        tv.set_cursor_visible(False)
        tv.set_wrap_mode(Gtk.WrapMode.WORD)
        tv.override_font(Pango.FontDescription("monospace 11"))
        tv.set_margin_left(8)
        tv.set_margin_right(8)
        tv.set_margin_top(4)
        tv.set_margin_bottom(4)
        scrolled.add(tv)
        vbox.pack_start(scrolled, True, True, 0)

        def _append(text: str, bold: bool = False) -> None:
            end = buf.get_end_iter()
            if bold:
                buf.insert_with_tags_by_name(end, text, "bold")
            else:
                buf.insert(end, text)

        # Set up bold tag
        bold_tag = buf.create_tag("bold", weight=Pango.Weight.BOLD)

        def _clear():
            buf.set_text("")
            self.flowchart.set_highlighted(set())

        def _run_test(*_):
            _clear()
            raw = entry.get_text().strip()
            if not raw:
                return
            text = strip_punctuation(raw)
            if not text:
                _append("(input was only punctuation)")
                return

            _append(f"Input: \"{text}\"\n")
            _append("─" * 40 + "\n")

            # Strip wake word — identifies which root matched.
            stripped, root_name = strip_wake_word(self.config, text)
            if root_name:
                _append(f"Wake word: \"{root_name}\" matched, stripped\n", bold=True)
                _append(f"After wake: \"{stripped}\"\n")
            else:
                _append(f"Wake word: none matched\n")

            if not stripped:
                _append("\n(empty after wake word — nothing to match)")
                return

            _append("─" * 40 + "\n")

            path, results = trace_path(self.config, stripped, root_name)

            # Show prefix/suffix rules that fired.
            prefixes_fired = set()
            suffixes_fired = set()
            for r in results:
                if r.prefix:
                    prefixes_fired.add(r.prefix)
                if r.suffix:
                    suffixes_fired.add(r.suffix)

            if prefixes_fired:
                for p in prefixes_fired:
                    _append(f"Prefix rule: \"{p}\"\n", bold=True)
            if suffixes_fired:
                for s in suffixes_fired:
                    _append(f"Suffix rule: \"{s}\"\n", bold=True)

            if not path and not results:
                _append("\nNo matching path found. The string did not\n"
                        "follow any route through the graph.")
                return

            # Show path.
            for i, node_name in enumerate(path):
                node = self.config.tree.get(node_name)
                if node is None:
                    _append(f"  {node_name}  (unknown)\n")
                    continue
                is_branch = node.type not in ("exec", "shell_exec", "type")
                if is_branch:
                    _append(f"  {node_name}  branch\u2192\"{node.trigger}\"\n")
                else:
                    _append(f"  {node_name}  {node.type}\n")

            if path:
                self.flowchart.set_highlighted(set(path))

            # Show action results.
            if results:
                _append("─" * 40 + "\n")
                if not path:
                    _append("Immediate execute (graph bypassed):\n", bold=True)
                else:
                    _append("Actions to execute:\n", bold=True)
                for r in results:
                    cmd = r.command
                    if r.text:
                        cmd = cmd.replace("{text}", f"\"{r.text}\"")
                    full = cmd
                    if r.prefix:
                        full = r.prefix + " " + full
                    if r.suffix:
                        full = full + " " + r.suffix
                    _append(f"  {r.action_type}: {full}\n")

        run_btn.connect("clicked", _run_test)
        entry.connect("activate", _run_test)

        dialog.show_all()
        dialog.run()
        self.flowchart.set_highlighted(set())
        dialog.destroy()

    # ── Settings dialog ───────────────────────────────────────────────────────

    def _on_settings(self) -> None:
        dialog = SettingsDialog(self.window, self.config)
        if dialog.run() == Gtk.ResponseType.OK:
            dialog.apply(self.config)
            save_config(self.config, self.config_path)
        dialog.destroy()
        self._rebuild_view()

    # ── Daemon launch/stop (via mmsg so it's not a child of the GUI) ──────────

    def _on_toggle_daemon(self) -> None:
        if self._daemon_running:
            self._stop_daemon()
        else:
            self._start_daemon()

    def _start_daemon(self) -> None:
        prefix = self.config.exec_prefix or ""
        subprocess.Popen(["sh", "-c", f"{prefix}vox daemon"],
                         start_new_session=True)
        self._daemon_running = True
        self.btn_daemon.set_label("Restart daemon")
        self.btn_daemon.set_tooltip_text("Restart the voice daemon")
        self.daemon_status.set_text("\u25cf running")
        self.daemon_status.override_color(
            Gtk.StateFlags.NORMAL, Gdk.RGBA(0.2, 0.8, 0.2, 1)
        )
        GLib.timeout_add(1000, self._poll_daemon)

    def _stop_daemon(self) -> None:
        subprocess.run(["pkill", "whisper-server"],
                       capture_output=True)
        self._daemon_running = False
        self.btn_daemon.set_label("Launch daemon")
        self.btn_daemon.set_icon_name("media-playback-start-symbolic")
        self.daemon_status.set_text("")

    def _poll_daemon(self) -> bool:
        if not self._daemon_running:
            return False
        ret = subprocess.run(
            ["pgrep", "whisper-server"],
            capture_output=True,
        )
        if ret.returncode != 0:
            self._daemon_running = False
            self.btn_daemon.set_label("Launch daemon")
            self.btn_daemon.set_icon_name("media-playback-start-symbolic")
            self.daemon_status.set_text("stopped")
            self.daemon_status.override_color(
                Gtk.StateFlags.NORMAL, Gdk.RGBA(0.8, 0.2, 0.2, 1)
            )
            return False
        return True

    def _on_destroy(self) -> None:
        self._stop_daemon()
        Gtk.main_quit()

    def _show_message(self, msg: str) -> None:
        dialog = Gtk.MessageDialog(
            parent=self.window,
            flags=Gtk.DialogFlags.MODAL,
            type=Gtk.MessageType.INFO,
            buttons=Gtk.ButtonsType.OK,
            message_format=msg,
        )
        dialog.run()
        dialog.destroy()
