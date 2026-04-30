"""
keygen.py — Admin Activation Key Generator.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠  SECURITY: Keep this tool private. NEVER distribute it to end users.
   Anyone who has this EXE can generate keys for any machine.

Usage:
  1. Customer sends you their Machine ID (8-char hex from main.exe).
  2. Paste it in the "Machine ID" field and fill the license details.
  3. Click "Generate Key" — supply the 12-char key to the customer.
  4. Optionally click "Save license.dat" to send the file directly.

Build command (run build.bat instead):
  pyinstaller --onefile --windowed --name "KeyGen_ADMIN" keygen.py
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"""
import tkinter as tk
from tkinter import filedialog, messagebox
from datetime import datetime, timezone, timedelta

from shared_crypto  import generate_activation_key, MACHINE_ID_LENGTH, ACTIVATION_KEY_LENGTH
from license_store  import (
    build_license_record, save_license,
    LICENSE_TYPES, ALL_FEATURES,
)

# ── UI constants ────────────────────────────────────────────────────────────
APP_TITLE = "License Key Generator  —  ADMIN TOOL"
WIN_W     = 540
WIN_H     = 680

BG         = "#0F172A"
BG_CARD    = "#1E293B"
BG_INPUT   = "#162032"
ACCENT     = "#3B82F6"
ACCENT_HVR = "#2563EB"
TEXT       = "#E2E8F0"
TEXT_MUTED = "#94A3B8"
SUCCESS    = "#10B981"
ERROR      = "#EF4444"
WARN       = "#F59E0B"
DANGER_BG  = "#7F1D1D"

F_HEAD  = ("Segoe UI", 15, "bold")
F_BODY  = ("Segoe UI", 11)
F_MONO  = ("Courier New", 14, "bold")
F_SMALL = ("Segoe UI", 9)
F_LABEL = ("Segoe UI", 9, "bold")


def _center(win: tk.Misc, w: int, h: int) -> None:
    win.update_idletasks()
    sw = win.winfo_screenwidth()
    sh = win.winfo_screenheight()
    win.geometry(f"{w}x{h}+{(sw - w) // 2}+{(sh - h) // 2}")


def _label(parent, text: str, color=TEXT_MUTED) -> tk.Label:
    lbl = tk.Label(parent, text=text, bg=BG, fg=color, font=F_LABEL, anchor="w")
    lbl.pack(fill="x", pady=(10, 2))
    return lbl


def _input_frame(parent) -> tk.Frame:
    f = tk.Frame(parent, bg=BG_INPUT, bd=0)
    f.pack(fill="x", pady=(0, 2))
    return f


def _entry(parent, var: tk.Variable, mono=False, **kw) -> tk.Entry:
    frm = _input_frame(parent)
    e = tk.Entry(
        frm, textvariable=var,
        bg=BG_INPUT, fg=TEXT, insertbackground=TEXT,
        font=F_MONO if mono else F_BODY,
        relief="flat", bd=0, **kw,
    )
    e.pack(fill="x", padx=10, pady=8)
    return e


# ══════════════════════════════════════════════════════════════════════════════
#  Main keygen window
# ══════════════════════════════════════════════════════════════════════════════
class KeygenApp:
    def __init__(self, root: tk.Tk):
        self._root = root
        root.title(APP_TITLE)
        root.configure(bg=BG)
        root.resizable(False, False)
        _center(root, WIN_W, WIN_H)
        self._build()

    # ── Layout ────────────────────────────────────────────────────────────

    def _build(self) -> None:
        # ── Warning banner ────────────────────────────────────────────────
        warn = tk.Frame(self._root, bg=DANGER_BG)
        warn.pack(fill="x")
        tk.Label(warn,
                 text="⚠  ADMIN TOOL — Do NOT distribute to end users  ⚠",
                 bg=DANGER_BG, fg="#FECACA", font=F_SMALL,
                 padx=16, pady=6).pack()

        # ── Header ────────────────────────────────────────────────────────
        hdr = tk.Frame(self._root, bg=BG_CARD)
        hdr.pack(fill="x")
        tk.Label(hdr, text="🔑  License Key Generator",
                 bg=BG_CARD, fg=TEXT, font=F_HEAD,
                 padx=24, pady=14).pack(anchor="w")

        # ── Scrollable content area ────────────────────────────────────────
        content = tk.Frame(self._root, bg=BG)
        content.pack(fill="both", expand=True, padx=24, pady=10)

        # Machine ID
        _label(content, "Machine ID  *  (8-char hex from customer's machine)")
        self._mid_var = tk.StringVar()
        self._mid_entry = _entry(content, self._mid_var, mono=True)
        self._mid_entry.focus_set()

        # Issued To
        _label(content, "Issued To  (customer name / company)")
        self._name_var = tk.StringVar()
        _entry(content, self._name_var)

        # License Type
        _label(content, "License Type")
        self._type_var = tk.StringVar(value=LICENSE_TYPES[0])
        type_row = tk.Frame(content, bg=BG)
        type_row.pack(fill="x", pady=(0, 4))
        for lt in LICENSE_TYPES:
            tk.Radiobutton(
                type_row, text=lt.title(),
                variable=self._type_var, value=lt,
                bg=BG, fg=TEXT, selectcolor=BG_CARD,
                activebackground=BG, font=F_SMALL,
            ).pack(side="left", padx=(0, 10))

        # Features
        _label(content, "Features  (check all that apply)")
        feat_row = tk.Frame(content, bg=BG)
        feat_row.pack(fill="x", pady=(0, 4))
        self._feat_vars: dict[str, tk.BooleanVar] = {}
        for feat in ALL_FEATURES:
            v = tk.BooleanVar(value=(feat == "all"))
            self._feat_vars[feat] = v
            tk.Checkbutton(
                feat_row, text=feat,
                variable=v, bg=BG, fg=TEXT,
                selectcolor=BG_CARD, activebackground=BG,
                font=F_SMALL,
            ).pack(side="left", padx=(0, 8))

        # Expiry
        _label(content, "Expires  (ISO datetime, leave blank = perpetual)")
        exp_row = tk.Frame(content, bg=BG)
        exp_row.pack(fill="x", pady=(0, 2))
        self._exp_var = tk.StringVar()
        frm = _input_frame(exp_row)
        tk.Entry(frm, textvariable=self._exp_var,
                 bg=BG_INPUT, fg=TEXT, insertbackground=TEXT,
                 font=F_BODY, relief="flat", bd=0).pack(
            fill="x", padx=10, pady=8)
        shortcuts = tk.Frame(content, bg=BG)
        shortcuts.pack(fill="x", pady=(0, 4))
        for days, label in [(30, "30 days"), (90, "90 days"),
                            (365, "1 year"), (0, "Perpetual ∞")]:
            tk.Button(
                shortcuts, text=label,
                bg=BG_CARD, fg=TEXT_MUTED,
                relief="flat", bd=0, font=F_SMALL, padx=8, pady=4,
                cursor="hand2",
                command=lambda d=days: self._set_expiry(d),
            ).pack(side="left", padx=(0, 4))

        # Max users
        _label(content, "Max Users  (-1 = unlimited)")
        self._users_var = tk.StringVar(value="-1")
        _entry(content, self._users_var)

        # Notes
        _label(content, "Notes  (internal reference)")
        self._notes_var = tk.StringVar()
        _entry(content, self._notes_var)

        # ── Generate button ────────────────────────────────────────────────
        tk.Button(
            content, text="  Generate Activation Key  ",
            bg=ACCENT, fg="white",
            activebackground=ACCENT_HVR, activeforeground="white",
            relief="flat", bd=0, cursor="hand2",
            font=("Segoe UI", 12, "bold"), pady=10,
            command=self._generate,
        ).pack(fill="x", pady=(14, 8))

        # ── Output card ────────────────────────────────────────────────────
        out = tk.Frame(content, bg=BG_CARD)
        out.pack(fill="x")

        key_col = tk.Frame(out, bg=BG_CARD)
        key_col.pack(side="left", fill="both", expand=True, padx=14, pady=10)
        tk.Label(key_col, text="Activation Key:",
                 bg=BG_CARD, fg=TEXT_MUTED, font=F_SMALL).pack(anchor="w")
        self._key_var = tk.StringVar(value="—  (not yet generated)")
        self._key_lbl = tk.Label(
            key_col, textvariable=self._key_var,
            bg=BG_CARD, fg=ACCENT, font=F_MONO,
            cursor="hand2",
        )
        self._key_lbl.pack(anchor="w")
        self._key_lbl.bind("<Button-1>", lambda _: self._copy_key())
        tk.Label(key_col, text="(click key to copy)",
                 bg=BG_CARD, fg=TEXT_MUTED, font=F_SMALL).pack(anchor="w")

        btn_col = tk.Frame(out, bg=BG_CARD)
        btn_col.pack(side="right", padx=14, pady=10)
        tk.Button(
            btn_col, text="📋 Copy Key",
            bg=BG, fg=TEXT, relief="flat", bd=0,
            font=F_SMALL, padx=8, pady=5, cursor="hand2",
            command=self._copy_key,
        ).pack(pady=(0, 4))
        tk.Button(
            btn_col, text="💾 Save license.dat",
            bg=BG, fg=TEXT, relief="flat", bd=0,
            font=F_SMALL, padx=8, pady=5, cursor="hand2",
            command=self._save_license_file,
        ).pack()

        # ── Status bar ────────────────────────────────────────────────────
        self._status_var = tk.StringVar()
        self._status_lbl = tk.Label(
            content, textvariable=self._status_var,
            bg=BG, fg=SUCCESS, font=F_SMALL,
        )
        self._status_lbl.pack(anchor="w", pady=(6, 0))

        # Store generated record for saving
        self._last_record: dict | None = None

    # ── Actions ───────────────────────────────────────────────────────────

    def _set_expiry(self, days: int) -> None:
        if days == 0:
            self._exp_var.set("")
        else:
            dt = datetime.now(timezone.utc) + timedelta(days=days)
            self._exp_var.set(dt.isoformat())

    def _collect_features(self) -> list[str]:
        return [f for f, v in self._feat_vars.items() if v.get()]

    def _validate_inputs(self) -> str | None:
        """Return error message string if invalid, else None."""
        mid = self._mid_var.get().strip().upper()
        if not mid:
            return "Machine ID is required."
        if len(mid) != MACHINE_ID_LENGTH:
            return (
                f"Machine ID must be exactly {MACHINE_ID_LENGTH} characters. "
                f"Got {len(mid)}."
            )
        exp = self._exp_var.get().strip()
        if exp:
            try:
                datetime.fromisoformat(exp)
            except ValueError:
                return "Invalid expiry date format. Use ISO format e.g. 2027-12-31T00:00:00"
        users = self._users_var.get().strip()
        try:
            int(users)
        except ValueError:
            return "Max Users must be an integer (-1 for unlimited)."
        return None

    def _generate(self) -> None:
        err = self._validate_inputs()
        if err:
            messagebox.showerror("Validation Error", err, parent=self._root)
            return

        mid      = self._mid_var.get().strip().upper()
        key      = generate_activation_key(mid)
        features = self._collect_features() or ["all"]
        exp      = self._exp_var.get().strip() or None

        self._last_record = build_license_record(
            machine_id=mid,
            activation_key=key,
            license_type=self._type_var.get(),
            features=features,
            issued_to=self._name_var.get().strip(),
            expires_at=exp,
            max_users=int(self._users_var.get().strip()),
            notes=self._notes_var.get().strip(),
        )

        self._key_var.set(key)
        self._set_status(
            f"✓ Key generated for machine {mid}  —  click to copy.", SUCCESS)

    def _copy_key(self) -> None:
        key = self._key_var.get()
        if key.startswith("—"):
            self._set_status("Generate a key first.", WARN)
            return
        self._root.clipboard_clear()
        self._root.clipboard_append(key)
        self._set_status("✓ Activation Key copied to clipboard.", SUCCESS)

    def _save_license_file(self) -> None:
        if not self._last_record:
            self._set_status("Generate a key first, then save.", WARN)
            return
        path = filedialog.asksaveasfilename(
            parent=self._root,
            title="Save license.dat",
            defaultextension=".dat",
            initialfile="license.dat",
            filetypes=[("License file", "*.dat"), ("All files", "*.*")],
        )
        if not path:
            return
        try:
            save_license(self._last_record, path)
            self._set_status(f"✓ License file saved to: {path}", SUCCESS)
        except Exception as e:
            messagebox.showerror("Save Error", str(e), parent=self._root)

    def _set_status(self, msg: str, color: str) -> None:
        self._status_var.set(msg)
        self._status_lbl.config(fg=color)
        self._root.after(6000, lambda: self._status_var.set(""))


# ══════════════════════════════════════════════════════════════════════════════
#  Entry point
# ══════════════════════════════════════════════════════════════════════════════

def main() -> None:
    root = tk.Tk()
    KeygenApp(root)
    root.mainloop()


if __name__ == "__main__":
    main()
