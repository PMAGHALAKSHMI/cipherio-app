import 'package:flutter/material.dart';

class DataQualityScore extends StatelessWidget {
  final int totalRows;
  final int totalColumns;
  final int nullValues;
  final int duplicateRows;
  final List<Map<String, dynamic>> data;

  const DataQualityScore({
    Key? key,
    required this.totalRows,
    required this.totalColumns,
    required this.nullValues,
    required this.duplicateRows,
    required this.data,
  }) : super(key: key);

  double _calculateQualityScore() {
    if (totalRows == 0) return 100;
    
    double score = 100;
    
    // Penalty for null values (max -40%)
    final nullPercentage = (nullValues / (totalRows * totalColumns)) * 100;
    score -= (nullPercentage * 0.4).clamp(0, 40);
    
    // Penalty for duplicates (max -30%)
    final duplicatePercentage = (duplicateRows / totalRows) * 100;
    score -= (duplicatePercentage * 0.3).clamp(0, 30);
    
    return score.clamp(0, 100);
  }

  String _getQualityLabel(double score) {
    if (score >= 90) return 'Excellent';
    if (score >= 75) return 'Good';
    if (score >= 50) return 'Fair';
    return 'Poor';
  }

  Color _getQualityColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 75) return Colors.blue;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final score = _calculateQualityScore();
    final label = _getQualityLabel(score);
    final color = _getQualityColor(score);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.assessment_outlined,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Data Quality Score',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: score / 100,
                          strokeWidth: 6,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(color),
                          backgroundColor: color.withValues(alpha: 0.1),
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            '${score.toStringAsFixed(1)}%',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            label,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildStatChip(
                        'Total Rows',
                        totalRows.toString(),
                        Colors.blue,
                      ),
                      _buildStatChip(
                        'Columns',
                        totalColumns.toString(),
                        Colors.purple,
                      ),
                      _buildStatChip(
                        'Null Values',
                        nullValues.toString(),
                        Colors.orange,
                      ),
                      _buildStatChip(
                        'Duplicates',
                        duplicateRows.toString(),
                        Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.2),
        child: Text(
          value[0],
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
            ),
          ),
        ],
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
    );
  }
}
