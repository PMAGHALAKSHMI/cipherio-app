import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/widgets/data_preview.dart';
import 'package:flutter_application_1/widgets/data_quality_score.dart';
import 'package:flutter_application_1/widgets/data_insights_card.dart';
import 'cleaning_screen.dart';
import 'dart:typed_data';
import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as excel;
import 'package:archive/archive.dart';

import 'dart:io' show File, Directory;
import 'dart:html' show Blob, Url, AnchorElement;

class UploadScreen extends StatefulWidget {
  static const routeName = '/';
  const UploadScreen({Key? key}) : super(key: key);

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  List<Map<String, dynamic>> _data = [];
  final TextEditingController _pathController = TextEditingController();
  String? _fileName;
  int? _fileSize;
  String? _fileExt;
  bool _showAllData = false;

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _exportToCSV() async {
    try {
      if (_data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data to export')),
        );
        return;
      }

      final String csv = const ListToCsvConverter().convert(
        [
          _data.first.keys.toList(),
          ..._data.map((row) => row.values.toList()),
        ],
      );

      final time = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'data_export_$time.csv';
      
      if (kIsWeb) {
        // Web: Download using HTML
        final bytes = utf8.encode(csv);
        final blob = Blob([bytes]);
        final url = Url.createObjectUrlFromBlob(blob);
        final anchor = AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        Url.revokeObjectUrl(url);
      } else {
        // Mobile/Desktop: Save to temp directory
        final path = '${Directory.systemTemp.path}/$fileName';
        await File(path).writeAsString(csv);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Exported to $path'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded: $fileName'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _pickCsvFile() async {
    try {
      // accept many formats: csv, xlsx, pdf, docx
      final typeGroup = XTypeGroup(
        label: 'data',
        extensions: ['csv', 'xlsx', 'xls', 'pdf', 'docx'],
      );
      final XFile? xfile = await openFile(acceptedTypeGroups: [typeGroup]);
      if (xfile == null) return; // user cancelled
      
      // Get filename and extension from XFile.name (works on web)
      final fileName = xfile.name;
      final ext = fileName.split('.').last.toLowerCase();
      _fileName = fileName;
      _fileExt = ext;
      
      // Validate extension
      if (!['csv', 'xlsx', 'xls', 'pdf', 'docx'].contains(ext)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unsupported file type: .$ext')),
          );
        }
        return;
      }
      
      // Read file bytes (works for both web and native)
      final bytes = await xfile.readAsBytes();
      _fileSize = bytes.length;
      
      List<Map<String, dynamic>> parsed = [];
      
      if (ext == 'csv') {
        final content = utf8.decode(bytes);
        parsed = _parseCsvString(content);
      } else if (ext == 'xlsx' || ext == 'xls') {
        parsed = _parseExcelBytes(bytes);
      } else if (ext == 'pdf') {
        parsed = await _parsePdfBytes(bytes);
      } else if (ext == 'docx') {
        parsed = _parseDocxBytes(bytes);
      }

      setState(() {
        _data = parsed;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to read file: $e')));
    }
  }

  Future<void> _loadFromPath() async {
    final path = _pathController.text.trim();
    if (path.isEmpty) return;
    try {
      final file = File(path);
      if (!await file.exists()) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('File not found')));
        return;
      }
      final ext = path.split('.').last.toLowerCase();
      List<Map<String, dynamic>> parsed = [];
      if (ext == 'csv') {
        final content = await file.readAsString();
        parsed = _parseCsvString(content);
      } else if (ext == 'xlsx' || ext == 'xls') {
        final bytes = await file.readAsBytes();
        parsed = _parseExcelBytes(bytes);
      } else if (ext == 'pdf') {
        parsed = await _parsePdfFile(path);
      } else if (ext == 'docx') {
        final bytes = await file.readAsBytes();
        parsed = _parseDocxBytes(bytes);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unsupported file type: .$ext')));
        return;
      }
      final stat = await file.stat();
      setState(() {
        _data = parsed;
        _fileName = path.contains('/') ? path.split('/').last : path.split('\\\\').last;
        _fileSize = stat.size;
        _fileExt = ext;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to read file: $e')));
    }
  }

  List<Map<String, dynamic>> _parseCsvString(String content) {
    final rows = const CsvToListConverter(eol: '\n').convert(content);
    if (rows.isEmpty) return [];
    final headers = rows.first.map((e) => e.toString()).toList();
    final parsed = <Map<String, dynamic>>[];
    for (var i = 1; i < rows.length; i++) {
      final r = rows[i];
      final map = <String, dynamic>{};
      for (var j = 0; j < headers.length; j++) {
        map[headers[j]] = j < r.length ? r[j] : null;
      }
      parsed.add(map);
    }
    return parsed;
  }

  List<Map<String, dynamic>> _parseExcelBytes(Uint8List bytes) {
    try {
      final excelData = excel.Excel.decodeBytes(bytes);
      if (excelData.tables.isEmpty) return [];
      final sheetName = excelData.tables.keys.first;
      final sheet = excelData.tables[sheetName];
      if (sheet == null || sheet.rows.isEmpty) return [];
      final headerRow = sheet.rows.first
          .map((c) => c?.value?.toString() ?? '')
          .toList();
      final parsed = <Map<String, dynamic>>[];
      for (var i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        final map = <String, dynamic>{};
        for (var j = 0; j < headerRow.length; j++) {
          map[headerRow[j]] = j < row.length ? row[j]?.value : null;
        }
        parsed.add(map);
      }
      return parsed;
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _parsePdfFile(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      // Simple PDF text extraction using regex pattern matching
      final content = String.fromCharCodes(bytes);
      // Extract text between common PDF markers
      final textPattern = RegExp(r'BT\s+([\s\S]*?)\s+ET', multiLine: true);
      final matches = textPattern.allMatches(content);
      final lines = <String>[];
      for (final match in matches) {
        final text = match.group(1) ?? '';
        final cleanText = text
            .replaceAll(RegExp(r'[\(\)<>\[\]{}/%@#]'), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        if (cleanText.isNotEmpty) {
          lines.add(cleanText);
        }
      }
      if (lines.isEmpty) {
        // Fallback: extract any readable text
        final fallback = content
            .replaceAll(RegExp(r'[^\x20-\x7E\n\r]'), '')
            .split(RegExp(r'\n+'))
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty && l.length > 3)
            .toList();
        return fallback.isNotEmpty
            ? fallback.map((l) => {'text': l}).toList()
            : [
                {'text': 'PDF: No readable text found'},
              ];
      }
      return lines.map((l) => {'text': l}).toList();
    } catch (e) {
      return [
        {'text': 'PDF: $e'},
      ];
    }
  }

  Future<List<Map<String, dynamic>>> _parsePdfBytes(Uint8List bytes) async {
    try {
      // Simple PDF text extraction using regex pattern matching
      final content = String.fromCharCodes(bytes);
      // Extract text between common PDF markers
      final textPattern = RegExp(r'BT\s+([\s\S]*?)\s+ET', multiLine: true);
      final matches = textPattern.allMatches(content);
      final lines = <String>[];
      for (final match in matches) {
        final text = match.group(1) ?? '';
        final cleanText = text
            .replaceAll(RegExp(r'[\(\)<>\[\]{}/%@#]'), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        if (cleanText.isNotEmpty) {
          lines.add(cleanText);
        }
      }
      if (lines.isEmpty) {
        // Fallback: extract any readable text
        return [
          {'text': 'PDF: No readable text found'},
        ];
      }
      return lines.map((l) => {'text': l}).toList();
    } catch (e) {
      return [
        {'text': 'PDF: $e'},
      ];
    }
  }

  List<Map<String, dynamic>> _parseDocxBytes(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final file = archive.files.firstWhere(
        (f) => f.name == 'word/document.xml',
        orElse: () => ArchiveFile('', 0, <int>[]),
      );
      if (file.content == null || (file.content as List).isEmpty)
        return [
          {'text': 'No document.xml found inside .docx'},
        ];
      final xmlStr = utf8.decode(file.content as List<int>);
      // naive extraction of <w:t> text nodes
      final matches = RegExp(
        r'<w:t[^>]*>(.*?)<\/w:t>',
        dotAll: true,
      ).allMatches(xmlStr);
      final parts = matches.map((m) => m.group(1) ?? '').join(' ');
      final lines = parts
          .split(RegExp(r'\r?\n'))
          .where((l) => l.trim().isNotEmpty)
          .toList();
      return lines.isEmpty
          ? [
              {'text': parts},
            ]
          : lines.map((l) => {'text': l}).toList();
    } catch (e) {
      return [
        {'text': 'Failed to parse DOCX: $e'},
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final cols = _data.isNotEmpty ? _data.first.keys.length : 0;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload & Preview Data'),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                
                // Header Card with App Branding
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 32,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'DataFlow',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Upload, clean, and analyze your data in seconds',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 28),
                
                // Upload Section
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.file_upload_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Import Data',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _pickCsvFile,
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Text('Choose File', style: TextStyle(fontSize: 16)),
                          ),
                          style: ElevatedButton.styleFrom(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Divider(color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Or paste file path:',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _pathController,
                                decoration: InputDecoration(
                                  hintText: 'e.g., C:/Users/Data/file.csv',
                                  isDense: true,
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  prefixIcon: const Icon(Icons.folder_open_outlined, size: 18),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).colorScheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.icon(
                              onPressed: _loadFromPath,
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Load'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // File Info Chips
                if (_fileName != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'File Information',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          Chip(
                            avatar: const Icon(Icons.description_outlined, size: 18),
                            label: Text(_fileName!),
                            backgroundColor: Colors.blue[50],
                            side: BorderSide(color: Colors.blue[200]!),
                          ),
                          if (_fileExt != null)
                            Chip(
                              avatar: const Icon(Icons.tag_outlined, size: 18),
                              label: Text('.${_fileExt!.toUpperCase()}'),
                              backgroundColor: Colors.green[50],
                              side: BorderSide(color: Colors.green[200]!),
                            ),
                          if (_fileSize != null)
                            Chip(
                              avatar: const Icon(Icons.storage_outlined, size: 18),
                              label: Text('${(_fileSize! / 1024).toStringAsFixed(1)} KB'),
                              backgroundColor: Colors.orange[50],
                              side: BorderSide(color: Colors.orange[200]!),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                
                // Quick Insights
                if (_data.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: DataInsightsCard(
                      fileType: _fileExt?.toUpperCase() ?? 'File',
                      fileSize: _fileSize ?? 0,
                      totalRows: _data.length,
                      totalColumns: _data.isNotEmpty ? _data[0].length : 0,
                    ),
                  ),
                
                // Data Summary Stats
                if (_data.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Data Summary',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              icon: Icons.table_rows_outlined,
                              title: 'Total Rows',
                              value: _data.length.toString(),
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatCard(
                              icon: Icons.view_column_outlined,
                              title: 'Columns',
                              value: cols.toString(),
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                
                // Data Quality Score
                if (_data.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DataQualityScore(
                        totalRows: _data.length,
                        totalColumns: cols,
                        nullValues: _data.fold(
                          0,
                          (sum, row) =>
                              sum +
                              row.values
                                  .where((v) => v == null)
                                  .length,
                        ),
                        duplicateRows: 0,
                        data: _data,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                
                // Data Preview Section
                if (_data.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _showAllData
                                ? 'Complete Dataset'
                                : 'Data Preview',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Chip(
                            label: Text(
                              _showAllData
                                  ? 'Showing All'
                                  : 'Preview Mode',
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: _showAllData
                                ? Colors.green[50]
                                : Colors.amber[50],
                            side: BorderSide(
                              color: _showAllData
                                  ? Colors.green[300]!
                                  : Colors.amber[300]!,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[200]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DataPreview(
                          rows: _data,
                          maxRows: _showAllData ? _data.length : 4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton.icon(
                          onPressed: () =>
                              setState(() => _showAllData = !_showAllData),
                          icon: Icon(
                            _showAllData
                                ? Icons.unfold_less
                                : Icons.unfold_more,
                          ),
                          label: Text(
                            _showAllData ? 'Show Less' : 'Show All Rows',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                
                // Action Buttons
                if (_data.isNotEmpty)
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            CleaningScreen.routeName,
                            arguments: _data,
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.cleaning_services_outlined),
                              SizedBox(width: 8),
                              Text(
                                'Clean Data',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _exportToCSV,
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('Export'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                
                if (_data.isEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Upload a file to get started',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Supported formats: CSV, XLSX, XLS, PDF, DOCX',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper Widget for Stats
class StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const StatCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
