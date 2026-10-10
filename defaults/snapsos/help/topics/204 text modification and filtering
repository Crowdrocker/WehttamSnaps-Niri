> text modification and filtering

Filtering and modifying text is essential for working with files and command output. linux includes tools like `grep`, `sed`, `awk`, and `cut` for these tasks.

in this help article, all commands will show how to use them *with a file*, but instead of a filename, you can also use these in pipes (explained more in 205 terminal piping).

in which case you'd do `somecommand with --flags | grep "pattern"` for example. 

you can also combine these. for example:
`somecommand with --flags | grep "pattern" | grep -v "blah"

this will output all the lines in the output of somecommand that DO have "pattern" and DO NOT have "blah". 

or:
`somecommand with --flags | grep "pattern" | sed 's/pat/lec/' | awk '{print $1 " " $2 " " $3 }'`
this will take the output of somecommand, filter down to only lines with "pattern", replace the first occurence of "pat" with "lec" (changing pattern to lectern) and then outputs the first 3 words from the line. 


---

### Searching Text with `grep`
- `grep "pattern" <filename>`: Searches for "pattern" in a file. For example, `grep "error" log.txt` prints all lines in 'log.txt' containing "error".

- `grep -i "pattern" <filename>`: Performs a case-insensitive search. For example, `grep -i "warning" log.txt` matches "Warning", "WARNING", etc.

- `grep -v "pattern" <filename>`: Excludes lines matching "pattern". For example, `grep -v "debug" log.txt` prints all lines except those containing "debug".

- `grep -r "pattern" <directory>`: Recursively searches for "pattern" in all files within a directory. For example, `grep -r "main" ~/projects/` searches for "main" in all files under 'projects/'.

---

### Modifying Text with `sed`
- `sed 's/old/new/' <filename>`: Replaces the first occurrence of "old" with "new" in each line. For example, `sed 's/hello/hi/' greeting.txt` replaces "hello" with "hi" in 'greeting.txt'. if you need to use slashes inside the text, you can use a different delimiter like "|": 's|old|new|g'

- `sed 's/old/new/g' <filename>`: Replaces all occurrences of "old" with "new" in each line. For example, `sed 's/hello/hi/g' greeting.txt` replaces every "hello" with "hi".

- `sed -i 's/old/new/g' <filename>`: Edits the file in-place, saving changes to the file. For example, `sed -i 's/hello/hi/g' greeting.txt` permanently replaces all occurrences.

---

### Extracting Columns with `cut`
- `cut -d',' -f1 <filename>`: Extracts the first field from a comma-delimited file. For example, `cut -d',' -f1 data.csv` prints the first column of `data.csv`. you can determine the delimiter yourself, using any single character. you can use the -f flag to print multiple fields (-f 1,3,5 or f1-5)

- `cut -c1-5 <filename>`: Extracts characters 1 through 5 from each line. For example, `cut -c1-5 notes.txt` prints the first 5 characters of each line in `notes.txt`.

---

### Processing Text with `awk`
- `awk '{print $1}' <filename>`: Prints the first field of each line (default delimiter is whitespace). For example, `awk '{print $1}' data.txt` prints the first column of 'data.txt'.

- `awk -F',' '{print $2}' <filename>`: Uses a comma as the field separator and prints the second field. For example, `awk -F',' '{print $2}' data.csv` prints the second column of 'data.csv'.

- `awk '/pattern/ {print $0}' <filename>`: Prints lines matching "pattern". For example, `awk '/error/ {print $0}' log.txt` prints all lines in 'log.txt' containing "error".