"""
main.py — License-protected application entry point.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Activation flow
───────────────
First run   : No license.dat  → show Machine ID → ask for Activation Key.
Valid key   : Write license.dat → open main application.
Second run  : Read license.dat → verify hash matches THIS machine → open.
Copied file : Hash mismatch on new PC → show activation screen again.
Expired     : expires_at is past → error dialog → app closes.

Build command (run build.bat instead):
  pyinstaller --onefile --windowed --name "MyApp" main.py

Obfuscation (recommended before building):
  pyarmor gen main.py shared_crypto.py hardware_id.py license_store.py
  then build from the pyarmor output folder.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"""
import tkinter as tk
from tkinter import messagebox

from shared_crypto  import derive_machine_id, verify_activation_key
from hardware_id    import get_cpu_id, get_board_serial
from license_store  import load_license, save_license, build_license_record

# ── Application metadata  (edit these) ─────────────────────────────────────
APP_NAME    = "MyApp"
APP_VERSION = "1.0.0"
VENDOR_NAME = "Your Company Name"

# ── UI constants ────────────────────────────────────────────────────────────
WIN_W          = 480
WIN_H_ACTIVATE = 440
WIN_H_APP      = 520

BG         = "#0F172A"
BG_CARD    = "#1E293B"
ACCENT     = "#3B82F6"
ACCENT_HVR = "#2563EB"
TEXT       = "#E2E8F0"
TEXT_MUTED = "#94A3B8"
SUCCESS    = "#10B981"
ERROR      = "#EF4444"
WARN       = "#F59E0B"

F_HEAD  = ("Segoe UI", 18, "bold")
F_BODY  = ("Segoe UI", 11)
F_MONO  = ("Courier New", 13, "bold")
F_SMALL = ("Segoe UI", 9)


def _center(win: tk.Misc, w: int, h: int) -> None:
    win.update_idletasks()
    sw = win.winfo_screenwidth()
    sh = win.winfo_screenheight()
    win.geometry(f"{w}x{h}+{(sw - w) // 2}+{(sh - h) // 2}")


def _btn(parent, text, cmd, bg=ACCENT, fg="white", **kw) -> tk.Button:
    return tk.Button(
        parent, text=text, command=cmd,
        bg=bg, fg=fg, activebackground=ACCENT_HVR, activeforeground="white",
        relief="flat", bd=0, cursor="hand2",
        font=("Segoe UI", 11, "bold"),
        padx=16, pady=9, **kw,
    )


# ══════════════════════════════════════════════════════════════════════════════
#  Activation Screen
# ══════════════════════════════════════════════════════════════════════════════
class ActivationScreen:
    """
    Shown when no valid license.dat is found.
    Displays the Machine ID and accepts an Activation Key.
    """

    def __init__(self, root: tk.Tk, machine_id: str, on_activated):
        self._root       = root
        self._machine_id = machine_id
        self._on_activated = on_activated

        root.title(f"{APP_NAME} — Activation Required")
        root.configure(bg=BG)
        root.resizable(False, False)
        _center(root, WIN_W, WIN_H_ACTIVATE)
        self._build()

    # ── Layout ────────────────────────────────────────────────────────────

    def _build(self) -> None:
        P = dict(padx=32, pady=0)

        # ── Header ────────────────────────────────────────────────────────
        tk.Label(self._root, text="🔒  Activation Required",
                 bg=BG, fg=TEXT, font=F_HEAD).pack(pady=(28, 4))
        tk.Label(self._root, text=f"{APP_NAME}  v{APP_VERSION}  ·  {VENDOR_NAME}",
                 bg=BG, fg=TEXT_MUTED, font=F_SMALL).pack()
        tk.Frame(self._root, bg=ACCENT, height=2).pack(fill="x", padx=32, pady=14)

        # ── Machine ID display ─────────────────────────────────────────────
        tk.Label(self._root, text="Your Machine ID (send this to your vendor):",
                 bg=BG, fg=TEXT_MUTED, font=F_SMALL).pack(**P, anchor="w")

        mid_card = tk.Frame(self._root, bg=BG_CARD)
        mid_card.pack(fill="x", padx=32, pady=(4, 14))

        self._mid_lbl = tk.Label(
            mid_card, text=self._machine_id,
            bg=BG_CARD, fg=ACCENT, font=F_MONO,
            padx=14, pady=12, cursor="hand2",
        )
        self._mid_lbl.pack(side="left")
        self._mid_lbl.bind("<Button-1>", lambda _: self._copy_mid())

        tk.Label(mid_card, text="← click to copy",
                 bg=BG_CARD, fg=TEXT_MUTED, font=F_SMALL).pack(side="left", padx=4)

        # ── Instructions ──────────────────────────────────────────────────
        tk.Label(
            self._root,
            text=(
                "Copy your Machine ID above and send it to your software vendor.\n"
                "You will receive an Activation Key — enter it below."
            ),
            bg=BG, fg=TEXT_MUTED, font=F_SMALL, justify="center",
        ).pack(**P, pady=(0, 14))

        # ── Key entry ─────────────────────────────────────────────────────
        tk.Label(self._root, text="Activation Key:",
                 bg=BG, fg=TEXT_MUTED, font=F_BODY).pack(**P, anchor="w")

        self._key_var = tk.StringVar()
        key_card = tk.Frame(self._root, bg=BG_CARD)
        key_card.pack(fill="x", padx=32, pady=(4, 4))
        self._key_entry = tk.Entry(
            key_card, textvariable=self._key_var,
            bg=BG_CARD, fg=TEXT, insertbackground=TEXT,
            font=F_MONO, relief="flat", bd=0,
        )
        self._key_entry.pack(fill="x", padx=14, pady=10)
        self._key_entry.bind("<Return>", lambda _: self._activate())
        self._key_entry.focus_set()

        # ── Status message ────────────────────────────────────────────────
        self._status_var = tk.StringVar()
        self._status_lbl = tk.Label(
            self._root, textvariable=self._status_var,
            bg=BG, fg=ERROR, font=F_SMALL,
        )
        self._status_lbl.pack(pady=(4, 8))

        # ── Activate button ───────────────────────────────────────────────
        _btn(self._root, "  Activate  ", self._activate).pack(
            fill="x", padx=32, pady=(0, 24))

    # ── Actions ───────────────────────────────────────────────────────────

    def _copy_mid(self) -> None:
        self._root.clipboard_clear()
        self._root.clipboard_append(self._machine_id)
        self._status_var.set("✓ Machine ID copied to clipboard")
        self._status_lbl.config(fg=SUCCESS)
        self._root.after(2500, lambda: self._status_var.set(""))

    def _activate(self) -> None:
        key = self._key_var.get().strip().upper()
        if not key:
            self._set_status("Please enter the activation key.", ERROR)
            return

        if verify_activation_key(self._machine_id, key):
            record = build_license_record(
                machine_id=self._machine_id,
                activation_key=key,
            )
            save_license(record)
            self._set_status("✓ Activation successful! Opening application…", SUCCESS)
            self._root.after(900, lambda: self._on_activated(record))
        else:
            self._set_status(
                "✗ Invalid key — please check and try again.", ERROR)
            self._key_var.set("")
            self._key_entry.focus_set()

    def _set_status(self, msg: str, color: str) -> None:
        self._status_var.set(msg)
        self._status_lbl.config(fg=color)


# ══════════════════════════════════════════════════════════════════════════════
#  Main Application Screen
#  ► Replace the body section marked below with your real application UI.
# ══════════════════════════════════════════════════════════════════════════════
class MainApplicationScreen:
    """
    Shown after a valid license has been confirmed.
    Replace the "APPLICATION BODY" section with your real UI.
    """

    def __init__(self, root: tk.Tk, license_record: dict):
        self._root = root
        root.title(f"{APP_NAME}  v{APP_VERSION}  — Licensed")
        root.configure(bg=BG)
        root.resizable(True, True)
        _center(root, WIN_W, WIN_H_APP)
        self._build(license_record)

    def _build(self, lic: dict) -> None:
        # ── License banner ────────────────────────────────────────────────
        banner = tk.Frame(self._root, bg=BG_CARD)
        banner.pack(fill="x")
        tk.Label(banner, text=f"✅  {APP_NAME}  —  Licensed",
                 bg=BG_CARD, fg=SUCCESS, font=F_HEAD,
                 padx=24, pady=14).pack(side="left")
        tk.Label(banner, text=f"v{APP_VERSION}",
                 bg=BG_CARD, fg=TEXT_MUTED, font=F_SMALL,
                 padx=8).pack(side="right", anchor="s", pady=18)

        # ── License info strip ────────────────────────────────────────────
        info_rows = [
            ("Machine ID",   lic.get("machine_id", "")),
            ("License Type", lic.get("license_type", "full").title()),
            ("Issued To",    lic.get("issued_to") or "—"),
            ("Activated",    (lic.get("activated_at") or "")[:10]),
            ("Expires",      lic.get("expires_at", "Never") or "Never"),
            ("Features",     ", ".join(lic.get("features", ["all"]))),
        ]
        info_frame = tk.Frame(self._root, bg=BG)
        info_frame.pack(fill="x", padx=24, pady=12)
        for label, value in info_rows:
            row = tk.Frame(info_frame, bg=BG)
            row.pack(fill="x", pady=1)
            tk.Label(row, text=f"{label}:", bg=BG, fg=TEXT_MUTED,
                     font=F_SMALL, width=14, anchor="w").pack(side="left")
            tk.Label(row, text=value, bg=BG, fg=TEXT,
                     font=F_SMALL, anchor="w").pack(side="left")

        tk.Frame(self._root, bg=BG_CARD, height=1).pack(fill="x", padx=24, pady=8)

        # ════════════════════════════════════════════════════════════════
        # ► APPLICATION BODY — replace everything below this comment
        #   with your real application widgets / logic.
        # ════════════════════════════════════════════════════════════════
        tk.Label(
            self._root,
            text=(
                "Your application content goes here.\n\n"
                "In main.py, replace this section\n"
                "(inside MainApplicationScreen._build)\n"
                "with your real application UI."
            ),
            bg=BG, fg=TEXT_MUTED, font=F_BODY, justify="center",
        ).pack(expand=True)
        # ════════════════════════════════════════════════════════════════
        # ► END APPLICATION BODY
        # ════════════════════════════════════════════════════════════════


# ══════════════════════════════════════════════════════════════════════════════
#  Entry point
# ══════════════════════════════════════════════════════════════════════════════

def _open_app(root: tk.Tk, record: dict) -> None:
    """Clear all widgets and show the main application screen."""
    for widget in root.winfo_children():
        widget.destroy()
    MainApplicationScreen(root, record)


def main() -> None:
    # ── Step 1: collect hardware fingerprint ──────────────────────────────
    cpu_id       = get_cpu_id()
    board_serial = get_board_serial()
    machine_id   = derive_machine_id(cpu_id, board_serial)

    # ── Step 2: check existing license ────────────────────────────────────
    lic = load_license()

    root = tk.Tk()

    if lic is not None:
        key_valid     = verify_activation_key(lic.machine_id, lic.activation_key)
        machine_match = lic.machine_id == machine_id

        if key_valid and machine_match:
            # ── Valid license for this machine ─────────────────────────
            if lic.is_expired():
                messagebox.showerror(
                    "License Expired",
                    f"Your license expired on {(lic.expires_at or '')[:10]}.\n"
                    "Please contact your vendor to renew.",
                    parent=root,
                )
                root.destroy()
                return
            _open_app(root, lic.to_dict())
        else:
            # License file is corrupt or belongs to a different machine
            reason = (
                "The license file does not match this computer's hardware."
                if key_valid else
                "The license file is invalid or has been tampered with."
            )
            messagebox.showwarning(
                "License Problem",
                f"{reason}\n\nPlease enter a valid Activation Key.",
                parent=root,
            )
            ActivationScreen(root, machine_id,
                             lambda rec: _open_app(root, rec))
    else:
        # ── No license found — show activation screen ──────────────────
        ActivationScreen(root, machine_id,
                         lambda rec: _open_app(root, rec))

    root.mainloop()


if __name__ == "__main__":
    main()
