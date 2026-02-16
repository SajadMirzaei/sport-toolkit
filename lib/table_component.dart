import 'package:flutter/material.dart';

class TableComponent extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String orderBy;
  final bool ascending;
  final void Function(String, bool) onSort;

  const TableComponent({super.key, 
    required this.data,
    required this.orderBy,
    required this.ascending,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(child: Text("No Data Available"));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, // Horizontal scrolling
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical, // Vertical scrolling
        child: DataTable(
          columnSpacing: 20.0,
          sortColumnIndex:
              data.isNotEmpty
                  ? data.first.keys.toList().indexOf(orderBy)
                  : null,
          sortAscending: ascending,
          columns:
              data.first.keys.map((key) {
                return DataColumn(
                  label: Text(key),
                  onSort: (columnIndex, ascending) {
                    onSort(key, ascending);
                  },
                );
              }).toList(),
          rows:
              data.map((row) {
                return DataRow(
                  cells:
                      row.values.map((value) {
                        return DataCell(Text(value.toString()));
                      }).toList(),
                );
              }).toList(),
        ),
      ),
    );
  }
}
