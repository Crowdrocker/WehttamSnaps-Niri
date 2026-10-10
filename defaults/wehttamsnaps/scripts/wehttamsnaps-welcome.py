#!/usr/bin/env python3
"""
WehttamSnaps Welcome App v2.0
Modern welcome screen for Niri + Noctalia + JARVIS setup
GitHub: github.com/Crowdrocker
"""

import gi
gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gtk, Gdk, GdkPixbuf, GLib, Pango
import os
import json
import sys
import subprocess
from datetime import datetime


class WehttamSnapsWelcome:
    def __init__(self):
        self.window = Gtk.Window()
        self.window.set_title("Welcome to WehttamSnaps")
        self.window.set_default_size(1000, 800)
        self.window.set_position(Gtk.WindowPosition.CENTER)
        self.window.set_resizable(True)

        # Window properties
        self.window.set_modal(False)
        self.window.set_keep_above(False)
        self.window.set_focus_on_map(True)
        self.window.set_type_hint(Gdk.WindowTypeHint.DIALOG)

        # Main container
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)

        # Header
        self.add_header(main_box)

        # Notebook for tabs
        self.add_notebook(main_box)

        # Footer with buttons
        self.add_footer(main_box)

        self.window.add(main_box)
        self.window.connect("destroy", self.on_window_destroy)
        self.window.show_all()

        # Play startup sound
        self.play_startup_sound()

    def play_startup_sound(self):
        """Play J.A.R.V.I.S. startup sound"""
        sound_script = os.path.expanduser("~/.config/wehttamsnaps/scripts/sound-system")
        if os.path.exists(sound_script):
            try:
                subprocess.Popen([sound_script, "startup"],
                               stdout=subprocess.DEVNULL,
                               stderr=subprocess.DEVNULL)
            except:
                pass

    def add_header(self, container):
        """Add branded header"""
        header_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        header_box.set_margin_top(20)
        header_box.set_margin_bottom(20)

        # Title
        title = Gtk.Label()
        title.set_markup(
            '<span size="28000" weight="bold" foreground="#89b4fa">WehttamSnaps Niri Setup</span>'
        )
        header_box.pack_start(title, False, False, 0)

        # Subtitle
        subtitle = Gtk.Label()
        subtitle.set_markup(
            '<span size="12000" foreground="#cdd6f4">Photography • Gaming • Content Creation</span>'
        )
        header_box.pack_start(subtitle, False, False, 0)

        # Version
        version = Gtk.Label()
        version.set_markup(
            f'<span size="10000" foreground="#6c7086">v{self.get_version()} • Dell XPS 8700 • RX 580</span>'
        )
        header_box.pack_start(version, False, False, 0)

        container.pack_start(header_box, False, False, 0)

    def add_notebook(self, container):
        """Add tabbed notebook"""
        notebook = Gtk.Notebook()
        notebook.set_margin_start(20)
        notebook.set_margin_end(20)
        notebook.set_margin_bottom(10)

        # Quick Start Tab
        notebook.append_page(
            self.create_quickstart_page(),
            Gtk.Label(label="🚀 Quick Start")
        )

        # Workspaces Tab
        notebook.append_page(
            self.create_workspaces_page(),
            Gtk.Label(label="🗂️ Workspaces")
        )

        # Features Tab
        notebook.append_page(
            self.create_features_page(),
            Gtk.Label(label="⚡ Features")
        )

        # Tips Tab
        notebook.append_page(
            self.create_tips_page(),
            Gtk.Label(label="💡 Pro Tips")
        )

        container.pack_start(notebook, True, True, 0)

    def create_quickstart_page(self):
        """Create quick start page"""
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=15)
        box.set_margin_start(30)
        box.set_margin_end(30)
        box.set_margin_top(20)
        box.set_margin_bottom(20)

        # Essential shortcuts section
        self.add_section_title(box, "⌨️ Essential Shortcuts")

        shortcuts = [
            ("Mod + Space", "Application Launcher", "Noctalia launcher"),
            ("Mod + Enter", "Terminal", "Ghostty with Fira Code"),
            ("Mod + H", "KeyHints", "Show all keybindings"),
            ("Mod + B", "Browser", "Firefox"),
            ("Mod + E", "File Manager", "Thunar"),
            ("Mod + Q", "Close Window", "With J.A.R.V.I.S. sound"),
            ("Mod + G", "Gaming Mode", "Toggle performance mode"),
            ("Mod + 1-0", "Workspaces", "Switch between workspaces"),
        ]

        for key, desc, note in shortcuts:
            self.add_shortcut_row(box, key, desc, note)

        # Getting started section
        self.add_section_title(box, "🎯 Getting Started")

        steps = [
            "1. Press **Mod + Space** to open the application launcher",
            "2. Try **Mod + H** to see all keybindings",
            "3. Navigate workspaces with **Mod + 1-9**",
            "4. Launch apps: **Mod + B** (Browser), **Mod + Enter** (Terminal)",
            "5. Enable gaming mode with **Mod + G** for maximum performance",
        ]

        for step in steps:
            label = Gtk.Label()
            label.set_markup(f'<span foreground="#cdd6f4">{step}</span>')
            label.set_halign(Gtk.Align.START)
            label.set_line_wrap(True)
            label.set_margin_bottom(5)
            box.pack_start(label, False, False, 0)

        scrolled.add(box)
        return scrolled

    def create_workspaces_page(self):
        """Create workspaces page"""
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=15)
        box.set_margin_start(30)
        box.set_margin_end(30)
        box.set_margin_top(20)
        box.set_margin_bottom(20)

        self.add_section_title(box, "🗂️ 10 Organized Workspaces")

        workspaces = [
            ("1", "🌐 Browser", "Firefox, Brave - Web browsing"),
            ("2", "💻 Terminal", "Ghostty, Kate - Development"),
            ("3", "🎮 Gaming", "Steam, games - Pre-configured for RX 580"),
            ("4", "📺 Streaming", "OBS Studio - Recording/streaming"),
            ("5", "📸 Photography", "GIMP, Darktable, Krita - Photo workflow"),
            ("6", "🎬 Media", "Video editing, composites"),
            ("7", "💬 Communication", "Discord, social media"),
            ("8", "🎵 Music", "Spotify, audio production"),
            ("9", "📂 Files", "Thunar, file management"),
            ("10", "⚙️ Misc", "Overflow workspace"),
        ]

        for num, icon_name, desc in workspaces:
            self.add_workspace_row(box, num, icon_name, desc)

        # Add workspace tips
        self.add_section_title(box, "💡 Workspace Tips")

        tips = [
            "• Switch: **Mod + Number**",
            "• Move window: **Mod + Shift + Number**",
            "• Each workspace plays a sound when you switch (J.A.R.V.I.S.)",
            "• Gaming mode (Mod + G) switches to iDroid sound system",
        ]

        for tip in tips:
            label = Gtk.Label()
            label.set_markup(f'<span foreground="#cdd6f4">{tip}</span>')
            label.set_halign(Gtk.Align.START)
            label.set_margin_bottom(3)
            box.pack_start(label, False, False, 0)

        scrolled.add(box)
        return scrolled

    def create_features_page(self):
        """Create features page"""
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=15)
        box.set_margin_start(30)
        box.set_margin_end(30)
        box.set_margin_top(20)
        box.set_margin_bottom(20)

        # J.A.R.V.I.S. Section
        self.add_section_title(box, "🤖 J.A.R.V.I.S. Sound System")
        self.add_feature_text(box,
            "Adaptive sound system that switches between J.A.R.V.I.S. (Paul Bettany) "
            "and iDroid voices based on context:\n\n"
            "• **J.A.R.V.I.S. Mode**: Photography, desktop work\n"
            "• **iDroid Mode**: Gaming, high-performance tasks\n"
            "• **Auto-switching**: Changes based on workspace and activity\n"
            "• **Sound effects**: Startup, workspace switch, window close, screenshots"
        )

        # Photography Section
        self.add_section_title(box, "📸 Photography Workflow")
        self.add_feature_text(box,
            "Professional photo editing pipeline:\n\n"
            "1. **DigiKam**: Import and organize photos\n"
            "2. **Darktable**: RAW processing and development\n"
            "3. **GIMP**: Advanced editing and composites\n"
            "4. **Krita**: Digital painting and touch-ups\n"
            "5. **Export**: Ready for Twitch, YouTube, Instagram"
        )

        # Gaming Section
        self.add_section_title(box, "🎮 Gaming Optimizations")
        self.add_feature_text(box,
            "Pre-configured for AMD RX 580:\n\n"
            "• **16 Games Optimized**: Division 2, Cyberpunk, Fallout 4, Watch Dogs series\n"
            "• **Mesa Tweaks**: RADV_PERFTEST, mesa_glthread enabled\n"
            "• **Gaming Mode**: Disables animations, max CPU performance\n"
            "• **Proton GE**: Latest version via ProtonUp-Qt"
        )

        # Audio Section
        self.add_section_title(box, "🔊 Audio Routing")
        self.add_feature_text(box,
            "VoiceMeeter-like audio control with PipeWire:\n\n"
            "• **Separate channels**: Game, Browser, Discord, Spotify\n"
            "• **qpwgraph**: Visual audio routing (Mod + A)\n"
            "• **OBS Integration**: Route any app to stream\n"
            "• **Virtual sinks**: Professional audio management"
        )

        scrolled.add(box)
        return scrolled

    def create_tips_page(self):
        """Create pro tips page"""
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=15)
        box.set_margin_start(30)
        box.set_margin_end(30)
        box.set_margin_top(20)
        box.set_margin_bottom(20)

        self.add_section_title(box, "💡 Pro Tips")

        tips = [
            ("🎮 Gaming Performance",
             "Enable gaming mode (Mod + G) before launching games. "
             "This disables animations and sets CPU to performance mode."),

            ("📸 Photography Export",
             "Use Mod + Shift + E after saving photos - plays a sound and "
             "confirms your export is complete."),

            ("🔊 Audio Setup",
             "Launch qpwgraph (Mod + A) to visually route audio. "
             "Save your layouts for different scenarios."),

            ("🎨 Webapps",
             "Use Mod + Ctrl + Y/T/S/D for YouTube, Twitch, Spotify, Discord "
             "in floating windows with separate cookies."),

            ("⌨️ Keybinds",
             "Press Mod + H anytime to see the full keybindings cheat sheet."),

            ("🖥️ Screen Capture",
             "In OBS, add 'Screen Capture (PipeWire)' source. "
             "A portal dialog will let you select what to share."),

            ("🔄 Config Reload",
             "Modified Niri config? Reload with Mod + Shift + Ctrl + R"),

            ("📚 Documentation",
             "Full guides in ~/.config/wehttamsnaps/docs/ including "
             "GAMING.md, AUDIO-ROUTING.md, TROUBLESHOOTING.md"),
        ]

        for title, content in tips:
            self.add_tip_box(box, title, content)

        # Links section
        self.add_section_title(box, "🔗 Resources")

        links_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=20)
        links_box.set_halign(Gtk.Align.CENTER)
        links_box.set_margin_top(10)

        links = [
            ("📺 Twitch", "https://twitch.tv/WehttamSnaps"),
            ("🎬 YouTube", "https://youtube.com/@WehttamSnaps"),
            ("💻 GitHub", "https://github.com/Crowdrocker"),
        ]

        for name, url in links:
            btn = Gtk.LinkButton(uri=url, label=name)
            links_box.pack_start(btn, False, False, 0)

        box.pack_start(links_box, False, False, 0)

        scrolled.add(box)
        return scrolled

    def add_section_title(self, container, title):
        """Add section title"""
        label = Gtk.Label()
        label.set_markup(f'<span size="14000" weight="bold" foreground="#89b4fa">{title}</span>')
        label.set_halign(Gtk.Align.START)
        label.set_margin_top(10)
        label.set_margin_bottom(5)
        container.pack_start(label, False, False, 0)

    def add_shortcut_row(self, container, key, desc, note):
        """Add a shortcut row"""
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=15)
        box.set_margin_bottom(5)

        # Key
        key_label = Gtk.Label()
        key_label.set_markup(f'<span font_family="monospace" weight="bold" foreground="#f38ba8">{key}</span>')
        key_label.set_width_chars(20)
        key_label.set_halign(Gtk.Align.START)
        box.pack_start(key_label, False, False, 0)

        # Description
        desc_label = Gtk.Label()
        desc_label.set_markup(f'<span weight="bold" foreground="#cdd6f4">{desc}</span>')
        desc_label.set_width_chars(20)
        desc_label.set_halign(Gtk.Align.START)
        box.pack_start(desc_label, False, False, 0)

        # Note
        note_label = Gtk.Label()
        note_label.set_markup(f'<span foreground="#6c7086">{note}</span>')
        note_label.set_halign(Gtk.Align.START)
        box.pack_start(note_label, True, True, 0)

        container.pack_start(box, False, False, 0)

    def add_workspace_row(self, container, num, name, desc):
        """Add workspace row"""
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        box.set_margin_bottom(5)

        num_label = Gtk.Label()
        num_label.set_markup(f'<span font_family="monospace" weight="bold" foreground="#f9e2af">{num}</span>')
        num_label.set_width_chars(3)
        box.pack_start(num_label, False, False, 0)

        name_label = Gtk.Label()
        name_label.set_markup(f'<span weight="bold" foreground="#cdd6f4">{name}</span>')
        name_label.set_width_chars(18)
        name_label.set_halign(Gtk.Align.START)
        box.pack_start(name_label, False, False, 0)

        desc_label = Gtk.Label()
        desc_label.set_markup(f'<span foreground="#6c7086">{desc}</span>')
        desc_label.set_halign(Gtk.Align.START)
        box.pack_start(desc_label, True, True, 0)

        container.pack_start(box, False, False, 0)

    def add_feature_text(self, container, text):
        """Add feature description text"""
        label = Gtk.Label()
        label.set_markup(f'<span foreground="#cdd6f4">{text}</span>')
        label.set_halign(Gtk.Align.START)
        label.set_line_wrap(True)
        label.set_margin_bottom(10)
        container.pack_start(label, False, False, 0)

    def add_tip_box(self, container, title, content):
        """Add a tip box"""
        frame = Gtk.Frame()
        frame.set_margin_bottom(10)

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        box.set_margin_start(15)
        box.set_margin_end(15)
        box.set_margin_top(10)
        box.set_margin_bottom(10)

        title_label = Gtk.Label()
        title_label.set_markup(f'<span weight="bold" foreground="#89b4fa">{title}</span>')
        title_label.set_halign(Gtk.Align.START)
        box.pack_start(title_label, False, False, 0)

        content_label = Gtk.Label()
        content_label.set_markup(f'<span foreground="#cdd6f4">{content}</span>')
        content_label.set_halign(Gtk.Align.START)
        content_label.set_line_wrap(True)
        box.pack_start(content_label, False, False, 0)

        frame.add(box)
        container.pack_start(frame, False, False, 0)

    def add_footer(self, container):
        """Add footer with action buttons"""
        button_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        button_box.set_margin_start(20)
        button_box.set_margin_end(20)
        button_box.set_margin_bottom(20)

        # Dismiss forever
        dismiss_btn = Gtk.Button(label="Don't Show Again")
        dismiss_btn.connect("clicked", self.on_dismiss_forever)
        button_box.pack_start(dismiss_btn, False, False, 0)

        # Spacer
        button_box.pack_start(Gtk.Box(), True, True, 0)

        # Quick actions
        keybinds_btn = Gtk.Button(label="⌨️ KeyHints")
        keybinds_btn.connect("clicked", self.on_launch_keyhints)
        button_box.pack_start(keybinds_btn, False, False, 0)

        docs_btn = Gtk.Button(label="📚 Docs")
        docs_btn.connect("clicked", self.on_open_docs)
        button_box.pack_start(docs_btn, False, False, 0)

        config_btn = Gtk.Button(label="⚙️ Config Editor")
        config_btn.connect("clicked", self.on_open_config_editor)
        button_box.pack_start(config_btn, False, False, 0)

        # Get started
        start_btn = Gtk.Button(label="🚀 Get Started")
        start_btn.connect("clicked", self.on_close)
        button_box.pack_start(start_btn, False, False, 0)

        container.pack_start(button_box, False, False, 0)

    def on_dismiss_forever(self, button):
        """Don't show welcome again"""
        config_dir = os.path.expanduser("~/.config/wehttamsnaps")
        os.makedirs(config_dir, exist_ok=True)

        config = {
            "dismissed": True,
            "dismissed_at": datetime.now().isoformat(),
            "version": self.get_version()
        }

        try:
            with open(os.path.join(config_dir, "welcome.json"), "w") as f:
                json.dump(config, f, indent=2)
        except Exception as e:
            print(f"Error saving config: {e}")

        Gtk.main_quit()

    def on_launch_keyhints(self, button):
        """Launch keyhints script"""
        script = os.path.expanduser("~/.config/wehttamsnaps/scripts/KeyHints.sh")
        if os.path.exists(script):
            subprocess.Popen([script], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    def on_open_docs(self, button):
        """Open documentation folder"""
        docs = os.path.expanduser("~/.config/wehttamsnaps/docs")
        if os.path.exists(docs):
            subprocess.Popen(["thunar", docs], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    def on_open_config_editor(self, button):
        """Open Niri quick settings"""
        script = os.path.expanduser("~/.config/wehttamsnaps/scripts/niri-quick-settings.sh")
        if os.path.exists(script):
            subprocess.Popen([script], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    def on_close(self, button):
        """Close welcome screen"""
        Gtk.main_quit()

    def get_version(self):
        """Get version number"""
        paths = [
            "~/.config/wehttamsnaps/VERSION",
            "~/.local/share/wehttamsnaps/VERSION"
        ]
        for path in paths:
            expanded = os.path.expanduser(path)
            if os.path.exists(expanded):
                try:
                    with open(expanded) as f:
                        return f.read().strip()
                except:
                    pass
        return "2.0.0"

    def on_window_destroy(self, widget):
        """Handle window close"""
        Gtk.main_quit()


def should_show_welcome():
    """Check if welcome should be shown"""
    config_file = os.path.expanduser("~/.config/wehttamsnaps/welcome.json")
    if not os.path.exists(config_file):
        return True

    try:
        with open(config_file) as f:
            config = json.load(f)
        return not config.get("dismissed", False)
    except:
        return True


def main():
    """Main entry point"""
    if len(sys.argv) > 1 and sys.argv[1] == "--force":
        pass
    elif not should_show_welcome():
        print("Welcome screen dismissed")
        return

    # Apply CSS styling
    css = """
    * {
        font-family: "Fira Code", "Monospace", monospace;
    }

    window {
        background: #1e1e2e;
    }

    label {
        color: #cdd6f4;
    }

    button {
        background: #89b4fa;
        color: #1e1e2e;
        border: none;
        border-radius: 8px;
        padding: 8px 16px;
        font-weight: bold;
        min-height: 36px;
    }

    button:hover {
        background: #b4c8fa;
    }

    notebook {
        background: #1e1e2e;
    }

    notebook header {
        background: #313244;
    }

    notebook tab {
        background: #313244;
        color: #cdd6f4;
        padding: 8px 16px;
    }

    notebook tab:checked {
        background: #89b4fa;
        color: #1e1e2e;
    }

    frame {
        border: 1px solid #45475a;
        border-radius: 8px;
    }
    """

    provider = Gtk.CssProvider()
    provider.load_from_data(css.encode())
    Gtk.StyleContext.add_provider_for_screen(
        Gdk.Screen.get_default(),
        provider,
        Gtk.STYLE_PROVIDER_PRIORITY_USER
    )

    WehttamSnapsWelcome()
    Gtk.main()


if __name__ == "__main__":
    main()
