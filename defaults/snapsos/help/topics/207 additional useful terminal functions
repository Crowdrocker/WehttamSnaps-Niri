> additional useful terminal functions
Here are some additional terminal functions and tricks that can make your workflow more efficient.

---

### Process Management
- `ps`: Lists running processes. For example, `ps aux` shows all processes for all users. you can combine this with grep to get PIDs easily

- `kill <PID>`: Terminates a process by its ID. For example, `kill 1234` terminates the process with PID '1234'.

- `killall <name>`: Terminates a process by its name. For example, `killall firefox` closes all Firefox instances.

- `top` or `btop`: Monitors system resources interactively. For example, run `btop` for a detailed, interactive view of processes.

---

### Archiving and Compression
- `tar -cvf archive.tar <files>`: Creates a tar archive. For example, `tar -cvf backup.tar ~/documents/` creates 'backup.tar' from the 'documents' directory.

    mnemonic: tar Compress Ze File

- `tar -xvf archive.tar`: Extracts a tar archive. For example, `tar -xvf backup.tar` extracts the contents of 'backup.tar'.

    Mnemonic: tar eXtract Ze File

- `gzip <file>`: Compresses a file. For example, `gzip largefile.txt` compresses 'largefile.txt' to 'largefile.txt.gz'.


- `gunzip <file.gz>`: Decompresses a `.gz` file. For example, 'gunzip largefile.txt.gz' restores the original file.

---

### Networking
- `ping <host>`: Checks connectivity to a host. For example, `ping google.com` tests the connection to Google.
- `curl <URL>`: Downloads or interacts with a URL. For example, `curl https://example.com` retrieves the content of the webpage.
- `wget <URL>`: Downloads a file from a URL. For example, `wget https://example.com/file.zip` downloads 'file.zip'.
- `ssh <user>@<host>`: Connects to a remote machine. For example, `ssh den@192.168.1.100` attempts to connect over SSH to the remote machine at ip '192.168.1.100' as user 'den'.

---

### System Information
- `uname -a`: Displays system information. For example, `uname -a` shows the kernel version and system architecture.
- `df -h`: Displays disk space usage. For example, `df -h` shows disk usage in a human-readable format.
- `free -h`: Displays memory usage. For example, `free -h` shows RAM and swap usage in a human-readable format.
- `uptime`: Shows how long the system has been running. For example, `uptime` displays the system uptime and load averages.

---

### Terminal Shortcuts
- `Ctrl+C`: Interrupts the current command.
- `Ctrl+Z`: Suspends the current command (sends it to the background).
- `Ctrl+D`: Exits the current shell or sends EOF (End of File).
- `Ctrl+R`: Searches through command history.
- `!!`: Repeats the last command. For example, `sudo !!` repeats the last command with `sudo`.
- `Tab`: Auto-completes file or command names.

---

### Aliases
Create shortcuts for frequently used commands by adding aliases to your `.zshrc` file. For example:
alias ll='eza -l'
alias gs='git status'

After adding, run `source ~/.zshrc` to apply the changes.

the following aliasses exist by default:

find - replaces the default "find" command with a fzf menu that shows previews.
microfind - like find, but will open the selected file in micro
ls - replaces ls using eza, defaults to using list mode with colors, grouping and icons.
la - like ls, but lists all files
ll - lists in long format
lt - lists using tree format up to 4 layers deep 
l. - lists only hidden files
update - runs `sudo pacman -Syu`
jctl - runs a minimal journalctl command
cmdhist - opens a menu to go through your command history and select one, then types that back into the terminal. 
tipme - gets a random tip
cowtip - gets a random tip from an RGB cow


### fzf

you can use fzf inside your terminal by typing <**> and pressing <tab>. this will give you an fzf menu for autocompleting filepaths. 

---

### Environment Variables
- `printenv`: Displays all environment variables. For example, `printenv` lists variables like `PATH` and `HOME`.
- `echo $VARIABLE`: Prints the value of a specific variable. For example, `echo $HOME` prints your home directory path.
- `export VARIABLE=value`: Sets an environment variable temporarily. For example, `export EDITOR=micro` sets `micro` as the default editor for the current session.