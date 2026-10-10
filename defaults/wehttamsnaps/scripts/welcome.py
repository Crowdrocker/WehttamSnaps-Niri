#!/usr/bin/env python3
"""
WehttamSnaps Welcome App v2.1
Welcome screen for XFCE + i3 + JARVIS setup
github.com/Crowdrocker  |  twitch.tv/WehttamSnaps
"""

import gi
gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gtk, Gdk, GLib, Pango
import os
import json
import sys
import subprocess
from datetime import datetime


# ── WehttamSnaps Cyberpunk Palette ────────────────────────────────────────
CYAN    = "#00ffd1"
BLUE    = "#3b82ff"
PINK    = "#ff5af1"
ORANGE  = "#ff6b1a"
RED     = "#ff1744"
GREEN   = "#00e676"
BG0     = "#06060f"
BG1     = "#0a0a1c"
BG2     = "#0e0e24"
BG3     = "#141428"
BORDER  = "#1a1a3a"
FG0     = "#c8d0e8"
FG1     = "#8890aa"
FG2     = "#3a4060"


class WehttamSnapsWelcome:
    def __init__(self):
        self.window = Gtk.Window()
        self.window.set_title("WehttamSnaps — Welcome")
        self.window.set_default_size(960, 720)
        self.window.set_position(Gtk.WindowPosition.CENTER)
        self.window.set_resizable(True)
        self.window.set_type_hint(Gdk.WindowTypeHint.DIALOG)

        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.add_header(main_box)
        self.add_notebook(main_box)
        self.add_footer(main_box)

        self.window.add(main_box)
        self.window.connect("destroy", lambda w: Gtk.main_quit())
        self.window.show_all()

        # Play JARVIS startup sound (non-blocking, safe to fail)
        self.play_startup_sound()

    # ── Sound ─────────────────────────────────────────────────────────────
    def play_startup_sound(self):
        for path in [
            "/usr/local/bin/sound-system",
            os.path.expanduser("~/.config/wehttamsnaps/scripts/sound-system"),
        ]:
            if os.path.exists(path):
                try:
                    subprocess.Popen(
                        [path, "startup"],
                        stdout=subprocess.DEVNULL,
                        stderr=subprocess.DEVNULL,
                    )
                except Exception:
                    pass
                break

    # ── Header ────────────────────────────────────────────────────────────
    def add_header(self, container):
        header = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        header.set_margin_top(24)
        header.set_margin_bottom(16)
        header.get_style_context().add_class("ws-header")

        title = Gtk.Label()
        title.set_markup(
            f'<span size="26000" weight="bold" foreground="{CYAN}">'
            f'WehttamSnaps</span>'
            f'<span size="26000" weight="bold" foreground="{FG0}"> // i3 Workstation</span>'
        )
        header.pack_start(title, False, False, 0)

        subtitle = Gtk.Label()
        subtitle.set_markup(
            f'<span size="11000" foreground="{FG1}">'
            f'Photography  •  Gaming  •  Content Creation</span>'
        )
        header.pack_start(subtitle, False, False, 0)

        meta = Gtk.Label()
        meta.set_markup(
            f'<span size="9000" foreground="{FG2}" font_family="monospace">'
            f'v{self.get_version()}  //  Dell XPS 8700  //  i7-4790  //  RX 580  //  Arch Linux</span>'
        )
        header.pack_start(meta, False, False, 0)

        # Cyan divider line
        sep = Gtk.Separator()
        sep.get_style_context().add_class("ws-sep")
        header.pack_start(sep, False, False, 0)

        container.pack_start(header, False, False, 0)

    # ── Notebook ──────────────────────────────────────────────────────────
    def add_notebook(self, container):
        nb = Gtk.Notebook()
        nb.set_margin_start(16)
        nb.set_margin_end(16)
        nb.set_margin_bottom(8)

        nb.append_page(self.page_quickstart(), Gtk.Label(label="⚡  Quick Start"))
        nb.append_page(self.page_workspaces(), Gtk.Label(label="🗂  Workspaces"))
        nb.append_page(self.page_features(),   Gtk.Label(label="🤖  Features"))
        nb.append_page(self.page_tips(),       Gtk.Label(label="💡  Pro Tips"))

        container.pack_start(nb, True, True, 0)

    # ── Page: Quick Start ─────────────────────────────────────────────────
    def page_quickstart(self):
        scroll, box = self._scrollbox()

        self._section(box, "⌨️  Essential Keybinds")
        shortcuts = [
            ("Super + D",           "App Launcher",       "Rofi — WehttamSnaps theme"),
            ("Super + Enter",       "Terminal",           "Ghostty"),
            ("Super + H",           "KeyHints",           "Full keybind cheat sheet"),
            ("Super + B",           "Browser",            "Brave"),
            ("Super + F",           "File Manager",       "Thunar"),
            ("Super + Q",           "Close Window",       "With JARVIS sound"),
            ("Super + Shift + G",   "Gaming Mode",        "Toggle iDroid / max perf"),
            ("Super + 1–0",         "Workspaces",         "Switch workspace"),
            ("Super + Shift + 1–0", "Move Window",        "Send to workspace"),
            ("Super + Mod1 + H/J/K/L", "Focus (vim)",     "Super + Alt + hjkl"),
            ("Print",               "Screenshot",         "Full screen → ~/Pictures/Screenshots"),
            ("Super + Print",       "Region Screenshot",  "Draw selection with slurp"),
        ]
        for key, desc, note in shortcuts:
            self._keybind_row(box, key, desc, note)

        self._section(box, "🎯  First Steps")
        steps = [
            "1.  Press <b>Super + D</b> to open the app launcher",
            "2.  Press <b>Super + H</b> to see every keybind",
            "3.  Use <b>Super + 1–9</b> to jump between workspaces",
            "4.  Toggle gaming mode with <b>Super + Shift + G</b>",
            "5.  Add your JARVIS sounds → <tt>/usr/share/wehttamsnaps/sounds/jarvis/</tt>",
        ]
        for s in steps:
            lbl = Gtk.Label()
            lbl.set_markup(f'<span foreground="{FG0}">{s}</span>')
            lbl.set_halign(Gtk.Align.START)
            lbl.set_line_wrap(True)
            lbl.set_margin_bottom(4)
            box.pack_start(lbl, False, False, 0)

        scroll.add(box)
        return scroll

    # ── Page: Workspaces ──────────────────────────────────────────────────
    def page_workspaces(self):
        scroll, box = self._scrollbox()
        self._section(box, "🗂  10 Organised Workspaces")

        workspaces = [
            ("1", "Browser",   "Brave — web browsing"),
            ("2", "Media",     "Video, music players"),
            ("3", "Gaming",    "Steam, Lutris — pre-configured for RX 580"),
            ("4", "Stream",    "OBS Studio — recording & streaming"),
            ("5", "Photo",     "Darktable, GIMP, DigiKam, Krita"),
            ("6", "Code",      "Kate, VSCode, terminals"),
            ("7", "Work",      "Documents, spreadsheets"),
            ("8", "Comm",      "Discord, email"),
            ("9", "Files",     "Thunar — file management"),
            ("10","System",    "Settings, htop, overflow"),
        ]
        for num, name, desc in workspaces:
            self._workspace_row(box, num, name, desc)

        self._section(box, "💡  Tips")
        for tip in [
            "• <b>Super + Number</b>  →  switch workspace",
            "• <b>Super + Shift + Number</b>  →  move window to workspace",
            "• Gaming workspace (3) auto-switches to iDroid sound profile",
            "• Photography workspace (5) keeps JARVIS voice active",
        ]:
            lbl = Gtk.Label()
            lbl.set_markup(f'<span foreground="{FG0}">{tip}</span>')
            lbl.set_halign(Gtk.Align.START)
            lbl.set_margin_bottom(3)
            box.pack_start(lbl, False, False, 0)

        scroll.add(box)
        return scroll

    # ── Page: Features ────────────────────────────────────────────────────
    def page_features(self):
        scroll, box = self._scrollbox()

        self._section(box, "🤖  J.A.R.V.I.S. Sound System")
        self._feature_text(box,
            "Adaptive audio that switches voice based on context:\n\n"
            "• <b>J.A.R.V.I.S. mode</b>  (Paul Bettany)  —  desktop, photography, work\n"
            "• <b>iDroid mode</b>  —  gaming, Steam, high-performance workspaces\n"
            "• Auto-switches on workspace change and gaming mode toggle\n"
            "• Sounds for: startup, shutdown, window close, screenshot, vol up/down\n\n"
            f'<span foreground="{FG2}" font_family="monospace" size="9000">'
            f"Add sounds → /usr/share/wehttamsnaps/sounds/jarvis/\n"
            f"Source     → 101soundboards.com (jarvis-v1-paul-bettany-tts)</span>"
        )

        self._section(box, "📸  Photography Workflow")
        self._feature_text(box,
            "1. <b>DigiKam</b>   — import and organise RAW files\n"
            "2. <b>Darktable</b> — RAW development and colour grading\n"
            "3. <b>GIMP</b>      — advanced compositing and retouching\n"
            "4. <b>Krita</b>     — digital painting and touch-ups\n"
            "5. Export         — ready for Twitch overlays, YouTube thumbnails, Instagram"
        )

        self._section(box, "🎮  Gaming Setup")
        self._feature_text(box,
            "Optimised for AMD RX 580 on Arch Linux:\n\n"
            "• <b>Gaming Mode</b>  (Super+Shift+G)  —  kills compositor, max CPU governor\n"
            "• <b>Steam Library</b>  →  /run/media/wehttamsnaps/LINUXDRIVE/SteamLibrary\n"
            "• <b>GE-Proton</b>  —  install latest via <tt>protonup-qt</tt>\n"
            "• <b>MO2 Linux Helper</b>  —  Cyberpunk 2077 and Fallout 4 mod manager\n"
            "• <b>Gamemode</b> daemon active for CPU performance boost"
        )

        self._section(box, "🔊  Audio Routing")
        self._feature_text(box,
            "PipeWire + qpwgraph for Voicemeeter-style routing:\n\n"
            "• Separate virtual sinks: Game / Browser / Music / Mic\n"
            "• Route each app to its own channel in OBS\n"
            "• Scroll the i3 bar to adjust master volume\n"
            "• Run <tt>~/.config/wehttamsnaps/scripts/audio-setup.sh</tt> to create virtual sinks"
        )

        scroll.add(box)
        return scroll

    # ── Page: Tips ────────────────────────────────────────────────────────
    def page_tips(self):
        scroll, box = self._scrollbox()
        self._section(box, "💡  Pro Tips")

        tips = [
            ("🎮  Gaming Performance",
             "Toggle gaming mode before launching games — kills picom compositor "
             "and sets CPU to performance governor for max FPS."),
            ("📸  Screenshot Workflow",
             "Press Print for fullscreen, Super+Print to draw a region. "
             "All shots land in ~/Pictures/Screenshots/ with a timestamp filename."),
            ("🔊  Audio Routing for Streams",
             "Open qpwgraph, create virtual sinks with audio-setup.sh, "
             "then route game/browser/mic to separate OBS sources."),
            ("🌐  Webapps",
             "Super+Shift+T/Y/D/S opens Twitch, YouTube, Discord, Spotify "
             "as isolated browser apps with separate cookies — no cross-contamination."),
            ("⌨️  Vim Keys",
             "Super+Alt+H/J/K/L moves focus — same muscle memory as vim/tmux. "
             "Arrow keys always work too."),
            ("🔄  Config Reload",
             "Edit ~/.config/i3/config then press Super+Shift+R to reload instantly. "
             "No need to log out."),
            ("📂  Mod Organizer 2",
             "MO2 Linux Helper is in your tools. "
             "Use GE-Proton + protontricks for Cyberpunk and Fallout 4 mods."),
            ("📚  Docs",
             "Full guides in ~/.config/wehttamsnaps/docs/ — "
             "XFCE-I3-SETUP.md, sound README files, and more."),
        ]

        for title, content in tips:
            self._tip_box(box, title, content)

        self._section(box, "🔗  WehttamSnaps")
        links_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=16)
        links_box.set_halign(Gtk.Align.CENTER)
        links_box.set_margin_top(8)
        for label, url in [
            ("📺  Twitch",  "https://twitch.tv/WehttamSnaps"),
            ("🎬  YouTube", "https://youtube.com/@WehttamSnaps"),
            ("💻  GitHub",  "https://github.com/Crowdrocker"),
        ]:
            btn = Gtk.LinkButton(uri=url, label=label)
            links_box.pack_start(btn, False, False, 0)
        box.pack_start(links_box, False, False, 0)

        scroll.add(box)
        return scroll

    # ── Footer ────────────────────────────────────────────────────────────
    def add_footer(self, container):
        sep = Gtk.Separator()
        container.pack_start(sep, False, False, 0)

        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        row.set_margin_start(16)
        row.set_margin_end(16)
        row.set_margin_top(10)
        row.set_margin_bottom(14)

        # Don't show again
        dismiss = Gtk.Button(label="Don't show again")
        dismiss.get_style_context().add_class("ws-btn-dim")
        dismiss.connect("clicked", self.on_dismiss_forever)
        row.pack_start(dismiss, False, False, 0)

        row.pack_start(Gtk.Box(), True, True, 0)  # spacer

        for label, cb in [
            ("⌨️  KeyHints",   self.on_keyhints),
            ("📚  Docs",       self.on_docs),
            ("🚀  Get Started", self.on_close),
        ]:
            btn = Gtk.Button(label=label)
            btn.get_style_context().add_class("ws-btn")
            btn.connect("clicked", cb)
            row.pack_start(btn, False, False, 0)

        container.pack_start(row, False, False, 0)

    # ── Button callbacks ──────────────────────────────────────────────────
    def on_dismiss_forever(self, _):
        cfg = os.path.expanduser("~/.config/wehttamsnaps")
        os.makedirs(cfg, exist_ok=True)
        try:
            with open(os.path.join(cfg, "welcome.json"), "w") as f:
                json.dump({"dismissed": True,
                           "dismissed_at": datetime.now().isoformat(),
                           "version": self.get_version()}, f, indent=2)
        except Exception as e:
            print(f"Could not save welcome state: {e}")
        Gtk.main_quit()

    def on_keyhints(self, _):
        for path in [
            os.path.expanduser("~/.config/wehttamsnaps/scripts/KeyHints.sh"),
            os.path.expanduser("~/.config/wehttamsnaps/scripts/wehttamsnaps-keyhints.sh"),
        ]:
            if os.path.exists(path):
                subprocess.Popen([path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                return

    def on_docs(self, _):
        docs = os.path.expanduser("~/.config/wehttamsnaps/docs")
        os.makedirs(docs, exist_ok=True)
        subprocess.Popen(["thunar", docs], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    def on_close(self, _):
        Gtk.main_quit()

    # ── Helpers ───────────────────────────────────────────────────────────
    def _scrollbox(self):
        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        box.set_margin_start(28)
        box.set_margin_end(28)
        box.set_margin_top(18)
        box.set_margin_bottom(18)
        return scroll, box

    def _section(self, container, title):
        lbl = Gtk.Label()
        lbl.set_markup(
            f'<span size="13000" weight="bold" foreground="{CYAN}">{title}</span>'
        )
        lbl.set_halign(Gtk.Align.START)
        lbl.set_margin_top(12)
        lbl.set_margin_bottom(6)
        container.pack_start(lbl, False, False, 0)

        sep = Gtk.Separator()
        sep.get_style_context().add_class("ws-sep-dim")
        container.pack_start(sep, False, False, 0)

    def _keybind_row(self, container, key, desc, note):
        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        row.set_margin_bottom(3)

        k = Gtk.Label()
        k.set_markup(
            f'<span font_family="monospace" weight="bold" foreground="{ORANGE}">{key}</span>'
        )
        k.set_width_chars(26)
        k.set_halign(Gtk.Align.START)
        row.pack_start(k, False, False, 0)

        d = Gtk.Label()
        d.set_markup(f'<span weight="bold" foreground="{FG0}">{desc}</span>')
        d.set_width_chars(22)
        d.set_halign(Gtk.Align.START)
        row.pack_start(d, False, False, 0)

        n = Gtk.Label()
        n.set_markup(f'<span foreground="{FG2}">{note}</span>')
        n.set_halign(Gtk.Align.START)
        row.pack_start(n, True, True, 0)

        container.pack_start(row, False, False, 0)

    def _workspace_row(self, container, num, name, desc):
        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        row.set_margin_bottom(4)

        n = Gtk.Label()
        n.set_markup(
            f'<span font_family="monospace" weight="bold" foreground="{CYAN}">{num:>2}</span>'
        )
        n.set_width_chars(4)
        row.pack_start(n, False, False, 0)

        nm = Gtk.Label()
        nm.set_markup(f'<span weight="bold" foreground="{FG0}">{name}</span>')
        nm.set_width_chars(12)
        nm.set_halign(Gtk.Align.START)
        row.pack_start(nm, False, False, 0)

        d = Gtk.Label()
        d.set_markup(f'<span foreground="{FG1}">{desc}</span>')
        d.set_halign(Gtk.Align.START)
        row.pack_start(d, True, True, 0)

        container.pack_start(row, False, False, 0)

    def _feature_text(self, container, text):
        lbl = Gtk.Label()
        lbl.set_markup(f'<span foreground="{FG0}">{text}</span>')
        lbl.set_halign(Gtk.Align.START)
        lbl.set_line_wrap(True)
        lbl.set_margin_bottom(8)
        container.pack_start(lbl, False, False, 0)

    def _tip_box(self, container, title, content):
        frame = Gtk.Frame()
        frame.get_style_context().add_class("ws-frame")
        frame.set_margin_bottom(8)

        inner = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        inner.set_margin_start(14)
        inner.set_margin_end(14)
        inner.set_margin_top(8)
        inner.set_margin_bottom(8)

        t = Gtk.Label()
        t.set_markup(f'<span weight="bold" foreground="{CYAN}">{title}</span>')
        t.set_halign(Gtk.Align.START)
        inner.pack_start(t, False, False, 0)

        c = Gtk.Label()
        c.set_markup(f'<span foreground="{FG1}">{content}</span>')
        c.set_halign(Gtk.Align.START)
        c.set_line_wrap(True)
        inner.pack_start(c, False, False, 0)

        frame.add(inner)
        container.pack_start(frame, False, False, 0)

    def get_version(self):
        for path in [
            "~/.config/wehttamsnaps/VERSION",
            "~/.local/share/wehttamsnaps/VERSION",
        ]:
            p = os.path.expanduser(path)
            if os.path.exists(p):
                try:
                    return open(p).read().strip()
                except Exception:
                    pass
        return "2.1.0"


# ── Should we show? ───────────────────────────────────────────────────────
def should_show():
    cfg = os.path.expanduser("~/.config/wehttamsnaps/welcome.json")
    if not os.path.exists(cfg):
        return True
    try:
        return not json.load(open(cfg)).get("dismissed", False)
    except Exception:
        return True


# ── CSS ───────────────────────────────────────────────────────────────────
CSS = f"""
* {{
    font-family: "JetBrains Mono", "Fira Code", monospace;
}}
window {{
    background-color: {BG0};
}}
.ws-header {{
    background-color: {BG1};
    border-bottom: 1px solid {BORDER};
    padding: 0 20px;
}}
notebook {{
    background-color: {BG0};
}}
notebook header {{
    background-color: {BG1};
    border-bottom: 1px solid {BORDER};
}}
notebook header tab {{
    background-color: transparent;
    color: {FG1};
    padding: 8px 18px;
    border: none;
}}
notebook header tab:checked {{
    background-color: {BG0};
    color: {CYAN};
    border-bottom: 2px solid {CYAN};
}}
notebook header tab:hover {{
    color: {FG0};
}}
scrolledwindow {{
    background-color: {BG0};
}}
viewport {{
    background-color: {BG0};
}}
.ws-sep {{
    background-color: {CYAN};
    min-height: 1px;
    opacity: 0.4;
    margin: 4px 20px;
}}
.ws-sep-dim {{
    background-color: {BORDER};
    min-height: 1px;
    margin-bottom: 4px;
}}
.ws-frame {{
    border: 1px solid {BORDER};
    border-radius: 3px;
    background-color: {BG1};
}}
.ws-btn {{
    background-color: {BG2};
    color: {CYAN};
    border: 1px solid {CYAN};
    border-radius: 2px;
    padding: 6px 14px;
    font-weight: bold;
    min-height: 32px;
}}
.ws-btn:hover {{
    background-color: rgba(0,255,209,0.15);
}}
.ws-btn-dim {{
    background-color: {BG1};
    color: {FG2};
    border: 1px solid {BORDER};
    border-radius: 2px;
    padding: 6px 14px;
    min-height: 32px;
}}
.ws-btn-dim:hover {{
    color: {FG1};
    border-color: {FG2};
}}
label {{
    color: {FG0};
}}
separator {{
    background-color: {BORDER};
    min-height: 1px;
}}
"""


def main():
    force = len(sys.argv) > 1 and sys.argv[1] == "--force"
    if not force and not should_show():
        print("Welcome screen dismissed — run with --force to show anyway")
        return

    provider = Gtk.CssProvider()
    provider.load_from_data(CSS.encode())
    Gtk.StyleContext.add_provider_for_screen(
        Gdk.Screen.get_default(),
        provider,
        Gtk.STYLE_PROVIDER_PRIORITY_USER,
    )

    WehttamSnapsWelcome()
    Gtk.main()


if __name__ == "__main__":
    main()
