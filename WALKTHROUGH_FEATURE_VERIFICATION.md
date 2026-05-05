# POS Africa Feature Verification Walkthrough

## Verification Scope

This walkthrough covers end-to-end checks for:
- Authentication and session handling
- Dashboard and navigation shell
- POS billing flow
- Inventory management
- Customer management
- Expenses
- Reports
- Audit logs
- Settings persistence
- Manual backup and restore
- Windows installer EXE generation and install validation

## Environment Status Used For This Update

Code verification completed in this workspace:
- Backup/restore flow hardened and wired into startup restore application.
- Static error scan passed for modified files.

Runtime verification status:
- Flutter and Dart are not available in this container, so runtime execution and EXE generation cannot be executed here.
- Use the checklist below on a Windows machine to complete runtime verification.

## Pre-Flight (Windows)

1. Install Flutter SDK (stable) and run:
   - `flutter --version`
   - `flutter doctor -v`
2. Install Visual Studio 2022 with Desktop C++ workload.
3. Install Inno Setup 6 and ensure `iscc` is in PATH.
4. In project root run:
   - `flutter config --enable-windows-desktop`
   - `flutter pub get`

## Build Single Installer EXE

Option A (PowerShell):
- `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\build_release_installer.ps1 -Version 1.0.0`

Option B (Double-click / CMD):
- `.\\scripts\\windows\\build_release_installer.bat 1.0.0`

Expected output:
- `build\\windows\\installer\\pos_africa_setup_1.0.0.exe`

## Full Feature Verification Checklist

Mark each item after running it on Windows.

### 1. Installer and Launch
- [ ] Installer EXE runs without error.
- [ ] App installs in Program Files.
- [ ] Start Menu shortcut is created.
- [ ] Optional desktop icon works.
- [ ] App launches from installed shortcut.

### 2. Authentication
- [ ] Login with default user: `admin / master`.
- [ ] First-login password change is enforced.
- [ ] Login succeeds with updated password.
- [ ] Logout returns to login screen.

### 3. Dashboard and Navigation
- [ ] Dashboard loads without crash.
- [ ] Each navigation rail tab opens expected screen.
- [ ] No tab throws runtime exceptions during first load.

### 4. Settings Persistence
- [ ] Update business profile fields and save.
- [ ] Close and relaunch app.
- [ ] Saved settings persist after restart.
- [ ] Dual currency toggle and VAT toggle persist.

### 5. Inventory
- [ ] Create category and supplier (if present in flow).
- [ ] Add product with price/stock.
- [ ] Edit product and confirm updates.
- [ ] Stock movement reflects inventory operations.

### 6. Customers
- [ ] Add a new customer.
- [ ] Edit customer details.
- [ ] Search/list reflects saved customer data.

### 7. Billing (POS)
- [ ] Add product(s) to cart.
- [ ] Complete sale with payment.
- [ ] Sale lines are saved.
- [ ] Stock levels update after sale.
- [ ] **Bill-total override:** tap the BILL TOTAL field, type a higher amount (e.g. 200000 on a 180000 cart), verify AMOUNT TO PAY updates, Markup hint appears, and the sale record stores the overridden total (not the cart total).
- [ ] Confirm next sale opens with a fresh cart-derived total (no state carried over).

### 8. Expenses
- [ ] Add expense category.
- [ ] Add expense entry.
- [ ] Expense list shows new records.

### 9. Reports
- [ ] Open reports screen with no crash.
- [ ] Sales summary reflects recent transactions.
- [ ] After a bill-total-override sale, verify the overridden amount appears in daily revenue totals (not the cart price).
- [ ] Expense-related values appear correctly.

### 10. Audit Log
- [ ] Open audit screen with no crash.
- [ ] Core actions (login, create/update where implemented) appear in logs.

## Backup and Restore Verification (Critical)

The app now uses a staged restore flow:
1. User selects a backup file.
2. Backup is staged as pending restore.
3. Restore is applied automatically on next startup before DB initialization.

Run this exact test:

1. Prepare known state:
- [ ] Add a test product named `RESTORE_TEST_PRODUCT_A`.
- [ ] Save and verify it appears in inventory.

2. Create backup:
- [ ] Go to Settings -> Data Management -> Manual Backup.
- [ ] Save backup file to a known folder.
- [ ] Confirm success message shows backup path.

3. Mutate data after backup:
- [ ] Delete or rename `RESTORE_TEST_PRODUCT_A`.
- [ ] Add another product named `POST_BACKUP_PRODUCT_B`.

4. Stage restore:
- [ ] Click Restore Backup.
- [ ] Select the saved backup file.
- [ ] Confirm message: restart required to complete restore.

5. Restart app:
- [ ] Close app completely.
- [ ] Launch app again.

6. Validate restore result:
- [ ] `RESTORE_TEST_PRODUCT_A` is present.
- [ ] `POST_BACKUP_PRODUCT_B` is absent.
- [ ] Login and core navigation still work.
- [ ] No database integrity error appears at startup.

## Final Sign-Off Template

Release version: __________________
Build date: ______________________
Tester name: _____________________
Machine/OS: ______________________

Checklist completion:
- [ ] All sections passed
- [ ] Backup/restore test passed
- [ ] Installer EXE validated on clean machine
- [ ] Ready for user distribution

Notes / defects found:
- ___________________________________________
- ___________________________________________
- ___________________________________________
