> terminal piping

Piping (`|`) and redirection (`>`, `>>`, `<`) allow you to chain commands together and control input/output. These are powerful tools for combining and manipulating data in the terminal.

---

### Piping with `|`, `||`, `&` and `&&`
- `command1 | command2`: Sends the output of `command1` as input to `command2`. For example, `ls | grep "txt"` lists all files in the current directory and filters for files containing "txt".

  Another example: `cat log.txt | grep "error" | less` searches for "error" in `log.txt` and displays the results in `less`.


- `command1 && command2`: Runs `command2` only if `command1` succeeds (exits with status 0).

  Example: `mkdir new_folder && cd new_folder` creates 'new_folder' and moves into it only if the directory is created successfully.

  Example: `git commit -m "Update" && git push` pushes changes only if the commit succeeds.


- `command1 || command2`: Runs `command2` only if `command1` fails (exits with a non-zero status).

  Example: `cat file.txt || echo "File not found"` prints the contents of 'file.txt' or displays "File not found" if the file doesn’t exist.

  Example: `ping -c 1 google.com || echo "Network unavailable"` checks connectivity and shows an error message if the ping fails.


- `command &`: Runs `command` in the background, allowing you to continue using the terminal. the command is still a child of the terminal and *will* exit when you close the terminal. 

  Example: `firefox &` opens Firefox in the background while keeping the terminal available for other commands.

  Example: `cp -r ~/Documents/* ~/Backups/ &` will start a file copy to copy all files in 'Documents' to 'Backups', but sends it to the background so your terminal is not frozen until it is completed.

  Example: `$(cp -r ~/Documents/* ~/backups/ && notify-send "copy complete!" || notify-send "copy failed!") &` will do the same as above, run a copy in the background, but once the command exits, it'll notify you of the success or failure.


---

### Redirection with `>` and `>>`
- `command > file.txt`: Redirects the output of `command` to 'file.txt', overwriting any existing content. For example, `echo "Hello" > greeting.txt` writes "Hello" to 'greeting.txt'.

- `command >> file.txt`: Appends the output of `command` to 'file.txt'. For example, `echo "World" >> greeting.txt` appends "World" to 'greeting.txt'.

- `command < file.txt`: Redirects the contents of 'file.txt' as input to `command`. For example, `grep "pattern" < input.txt` searches for "pattern" in 'input.txt'.

---

### Combining Pipes and Redirection
- Example: `ls -1 | grep ".txt" > textfiles.txt` lists all files, filters for '.txt' files, and saves the result to 'textfiles.txt'.

- Example: `cat access.log | grep "404" | wc -l > error_count.txt` counts 404 errors in 'access.log' and saves the count to 'error_count.txt'.

---

### Discarding Output with `/dev/null`
- `command > /dev/null`: Discards the output of `command`. For example, `ls > /dev/null` runs `ls` but suppresses its output.

- `command 2> /dev/null`: Discards error messages. For example, `ls /nonexistent 2> /dev/null` suppresses the error message for a non-existent directory.

---

### Using `tee` for Intermediate Output
- `command | tee file.txt`: Displays output in the terminal and saves it to 'file.txt'. For example, `ls | tee files.txt` lists files in the terminal and saves the list to 'files.txt'.

- `command | tee -a file.txt`: Appends output to 'file.txt' instead of overwriting. For example, `echo "New line" | tee -a notes.txt` appends "New line" to 'notes.txt'.