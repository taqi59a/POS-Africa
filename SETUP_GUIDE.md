# Installation & Running Guide

All files and updates have been successfully implemented in the **`/Users/taqi/Downloads/POS AFRICA`** folder. This project is a standard Flutter Desktop application.

### Prerequisites
1. **Flutter SDK**: Ensure you have Flutter installed. Run `flutter --version` in your terminal to check.
2. **Desktop Support**: Ensure your Flutter environment is configured for Desktop:
   - For Windows: `flutter config --enable-windows-desktop`
   - For macOS: `flutter config --enable-macos-desktop`

### How to Install & Run

Follow these steps in your terminal inside the `POS AFRICA` directory:

1.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```

2.  **Generate Database Code** (If you make changes to tables):
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```
    *(Note: I have already generated the initial code for you, so you might skip this for the first run.)*

3.  **Run the Application**:
    - **On macOS**:
      ```bash
      flutter run -d macos
      ```
    - **On Windows**:
      ```bash
      flutter run -d windows
      ```

### Login Credentials
- **Username**: `admin`
- **Password**: `master`
- *You will be prompted to change your password immediately upon the first login for security.*

### How to Check/Verify
- **Database**: The database is stored in your user's AppData/Application Support folder. You can use any SQLite browser (like [DB Browser for SQLite](https://sqlitebrowser.org/)) to open `db.sqlite`.
- **Manual Backup**: Go to **Settings** -> **Data Management** -> **Manual Backup** to verify the export functionality.
- **Audit Logs**: Perform any action (like adding a product) and then check the **Audit** tab to see the system tracking your actions.
