import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:flutter_application_1/widgets/data_preview.dart';
import 'report_screen.dart';

import 'dart:io' show File, Directory;
import 'dart:html' show Blob, Url, AnchorElement;

class CleaningScreen extends StatefulWidget {
  static const routeName = '/cleaning';
  const CleaningScreen({Key? key}) : super(key: key);

  @override
  State<CleaningScreen> createState() => _CleaningScreenState();
}

class _CleaningScreenState extends State<CleaningScreen> {
  late List<Map<String, dynamic>> original;
  List<Map<String, dynamic>> cleaned = [];
  bool dropDuplicates = false;
  bool fillMissing = false;
  bool fixFormats = false;
  bool fixTypes = false;
  bool fixEncoding = false;
  bool processing = false;
  bool success = false;
  // summary counts
  int duplicatesRemoved = 0;
  int missingFilled = 0;
  int typesConverted = 0;
  int formatsNormalized = 0;
  int encodingFixed = 0;
  // preview display toggles
  bool showFullOriginal = false;
  bool showFullCleaned = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is List) {
      original = args.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      original = [];
    }
    cleaned = List.from(original);
  }

  Future<void> _runCleaning() async {
    setState(() {
      processing = true;
      success = false;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    List<Map<String, dynamic>> data = original
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    // reset counters
    duplicatesRemoved = 0;
    missingFilled = 0;
    typesConverted = 0;
    formatsNormalized = 0;
    encodingFixed = 0;

    if (fillMissing) {
      for (var row in data) {
        for (var k in row.keys.toList()) {
          if (row[k] == null) {
            row[k] = 'N/A';
            missingFilled++;
          }
        }
      }
    }

    if (fixEncoding) {
      for (var row in data) {
        for (var k in row.keys.toList()) {
          final v = row[k];
          if (v is String) {
            var s = v;
            final before = s;
            s = s.replaceAll('\uFFFD', '');
            s = s.replaceAll('ï»¿', '');
            s = s.trim();
            if (s != before) encodingFixed++;
            row[k] = s;
          }
        }
      }
    }

    if (fixTypes) {
      for (var row in data) {
        for (var k in row.keys.toList()) {
          final v = row[k];
          if (v is String) {
            final s = v.trim();
            final intRe = RegExp(r'^-?\d+$');
            final doubleRe = RegExp(r'^-?\d+\.\d+$');
            if (intRe.hasMatch(s)) {
              final parsed = int.tryParse(s);
              if (parsed != null) {
                row[k] = parsed;
                typesConverted++;
              }
              continue;
            }
            if (doubleRe.hasMatch(s)) {
              final parsed = double.tryParse(s);
              if (parsed != null) {
                row[k] = parsed;
                typesConverted++;
              }
              continue;
            }
          }
        }
      }
    }

    if (fixFormats) {
      for (var row in data) {
        for (var k in row.keys.toList()) {
          final v = row[k];
          if (v is String) {
            final s = v.trim();
            try {
              final dt = DateTime.parse(s);
              row[k] =
                  '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
              formatsNormalized++;
              continue;
            } catch (_) {}

            final m1 = RegExp(
              r'^(\d{2})[\/\-](\d{2})[\/\-](\d{4})\s*$',
            ).firstMatch(s);
            if (m1 != null) {
              final p1 = int.parse(m1.group(1)!);
              final p2 = int.parse(m1.group(2)!);
              final p3 = int.parse(m1.group(3)!);
              DateTime? dt;
              if (p1 > 12) {
                dt = DateTime(p3, p2, p1);
              } else if (p2 > 12) {
                dt = DateTime(p3, p1, p2);
              } else {
                dt = DateTime(p3, p1, p2);
              }
              row[k] =
                  '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
              formatsNormalized++;
            }
          }
        }
      }
    }

    if (dropDuplicates) {
      final seen = <String>{};
      final out = <Map<String, dynamic>>[];
      for (var r in data) {
        final key = jsonEncode(r);
        if (!seen.contains(key)) {
          seen.add(key);
          out.add(r);
        }
      }
      duplicatesRemoved = data.length - out.length;
      data = out;
    }

    await Future.delayed(const Duration(milliseconds: 400));

    setState(() {
      cleaned = data;
      processing = false;
      success = true;
    });
  }

  Future<void> _exportCleanedData() async {
    try {
      if (cleaned.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No cleaned data to export')),
        );
        return;
      }

      final String csv = const ListToCsvConverter().convert(
        [
          cleaned.first.keys.toList(),
          ...cleaned.map((row) => row.values.toList()),
        ],
      );

      final time = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'cleaned_data_$time.csv';
      
      if (kIsWeb) {
        // Web: Download using HTML
        final bytes = utf8.encode(csv);
        final blob = Blob([bytes]);
        final url = Url.createObjectUrlFromBlob(blob);
        AnchorElement(href: url)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Cleaning & Preprocessing'),
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

                // Header Status Card
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            success
                                ? Icons.verified_outlined
                                : Icons.hourglass_empty_outlined,
                            size: 28,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  success ? 'Cleaning Complete' : 'Ready to Clean',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  success
                                      ? 'View the comparison below'
                                      : 'Configure options and run cleaning',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (success) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            if (duplicatesRemoved > 0)
                              Chip(
                                avatar: const Icon(Icons.close, size: 16),
                                label: Text('$duplicatesRemoved duplicates removed'),
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                labelStyle: const TextStyle(color: Colors.white),
                              ),
                            if (missingFilled > 0)
                              Chip(
                                avatar: const Icon(Icons.check, size: 16),
                                label: Text('$missingFilled missing values filled'),
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                labelStyle: const TextStyle(color: Colors.white),
                              ),
                            if (typesConverted > 0)
                              Chip(
                                avatar: const Icon(Icons.transform, size: 16),
                                label: Text('$typesConverted types converted'),
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                labelStyle: const TextStyle(color: Colors.white),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Cleaning Options Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.settings_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Cleaning Options',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildCleaningOption(
                          context,
                          Icons.group_work,
                          'Drop Duplicates',
                          'Remove exact duplicate rows based on all columns',
                          dropDuplicates,
                          (v) => setState(() => dropDuplicates = v),
                          Colors.red,
                        ),
                        Divider(color: Colors.grey[200]),
                        _buildCleaningOption(
                          context,
                          Icons.format_color_fill,
                          'Fill Missing Values',
                          'Replace null/empty cells with "N/A"',
                          fillMissing,
                          (v) => setState(() => fillMissing = v),
                          Colors.blue,
                        ),
                        Divider(color: Colors.grey[200]),
                        _buildCleaningOption(
                          context,
                          Icons.language,
                          'Fix Encoding Issues',
                          'Remove BOM markers and fix garbled text',
                          fixEncoding,
                          (v) => setState(() => fixEncoding = v),
                          Colors.purple,
                        ),
                        Divider(color: Colors.grey[200]),
                        _buildCleaningOption(
                          context,
                          Icons.tag_outlined,
                          'Fix Data Types',
                          'Convert numeric strings to numbers',
                          fixTypes,
                          (v) => setState(() => fixTypes = v),
                          Colors.green,
                        ),
                        Divider(color: Colors.grey[200]),
                        _buildCleaningOption(
                          context,
                          Icons.calendar_today,
                          'Standardize Date Formats',
                          'Normalize dates to YYYY-MM-DD format',
                          fixFormats,
                          (v) => setState(() => fixFormats = v),
                          Colors.orange,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Action Button
                SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: processing ? null : _runCleaning,
                    icon: processing
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : const Icon(Icons.play_arrow_outlined),
                    label: Text(
                      processing ? 'Cleaning...' : 'Run Cleaning',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Data Preview Section
                if (original.isNotEmpty) ...[
                  Text(
                    'Data Comparison',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Before Card
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.history, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(
                                'Original Data',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text('${original.length} rows'),
                                backgroundColor: Colors.amber[50],
                                side: BorderSide(color: Colors.amber[200]!),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DataPreview(
                            rows: original,
                            maxRows: showFullOriginal ? original.length : 3,
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton.icon(
                              onPressed: () => setState(
                                () => showFullOriginal = !showFullOriginal,
                              ),
                              icon: Icon(
                                showFullOriginal
                                    ? Icons.unfold_less
                                    : Icons.unfold_more,
                              ),
                              label: Text(
                                showFullOriginal ? 'Show Less' : 'Show All',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Arrow
                  Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.arrow_downward,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // After Card
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green[600]),
                              const SizedBox(width: 8),
                              Text(
                                'Cleaned Data',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text('${cleaned.length} rows'),
                                backgroundColor: Colors.green[50],
                                side: BorderSide(color: Colors.green[200]!),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DataPreview(
                            rows: cleaned,
                            maxRows: showFullCleaned ? cleaned.length : 3,
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton.icon(
                              onPressed: () => setState(
                                () => showFullCleaned = !showFullCleaned,
                              ),
                              icon: Icon(
                                showFullCleaned
                                    ? Icons.unfold_less
                                    : Icons.unfold_more,
                              ),
                              label: Text(
                                showFullCleaned ? 'Show Less' : 'Show All',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Next Action
                  if (success)
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              ReportScreen.routeName,
                              arguments: cleaned,
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
                                Icon(Icons.description_outlined),
                                SizedBox(width: 8),
                                Text(
                                  'Generate Report',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: _exportCleanedData,
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
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCleaningOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    Color color,
  ) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      secondary: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: value ? color.withValues(alpha: 0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: value ? color : Colors.grey[600],
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      value: value,
      onChanged: (v) => onChanged(v),
    );
  }
}
