#!/usr/bin/env python3
# ===================================================================================
# WEHTTAMSNAPS - J.A.R.V.I.S. WELCOME APPLICATION
# Branded welcome screen for Arch Linux Niri workstation
# https://github.com/Crowdrocker
# ===================================================================================

import gi
gi.require_version('Gtk', '3.0')
gi.require_version('Gdk', '3.0')
from gi.repository import Gtk, Gdk, GdkPixbuf, GLib, Pango
import os
import json
import sys
import subprocess

class WehttamSnapsWelcome:
    def __init__(self):
        self.window = Gtk.Window()
        self.window.set_title("WehttamSnaps - J.A.R.V.I.S. Workstation")
        self.window.set_default_size(900, 700)
        self.window.set_position(Gtk.WindowPosition.CENTER)
        self.window.set_resizable(False)
        self.window.set_modal(False)
        self.window.set_keep_above(False)
        self.window.set_focus_on_map(False)
        self.window.set_type_hint(Gdk.WindowTypeHint.NORMAL)

        # J.A.R.V.I.S. themed colors
        self.jarvis_blue = "#00d4ff"
        self.jarvis_green = "#00ff88"
        self.jarvis_dark = "#0a0a0a"
        self.jarvis_medium = "#1a1a2e"
        self.jarvis_light = "#cdd6f4"

        # Create main container
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        main_box.set_margin_start(20)
        main_box.set_margin_end(20)
        main_box.set_margin_top(20)
        main_box.set_margin_bottom(30)

        # Add branding header
        self.add_branding_header(main_box)

        # Add WehttamSnaps logo
        self.add_welcome_image(main_box)

        # Add main content
        self.add_main_content(main_box)

        # Add buttons
        self.add_buttons(main_box)

        self.window.add(main_box)
        self.window.connect("destroy", self.on_window_destroy)
        self.window.show_all()

        # Play J.A.R.V.I.S. startup sound
        self.play_startup_sound()

    def add_branding_header(self, container):
        # Header with WehttamSnaps branding
        header_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        header_box.set_halign(Gtk.Align.CENTER)

        # Main title
        title_label = Gtk.Label()
        title_label.set_markup('<span size="28000" weight="bold" foreground="#00d4ff">WEHTTAMSNAPS</span>')
        title_label.set_halign(Gtk.Align.CENTER)
        header_box.pack_start(title_label, False, False, 0)

        # Subtitle
        subtitle_label = Gtk.Label()
        subtitle_label.set_markup('<span size="18000" foreground="#00ff88">J.A.R.V.I.S. Workstation</span>')
        subtitle_label.set_halign(Gtk.Align.CENTER)
        header_box.pack_start(subtitle_label, False, False, 0)

        # Description
        desc_label = Gtk.Label()
        desc_label.set_markup('<span size="12000" foreground="#cdd6f4">Photography • Gaming • Streaming</span>')
        desc_label.set_halign(Gtk.Align.CENTER)
        header_box.pack_start(desc_label, False, False, 0)

        # GitHub link
        github_label = Gtk.Label()
        github_label.set_markup('<span size="10000" foreground="#00d4ff"><a href="https://github.com/Crowdrocker">github.com/Crowdrocker</a></span>')
        github_label.set_halign(Gtk.Align.CENTER)
        github_label.connect("activate-link", self.on_github_clicked)
        header_box.pack_start(github_label, False, False, 0)

        container.pack_start(header_box, False, False, 0)

    def add_welcome_image(self, container):
        # Look for WehttamSnaps logo
        home_dir = os.environ.get("HOME") or os.path.expanduser("~")
        image_paths = [
            os.path.join(home_dir, ".local", "share", "wehttamsnaps", "images", "welcome.png"),
            os.path.join(home_dir, ".config", "wehttamsnaps", "assets", "images", "ws-logo.png"),
            "/usr/share/wehttamsnaps/wallpapers/jarvis-reactor.png"
        ]

        for image_path in image_paths:
            if os.path.exists(image_path):
                try:
                    pixbuf = GdkPixbuf.Pixbuf.new_from_file(image_path)
                    target_width = 600
                    scale_factor = target_width / pixbuf.get_width()
                    new_width = target_width
                    new_height = int(pixbuf.get_height() * scale_factor)
                    pixbuf = pixbuf.scale_simple(
                        new_width, new_height, GdkPixbuf.InterpType.BILINEAR
                    )

                    image = Gtk.Image.new_from_pixbuf(pixbuf)
                    image.set_halign(Gtk.Align.CENTER)
                    container.pack_start(image, False, False, 0)
                    break
                except Exception as e:
                    print(f"Could not load image {image_path}: {e}")

    def add_main_content(self, container):
        # Create scrollable content area
        scrolled_window = Gtk.ScrolledWindow()
        scrolled_window.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        scrolled_window.set_size_request(-1, 450)

        text_view = Gtk.TextView()
        text_view.set_editable(False)
        text_view.set_cursor_visible(False)
        text_view.set_wrap_mode(Gtk.WrapMode.WORD)
        text_view.set_left_margin(40)
        text_view.set_right_margin(40)
        text_view.set_top_margin(20)
        text_view.set_bottom_margin(20)

        # Set font
        font_desc = Pango.FontDescription()
        font_desc.set_family("Fira Code")
        font_desc.set_size(12 * Pango.SCALE)
        text_view.override_font(font_desc)

        buffer = text_view.get_buffer()

        # Content sections
        content_parts = [
            f"Welcome to WehttamSnaps v{self.get_version()} - J.A.R.V.I.S. Integrated Workstation\n\n",
            "This Arch Linux Niri workstation is optimized for photography, gaming, and streaming. "
            "Built with precision and J.A.R.V.I.S. intelligence for maximum productivity and performance.\n\n",
            "🚀 QUICK START\n\n",
            "Essential Shortcuts:\n",
            "• SUPER + Space     → Application Launcher (J.A.R.V.I.S.)\n",
            "• SUPER + Enter     → Ghostty Terminal\n",
            "• SUPER + B         → Brave Browser\n",
            "• SUPER + F         → File Manager\n",
            "• SUPER + H         → Help & Keybinds\n",
            "• SUPER + Shift + G → Toggle Gaming Mode\n",
            "• SUPER + C         → Control Center\n",
            "• Print             → Screenshot\n",
            "• SUPER + Print     → Region Screenshot\n\n",
            "🎮 GAMING OPTIMIZATIONS\n\n",
            "• Gaming mode: Maximum performance with J.A.R.V.I.S. alerts\n",
            "• Steam launch options configured for your game library\n",
            "• Audio routing for separate game and voice channels\n",
            "• Performance monitoring with temperature alerts\n",
            "• RX 580 optimized for Linux gaming\n\n",
            "🎵 AUDIO SYSTEM\n\n",
            "• Virtual sinks for streaming (Game, Browser, Discord, Music)\n",
            "• Voicemeeter-like routing with qpwgraph\n",
            "• J.A.R.V.I.S. sound integration for system events\n",
            "• Easy audio control GUI available\n\n",
            "🎨 PHOTOGRAPHY TOOLS\n\n",
            "• Darktable and RawTherapee for RAW processing\n",
            "• GIMP and Inkscape for editing\n",
            "• Color-accurate display configuration\n",
            "• Organized workspace for photo management\n\n",
            "🎙️ STREAMING READY\n\n",
            "• OBS Studio with optimized settings\n",
            "• Audio routing for perfect stream mixing\n",
            "• Performance presets for different scenarios\n",
            "• Integrated with your streaming workflow\n\n",
            "🛠️ CUSTOMIZATION\n\n",
            "• J.A.R.V.I.S. themed DankMaterialShell\n",
            "• Ghostty terminal with Fira Code font\n",
            "• Starship prompt with gaming aliases\n",
            "• Fastfetch with system monitoring\n\n",
            "🔧 SYSTEM FEATURES\n\n",
            "• Arch Linux CachyOS kernel for performance\n",
            "• PipeWire audio system with advanced routing\n",
            "• Gamemode for automatic performance tuning\n",
            "• Zsh with powerful completions and plugins\n\n",
            "💡 J.A.R.V.I.S. INTEGRATION\n\n",
            "• Startup and shutdown voice feedback\n",
            "• Gaming mode activation announcements\n",
            "• Temperature and system warnings\n",
            "• Notification sound system\n\n",
            "Your WehttamSnaps workstation is ready for anything!\n\n",
        ]

        # Insert content
        iter_end = buffer.get_end_iter()
        for part in content_parts:
            buffer.insert(iter_end, part)
            iter_end = buffer.get_end_iter()

        # Add signature
        signature_tag = buffer.create_tag("signature", scale=1.2, foreground=self.jarvis_green)
        buffer.insert_with_tags(iter_end, "\n🎯 WehttamSnaps - Just Works!", signature_tag)
        iter_end = buffer.get_end_iter()

        buffer.insert(iter_end, "\n\n")
        iter_end = buffer.get_end_iter()

        # Add links
        github_tag = buffer.create_tag("github_link", foreground=self.jarvis_blue, underline=True)
        buffer.insert_with_tags(iter_end, "📦 Repository & Documentation", github_tag)
        iter_end = buffer.get_end_iter()

        buffer.insert(iter_end, " • ")
        iter_end = buffer.get_end_iter()

        gaming_tag = buffer.create_tag("gaming_link", foreground=self.jarvis_green, underline=True)
        buffer.insert_with_tags(iter_end, "🎮 Gaming Guide", gaming_tag)
        iter_end = buffer.get_end_iter()

        buffer.insert(iter_end, " • ")
        iter_end = buffer.get_end_iter()

        audio_tag = buffer.create_tag("audio_link", foreground=self.jarvis_blue, underline=True)
        buffer.insert_with_tags(iter_end, "🎵 Audio Setup", audio_tag)
        iter_end = buffer.get_end_iter()

        # Connect click events
        text_view.connect("button-press-event", self.on_text_clicked)

        scrolled_window.add(text_view)
        container.pack_start(scrolled_window, True, True, 0)

    def add_buttons(self, container):
        # Button container
        button_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=15)
        button_box.set_halign(Gtk.Align.FILL)
        button_box.set_margin_start(40)
        button_box.set_margin_end(40)

        # Quick Actions button
        quick_actions_btn = Gtk.Button(label="🚀 Quick Actions")
        quick_actions_btn.connect("clicked", self.show_quick_actions)
        quick_actions_btn.set_halign(Gtk.Align.START)
        button_box.pack_start(quick_actions_btn, False, False, 0)

        # Spacer
        spacer = Gtk.Box()
        button_box.pack_start(spacer, True, True, 0)

        # Gaming Mode button
        gaming_btn = Gtk.Button(label="🎮 Gaming Mode")
        gaming_btn.connect("clicked", self.toggle_gaming_mode)
        gaming_btn.set_halign(Gtk.Align.END)
        button_box.pack_start(gaming_btn, False, False, 0)

        # Close button
        close_btn = Gtk.Button(label="Close")
        close_btn.connect("clicked", self.on_close)
        close_btn.set_halign(Gtk.Align.END)
        button_box.pack_start(close_btn, False, False, 0)

        container.pack_start(button_box, False, False, 0)

    def play_startup_sound(self):
        # Play J.A.R.V.I.S. startup sound
        try:
            sound_script = os.path.expanduser("~/.config/wehttamsnaps/scripts/jarvis-sound-manager.sh")
            if os.path.exists(sound_script):
                subprocess.Popen([sound_script, "play", "startup", "0.8"])
        except Exception as e:
            print(f"Could not play startup sound: {e}")

    def get_version(self):
        # Get version from file or return default
        home_dir = os.environ.get("HOME") or os.path.expanduser("~")
        version_path = os.path.join(home_dir, ".local", "share", "wehttamsnaps", "VERSION")

        try:
            if os.path.exists(version_path):
                with open(version_path, "r") as f:
                    return f.read().strip()
        except:
            pass

        return "1.0.0"

    def on_github_clicked(self, label, uri):
        os.system(f"xdg-open {uri} &")
        return True

    def on_text_clicked(self, text_view, event):
        if event.button == 1:  # Left click
            x, y = text_view.window_to_buffer_coords(
                Gtk.TextWindowType.WIDGET, int(event.x), int(event.y)
            )
            iter_result = text_view.get_iter_at_location(x, y)

            if iter_result[0]:
                iter_pos = iter_result[1]
                tags = iter_pos.get_tags()

                for tag in tags:
                    if hasattr(tag, "get_property"):
                        tag_name = tag.get_property("name")
                        if tag_name == "github_link":
                            os.system("xdg-open https://github.com/Crowdrocker &")
                            return True
                        elif tag_name == "gaming_link":
                            self.show_gaming_guide()
                            return True
                        elif tag_name == "audio_link":
                            self.show_audio_setup()
                            return True

        return False

    def show_quick_actions(self, button):
        # Create quick actions dialog
        dialog = Gtk.MessageDialog(
            parent=self.window,
            flags=Gtk.DialogFlags.MODAL,
            type=Gtk.MessageType.INFO,
            buttons=Gtk.ButtonsType.CLOSE,
            message_format="J.A.R.V.I.S. Quick Actions"
        )

        dialog.format_secondary_text(
            "Available Quick Actions:\n\n"
            "• Gaming Mode Toggle: SUPER + Shift + G\n"
            "• Audio Control: Run audio-control-gui.py\n"
            "• Performance Monitor: gaming-performance-monitor.sh\n"
            "• System Update: Update alias in terminal\n"
            "• Keybinds Help: SUPER + H"
        )

        dialog.run()
        dialog.destroy()

    def toggle_gaming_mode(self, button):
        # Toggle gaming mode
        try:
            gaming_script = os.path.expanduser("~/.config/wehttamsnaps/scripts/gaming-mode.sh")
            if os.path.exists(gaming_script):
                subprocess.Popen([gaming_script, "toggle"])
                self.show_notification("Gaming Mode", "Toggling J.A.R.V.I.S. Gaming Mode...")
        except Exception as e:
            print(f"Could not toggle gaming mode: {e}")

    def show_gaming_guide(self):
        # Open gaming optimization guide
        guide_path = os.path.expanduser("~/.config/wehttamsnaps/docs/steam-optimization-guide.md")
        if os.path.exists(guide_path):
            os.system(f"xdg-open {guide_path} &")

    def show_audio_setup(self):
        # Open audio setup GUI
        audio_script = os.path.expanduser("~/.config/wehttamsnaps/scripts/audio-control-gui.py")
        if os.path.exists(audio_script):
            subprocess.Popen([audio_script])

    def show_notification(self, title, message):
        try:
            subprocess.Popen(["notify-send", title, message])
        except:
            pass

    def on_dismiss_forever(self, button):
        # Create config directory
        config_dir = os.path.expanduser("~/.config/wehttamsnaps")
        os.makedirs(config_dir, exist_ok=True)

        # Save dismissed state
        welcome_config = {"dismissed": True, "timestamp": GLib.get_real_time()}
        config_file = os.path.join(config_dir, "welcome.json")

        try:
            with open(config_file, "w") as f:
                json.dump(welcome_config, f, indent=2)
            print("WehttamSnaps welcome dismissed forever")
        except Exception as e:
            print(f"Error saving welcome config: {e}")

        Gtk.main_quit()

    def on_close(self, button):
        Gtk.main_quit()

    def on_window_destroy(self, widget):
        Gtk.main_quit()


def should_show_welcome():
    config_file = os.path.expanduser("~/.config/wehttamsnaps/welcome.json")

    if not os.path.exists(config_file):
        return True

    try:
        with open(config_file, "r") as f:
            config = json.load(f)
        return not config.get("dismissed", False)
    except:
        return True


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "--force":
        pass  # Force show
    elif not should_show_welcome():
        print("WehttamSnaps welcome has been dismissed")
        return

    # Apply J.A.R.V.I.S. themed CSS
    css_provider = Gtk.CssProvider()
    css_data = """
    * {
        font-family: "Fira Code", monospace;
    }

    window {
        background: linear-gradient(135deg, #0a0a0a 0%, #1a1a2e 50%, #0a0a0a 100%);
        color: #cdd6f4;
        font-family: "Fira Code", monospace;
    }

    label {
        color: #cdd6f4;
        font-family: "Fira Code", monospace;
    }

    textview {
        background: rgba(10, 10, 10, 0.95);
        color: #cdd6f4;
        border: 1px solid #00d4ff;
        font-family: "Fira Code", monospace;
        border-radius: 8px;
    }

    textview text {
        background: rgba(10, 10, 10, 0.95);
        color: #cdd6f4;
        font-family: "Fira Code", monospace;
    }

    button {
        background: linear-gradient(135deg, #1a1a2e 0%, #00d4ff 100%);
        color: #ffffff;
        border: none;
        border-radius: 8px;
        padding: 12px 20px;
        font-weight: bold;
        min-width: 120px;
        min-height: 40px;
        font-family: "Fira Code", monospace;
        box-shadow: 0 2px 8px rgba(0, 212, 255, 0.3);
    }

    button:hover {
        background: linear-gradient(135deg, #00d4ff 0%, #00ff88 100%);
        box-shadow: 0 4px 12px rgba(0, 212, 255, 0.5);
    }

    scrolledwindow {
        border: none;
        background: rgba(10, 10, 10, 0.9);
        border-radius: 8px;
    }

    scrollbar {
        background: #1a1a2e;
        border: none;
    }

    scrollbar slider {
        background: #00d4ff;
        border: none;
        border-radius: 4px;
    }

    scrollbar slider:hover {
        background: #00ff88;
    }
    """

    css_provider.load_from_data(css_data.encode())
    screen = Gdk.Screen.get_default()
    Gtk.StyleContext.add_provider_for_screen(
        screen, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER
    )

    WehttamSnapsWelcome()
    Gtk.main()


if __name__ == "__main__":
    main()