"""Core data collection for the macOS RAM usage helper."""

from collections import defaultdict
from datetime import datetime
import os
import re
import subprocess

from ram_usage_report import print_app_groups
from ram_usage_report import print_header
from ram_usage_report import print_memory_breakdown
from ram_usage_report import print_report_timestamp
from ram_usage_report import print_top_processes


def get_command_output(command):
    """Run a command and return its output as a string."""
    try:
        result = subprocess.run(command, check=True, capture_output=True, text=True)
        return result.stdout
    except subprocess.CalledProcessError as exc:
        print(f"Error running command: {command}")
        print(f"Error message: {exc.stderr}")
        return ""


def get_total_ram():
    """Get total physical RAM."""
    output = get_command_output(["sysctl", "hw.memsize"])
    if output:
        match = re.search(r"hw.memsize: (\d+)", output)
        if match:
            return int(match.group(1))
    return 0


def parse_vm_stat():
    """Parse vm_stat into a memory summary dictionary."""
    output = get_command_output(["vm_stat"])
    if not output:
        return {}

    first_line = output.split("\n")[0]
    page_size_match = re.search(r"page size of (\d+) bytes", first_line)
    if not page_size_match:
        return {}

    page_size = int(page_size_match.group(1))
    memory_stats = {}
    patterns = {
        "free": r"Pages free:\s+(\d+)",
        "active": r"Pages active:\s+(\d+)",
        "inactive": r"Pages inactive:\s+(\d+)",
        "speculative": r"Pages speculative:\s+(\d+)",
        "wired": r"Pages wired down:\s+(\d+)",
        "compressed": r"Pages occupied by compressor:\s+(\d+)",
        "purgeable": r"Pages purgeable:\s+(\d+)",
    }

    for key, pattern in patterns.items():
        match = re.search(pattern, output)
        if match:
            pages = int(match.group(1).replace(".", ""))
            memory_stats[key] = pages * page_size

    memory_stats["total"] = get_total_ram()
    memory_stats["available"] = (
        memory_stats.get("free", 0)
        + memory_stats.get("purgeable", 0)
        + memory_stats.get("inactive", 0)
        + memory_stats.get("speculative", 0)
    )
    memory_stats["used"] = memory_stats["total"] - memory_stats["available"]

    if memory_stats["total"] > 0:
        memory_stats["used_percent"] = (memory_stats["used"] / memory_stats["total"]) * 100
    else:
        memory_stats["used_percent"] = 0

    return memory_stats


def get_process_memory():
    """Collect process memory usage."""
    output = get_command_output(["ps", "-eo", "pid,rss,vsz,user,comm"])
    processes = []

    for line in output.strip().split("\n")[1:]:
        parts = line.split(None, 4)
        if len(parts) < 5:
            continue
        try:
            pid, rss, vsz, user, command = parts
            processes.append(
                {
                    "pid": int(pid),
                    "rss": int(rss) * 1024,
                    "vsz": int(vsz) * 1024,
                    "user": user,
                    "command": command,
                }
            )
        except (ValueError, IndexError):
            continue

    return processes


def group_processes_by_app(processes):
    """Group processes by app name."""
    app_groups = defaultdict(lambda: {"count": 0, "memory": 0, "pids": []})

    for process in processes:
        command = process["command"]
        app_name = os.path.basename(command)

        if "chrome" in command.lower() or "google chrome" in command.lower():
            app_name = "Google Chrome"
        elif "firefox" in command.lower():
            app_name = "Firefox"
        elif "safari" in command.lower():
            app_name = "Safari"
        elif "slack" in command.lower():
            app_name = "Slack"
        elif "vs code" in command.lower() or "code helper" in command.lower():
            app_name = "VS Code"
        elif "cursor" in command.lower():
            app_name = "Cursor"
        elif "iterm" in command.lower():
            app_name = "iTerm"
        elif "terminal" in command.lower():
            app_name = "Terminal"
        elif "finder" in command.lower():
            app_name = "Finder"
        elif "kernel" in command.lower():
            app_name = "Kernel"
        elif "launchd" in command.lower():
            app_name = "System (launchd)"
        elif "windowserver" in command.lower():
            app_name = "WindowServer"

        app_groups[app_name]["count"] += 1
        app_groups[app_name]["memory"] += process["rss"]
        app_groups[app_name]["pids"].append(process["pid"])

    return app_groups


def main():
    """Collect memory information and print the report."""
    memory_stats = parse_vm_stat()
    if not memory_stats:
        print("Error: Could not get memory statistics")
        return 1

    processes = get_process_memory()
    if not processes:
        print("Error: Could not get process information")
        return 1

    app_groups = group_processes_by_app(processes)

    print_header(memory_stats)
    print_memory_breakdown(memory_stats)
    print_top_processes(processes, memory_stats["total"])
    print_app_groups(app_groups, memory_stats["total"])
    print_report_timestamp(datetime.now())

    return 0
