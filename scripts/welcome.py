#!/usr/bin/env python3
"""
WehttamSnaps Welcome App
Branded welcome screen for first-time Niri setup
GitHub: https://github.com/Crowdrocker
"""

import gi
gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gtk, Gdk, GdkPixbuf, GLib, Pango
import os
import json
import sys
import subprocess


class WehttamSnapsWelcome:
    def __init__(self):
        self.window = Gtk.Window()
        self.window.set_title("Welcome to WehttamSnaps")
        self.window.set_default_size(900, 700)
        self.window.set_position(Gtk.WindowPosition.CENTER)
        self.window.set_resizable(False)

        # Non-modal window
        self.window.set_modal(False)
        self.window.set_keep_above(False)
        self.window.set_focus_on_map(True)
        self.window.set_type_hint(Gdk.WindowTypeHint.NORMAL)

        # Create main container
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        main_box.set_margin_start(0)
        main_box.set_margin_end(0)
        main_box.set_margin_top(0)
        main_box.set_margin_bottom(30)

        # Add logo/branding image
        self.add_logo(main_box)

        # Add welcome text
        self.add_welcome_text(main_box)

        # Add buttons
        self.add_buttons(main_box)

        self.window.add(main_box)
        self.window.connect("destroy", self.on_window_destroy)
        self.window.show_all()

        # Play J.A.R.V.I.S. startup sound
        self.play_startup_sound()

    def play_startup_sound(self):
        """Play J.A.R.V.I.S. startup sound"""
        jarvis_script = os.path.expanduser("~/.config/wehttamsnaps/scripts/jarvis-manager.sh")
        if os.path.exists(jarvis_script) and os.access(jarvis_script, os.X_OK):
            try:
                subprocess.Popen([jarvis_script, "startup"],
                               stdout=subprocess.DEVNULL,
                               stderr=subprocess.DEVNULL)
            except Exception as e:
                print(f"Could not play startup sound: {e}")

    def add_logo(self, container):
        """Add WehttamSnaps logo"""
        home_dir = os.path.expanduser("~")

        # Try multiple possible logo locations
        logo_paths = [
            os.path.join(home_dir, ".config", "wehttamsnaps", "assets", "logo.png"),
            os.path.join(home_dir, ".config", "wehttamsnaps", "assets", "wehttamsnaps-logo.png"),
            os.path.join(home_dir, ".local", "share", "wehttamsnaps", "logo.png"),
        ]

        logo_path = None
        for path in logo_paths:
            if os.path.exists(path):
                logo_path = path
                break

        if logo_path:
            try:
                pixbuf = GdkPixbuf.Pixbuf.new_from_file(logo_path)
                # Scale to reasonable size
                width = pixbuf.get_width()
                height = pixbuf.get_height()
                target_width = 300
                scale_factor = target_width / width
                new_width = target_width
                new_height = int(height * scale_factor)
                pixbuf = pixbuf.scale_simple(
                    new_width, new_height, GdkPixbuf.InterpType.BILINEAR
                )

                image = Gtk.Image.new_from_pixbuf(pixbuf)
                image.set_halign(Gtk.Align.CENTER)
                container.pack_start(image, False, False, 10)
            except Exception as e:
                print(f"Could not load logo: {e}")
                self.add_text_logo(container)
        else:
            self.add_text_logo(container)

    def add_text_logo(self, container):
        """Add ASCII text logo as fallback"""
        logo_label = Gtk.Label()
        logo_label.set_markup(
            '<span size="24000" weight="bold" foreground="#89b4fa">WehttamSnaps</span>'
        )
        logo_label.set_halign(Gtk.Align.CENTER)
        container.pack_start(logo_label, False, False, 10)

    def add_welcome_text(self, container):
        """Add main welcome text"""
        # Get version
        version = self.get_version()

        # Create scrollable text view
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
        font_desc.set_family("Fira Code, monospace")
        font_desc.set_size(12 * Pango.SCALE)
        text_view.override_font(font_desc)

        buffer = text_view.get_buffer()

        # Welcome content
        content = f"""Welcome to WehttamSnaps Niri Setup v{version}

🎯 YOUR PROFESSIONAL WORKSTATION

This Arch Linux Niri configuration is optimized for photography, content creation, and gaming. Built specifically for the WehttamSnaps brand and workflow.

⚡ QUICK START

Essential Shortcuts:
• Mod + Space        → Application Launcher (Noctalia)
• Mod + Enter        → Terminal (Ghostty with Fira Code)
• Mod + H            → Help & Keybindings Cheat Sheet
• Mod + S            → Control Center (Quick Settings)
• Mod + B            → Browser (Brave)
• Mod + Q            → Close Window
• Mod + G            → Gaming Mode Toggle

📸 PHOTOGRAPHY WORKFLOW (Workspace 3)
• Mod + 3            → Jump to Photo Workspace
• Mod + Shift + D    → Darktable (RAW Processing)
• Mod + Shift + G    → GIMP (Photo Editing)
• Mod + Shift + K    → Krita (Digital Art)
• Mod + Shift + P    → DigiKam (Photo Management)

🎮 GAMING OPTIMIZATIONS (Workspace 9)
• Mod + 9            → Jump to Gaming Workspace
• Mod + G            → Toggle Gaming Mode (Disable Animations)
• Mod + Shift + S    → Launch Steam

Your library includes: Division 2, Cyberpunk 2077, Fallout 4, Watch Dogs series, and more - all pre-configured with optimal launch options for RX 580.

🎨 10 ORGANIZED WORKSPACES
1. Browser   - Web browsing
2. Terminal  - Development & files
3. Photo     - Photography (GIMP, Darktable, Krita)
4. Design    - Vector graphics (Inkscape)
5. 3D        - Blender for composites
6. Chat      - Discord, social media
7. Media     - Spotify, YouTube, Twitch webapps
8. Stream    - OBS Studio, audio routing
9. Gaming    - Steam, Lutris, all games
10. Modding  - Vortex, MO2, Wabbajack

🔊 AUDIO ROUTING
PipeWire + qpwgraph provides VoiceMeeter-like audio control:
• Mod + A            → Open qpwgraph
• Separate channels for: Game, Browser, Discord, Spotify
• See docs/AUDIO-ROUTING.md for detailed setup

🤖 J.A.R.V.I.S. INTEGRATION
Your AI assistant provides audio feedback:
• Startup greeting when system boots
• "Gaming mode activated" when enabling performance mode
• "Streaming systems online" when entering OBS workspace
• Temperature warnings if CPU/GPU gets too hot

🎨 CUSTOMIZATION
• Mod + Comma        → Open Noctalia Settings
• Mod + Shift + W    → Wallpaper Selector
• Mod + Ctrl + Space → Random Wallpaper
• Material You colors auto-generate from wallpapers

📚 DOCUMENTATION
Full docs available in ~/.config/wehttamsnaps/docs/:
• INSTALL.md - Detailed installation guide
• QUICKSTART.md - First-time setup
• AUDIO-ROUTING.md - PipeWire configuration
• GAMING.md - Per-game optimizations
• TROUBLESHOOTING.md - Common issues

💡 TIPS
• Use Mod + H anytime for the keybindings cheat sheet
• Gaming mode (Mod + G) disables animations for maximum FPS
• Your RX 580 is pre-configured with Mesa optimizations
• Check ~/.config/wehttamsnaps/README.md for full details

🚀 GET STARTED
Press Mod + Space to launch apps, or Mod + Enter for a terminal. Your WehttamSnaps workstation is ready!

"""

        # Insert content
        buffer.set_text(content)

        # Add signature
        iter_end = buffer.get_end_iter()
        buffer.insert(iter_end, "\n\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        iter_end = buffer.get_end_iter()

        signature_tag = buffer.create_tag("signature",
                                         scale=1.3,
                                         weight=Pango.Weight.BOLD,
                                         foreground="#89b4fa")
        buffer.insert_with_tags(iter_end, "WehttamSnaps", signature_tag)
        iter_end = buffer.get_end_iter()

        buffer.insert(iter_end, "\n")
        iter_end = buffer.get_end_iter()

        # Links
        link_tag = buffer.create_tag("link",
                                     foreground="#89b4fa",
                                     underline=Pango.Underline.SINGLE)

        buffer.insert(iter_end, "\n📺 ")
        iter_end = buffer.get_end_iter()
        buffer.insert_with_tags(iter_end, "Twitch", link_tag)
        iter_end = buffer.get_end_iter()

        buffer.insert(iter_end, "  •  🎬 ")
        iter_end = buffer.get_end_iter()
        buffer.insert_with_tags(iter_end, "YouTube", link_tag)
        iter_end = buffer.get_end_iter()

        buffer.insert(iter_end, "  •  💻 ")
        iter_end = buffer.get_end_iter()
        buffer.insert_with_tags(iter_end, "GitHub", link_tag)
        iter_end = buffer.get_end_iter()

        # Connect click handler
        text_view.connect("button-press-event", self.on_text_clicked)

        scrolled_window.add(text_view)
        container.pack_start(scrolled_window, True, True, 0)

    def add_buttons(self, container):
        """Add action buttons"""
        button_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        button_box.set_halign(Gtk.Align.FILL)
        button_box.set_margin_start(40)
        button_box.set_margin_end(40)

        # Dismiss forever button
        dismiss_button = Gtk.Button(label="Don't Show Again")
        dismiss_button.connect("clicked", self.on_dismiss_forever)
        dismiss_button.set_halign(Gtk.Align.START)
        button_box.pack_start(dismiss_button, False, False, 0)

        # Spacer
        spacer = Gtk.Box()
        button_box.pack_start(spacer, True, True, 0)

        # Open docs button
        docs_button = Gtk.Button(label="📚 View Docs")
        docs_button.connect("clicked", self.on_open_docs)
        button_box.pack_start(docs_button, False, False, 0)

        # Close button
        close_button = Gtk.Button(label="Get Started")
        close_button.connect("clicked", self.on_close)
        close_button.set_halign(Gtk.Align.END)
        button_box.pack_start(close_button, False, False, 0)

        container.pack_start(button_box, False, False, 0)

    def on_dismiss_forever(self, button):
        """Save preference to never show welcome again"""
        config_dir = os.path.expanduser("~/.config/wehttamsnaps")
        os.makedirs(config_dir, exist_ok=True)

        config_file = os.path.join(config_dir, "welcome.json")
        config = {"dismissed": True, "timestamp": GLib.get_real_time()}

        try:
            with open(config_file, "w") as f:
                json.dump(config, f, indent=2)
            print("Welcome screen dismissed forever")
        except Exception as e:
            print(f"Error saving welcome config: {e}")

        Gtk.main_quit()

    def on_open_docs(self, button):
        """Open documentation in file manager"""
        docs_path = os.path.expanduser("~/.config/wehttamsnaps/docs")

        if os.path.exists(docs_path):
            try:
                subprocess.Popen(["thunar", docs_path],
                               stdout=subprocess.DEVNULL,
                               stderr=subprocess.DEVNULL)
            except:
                try:
                    subprocess.Popen(["xdg-open", docs_path],
                                   stdout=subprocess.DEVNULL,
                                   stderr=subprocess.DEVNULL)
                except Exception as e:
                    print(f"Could not open docs: {e}")

    def on_close(self, button):
        """Close welcome screen"""
        Gtk.main_quit()

    def on_text_clicked(self, text_view, event):
        """Handle clicks on links"""
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
                        if tag_name == "link":
                            # Determine which link based on surrounding text
                            start = iter_pos.copy()
                            start.backward_chars(10)
                            end = iter_pos.copy()
                            end.forward_chars(10)
                            context = text_view.get_buffer().get_text(start, end, False)

                            if "Twitch" in context:
                                self.open_url("https://twitch.tv/WehttamSnaps")
                            elif "YouTube" in context:
                                self.open_url("https://youtube.com/@WehttamSnaps")
                            elif "GitHub" in context:
                                self.open_url("https://github.com/Crowdrocker")

                            return True
        return False

    def open_url(self, url):
        """Open URL in default browser"""
        try:
            subprocess.Popen(["xdg-open", url],
                           stdout=subprocess.DEVNULL,
                           stderr=subprocess.DEVNULL)
        except Exception as e:
            print(f"Could not open URL: {e}")

    def get_version(self):
        """Get WehttamSnaps version"""
        version_paths = [
            os.path.expanduser("~/.config/wehttamsnaps/VERSION"),
            os.path.expanduser("~/.local/share/wehttamsnaps/VERSION"),
        ]

        for path in version_paths:
            if os.path.exists(path):
                try:
                    with open(path, "r") as f:
                        return f.read().strip()
                except:
                    pass

        return "1.0.0"

    def on_window_destroy(self, widget):
        """Handle window destruction"""
        Gtk.main_quit()


def should_show_welcome():
    """Check if welcome should be shown"""
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
    """Main entry point"""
    # Check for force flag
    if len(sys.argv) > 1 and sys.argv[1] == "--force":
        pass
    elif not should_show_welcome():
        print("Welcome screen has been dismissed")
        return

    # Apply CSS styling
    css_provider = Gtk.CssProvider()
    css_data = """
    * {
        font-family: "Fira Code", "Monospace", monospace;
    }

    window {
        background: #1e1e2e;
        color: #cdd6f4;
    }

    label {
        color: #cdd6f4;
    }

    textview {
        background: #1e1e2e;
        color: #cdd6f4;
        border: none;
    }

    textview text {
        background: #1e1e2e;
        color: #cdd6f4;
    }

    button {
        background: #89b4fa;
        color: #1e1e2e;
        border: none;
        border-radius: 8px;
        padding: 10px 20px;
        font-weight: bold;
        min-width: 120px;
        min-height: 36px;
    }

    button:hover {
        background: #b4c8fa;
    }

    scrolledwindow {
        border: none;
        background: #1e1e2e;
    }
    """

    css_provider.load_from_data(css_data.encode())

    screen = Gdk.Screen.get_default()
    Gtk.StyleContext.add_provider_for_screen(
        screen, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER
    )

    # Create and show window
    WehttamSnapsWelcome()
    Gtk.main()


if __name__ == "__main__":
    main()
