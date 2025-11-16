import 'package:flutter/material.dart';

class DataInsightsCard extends StatelessWidget {
  final int totalRows;
  final int totalColumns;
  final String fileType;
  final int fileSize;

  const DataInsightsCard({
    Key? key,
    required this.totalRows,
    required this.totalColumns,
    required this.fileType,
    required this.fileSize,
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
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.info_outlined,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Quick Insights',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _InsightItem(
                  label: 'File Type',
                  value: fileType.toUpperCase(),
                  icon: Icons.document_scanner_outlined,
                ),
                _InsightItem(
                  label: 'File Size',
                  value: '${(fileSize / 1024).toStringAsFixed(1)} KB',
                  icon: Icons.storage_outlined,
                ),
                _InsightItem(
                  label: 'Avg Row Size',
                  value: totalRows > 0
                      ? '${(fileSize / totalRows).toStringAsFixed(0)} B'
                      : '0 B',
                  icon: Icons.straighten_outlined,
                ),
                _InsightItem(
                  label: 'Total Cells',
                  value: (totalRows * totalColumns).toString(),
                  icon: Icons.table_chart_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InsightItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
