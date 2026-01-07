#!/usr/bin/env python3

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gtk, Gdk, GdkPixbuf, GLib, Pango
import os
import json
import sys
import subprocess


class WelcomeWindow:
    def __init__(self):
        self.window = Gtk.Window()
        self.window.set_title("Welcome to WehttamSnaps")
        self.window.set_default_size(900, 700)
        self.window.set_position(Gtk.WindowPosition.CENTER)
        self.window.set_resizable(False)

        # Make window non-modal
        self.window.set_modal(False)
        self.window.set_keep_above(False)
        self.window.set_focus_on_map(False)
        self.window.set_type_hint(Gdk.WindowTypeHint.NORMAL)

        # Create main container
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=15)
        main_box.set_margin_start(0)
        main_box.set_margin_end(0)
        main_box.set_margin_top(0)
        main_box.set_margin_bottom(20)

        # Add banner placeholder
        self.add_banner(main_box)

        # Add main text
        self.add_main_text(main_box)

        # Add buttons
        self.add_buttons(main_box)

        self.window.add(main_box)
        self.window.connect("destroy", self.on_window_destroy)
        self.window.show_all()

    def add_banner(self, container):
        """Add cyberpunk banner - placeholder for custom image"""
        home_dir = os.path.expanduser("~")
        banner_path = os.path.join(
            home_dir, ".config", "wehttamsnaps", "images", "banner.png"
        )

        if os.path.exists(banner_path):
            try:
                pixbuf = GdkPixbuf.Pixbuf.new_from_file(banner_path)
                width = pixbuf.get_width()
                height = pixbuf.get_height()
                target_width = int(900 * 0.9)
                scale_factor = target_width / width
                new_width = target_width
                new_height = int(height * scale_factor)
                pixbuf = pixbuf.scale_simple(
                    new_width, new_height, GdkPixbuf.InterpType.BILINEAR
                )

                image = Gtk.Image.new_from_pixbuf(pixbuf)
                image.set_halign(Gtk.Align.CENTER)
                container.pack_start(image, False, False, 0)
            except Exception as e:
                print(f"Could not load banner: {e}")
                self.add_text_banner(container)
        else:
            self.add_text_banner(container)

    def add_text_banner(self, container):
        """Fallback ASCII art banner"""
        banner_label = Gtk.Label()
        banner_text = """
╦ ╦┌─┐┬ ┬┌┬┐┌┬┐┌─┐┌┬┐╔═╗┌┐┌┌─┐┌─┐┌─┐
║║║├┤ ├─┤ │  │ ├─┤│││╚═╗│││├─┤├─┘└─┐
╚╩╝└─┘┴ ┴ ┴  ┴ ┴ ┴┴ ┴╚═╝┘└┘┴ ┴┴  └─┘
        """
        banner_label.set_markup(
            f'<span font="Monospace 10" foreground="#00ffff">{banner_text}</span>'
        )
        banner_label.set_halign(Gtk.Align.CENTER)
        container.pack_start(banner_label, False, False, 0)

    def add_main_text(self, container):
        version = self.get_system_version()

        scrolled_window = Gtk.ScrolledWindow()
        scrolled_window.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        scrolled_window.set_size_request(-1, 400)

        text_view = Gtk.TextView()
        text_view.set_editable(False)
        text_view.set_cursor_visible(False)
        text_view.set_wrap_mode(Gtk.WrapMode.WORD)
        text_view.set_left_margin(40)
        text_view.set_right_margin(40)
        text_view.set_top_margin(20)
        text_view.set_bottom_margin(20)

        font_desc = Pango.FontDescription()
        font_desc.set_family("Monospace")
        font_desc.set_size(11 * Pango.SCALE)
        text_view.override_font(font_desc)

        buffer = text_view.get_buffer()

        text_content = f"""Welcome to WehttamSnaps v{version}

⚡ SYSTEM INITIALIZED ⚡

WehttamSnaps is a cyberpunk-themed Niri configuration built for power users who demand both aesthetics and performance. Built on Arch Linux with the Niri Wayland compositor.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎮 QUICK START

Essential Keybinds:
• MOD + SPACE       → J.A.R.V.I.S. Command Center
• MOD + ALT + H     → Show Keyhints
• MOD + SHIFT + N   → Quick Settings
• MOD + T / RETURN  → Terminal (Ghostty)
• MOD + B           → Browser (Vivaldi)
• MOD + E           → File Manager (Thunar)
• MOD + Q           → Close Window
• MOD + G           → Toggle Gaming Mode

J.A.R.V.I.S. Menu System:
• MOD + ALT + A     → Quick App Launcher
• MOD + W           → Workspace Switcher
• MOD + ALT + J     → Interactive Terminal

Workspaces (1-10):
 1: Browser      2: Terminal/Dev   3: Gaming        4: Streaming/OBS
 5: Photography  6: Media/Video    7: Communication 8: Music/Audio
 9: Files        10: Misc

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔧 CONFIGURATION

Your config files are located at:
~/.config/wehttamsnaps/
~/.config/niri/

Edit configs with: kate ~/.config/niri/config.kdl

Sound System Features:
• Adaptive audio feedback for actions
• Gaming mode audio routing
• Steam launch sounds (iDroid theme)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 FEATURES

✓ Modular Niri configuration (KDL files)
✓ J.A.R.V.I.S. visual menu system
✓ Sound system with adaptive audio
✓ Gaming-optimized workspaces
✓ Modding tools support (STL, Vortex, MO2, Wabbajack)
✓ Web app integration (YouTube, Twitch, Spotify, Discord)
✓ Rainbow border animations
✓ Quickshell ii integration

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 TIPS

• Press MOD + / for the cheatsheet overlay
• Gaming mode disables animations for better performance
• Use MOD + CTRL + T for wallpaper selection
• Config validation runs automatically on changes

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The future is now. Make it yours.

"""

        buffer.insert(buffer.get_end_iter(), text_content)

        # Add signature
        signature_tag = buffer.create_tag("signature", scale=1.3, foreground="#00ffff")
        buffer.insert_with_tags(
            buffer.get_end_iter(), "\n— WehttamSnaps", signature_tag
        )

        # Add clickable links
        buffer.insert(buffer.get_end_iter(), "\n\n")
        github_tag = buffer.create_tag(
            "github_link", foreground="#00ffff", underline=True
        )
        buffer.insert_with_tags(
            buffer.get_end_iter(), "GitHub Repository", github_tag
        )

        buffer.insert(buffer.get_end_iter(), " | ")

        config_tag = buffer.create_tag(
            "config_link", foreground="#ff00ff", underline=True
        )
        buffer.insert_with_tags(
            buffer.get_end_iter(), "Edit Configuration", config_tag
        )

        text_view.connect("button-press-event", self.on_text_clicked)

        scrolled_window.add(text_view)
        container.pack_start(scrolled_window, True, True, 0)

    def add_buttons(self, container):
        button_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=15)
        button_box.set_halign(Gtk.Align.FILL)
        button_box.set_margin_start(40)
        button_box.set_margin_end(40)

        # Left side buttons
        left_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        
        dismiss_button = Gtk.Button(label="⚡ Dismiss Forever")
        dismiss_button.connect("clicked", self.on_dismiss_forever)
        left_box.pack_start(dismiss_button, False, False, 0)

        keybinds_button = Gtk.Button(label="⌨ Keybinds")
        keybinds_button.connect("clicked", self.on_show_keybinds)
        left_box.pack_start(keybinds_button, False, False, 0)

        button_box.pack_start(left_box, False, False, 0)

        # Spacer
        spacer = Gtk.Box()
        button_box.pack_start(spacer, True, True, 0)

        # Right side button
        close_button = Gtk.Button(label="✕ Close")
        close_button.connect("clicked", self.on_close)
        button_box.pack_start(close_button, False, False, 0)

        container.pack_start(button_box, False, False, 0)

    def on_dismiss_forever(self, button):
        config_dir = os.path.expanduser("~/.config/wehttamsnaps")
        os.makedirs(config_dir, exist_ok=True)

        welcome_config = {"dismissed": True, "timestamp": GLib.get_real_time()}

        config_file = os.path.join(config_dir, "welcome.json")
        try:
            with open(config_file, "w") as f:
                json.dump(welcome_config, f, indent=2)
            print("Welcome dismissed forever")
        except Exception as e:
            print(f"Error saving welcome config: {e}")

        Gtk.main_quit()

    def on_close(self, button):
        Gtk.main_quit()

    def on_show_keybinds(self, button):
        """Launch keybinds helper"""
        try:
            subprocess.Popen(
                ["sh", "-c", "~/.config/wehttamsnaps/scripts/KeyHints.sh"]
            )
        except Exception as e:
            print(f"Could not launch keybinds: {e}")

    def on_text_clicked(self, text_view, event):
        if event.button == 1:
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
                            os.system(
                                "xdg-open https://github.com/wehttamsnaps &"
                            )
                            return True
                        elif tag_name == "config_link":
                            os.system(
                                "kate ~/.config/niri/config.kdl &"
                            )
                            return True

        return False

    def get_system_version(self):
        """Get system version"""
        version_file = os.path.expanduser("~/.config/wehttamsnaps/VERSION")

        try:
            with open(version_file, "r") as f:
                return f.read().strip()
        except:
            return "1.0.0"

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
        pass
    elif not should_show_welcome():
        print("Welcome has been dismissed")
        return

    css_provider = Gtk.CssProvider()
    css_data = """
    * {
        font-family: "Monospace", "Hack Nerd Font", monospace;
    }

    window {
        background: linear-gradient(135deg, #0a0a0a 0%, #1a0a1a 100%);
        color: #00ffff;
    }

    label {
        color: #00ffff;
    }

    textview {
        background: rgba(10, 10, 30, 0.95);
        color: #00ffff;
        border: 1px solid #00ffff;
        border-radius: 8px;
    }

    textview text {
        background: rgba(10, 10, 30, 0.95);
        color: #00ffff;
    }

    button {
        background: linear-gradient(135deg, #ff00ff 0%, #00ffff 100%);
        color: #000000;
        border: 2px solid #00ffff;
        border-radius: 6px;
        padding: 10px 20px;
        font-weight: bold;
        font-size: 12px;
        min-height: 36px;
        text-shadow: 0 0 5px rgba(0, 255, 255, 0.5);
    }

    button:hover {
        background: linear-gradient(135deg, #00ffff 0%, #ff00ff 100%);
        border-color: #ff00ff;
        box-shadow: 0 0 15px rgba(255, 0, 255, 0.6);
    }

    scrolledwindow {
        border: none;
        background: transparent;
    }
    """

    css_provider.load_from_data(css_data.encode())

    screen = Gdk.Screen.get_default()
    Gtk.StyleContext.add_provider_for_screen(
        screen, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER
    )

    WelcomeWindow()
    Gtk.main()


if __name__ == "__main__":
    main()
