> file permissions

File permissions control who can read, write, or execute files and directories which can be managed with `chmod` and `chown`.

---

### Understanding Permissions
Permissions are displayed in `ls -l` output, for example:
`drwxr-xr-x 2 den users 4096 May 24 12:34 myfolder`
`-rw-r--r-- 1 den users   10 May 24 12:35 file.txt`

- The first character indicates the file type:
  - `-`: Regular file.
  - `d`: Directory.
  - `l`: Symbolic link.
- The next 9 characters represent permissions for the **owner**, **group**, and **others** (in groups of 3):
  - `r`: Read.
  - `w`: Write.
  - `x`: Execute.
  - `-`: No permission.

For example, `rw-r--r--` means:
- Owner: read and write (`rw-`).
- Group: read only (`r--`).
- Others: read only (`r--`).

---

### Changing Permissions with `chmod`
- **Symbolic Mode**:
  - `chmod u+x <file>`: Adds execute permission for the owner. For example, `chmod u+x script.sh` makes `script.sh` executable for the owner.
  - `chmod g-w <file>`: Removes write permission for the group. For example, `chmod g-w file.txt` removes write access for the group.
  - `chmod o=r <file>`: Sets read-only permission for others. For example, `chmod o=r file.txt` allows others to only read the file.
  - `chmod a+r <file>`: Adds read permission for everyone (owner, group, others). For example, `chmod a+r file.txt` makes the file readable by everyone.

- **Numeric Mode**:
  Permissions can also be set using numbers:
  - `4`: Read (`r`).
  - `2`: Write (`w`).
  - `1`: Execute (`x`).
  - `0`: No permission.

  Example: `chmod 755 script.sh` sets:
  - Owner: read, write, execute (`4+2+1 = 7`).
  - Group: read, execute (`4+1 = 5`).
  - Others: read, execute (`4+1 = 5`).

  note: for a directory to be writeable, it *also* has to be executable, otherwise you cannot target it in commands. this is why you cannot CD into directories owned by root that do not have user execute permissions. 

---

### Changing Ownership with `chown`
- `chown <owner> <file>`: Changes the owner of a file. For example, `chown den file.txt` changes the owner of 'file.txt' to the user 'den'.
- `chown <owner>:<group> <file>`: Changes the owner and group of a file. For example, `chown den:users file.txt` changes the owner to 'den' and the group to 'users'.
- `chown -R <owner> <directory>`: Recursively changes ownership of a directory and its contents. For example, `chown -R den projects/` changes the owner of 'projects/' and all its files to 'den'.

---

### Special Permissions
- Set User ID (SUID): `chmod u+s <file>`: Runs the file with the owner's permissions. For example, `chmod u+s script.sh` (use with caution).
- Set Group ID (SGID): `chmod g+s <file>`: Runs the file with the group's permissions. For example, `chmod g+s shared_folder` ensures new files in 'shared_folder' inherit the group.
- Sticky Bit: `chmod +t <directory>`: Only the owner can delete files in the directory. For example, `chmod +t /shared` prevents users from deleting each other's files in '/shared'.

---

### Default Permissions with `umask`
- `umask`: Views the current default permissions for new files and directories. For example, `umask` might output `0022`, which means new files are created with `644` permissions and directories with `755`.
- `umask <value>`: Sets the default permissions. For example, `umask 0002` sets the default so that new files are group-writable.