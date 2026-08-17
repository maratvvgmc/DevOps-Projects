Fundamentals of Nginx Access Log Structure
Nginx uses the Combined Log Format by default to record client interactions. Understanding field positional ordering is essential for writing accurate parsing pipelines:

127.0.0.1 - frank [10/Oct/2000:13:55:36 -0700] "GET /apache_pb.gif HTTP/1.0" 200 2326 "http://www.example.com/start.html" "Mozilla/4.08 [en] (Win98; I)"

Field 1 ($1): Client IP Address (127.0.0.1).

Field 4 & 5 ($4 $5): Timestamp and time zone offset.

Field 6, 7, 8 ($6 $7 $8): HTTP request method (GET), request path (/apache_pb.gif), and protocol version.

Field 9 ($9): HTTP response status code (200).

Field 10 ($10): Response payload size in bytes (2326).

Quoted Section 2: HTTP Referrer string.

Quoted Section 3: User-Agent string (Mozilla/4.08...).

Granular Command and Pipeline Breakdown
To enforce runtime execution safety, the script starts with set -euo pipefail.

-e: Immediately terminates the script if any command returns a non-zero exit status.

-u: Flags uninitialized variables as errors and halts execution.

-o pipefail: Configures pipelines to return the exit code of the first failing command rather than masking errors behind successful downstream utilities.

Argument and file validations are performed using conditional blocks:

if [ "$#" -ne 1 ]; then: Verifies that exactly one command line parameter (the path to the log file) is provided.

if [ ! -f "$LOG_FILE" ]; then: Checks whether the provided target exists and is a regular file using the -f file test operator.

Pipeline 1: Parsing Fixed Column Fields (IPs, Paths, Status Codes)
Bash
awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -n 5 | awk '{print $2 " - " $1 " requests"}'
awk '{print $1}': Splits input lines by whitespace delimiters and isolates field 1 (Client IP). Replacing $1 with $7 extracts request paths, and $9 captures response status codes.

sort: Alphabetically sorts raw values. This step is mandatory because the subsequent counting utility requires identical string instances to be contiguous.

uniq -c: Collapses adjacent identical lines into single unique entries, prefixing each entry with its occurrence frequency count.

sort -nr: Sorts entries numerically (-n) in reverse descending order (-r), placing high-frequency records at the top.

head -n 6 / head -n 5: Captures the top 5 occurrences from the stream.

awk '{print $2 " - " $1 " requests"}': Reformats raw counts ($1) and values ($2) into clean presentation strings matching assignment output criteria.

Pipeline 2: Parsing Variable Whitespace Fields (User Agents)
Bash
awk -F'"' '{print $6}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -n 5 | awk '{count=$1; $1=""; sub(/^ /, ""); print $0 " - " count " requests"}'
awk -F'"': Overrides the default whitespace delimiter by specifying double quotes (") as field boundaries. User-Agent strings contain whitespace, making column indexes unreliable under standard space splitting. Inside double-quote delimiters, Field 6 strictly extracts the entire User-Agent string.

Reformatting String Logic:

count=$1: Stores the frequency count produced by uniq -c.

$1="": Clears the count column from AWK's record array.

sub(/^ /, ""): Removes leading whitespace artifacts remaining after field deletion.

print $0 " - " count " requests": Reconstructs multi-word User-Agent strings alongside their calculated request totals.

Alternative Implementation Strategies (Stretch Goals)
While awk is optimal for column parsing, Linux shell tools allow multiple approaches to achieve identical outcomes.

Strategy A: Using grep and sed for Status Code Extraction
Instead of positional field parsing via awk, regular expressions can extract fields based on log structural patterns:

Bash
grep -oE '" [1-5][0-9]{2} ' "$LOG_FILE" | sed 's/" //; s/ //' | sort | uniq -c | sort -nr | head -n 5
grep -oE: Extends regular expressions (-E) and prints only matching substring instances (-o) rather than whole lines. " [1-5][0-9]{2} matches 3-digit HTTP status codes bounded by double quotes and spaces.

sed 's/" //; s/ //': Strips bounding quotation marks and spaces to isolate raw status integers before sorting and counting.

Strategy B: Pure sed Capture Groups for IP Extraction
Bash
sed -E 's/^([^ ]+).*/\1/' "$LOG_FILE" | sort | uniq -c | sort -nr | head -n 5
sed -E 's/^([^ ]+).*/\1/': Matches non-space characters ([^ ]+) at line start (^), captures them into Group 1 (\1), and discards trailing log details, leaving pure IP addresses.