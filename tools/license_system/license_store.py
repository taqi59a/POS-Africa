"""
license_store.py — Versioned license file manager.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Schema is versioned from day one so future releases can add fields
(expiry dates, feature flags, user limits, tier levels, etc.) without
breaking existing license files already deployed in the field.

Current schema version: 1
Upgrade path: add elif blocks inside _migrate() and bump CURRENT_SCHEMA_VERSION.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

File location (auto-detected):
  • PyInstaller EXE → same folder as the .exe
  • Running as .py  → same folder as this script
"""
import json
import os
import sys
from datetime import datetime, timezone
from typing import Optional

# ── Schema constants ────────────────────────────────────────────────────────
CURRENT_SCHEMA_VERSION = 1
LICENSE_FILE_NAME       = "license.dat"

# Available license tiers
LICENSE_TYPES = ["full", "trial", "enterprise", "academic"]

# Available feature flags (extend freely for future versions)
ALL_FEATURES = ["pos", "inventory", "reports", "multi_user", "api", "all"]


# ── Path resolution ──────────────────────────────────────────────────────────

def get_license_path() -> str:
    """Return the absolute path to license.dat next to the running executable."""
    if getattr(sys, "frozen", False):
        # PyInstaller bundle — use the EXE's directory
        app_dir = os.path.dirname(sys.executable)
    else:
        # Running as a plain .py script
        app_dir = os.path.dirname(os.path.abspath(__file__))
    return os.path.join(app_dir, LICENSE_FILE_NAME)


# ── Data model ───────────────────────────────────────────────────────────────

class LicenseData:
    """
    Immutable view of a parsed license record.

    Adding a new field in a future schema version:
      1. Add a property below with a sensible default.
      2. Add the field to build_license_record().
      3. Add a migration step in _migrate() and bump CURRENT_SCHEMA_VERSION.
    """

    def __init__(self, data: dict):
        self._d = data

    # ── Schema v1 fields ───────────────────────────────────────────────────
    @property
    def schema_version(self) -> int:
        return int(self._d.get("version", 1))

    @property
    def machine_id(self) -> str:
        return str(self._d.get("machine_id", "")).upper()

    @property
    def activation_key(self) -> str:
        return str(self._d.get("activation_key", "")).upper()

    @property
    def license_type(self) -> str:
        return str(self._d.get("license_type", "full"))

    @property
    def features(self) -> list[str]:
        return list(self._d.get("features", ["all"]))

    @property
    def activated_at(self) -> str:
        return str(self._d.get("activated_at", ""))

    @property
    def issued_to(self) -> str:
        return str(self._d.get("issued_to", ""))

    @property
    def expires_at(self) -> Optional[str]:
        v = self._d.get("expires_at")
        return str(v) if v else None

    @property
    def max_users(self) -> int:
        """Maximum concurrent users. -1 = unlimited."""
        return int(self._d.get("max_users", -1))

    @property
    def notes(self) -> str:
        return str(self._d.get("notes", ""))

    # ── Schema v2+ reserved (future) ──────────────────────────────────────
    # @property
    # def subscription_id(self) -> Optional[str]:
    #     return self._d.get("subscription_id")   # v2

    # ── Derived helpers ────────────────────────────────────────────────────
    def is_expired(self) -> bool:
        if not self.expires_at:
            return False
        try:
            exp = datetime.fromisoformat(self.expires_at)
            if exp.tzinfo is None:
                exp = exp.replace(tzinfo=timezone.utc)
            return datetime.now(timezone.utc) > exp
        except Exception:
            return False

    def has_feature(self, feature: str) -> bool:
        return "all" in self.features or feature in self.features

    def to_dict(self) -> dict:
        return dict(self._d)

    def summary(self) -> str:
        exp = self.expires_at[:10] if self.expires_at else "Never"
        return (
            f"Machine: {self.machine_id}  |  "
            f"Type: {self.license_type}  |  "
            f"Expires: {exp}"
        )


# ── Builder ───────────────────────────────────────────────────────────────────

def build_license_record(
    machine_id: str,
    activation_key: str,
    *,
    license_type: str = "full",
    features: Optional[list[str]] = None,
    issued_to: str = "",
    expires_at: Optional[str] = None,
    max_users: int = -1,
    notes: str = "",
) -> dict:
    """
    Build a fully versioned license dict ready to be written to disk.
    Add new keyword arguments here when the schema is extended.
    """
    return {
        # ── Schema metadata ────────────────────────────────────────────────
        "version":        CURRENT_SCHEMA_VERSION,
        "schema":         f"pos_license_v{CURRENT_SCHEMA_VERSION}",
        # ── Core identity ──────────────────────────────────────────────────
        "machine_id":     machine_id.strip().upper(),
        "activation_key": activation_key.strip().upper(),
        # ── License details ────────────────────────────────────────────────
        "license_type":   license_type,
        "features":       features if features is not None else ["all"],
        "issued_to":      issued_to.strip(),
        "max_users":      max_users,
        # ── Timestamps ────────────────────────────────────────────────────
        "activated_at":   datetime.now(timezone.utc).isoformat(),
        "expires_at":     expires_at,           # None = perpetual
        # ── Metadata ──────────────────────────────────────────────────────
        "notes":          notes.strip(),
        # reserved for future schema versions:
        # "subscription_id": None,
        # "hardware_fingerprint_v2": None,
    }


# ── Migration ─────────────────────────────────────────────────────────────────

def _migrate(data: dict) -> dict:
    """
    Upgrade an old license dict to the current schema version.
    Add elif blocks as schema versions increase.
    """
    version = int(data.get("version", 1))

    # Example future migration:
    # if version < 2:
    #     data.setdefault("subscription_id", None)
    #     data["version"] = 2
    #     version = 2

    # if version < 3:
    #     data.setdefault("hardware_fingerprint_v2", "")
    #     data["version"] = 3

    return data


# ── I/O ───────────────────────────────────────────────────────────────────────

def save_license(record: dict, path: Optional[str] = None) -> None:
    """Serialize record to disk as pretty-printed JSON."""
    target = path or get_license_path()
    with open(target, "w", encoding="utf-8") as f:
        json.dump(record, f, indent=2, ensure_ascii=False)


def load_license(path: Optional[str] = None) -> Optional[LicenseData]:
    """
    Read, migrate, and return a LicenseData from disk.
    Returns None if the file does not exist or cannot be parsed.
    """
    target = path or get_license_path()
    if not os.path.isfile(target):
        return None
    try:
        with open(target, "r", encoding="utf-8") as f:
            data = json.load(f)
        if not isinstance(data, dict):
            return None
        data = _migrate(data)
        return LicenseData(data)
    except Exception:
        return None


def delete_license(path: Optional[str] = None) -> bool:
    """Remove the license file. Returns True if deleted."""
    target = path or get_license_path()
    try:
        if os.path.isfile(target):
            os.remove(target)
            return True
    except Exception:
        pass
    return False
