
# sdc - A bash function that allow user to navigate back to the previous directories.

Navigate  back to  the previous navigated  directories  by providing
the corresponding number in the menu. With or without autocd enabled.
The sqlite3 directories table created by sdb is being parsed.

By default only directories are shown for the current shell session.
The **-a** flag will remove that  restriction  and show  all directories
that  are  current/past  and  all other  directories in  other shell
sessions.

Regardless how many times a directory appears in the table. Only one
instance of a directory is shown in the menu. Avoiding duplicates
Without an option and if the "tput" utility is installed, by default
the fonts are bold  and  colored. If the  "git" utility is installed
the status of the git repository is printed once inside the directory
repository.

----
## Requirements

* **sdb** https://github.com/Jetchisel/sdb

----
## Installation
* git clone https://github.com/Jetchisel/sdc
* cd sdc/ && source ./sdc
* or just download the zip archive and unpack it.
* Do the same procedure with sdb for a permanent change.

----
## Usage: A simple test run once you have sourced sdc

```shell
for f in /*/; do [[ -x $f ]] && cd "$f"; done
```

Now run

```shell
sdc
```

With **autocd** enabled
```shell
shopt -s autocd
```

```shell
for f in /*/; do [[ -x $f ]] && "$f"; done
```

Now run
```shell
sdc
```

----
This is almost the same functionality as **mcd** only **sdc** is parsing the **directories** table.



