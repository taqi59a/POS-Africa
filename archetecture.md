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
3. App starts with MultiBlocProvider and eagerly triggers bootstrap events for key modules.
4. AuthWrapper routes to Login, Password Change, or Dashboard shell based on auth state.

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

## 6. Data Layer and Persistence

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

## 7. Feature Responsibilities

Auth:
- Login and session state
- First-login password change policy
- Logout transitions

Billing (POS):
- Sale creation and cart-based checkout
- Payment capture records
- Sale line persistence

Inventory:
- Product/category/supplier linked catalog
- Stock movement tracking
- Low stock behavior through settings thresholds

Customers:
- Customer profile CRUD for retail relationships

Expenses:
- Expense category and expense tracking for operations

Reports:
- Aggregated reporting queries across sales, inventory, and expenses

Audit:
- Time-based immutable event-style business log viewing

Settings:
- Business identity values
- Currency and VAT toggles
- Receipt and behavior defaults

## 8. Security and Reliability

Security controls currently implemented:
- bcrypt-based password hash storage
- Forced password change for default admin user
- Role and permission model in persistence

Reliability controls currently implemented:
- SQLite integrity check at startup
- Foreign key constraints enabled
- WAL mode for better concurrent read/write behavior
- Single shared DB lifecycle through DI

Operational note:
- The default admin credentials should be rotated during first deployment.

## 9. Desktop Runtime and Distribution

Windows runtime architecture:
- flutter build windows --release produces executable plus required runtime files
- A standalone executable-only deployment is not sufficient for Flutter desktop runtime

Distribution strategy implemented:
- Inno Setup script packages the complete Release folder
- Output is one installer executable for user-friendly installation
- Installer creates Start Menu entry and optional desktop shortcut

Automation path:
- scripts/windows/build_release_installer.ps1
- windows/installer/pos_africa.iss

Expected output artifact:
- build/windows/installer/pos_africa_setup_<version>.exe

## 10. Typical Runtime Flows

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

## 11. Extension Guidelines

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

## 12. Current Gaps and Hardening Priorities

Areas to improve for production scale:
- Add comprehensive automated tests beyond baseline widget test
- Add structured logging and crash reporting hooks
- Add stronger secret handling for any future cloud integrations
- Add database backup scheduling and restore verification workflows
- Add CI pipeline for automated Windows installer builds on tagged releases

## 13. Architecture Decision Summary

Selected decisions and rationale:
- Local SQLite with drift for offline-first speed and deterministic behavior
- Feature-first modular boundaries for maintainability
- Bloc for explicit state transitions and predictable UI updates
- get_it for lightweight DI and low overhead composition
- Installer-based Windows distribution to keep user install process simple

This architecture is suitable for a desktop-first POS in SMB contexts and is ready for iterative hardening toward enterprise-grade operations.
