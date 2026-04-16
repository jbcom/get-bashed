"""Formatting helpers for the macOS RAM usage helper."""

import math


class Colors:
    BLUE = "\033[94m"
    GREEN = "\033[92m"
    YELLOW = "\033[93m"
    RED = "\033[91m"
    BOLD = "\033[1m"
    RESET = "\033[0m"


def format_bytes(byte_count, precision=2):
    """Format bytes to a human-readable value."""
    if byte_count == 0:
        return "0 B"

    size_names = ["B", "KB", "MB", "GB", "TB"]
    index = int(math.floor(math.log(byte_count, 1024)))
    power = math.pow(1024, index)
    scaled = round(byte_count / power, precision)

    return f"{scaled} {size_names[index]}"


def print_header(memory_stats):
    """Print report header and summary."""
    print(f"{Colors.BLUE}{'=' * 60}{Colors.RESET}")
    print(f"{Colors.BLUE}{Colors.BOLD}     MacOS RAM Usage Monitor     {Colors.RESET}")
    print(f"{Colors.BLUE}{'=' * 60}{Colors.RESET}")

    total = format_bytes(memory_stats["total"])
    used = format_bytes(memory_stats["used"])
    available = format_bytes(memory_stats["available"])

    print(f"{Colors.GREEN}Total RAM:{Colors.RESET} {total}")
    print(f"{Colors.GREEN}Used RAM:{Colors.RESET} {used} ({memory_stats['used_percent']:.2f}%)")
    print(f"{Colors.GREEN}Available RAM:{Colors.RESET} {available}")

    if memory_stats["used_percent"] < 70:
        print(f"{Colors.GREEN}Memory Pressure: Low{Colors.RESET}")
    elif memory_stats["used_percent"] < 85:
        print(f"{Colors.YELLOW}Memory Pressure: Medium{Colors.RESET}")
    else:
        print(f"{Colors.RED}Memory Pressure: High{Colors.RESET}")

    print(f"{Colors.BLUE}{'=' * 60}{Colors.RESET}")
    print()


def print_memory_breakdown(memory_stats):
    """Print detailed memory categories."""
    print(f"{Colors.GREEN}Memory Breakdown:{Colors.RESET}")

    categories = [
        ("active", "Active", "Apps currently in use"),
        ("wired", "Wired", "System/kernel memory"),
        ("inactive", "Inactive", "Recently used, can be freed"),
        ("compressed", "Compressed", "Compressed to save space"),
        ("free", "Free", "Immediately available"),
        ("purgeable", "Purgeable", "Can be reclaimed if needed"),
    ]

    for key, name, description in categories:
        if key in memory_stats:
            print(f"  {name}: {format_bytes(memory_stats[key])} ({description})")

    accounted = (
        memory_stats.get("active", 0)
        + memory_stats.get("wired", 0)
        + memory_stats.get("inactive", 0)
        + memory_stats.get("compressed", 0)
        + memory_stats.get("free", 0)
    )
    unaccounted = memory_stats["total"] - accounted
    if unaccounted > 0:
        print(f"  Unaccounted: {format_bytes(unaccounted)} (Memory used by GPU/file cache)")

    print()


def print_top_processes(processes, total_ram, count=10):
    """Print top processes by RSS."""
    sorted_processes = sorted(processes, key=lambda process: process["rss"], reverse=True)

    print(f"{Colors.GREEN}Top {count} Processes by RAM Usage:{Colors.RESET}")
    print(f"{Colors.BLUE}{'PID':<8}{'MEM':<12}{'%MEM':<8}{'USER':<15}{'COMMAND'}{Colors.RESET}")

    for process in sorted_processes[:count]:
        mem = format_bytes(process["rss"])
        mem_percent = (process["rss"] / total_ram) * 100 if total_ram else 0
        color = ""
        if mem_percent > 10:
            color = Colors.RED
        elif mem_percent > 5:
            color = Colors.YELLOW
        print(
            f"{color}{process['pid']:<8}{mem:<12}{mem_percent:.1f}%{' ':<5}"
            f"{process['user']:<15}{process['command']}{Colors.RESET}"
        )

    print()


def print_app_groups(app_groups, total_ram):
    """Print grouped app memory usage."""
    print(f"{Colors.GREEN}Memory Usage by Application Group:{Colors.RESET}")
    print(f"{Colors.BLUE}{'APPLICATION':<25}{'PROCESSES':<12}{'MEMORY':<15}{'%TOTAL'}{Colors.RESET}")

    total_shown_memory = 0
    sorted_apps = sorted(app_groups.items(), key=lambda item: item[1]["memory"], reverse=True)
    for app_name, data in sorted_apps[:20]:
        memory_percent = (data["memory"] / total_ram) * 100 if total_ram else 0
        total_shown_memory += data["memory"]
        color = ""
        if memory_percent > 10:
            color = Colors.RED
        elif memory_percent > 5:
            color = Colors.YELLOW
        print(
            f"{color}{app_name:<25}{data['count']:<12}{format_bytes(data['memory']):<15}"
            f"{memory_percent:.1f}%{Colors.RESET}"
        )

    print(f"\n{Colors.YELLOW}Total Memory from Top Apps: {format_bytes(total_shown_memory)}{Colors.RESET}")
    print()


def print_report_timestamp(timestamp):
    """Print the timestamp footer."""
    print(f"{Colors.BLUE}Report generated: {timestamp.strftime('%Y-%m-%d %H:%M:%S')}{Colors.RESET}")
