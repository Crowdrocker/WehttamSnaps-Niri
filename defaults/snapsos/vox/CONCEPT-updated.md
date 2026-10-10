# vox concept

A program that runs in either daemon mode (with a transparent overlay showing
transcriptions) or GUI mode (for configuration) that does voice-to-commands.

The program works like a "hotkey binding" system with the following features:

- A tree-based command structure with alias support
- Prefix words that prepend to the matched command regardless of position
- Suffix words that append to the matched command regardless of position
- Immediate triggers that fire on exact utterance matches

For example, if the wake word is "system command" and the user says
"system command, open firefox", the system walks down the tree from "open"
to "firefox", then executes the configured action.

The wake word is configurable.

Implementation: Python with GTK (PyGObject) for the UI, whisper-server
(whisper.cpp) for offline speech-to-text.
