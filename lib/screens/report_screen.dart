import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/widgets/data_preview.dart';
import 'dart:io' show File, Directory;
import 'dart:html' show Blob, Url, AnchorElement;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'upload_screen.dart';

class ReportScreen extends StatefulWidget {
  static const routeName = '/report';
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late List<Map<String, dynamic>> data;
  bool includeCharts = true;
  bool includeLogo = true;
  bool generating = false;
  // preview display toggle
  bool showFullData = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is List) {
      data = args.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      data = [];
    }
  }

  Future<void> _generatePdf() async {
    setState(() => generating = true);
    try {
      final pdf = pw.Document();

      // Add title page with data preview
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (includeLogo)
                  pw.Container(
                    padding: const pw.EdgeInsets.only(bottom: 20),
                    child: pw.Text(
                      'DATA REPORT',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                pw.Text(
                  'Analysis Report - Data Summary',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Generated on: ${DateTime.now().toString().split('.')[0]}',
                  style: const pw.TextStyle(fontSize: 11),
                ),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 15),

                // Data statistics
                pw.Text(
                  'Data Statistics:',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Total Records: ${data.length}',
                  style: const pw.TextStyle(fontSize: 11),
                ),
                if (data.isNotEmpty)
                  pw.Text(
                    'Columns: ${data.first.keys.length}',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Status: All data cleaned and formatted',
                  style: const pw.TextStyle(fontSize: 11),
                ),
                pw.SizedBox(height: 15),
                
                // Preview table with first 5 rows
                if (data.isNotEmpty)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Data Preview (First 5 Records):',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      _buildPdfTable(
                        data.first.keys.toList(),
                        data.take(5).toList(),
                      ),
                    ],
                  ),
                
                pw.SizedBox(height: 15),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Complete dataset with all ${data.length} records is displayed on the following pages.',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            );
          },
        ),
      );

      // Add data pages with all records in table format
      if (data.isNotEmpty) {
        _addDataPages(pdf);
      } else {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(20),
            build: (pw.Context context) {
              return pw.Text('No data available to export');
            },
          ),
        );
      }

      // Save PDF to Downloads directory
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'data_report_$timestamp.pdf';
      final pdfBytes = await pdf.save();

      try {
        if (kIsWeb) {
          // Web: Download PDF directly
          final blob = Blob([pdfBytes]);
          final url = Url.createObjectUrlFromBlob(blob);
          AnchorElement(href: url)
            ..setAttribute('download', filename)
            ..click();
          Url.revokeObjectUrl(url);
        } else {
          // Desktop/Mobile: Save to file system
          final directory = await _getDownloadsDirectory();
          final filepath = '${directory.path}/$filename';
          final file = File(filepath);
          await file.writeAsBytes(pdfBytes);
        }

        setState(() => generating = false);
        if (!mounted) return;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✓ ${kIsWeb ? 'Downloaded' : 'Saved'}: $filename (${data.length} records)',
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.green[700],
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      } catch (fileError) {
        setState(() => generating = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $fileError'),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } catch (e) {
      setState(() => generating = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF Error: ${e.toString()}'),
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  Future<Directory> _getDownloadsDirectory() async {
    if (kIsWeb) {
      // Web doesn't have file system access, just return a dummy directory
      return Directory('.');
    }
    
    // Try to get Downloads directory on Android
    try {
      // Check if /sdcard/Download exists
      final downloadPath = Directory('/storage/emulated/0/Download');
      if (await downloadPath.exists()) {
        return downloadPath;
      }
      // Fallback to /storage/emulated/0/Downloads
      final downloadPath2 = Directory('/storage/emulated/0/Downloads');
      if (await downloadPath2.exists()) {
        return downloadPath2;
      }
    } catch (_) {}
    
    // Fallback to documents directory
    return await getApplicationDocumentsDirectory();
  }

  void _addDataPages(pw.Document pdf) {
    if (data.isEmpty) return;

    final headers = data.first.keys.toList();
    final rowsPerPage = 15; // Number of data rows per page
    final totalPages = (data.length / rowsPerPage).ceil();

    for (int pageNum = 0; pageNum < totalPages; pageNum++) {
      final startIdx = pageNum * rowsPerPage;
      final endIdx = (startIdx + rowsPerPage).clamp(0, data.length);
      final pageData = data.sublist(startIdx, endIdx);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(15),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Cleaned Data - Page ${pageNum + 1} of $totalPages',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Records ${startIdx + 1}-$endIdx of ${data.length}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                _buildPdfTable(headers, pageData),
                pw.Spacer(),
                pw.Divider(thickness: 0.5),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Page ${pageNum + 1} of $totalPages',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ],
            );
          },
        ),
      );
    }
  }

  pw.Widget _buildPdfTable(
    List<String> headers,
    List<Map<String, dynamic>> pageData,
  ) {
    if (pageData.isEmpty) {
      return pw.Text('No data available');
    }

    // Build table with proper sizing
    return pw.SizedBox(
      width: double.infinity,
      child: pw.Table(
        border: pw.TableBorder.all(width: 0.5),
        columnWidths: {
          for (int i = 0; i < headers.length; i++)
            i: const pw.FlexColumnWidth(1),
        },
        children: [
          // Header row
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey300),
            children: headers
                .map(
                  (h) => pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      h,
                      maxLines: 2,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 8,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          // Data rows
          for (int rowIdx = 0; rowIdx < pageData.length; rowIdx++)
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: rowIdx % 2 == 0 ? PdfColors.white : PdfColors.grey100,
              ),
              children: headers
                  .map(
                    (h) => pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        pageData[rowIdx][h]?.toString() ?? '',
                        maxLines: 2,
                        style: const pw.TextStyle(fontSize: 7),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate Report')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Preview snippet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => showFullData = !showFullData),
                      icon: Icon(
                        showFullData ? Icons.unfold_less : Icons.unfold_more,
                        size: 16,
                      ),
                      label: Text(
                        showFullData
                            ? 'Show Preview'
                            : 'Show All (${data.length} rows)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DataPreview(
                  rows: data,
                  maxRows: showFullData ? data.length : 3,
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(12),
                    border: BoxBorder.all(color: Colors.purple[200]!, width: 1),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Report Options',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.purple[900],
                            ),
                      ),
                      const SizedBox(height: 14),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.bar_chart),
                        title: const Text('Include charts'),
                        subtitle: const Text('Add data visualization charts'),
                        value: includeCharts,
                        onChanged: (v) => setState(() => includeCharts = v),
                      ),
                      Divider(color: Colors.grey[300]),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.image),
                        title: const Text('Include logo'),
                        subtitle: const Text('Add company branding'),
                        value: includeLogo,
                        onChanged: (v) => setState(() => includeLogo = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (generating)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      children: [
                        const LinearProgressIndicator(),
                        const SizedBox(height: 8),
                        Text(
                          'Generating PDF...',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: generating ? null : _generatePdf,
                    icon: const Icon(Icons.file_download),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text('Generate PDF'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    UploadScreen.routeName,
                    (r) => false,
                  ),
                  icon: const Icon(Icons.restart_alt),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text('New Analysis'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
