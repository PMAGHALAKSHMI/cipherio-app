# Data Analysis & Cleaning Application

A professional Flutter application for uploading, cleaning, and generating reports from data files (CSV, Excel, PDF, DOCX).

## 🎯 Features

### 📤 Upload Screen
- **Multi-format file support**: CSV, Excel (.xlsx/.xls), PDF, and DOCX files
- **Cross-platform file picker**: Works on Android, iOS, Web, Windows, macOS, and Linux
- **Fallback path entry**: Manually enter file path if file picker unavailable
- **Data preview**: See a sample of your data before processing
- **File metadata**: Display filename, format, and file size
- **Instant parsing**: Automatic format detection and parsing

### 🧹 Cleaning Screen
- **Multiple cleaning operations**:
  - **Remove duplicates**: Identify and eliminate duplicate records
  - **Fill missing values**: Replace null/missing values with "N/A"
  - **Fix encoding issues**: Strip BOMs and replacement characters
  - **Fix data types**: Convert numeric strings to actual numbers
  - **Normalize date formats**: Convert dates to standard YYYY-MM-DD format
- **Before/after preview**: Compare original vs cleaned data
- **Animated success state**: Celebrate successful cleaning with smooth animations
- **Detailed summary**: View counts of all operations performed
- **Conditional display**: Only shows operations that affected data

### 📊 Report Screen
- **Data preview**: First 20 records of cleaned data in table format
- **Report options**:
  - Include charts visualization
  - Include company logo/branding
- **PDF generation**: Export cleaned data to professional PDF report
- **Smart table formatting**: Zebra-striped rows, bordered columns, auto-sizing
- **Data statistics**: Shows total records and column count
- **Direct download**: PDFs saved to device Downloads folder for easy access

## 🏗️ Architecture

```
lib/
├── main.dart              # App entry point, routing, theme configuration
├── screens/
│   ├── upload_screen.dart   # File upload and parsing
│   ├── cleaning_screen.dart # Data cleaning operations
│   └── report_screen.dart   # PDF generation
└── widgets/
    └── data_preview.dart    # Reusable data table widget
```

## 🎨 Design

- **Material Design 3**: Modern, responsive UI
- **Professional theme**: Consistent colors, typography, and spacing
- **Centered layouts**: Max-width 900px for optimal viewing
- **Smooth animations**: Gradient buttons, progress indicators, success celebrations
- **Responsive tables**: Zebra-striping, auto-sizing columns, readable fonts
- **Color-coded sections**: Blue (upload), Green (cleaning success), Purple (report)

## 📦 Dependencies

```yaml
dependencies:
  csv: ^5.0.0              # CSV parsing
  excel: ^2.0.1            # Excel file support
  archive: ^3.3.2          # DOCX extraction
  file_selector: ^1.0.4    # Cross-platform file picker
  pdf: ^3.10.0             # PDF generation
  path_provider: ^2.1.0    # File system access
```

## 🚀 Getting Started

### Prerequisites
- Flutter 3.9.2 or higher
- Dart 2.19.0 or higher
- Android SDK 21+ (for Android builds)

### Installation

```bash
# Clone the repository
git clone <repo-url>
cd flutter_application_1

# Get dependencies
flutter pub get

# Run the app
flutter run

# Build release APK
flutter build apk --release

# Build release app bundle
flutter build appbundle --release
```

## 💡 Usage

1. **Upload**: Open app → Select or enter path to CSV/Excel/PDF/DOCX file
2. **Preview**: Review data and file metadata
3. **Clean**: Choose cleaning operations and run cleaning process
4. **Report**: Toggle options and generate PDF report
5. **Download**: PDF automatically saved to Downloads folder

## 🔧 Data Cleaning Operations

| Operation | Description | Example |
|-----------|-------------|---------|
| **Remove Duplicates** | Eliminates exact duplicate rows | Row with same data removed |
| **Fill Missing** | Replaces null/empty values | `null` → `"N/A"` |
| **Fix Encoding** | Removes corrupted characters | `"ï»¿text"` → `"text"` |
| **Fix Types** | Converts numeric strings to numbers | `"123"` → `123` |
| **Normalize Dates** | Standardizes date formats | `"01/01/2023"` → `"2023-01-01"` |

## 📱 Supported File Formats

| Format | Extension | Supported |
|--------|-----------|-----------|
| CSV | .csv | ✅ |
| Excel | .xlsx, .xls | ✅ |
| PDF | .pdf | ✅ (text extraction) |
| Word | .docx | ✅ (text extraction) |

## 🎯 Key Files

- `lib/main.dart` - Theme configuration and routing
- `lib/screens/upload_screen.dart` - File parsing logic
- `lib/screens/cleaning_screen.dart` - Data cleaning algorithms
- `lib/screens/report_screen.dart` - PDF generation
- `lib/widgets/data_preview.dart` - Data table display

## 🐛 Troubleshooting

**PDF not appearing in Downloads:**
- Check file permissions in Android Manifest
- Try fallback to Documents folder
- Ensure adequate storage space

**File not recognized:**
- Check file format is supported
- Verify file isn't corrupted
- Try manual path entry instead of file picker

**Data appearing blank in PDF:**
- Ensure data was properly uploaded and cleaned
- Check summary shows correct record count
- Try exporting with fewer columns if too wide

## 📄 License

This project is open source and available under the MIT License.

## 🙋 Support

For issues or feature requests, please open an issue in the repository.

---

**Version**: 1.0.0  
**Last Updated**: November 15, 2025
