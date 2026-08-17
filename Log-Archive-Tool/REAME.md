# Log Archive Tool — Project Study Notes

This project focuses on building a Command Line Interface (CLI) tool in Bash (`log-archive.sh`) to automate log archiving on Unix-based systems. It compresses log directories into `.tar.gz` archives, stores them in a designated location, and appends timestamped records to a history log file.

Below is a detailed breakdown of the Linux concepts, file archiving mechanisms, and Bash scripting principles required to understand how this tool operates.

---
Fundamentals of Log Management and Archiving
Unix-based operating systems write system and application event records to /var/log. Over time, unmanaged log files accumulate, consuming storage space and degrading system performance. Log archiving solves this by compressing historical records and offloading them while retaining auditability.

Archiving relies on two distinct operations:

Archiving (Bundling): Combining multiple files and directory structures into a single file payload without altering raw data sizes.

Compression: Applying algorithmic encoding (such as DEFLATE/gzip) to eliminate data redundancy and minimize disk usage.

Combining tar and gzip creates .tar.gz (tarball) files, achieving high compression ratios ideal for plain text log files.

Granular Command and Scripting Breakdown
To enforce robust execution safety, the script begins with set -euo pipefail.

-e: Immediately exits the script if any command returns a non-zero (failure) exit status.

-u: Treats unset variables as an error during substitution and exits immediately.

-o pipefail: Forces pipelines to return the exit status of the last command that failed, rather than always returning success if the last command succeeded.

Argument validation is handled via if [ "$#" -ne 1 ]; then.
The special variable $# stores the number of positional parameters passed to the script. The operator -ne checks if the count is not equal to 1. If an incorrect parameter count is supplied, the script prints usage instructions and exits with code 1 (indicating error).

Directory verification uses if [ ! -d "$LOG_DIR" ]; then.
The -d conditional operator tests whether the specified path exists and is a valid directory. The ! negation operator reverses the check, raising an error if the directory does not exist.

Archive destination management relies on mkdir -p "$ARCHIVE_DIR".
The mkdir utility creates new directories. The -p (parents) flag prevents errors if the directory already exists and creates any missing parent directories automatically.

Dynamic timestamp formatting uses date +"%Y%m%d_%H%M%S".
The date utility formats system time based on conversion specifiers: %Y (4-digit year), %m (2-digit month), %d (2-digit day), %H (24-hour clock), %M (minute), and %S (second).

Compression is executed using tar -czf "$ARCHIVE_PATH" -C "$LOG_DIR" ..

tar: The Tape Archive utility.

-c: Creates a new archive.

-z: Filters the archive through gzip for compression.

-f: Specifies the target archive filename.

-C "$LOG_DIR": Changes working directory to $LOG_DIR before performing operations. This prevents storing absolute system directory paths inside the archive payload, ensuring relative extraction.

.: Targets all contents within the specified directory.

Audit logging utilizes redirection appending via echo "..." >> "$LOG_FILE".
The >> operator appends text output to the target file without overwriting existing content. If the log file does not exist, Bash creates it automatically.


### How to Prepare and Run the Script

In Unix environments, executable flags must be explicitly granted to scripts before execution. Grant execution permissions using `chmod +x log-archive.sh`. 

To make the script globally callable as `log-archive <log-directory>` (matching system utilities), move or symlink the script into a directory contained within your system's `PATH` environment variable (such as `/usr/local/bin`):

```bash
sudo cp log-archive.sh /usr/local/bin/log-archive