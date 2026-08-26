# Lab Inventory Manager

An offline-first Flutter application for managing laboratory inventory with barcode/QR code scanning, item tracking, and export capabilities.

## Features

- **Barcode & QR Code Scanning** – Capture item codes and package identifiers using your device camera
- **Flexible Code Configuration** – Support for single item codes or package + item code pairs
- **Inventory Search & Filtering** – Search by name, category, serial number, or scanned code
- **Item Type Classification** – Organize items as tools, equipment, or utilities
- **Archive Management** – Archive items while preserving code uniqueness
- **Export & Backup** – Export inventory as JSON or CSV for backup and data portability
- **Printable Labels** – Generate and share item labels with embedded QR codes
- **Offline Operation** – All data stored locally; no server required

## Getting Started

### Prerequisites

- Flutter 3.13.1 or later
- Android SDK 21+ (Android development) or iOS 13+ (iOS development)

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd lab-inventory-manager
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   flutter pub run build_runner build
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Usage

### Adding an Item

1. **Tap "Add item"** on the home screen
2. **Enter item details** (name, type, category, optional serial number)
3. **Choose code configuration:**
   - **Item only** – Single barcode/QR for the item
   - **Package + item** – Separate codes for package (1P/1T) and item
4. **Scan or manually enter** code values
5. **Save** to add to inventory

### Scanning to Find

1. Tap the **scanner icon** (top-right floating button)
2. Center a barcode or QR code in the frame
3. If the item exists, you'll jump to its details
4. If not found, you can create a new item from that code

### Exporting Data

1. Tap the **menu icon** (top-right of inventory list)
2. Choose **Export JSON** or **Export CSV**
3. Share or save the file

### Archiving Items

1. Open an item's details
2. Tap **Archive item**
3. The item is hidden from the active inventory but codes remain reserved

To restore, scan the archived item's code and tap **Restore** in the dialog.

## Architecture

### Data Layer (`lib/src/data/`)

- **`inventory_database.dart`** – SQLite database using Drift ORM
  - Tables: `InventoryItems`, `InventoryItemCodes`
  - Supports full-text search via joined queries
  - Automatic schema migrations

### Domain Layer (`lib/src/domain/`)

- **`inventory_enums.dart`** – Enums for item types, code types, roles, and configurations

### Features (`lib/src/features/`)

- **`inventory/`** – Home, item detail, item form, archived items pages
- **`scanner/`** – Barcode scanning UI with role-detection logic

### Services (`lib/src/services/`)

- **`export_service.dart`** – JSON and CSV export; handles path and file I/O

### State Management (`lib/src/providers.dart`)

- Riverpod providers for database access and data streams

## Development

### Code Generation

The project uses Drift for database code generation. After editing schema:

```bash
flutter pub run build_runner build
```

### Running Tests

```bash
flutter test
```

Current test coverage:
- Database migrations and code lookups
- Widget rendering and navigation
- Export format validation

### Adding New Tests

Place tests in `test/` directory. Examples:
- `*_test.dart` for unit tests
- Widget tests override `activeItemsProvider` in `ProviderScope`

## Deployment

### Android Release Build

1. Update app ID and signing config in `android/app/build.gradle.kts`:
   ```kotlin
   applicationId = "com.your_organization.lab_inventory"
   ```

2. Generate a release key:
   ```bash
   keytool -genkey -v -keystore ~/lab-inventory.jks -keyalg RSA -keysize 2048 -validity 10000 -alias lab-key
   ```

3. Build the APK:
   ```bash
   flutter build apk --release
   ```

### iOS Release Build

1. Update bundle ID in Xcode
2. Configure provisioning profiles
3. Build:
   ```bash
   flutter build ios --release
   ```

## Data Backup & Recovery

### Automatic Backups

Data is stored in the app's documents directory:
- **Android:** `/data/data/com.your_organization.lab_inventory/files/`
- **iOS:** `<App>/Documents/`

### Manual Export

Use the in-app **Export JSON** feature to create portable backups.

### Import

Currently, manual SQL restoration is required. JSON exports can be parsed to repopulate the database.

## Known Limitations

- No built-in sync across devices (offline-first, single device)
- Import from backup requires manual database migration
- Large inventories (1000+) may require database optimization

## Future Enhancements

- Multi-device sync via cloud backup
- Batch import/restore from JSON
- Advanced filtering and sorting options
- Inventory history and audit logs
- Multi-language support
- Barcode generation and printing templates

## License

[Add your license here]

## Support

For issues or feature requests, please file an issue in the repository.
