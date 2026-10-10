the idea is to have a program that can run in either daemon mode (mith just an overlay to see what you're saying) or in GUI mode (for configuration) that does voice-to-commands.

the program should work like a "hotkey binding" program, and should have the following:


a tree-based structure from the command word, with the ability to create aliasses.

next to that, option to have words that are prefixes, which will prefix something to the string regardless of where in the phrase you say it, suffixes, which work the same but append instead of prefix and immediate triggers, which will immediately run based on a single word. 

for example, if the command word is "system command" and the user says "system command, open firefox". the system would trigger and walk down the tree, going down to the "open" keyword, and then looking at the branches under that for "firefox", then under firefox there's just one node, which is an exec node that contains the command to open firefox. 

the command word should also be configurable. 

we can use python and GTK framework for the UI. 

