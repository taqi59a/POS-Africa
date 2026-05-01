# POS Africa Architecture

## 1. System Overview

POS Africa is a Flutter desktop Point of Sale application with a modular feature-first structure.

Primary goals:
- Fast local operations for retail counters
- Offline-first behavior using local SQLite storage
- Role-based access and auditability
- Clear module boundaries for future scaling
- Windows-first packaging and installer distribution

Core runtime stack:
- UI: Flutter Material 3
- State management: flutter_bloc
- Dependency Injection: get_it
- Persistence: drift + sqlite3
- Security: bcrypt password hashing
- Utilities: file_picker and archive for data movement and backups

## 2. Architectural Style

The project follows a layered feature architecture:
- Presentation layer in each feature (screens + bloc)
- Domain layer in each feature (repository contracts)
- Data layer in each feature (repository implementations)
- Shared core layer for database, dependency graph, and utilities

Dependency direction:
- Presentation depends on Domain abstractions through Blocs
- Data depends on Core database and implements Domain contracts
- Core is dependency-free from features and shared by all modules

## 3. Repository Layout

Top-level layout:
- lib/core: cross-cutting infrastructure
- lib/features: business modules grouped by capability
- windows: Windows runner and installer assets
- scripts/windows: release automation scripts

Feature modules currently present:
- auth
- billing
- inventory
- customers
- expenses
- reports
- audit
- settings
- shop (dashboard shell)

## 4. Application Bootstrap and Composition

Startup flow:
1. main initializes Flutter bindings.
2. initDependencies registers database, repositories, and bloc factories in get_it.
3. App starts with MultiBlocProvider, wrapped by LicenseGuard for activation enforcement.
4. LicenseGuard verifies machine hardware and license file, or shows ActivationScreen if unlicensed.
5. AuthWrapper routes to Login, Password Change, or Dashboard shell based on auth state.

License enforcement:
- LicenseGuard FutureBuilder collects hardware fingerprint (async) before showing any UI
- In debug/profile mode (`kReleaseMode` false), license check is skipped entirely
- In release mode, LicenseService checks license.dat and validates activation key matches machine ID
- If unlicensed/expired/tampered, full-screen ActivationScreen is shown with glassmorphism UI
- License file stored in EXE directory (portable) or %APPDATA% (installed)

UI shell:
- Single desktop scaffold with NavigationRail
- Page composition by selected index
- Feature screens loaded per section (POS, Inventory, Customers, Expenses, Audit, Reports, Settings)

## 5. Dependency Injection Graph

Singletons:
- AppDatabase as one shared database instance
- Repositories as lazy singletons per feature

Factories:
- AuthBloc
- SettingsBloc
- InventoryBloc
- SalesBloc
- CustomerBloc
- ReportBloc
- ExpenseBloc
- AuditBloc

This gives:
- Shared persistence layer
- Independent state machines per UI area
- Low coupling between features

## 6. License System and Activation

License architecture:
- Hardware fingerprinting via Windows WMI (CPU ID + board serial)
- SHA-256 based machine ID derivation (8-char hex)
- Admin key generation tool (KeyGen_ADMIN.exe) produces 12-char activation keys
- Activation keys are deterministic: SHA-256(machineId + SECRET_SALT)[:12]

Implementation files:
- lib/core/license/license_crypto.dart — SHA-256 machine ID / key derivation
- lib/core/license/hardware_fingerprint.dart — Async WMI/PowerShell hardware collection
- lib/core/license/license_store.dart — Versioned JSON license.dat I/O (schema v1)
- lib/core/license/license_service.dart — Combined check/activate API with debug bypass
- lib/core/license/activation_screen.dart — Full-screen glassmorphism activation UI
- lib/core/license/license_guard.dart — FutureBuilder widget wrapping app entry point

Admin tools:
- tools/license_system/keygen.py — Tkinter UI for generating keys (kept private)
- tools/license_system/shared_crypto.py — Identical crypto as Dart version
- tools/license_system/license_store.py — Python license file I/O
- tools/license_system/build.bat — PyInstaller onefile build script

CI/CD integration:
- GitHub Actions builds KeyGen_ADMIN.exe alongside Flutter installer + portable ZIP
- All 3 artifacts attached to tagged releases on GitHub

License verification flow:
1. LicenseGuard.initState calls LicenseService.check() (async)
2. check() collects CPU ID + board serial via hardware_fingerprint
3. Derives 8-char machine ID from hardware
4. Loads license.dat if exists; validates:
   - Machine ID matches current hardware (not changed)
   - Activation key matches derivation formula (not tampered)
   - Expiry date not reached (not expired)
5. Returns LicenseCheckResult with status enum
6. If licensed, shows widget.child (AuthWrapper)
7. If not/tampered/expired, shows ActivationScreen for manual key entry
8. Debug mode always returns licensed immediately

Security notes:
- SECRET_SALT split into 4 segments and reconstructed at runtime
- Keygen EXE must be kept private (anyone with it can generate keys for any machine)
- Customers cannot forge licenses without the salt constant
- License file is versioned for future schema extensions

## 7. Data Layer and Persistence

Database engine:
- drift on top of sqlite3
- NativeDatabase background connection
- File stored under application documents in CongoPOS/db.sqlite

Schema strategy:
- Current schemaVersion: 3
- onCreate creates all tables then seeds defaults
- onUpgrade applies incremental table additions for v2 and v3
- beforeOpen enforces foreign keys, WAL mode, and integrity check

Tables defined in the database:
- roles
- permissions
- users
- settings
- audit_logs
- categories
- suppliers
- products
- stock_movements
- customers
- sales
- sale_lines
- payments
- expense_categories
- expenses
- exchange_rate_history

Default seed behavior:
- Creates Admin, Manager, Cashier, Stock Clerk roles
- Creates role permission sets
- Creates default admin account with password change required
- Seeds baseline business and POS settings
- Seeds default inventory and expense categories

## 8. Feature Responsibilities

Auth:
- Login and session state
- First-login password change policy
- Logout transitions

Billing (POS):
- Sale creation and cart-based checkout
- Payment capture records
- Sale line persistence
- All monetary amounts stored and displayed in FC (Congolese Franc); USD shown as secondary where dual-currency is enabled

Inventory:
- Product/category/supplier linked catalog
- Stock movement tracking
- Low stock behavior through settings thresholds
- Product label printing: thermal receipt printer labels (58 mm) showing product name and FC price

Customers:
- Customer profile CRUD for retail relationships

Expenses:
- Expense category and expense tracking for operations

Returns (Sales/Purchase Returns):
- `sale_returns` table: return header with original sale reference, refund method, exchange rate snapshot, and USD/FC totals
- `return_lines` table: per-product line linking to original sale lines with stock restoration on processing and re-deduction on void
- Return number format: `RTN-YYYYMMDD-XXXX`
- Stock movements recorded for every return and void action
- Original sale status updated to REFUNDED when all quantities are returned

Reports:
- Aggregated reporting queries across sales, inventory, and expenses
- All PDF exports show USD as primary monetary column; FC values shown as secondary
- Exchange rate in use at transaction time is shown in the top-right corner of every PDF report
- On-screen DataTable columns use FC labels consistently

Audit:
- Time-based immutable event-style business log viewing

Settings:
- Business identity values
- Currency and VAT toggles (displayed as FC/USD)
- Receipt and behavior defaults

## 9. Security and Reliability

Security controls currently implemented:
- Machine-based license enforcement with hardware fingerprinting
- Role and permission model in persistence (admin, manager, cashier, stock clerk)
- bcrypt-based password hash storage
- Forced password change for default admin user
- CORS and secret salt splitting in crypto modules

Reliability controls currently implemented:
- SQLite integrity check at startup
- Foreign key constraints enabled
- WAL mode for better concurrent read/write behavior
- Single shared DB lifecycle through DI

Operational note:
- The default admin credentials should be rotated during first deployment.

## 10. Desktop Runtime and Distribution

Windows runtime architecture:
- flutter build windows --release produces executable plus required runtime files
- A standalone executable-only deployment is not sufficient for Flutter desktop runtime

Distribution strategy implemented:
- Inno Setup script packages the complete Release folder
- Output is one installer executable for user-friendly installation
- Installer creates Start Menu entry and optional desktop shortcut
- Every new installer must perform an in-place upgrade of existing POS Africa installations (same AppId), preserving all user data/configuration and maintaining backward compatibility so reinstalling with a newer installer applies updates without disrupting existing workflows.

Automation path:
- scripts/windows/build_release_installer.ps1
- windows/installer/pos_africa.iss

Expected output artifact:
- build/windows/installer/pos_africa_setup_<version>.exe

## 11. Typical Runtime Flows

Authentication flow:
1. App boot triggers AuthCheckStatus.
2. If unauthenticated, Login screen is shown.
3. If requirePasswordChange is true, password change screen is shown.
4. If authenticated and valid, dashboard shell is shown.

POS sale flow:
1. User opens POS screen.
2. Product selection updates local cart state.
3. Checkout commits sale header, sale lines, payments, and stock movement updates.
4. Reporting and audit visibility reflects persisted sale changes.

## 12. Extension Guidelines

When adding a new feature module:
1. Create feature folders under data, domain, and presentation.
2. Define repository contract in domain.
3. Implement repository in data using AppDatabase access.
4. Add Bloc and UI screens in presentation.
5. Register repository singleton and bloc factory in core DI.
6. Add navigation entry in dashboard shell if user-facing.

When changing schema:
1. Add or modify drift table definition.
2. Bump schemaVersion.
3. Add a safe migration block for previous versions.
4. Regenerate drift/build_runner outputs.
5. Validate startup integrity and existing-user migration path.

## 13. Current Gaps and Hardening Priorities

Areas to improve for production scale:
- Add comprehensive automated tests beyond baseline widget test
- Add structured logging and crash reporting hooks
- Add database backup scheduling and restore verification workflows
- Consider stronger secret handling for future cloud integrations (e.g., hardware-bound token storage)
- Expand license system with subscription/renewal workflows if needed

## 14. Architecture Decision Summary

Selected decisions and rationale:
- Local SQLite with drift for offline-first speed and deterministic behavior
- Feature-first modular boundaries for maintainability
- Bloc for explicit state transitions and predictable UI updates
- get_it for lightweight DI and low overhead composition
- Installer-based Windows distribution to keep user install process simple

This architecture is suitable for a desktop-first POS in SMB contexts and is ready for iterative hardening toward enterprise-grade operations.
