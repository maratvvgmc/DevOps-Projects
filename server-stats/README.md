# Server Performance Stats — Project Study Notes

This project is designed to build a deep understanding of Linux resource monitoring and Bash automation. The `server-stats.sh` script analyzes system workload, including CPU performance, RAM allocation, disk utilization, and resource-heavy processes.

Below is a detailed breakdown of the Linux system administration concepts and CLI commands required to understand how this script operates.
---

### How to Prepare and Run the Script

In Linux operating systems, newly created text files do not have execution permissions by default. To allow the OS to run the script, you must grant execution rights using `chmod +x server-stats.sh`. Once granted, execute the script by providing its relative path: `./server-stats.sh`. Running it simply as `server-stats.sh` will cause a `command not found` error because the current directory `.` is not included in the system's `PATH` environment variable by default.

---

### Fundamentals of Server Infrastructure

Monitoring any Linux server relies on tracking four core system resources: Central Processing Unit (CPU), Random Access Memory (RAM), Disk I/O, and Active Processes.

CPU time is not measured purely as a single percentage from 0 to 100%. Monitoring tools divide CPU utilization into specific execution states:
* User (us): The percentage of time the CPU spends executing user-space processes (e.g., web servers, application code, databases).
* System (sy): Time spent by the Linux kernel executing system calls and handling hardware requests.
* Idle (id): Time during which the CPU is completely idle with no queued tasks.
* I/O Wait (wa): A critical performance metric indicating time spent waiting for slow disk or network read/write operations.

Total active CPU utilization is calculated using the formula:
$$\text{Total CPU Usage (\%)} = 100\% - \text{Idle Time (\%)}$$

Random Access Memory (RAM) is managed aggressively by the Linux kernel. Unused memory is considered wasted, so the kernel actively utilizes free RAM for disk caching and buffers. When analyzing memory metrics, we separate:
* Total: Total installed physical memory.
* Used: Memory currently allocated by running user applications and system processes.
* Free: Memory that is completely unallocated and immediately available.
Memory usage percentages are calculated using the mathematical formula:
$$\text{Used \%} = \left(\frac{\text{Used}}{\text{Total}}\right) \times 100$$

Disk storage tracks persistent data allocation across block storage devices (`/dev/sda1`, `/dev/nvme0n1`). These devices are mounted into the root filesystem hierarchy (`/`, `/var`, `/home`).

A process is an active instance of a running program. Each process has a unique process ID (PID) and a parent process ID (PPID). Processes are categorized into CPU-bound (high compute demand) and Memory-bound (large RAM footprint, such as PostgreSQL or Redis).

Load Average represents average system demand over 1, 5, and 15-minute intervals. On a single-core machine, a Load Average of 1.0 indicates 100% capacity utilization. On a 4-core machine, a Load Average of 4.0 represents full utilization without process queue overload.

---

### Granular Command and Pipeline Breakdown

To extract the operating system name, the script executes `grep -E '^PRETTY_NAME=' /etc/os-release | cut -d'=' -f2 | tr -d '"'`.
The `/etc/os-release` file contains standardized OS distribution metadata. The `grep -E` command filters for lines starting with `PRETTY_NAME=`. The `cut -d'=' -f2` utility splits the line by the `=` delimiter and extracts the second field. Finally, `tr -d '"'` removes surrounding double quotes for clean output.

System uptime is retrieved using `uptime -p`. The `-p` flag converts the uptime duration into a clean, human-readable format ("pretty").

To isolate the system load average, the pipeline uses `uptime | awk -F'load average:' '{ print $2 }' | sed 's/^ //'`. The `awk` command with the `-F` flag alters the default column delimiter to the string `load average:`, grabbing everything after it (field 2). The `sed` command strips leading whitespace from the resulting string.

Active user sessions are counted via `who | wc -l`. The `who` command lists active terminal login sessions, and `wc -l` (word count) counts the output lines to determine the total number of logged-in users.

CPU utilization is calculated using `top -bn1 | grep "%Cpu(s)" | awk '{print $8}'`.
By default, `top` opens an interactive terminal UI. The `-b` flag enables batch mode to disable interactive UI rendering for scripting, while `-n1` limits execution to a single iteration before exiting. `grep` filters the summary line containing CPU metrics, and `awk '{print $8}'` extracts column 8, which holds the idle percentage (`%id`). Active CPU usage is then calculated by subtracting the idle percentage from 100 (`100 - idle`).

Memory metrics are parsed using `free -m | awk 'NR==2{ ... }'`.
The `-m` flag formats `free` output in Megabytes. The condition `NR==2` inside `awk` restricts processing strictly to line 2 (the `Mem:` row). Inside `awk`, variables `$2`, `$3`, and `$4` correspond to Total, Used, and Free RAM columns. The script computes percentages and formats the output using `printf`, where `%.2f%%` rounds floating-point values to two decimal places and appends a literal percent sign.

Disk usage is captured via `df -h --total | grep 'total'`.
The `df` utility reports filesystem space, the `-h` flag converts raw bytes to human-readable units (MB, GB), and `--total` appends an aggregated summary line at the end. The `grep 'total'` filter retains only this aggregated total row, filtering out individual partitions.

Top resource-consuming processes are listed using `ps -eo pid,ppid,cmd,%cpu --sort=-%cpu | head -n 6`.
The `-e` flag selects all system processes, while `-o` defines custom output columns (`pid`, `ppid`, process name `cmd`, and `%cpu`). The `--sort=-%cpu` flag sorts processes in descending order of CPU usage (the minus prefix denotes descending order). `head -n 6` isolates the top 6 lines (1 header row + top 5 processes). Sorting by memory usage follows the same logic using `--sort=-%mem`.