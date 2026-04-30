"""
hardware_id.py — Hardware fingerprinting.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Priority chain (Windows):
  1. WMIC (wmic.exe) — works on Windows 7–11 22H2
  2. PowerShell Get-WmiObject — fallback for Windows 11 24H2+ (wmic removed)
  3. Platform/UUID hash  — cross-platform last resort

The final Machine ID hash is deterministic as long as the CPU and
motherboard do not change. VM environments may return generic strings;
that is acceptable — the hash will still be unique per VM instance.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"""
import platform
import subprocess
import uuid
from typing import Optional


# ── Internal helpers ────────────────────────────────────────────────────────

_JUNK_VALUES = {
    "", "to be filled by o.e.m.", "none", "n/a",
    "default string", "not applicable", "system serial number",
    "base board serial number", "0000000000000000",
}


def _clean(value: str) -> Optional[str]:
    """Return value if it looks real, else None."""
    v = value.strip().lower()
    return None if v in _JUNK_VALUES else value.strip()


def _run_wmic(args: list[str]) -> str:
    """Execute wmic with the given args and return the first data line."""
    try:
        out = subprocess.check_output(
            ["wmic"] + args,
            stderr=subprocess.DEVNULL,
            timeout=6,
            creationflags=0x08000000,   # CREATE_NO_WINDOW
        ).decode(errors="ignore")
        lines = [l.strip() for l in out.splitlines() if l.strip()]
        # lines[0] is the header; lines[1] is the value
        return lines[1] if len(lines) > 1 else ""
    except Exception:
        return ""


def _run_powershell(expression: str) -> str:
    """Run a PowerShell one-liner and return stripped output."""
    try:
        out = subprocess.check_output(
            [
                "powershell",
                "-NonInteractive", "-NoProfile",
                "-Command", expression,
            ],
            stderr=subprocess.DEVNULL,
            timeout=8,
            creationflags=0x08000000,
        ).decode(errors="ignore")
        return out.strip()
    except Exception:
        return ""


# ── Public accessors ────────────────────────────────────────────────────────

def get_cpu_id() -> str:
    """Return CPU Processor ID string."""
    # 1. WMIC
    val = _clean(_run_wmic(["cpu", "get", "ProcessorId"]))
    if val:
        return val

    # 2. PowerShell WMI
    val = _clean(_run_powershell(
        "(Get-WmiObject -Class Win32_Processor).ProcessorId"
    ))
    if val:
        return val

    # 3. Cross-platform fallback
    return platform.processor() or platform.machine() or "UNKNOWN_CPU"


def get_board_serial() -> str:
    """Return motherboard / baseboard serial number."""
    # 1. WMIC
    val = _clean(_run_wmic(["baseboard", "get", "SerialNumber"]))
    if val:
        return val

    # 2. PowerShell WMI
    val = _clean(_run_powershell(
        "(Get-WmiObject -Class Win32_BaseBoard).SerialNumber"
    ))
    if val:
        return val

    # 3. System UUID via PowerShell
    val = _clean(_run_powershell(
        "(Get-WmiObject -Class Win32_ComputerSystemProduct).UUID"
    ))
    if val:
        return val

    # 4. MAC address as last resort (stable across reboots on physical NICs)
    return str(uuid.getnode())


def collect_hardware_info() -> dict:
    """Return a diagnostic dict with all raw hardware strings."""
    return {
        "cpu_id":       get_cpu_id(),
        "board_serial": get_board_serial(),
        "hostname":     platform.node(),
        "platform":     platform.system(),
        "release":      platform.release(),
        "machine":      platform.machine(),
    }
