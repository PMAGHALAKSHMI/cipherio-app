import 'package:flutter/material.dart';

class DataPreview extends StatefulWidget {
  final List<Map<String, dynamic>> rows;
  final int maxRows;

  const DataPreview({Key? key, required this.rows, this.maxRows = 5})
    : super(key: key);

  @override
  State<DataPreview> createState() => _DataPreviewState();
}

class _DataPreviewState extends State<DataPreview> {
  static const int rowsPerPage = 10;
  int currentPage = 0;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredRows() {
    final displayRows = widget.rows.take(widget.maxRows).toList();
    if (searchQuery.isEmpty) return displayRows;
    
    return displayRows.where((row) {
      return row.values.any((value) =>
          value.toString().toLowerCase().contains(searchQuery.toLowerCase()));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rows.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'No data to preview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final columns = widget.rows.first.keys.toList();
    final filteredRows = _getFilteredRows();
    
    // For large datasets, use pagination
    final shouldPaginate = filteredRows.length > rowsPerPage;
    final totalPages = shouldPaginate 
        ? (filteredRows.length / rowsPerPage).ceil() 
        : 1;
    
    final startIndex = currentPage * rowsPerPage;
    final endIndex = (startIndex + rowsPerPage).clamp(0, filteredRows.length);
    final paginatedRows = filteredRows.sublist(startIndex, endIndex);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  currentPage = 0;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search in data...',
                prefixIcon: const Icon(Icons.search_outlined, size: 20),
                suffixIcon: searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {
                            searchQuery = '';
                            currentPage = 0;
                          });
                        },
                        child: const Icon(Icons.close, size: 18),
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),

          // Data Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              constraints: const BoxConstraints(minWidth: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: DataTable(
                headingRowHeight: 48,
                dataRowHeight: 52,
                columnSpacing: 20,
                headingRowColor: MaterialStateColor.resolveWith(
                  (states) => Colors.blue[50]!,
                ),
                headingTextStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.blue[900],
                  fontSize: 13,
                ),
                columns: columns
                    .map((c) => DataColumn(
                      label: Tooltip(
                        message: c.toString(),
                        child: Text(
                          c.toString(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ))
                    .toList(),
                rows: paginatedRows.asMap().entries.map((entry) {
                  final i = entry.key;
                  final r = entry.value;
                  return DataRow.byIndex(
                    index: i,
                    color: MaterialStateColor.resolveWith(
                      (states) => i.isEven 
                        ? Colors.grey[50]! 
                        : Colors.white,
                    ),
                    cells: columns.map((c) {
                      final val = r[c];
                      final displayValue = val == null ? '—' : val.toString();
                      return DataCell(
                        Tooltip(
                          message: displayValue,
                          child: Text(
                            displayValue,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ),

          // Pagination controls
          if (shouldPaginate)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Page ${currentPage + 1} of $totalPages',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: currentPage > 0
                            ? () => setState(() => currentPage--)
                            : null,
                        tooltip: 'Previous page',
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: currentPage < totalPages - 1
                            ? () => setState(() => currentPage++)
                            : null,
                        tooltip: 'Next page',
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Summary
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  searchQuery.isEmpty
                      ? 'Showing ${paginatedRows.length} of ${filteredRows.length} rows'
                      : 'Found ${filteredRows.length} of ${widget.rows.take(widget.maxRows).length} rows',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.blue[900],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${columns.length} columns',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
