"""
shared_crypto.py — Cryptographic core.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
IMPORTANT: This file must be IDENTICAL in both main.py and keygen.py builds.
The SECRET_SALT is split across multiple variables and reconstructed at
runtime to make static binary analysis harder.
For stronger protection, run: pyarmor gen *.py  before building with PyInstaller.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"""
import hashlib

# ── Secret Salt (split + reconstructed at runtime) ─────────────────────────
# Change ALL four segments before distributing your product.
# Segments must be identical in main.py and keygen.py builds.
_SA = "9Xk#2mPq"
_SB = "!7vR$nL4"
_SC = "wZ@5jBt8"
_SD = "Ue6*Gy3F"
SECRET_SALT: str = _SA + _SB + _SC + _SD   # 32 characters total

# ── Length constants ────────────────────────────────────────────────────────
MACHINE_ID_LENGTH    = 8    # hex chars — shown to end user
ACTIVATION_KEY_LENGTH = 12  # hex chars — entered by end user


def derive_machine_id(cpu_id: str, board_serial: str) -> str:
    """
    Produce an 8-character uppercase hex fingerprint from two hardware strings.
    The separator "|" ensures cpu_id="AB" board="CD" differs from cpu_id="A" board="BCD".
    """
    raw = (cpu_id.strip() + "|" + board_serial.strip()).encode("utf-8")
    return hashlib.sha256(raw).hexdigest()[:MACHINE_ID_LENGTH].upper()


def generate_activation_key(machine_id: str) -> str:
    """
    Generate the 12-character activation key for a given Machine ID.
    Formula: SHA-256( UPPER(machine_id) + SECRET_SALT )[:12].upper()
    """
    payload = (machine_id.strip().upper() + SECRET_SALT).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()[:ACTIVATION_KEY_LENGTH].upper()


def verify_activation_key(machine_id: str, key: str) -> bool:
    """Return True if the key was generated for this machine_id."""
    return generate_activation_key(machine_id) == key.strip().upper()
