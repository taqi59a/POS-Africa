# POS Africa Update Compatibility Baseline

This file defines non-negotiable compatibility rules for all future updates so
new releases remain safe for already-installed versions.

## Scope

- Installed Windows versions upgraded via installer (`.iss`) with same `AppId`.
- Existing user databases and backups.
- Existing license files and key generation workflow.

## Recent Changes Log

### 2026-05-05 — Bill-total override (payment dialog)
- No schema changes. `schemaVersion` remains 5.
- `sales.grandTotal` / `sales.subtotal` now store the cashier-entered override
  amount when it differs from the cart total. `sales.discountAmount` is set to 0
  in that case. All existing report queries read `grandTotal` and are unaffected.
- `sale_lines` rows continue to store the original catalog unit prices; the
  override is a sale-level adjustment only.
- No changes to installer, DB path, license, or backup logic.

## Compatibility Invariants

1. Installer identity must stay stable.
- Keep `AppId` unchanged in `windows/installer/pos_africa.iss`.
- Keep executable name `pos_africa.exe` unchanged unless a migration plan is
  added.

2. Database storage location must stay stable.
- Keep DB path logic consistent with:
  - folder: `CongoPOS`
  - file: `db.sqlite`
- Current source of truth:
  `lib/core/data/database/app_database.dart` and
  `lib/core/utils/db_backup_utils.dart`.

3. Drift schema upgrades must be forward-safe.
- Only increase `schemaVersion` when adding an explicit migration.
- Every schema change must have an `onUpgrade` branch from all older supported
  versions.
- Never drop/rename columns or tables without data-preserving migration logic.
- Do not reset user credentials in migration unless explicitly required and
  documented in release notes.

4. Backup/restore contract must remain backward-compatible.
- Keep backup format as SQLite DB copy unless a converter is added.
- Keep pending-restore startup flow order:
  `applyPendingRestoreIfAny()` before DI/DB open.

5. License compatibility must remain stable.
- Keep Flutter and Python crypto logic in sync:
  - `lib/core/license/license_crypto.dart`
  - `tools/license_system/shared_crypto.py`
- Do not change activation key length or salt algorithm without a migration
  strategy for existing deployed keys.
- Keep `license.dat` schema additive; new fields must default safely.

6. User data safety over clean uninstall behavior.
- Upgrades must preserve user data and license files.
- Uninstall may prompt for data removal, but upgrade flow must not delete user
  data.

## Required Pre-Release Checks

Run these checks before shipping any update:

1. Existing install upgrade test
- Install previous release.
- Create real test data (products, sales, settings).
- Install new release over it.
- Verify login, data visibility, reports, and settings persistence.

2. Backup compatibility test
- Create backup on previous release.
- Restore with new release.
- Confirm startup succeeds and data is intact.

3. Database migration test
- Open a DB created by the previous release.
- Confirm migrations complete with no integrity errors.

4. License continuity test
- Validate that an old valid `license.dat` remains accepted.
- Validate that keygen output still activates in-app.

## Prompt Template For Future Update Requests

When requesting code updates, include this block:

```text
Compatibility requirement:
- Must remain upgrade-compatible with previously installed POS Africa versions.
- Do not change installer AppId, DB folder/file name, or license algorithm unless
  you also implement and document a safe migration.
- If schema changes are introduced, add forward migrations and update
  UPDATE_COMPATIBILITY_BASELINE.md.
```

## Change Control Rule

Any PR that changes one of these files must include a compatibility note:

- `lib/core/data/database/app_database.dart`
- `lib/core/utils/db_backup_utils.dart`
- `lib/core/license/license_crypto.dart`
- `lib/core/license/license_store.dart`
- `tools/license_system/shared_crypto.py`
- `windows/installer/pos_africa.iss`
