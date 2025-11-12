import 'package:flutter/material.dart';

/// A responsive data table that adapts to screen size
/// - Desktop: Shows as a table with all columns
/// - Tablet/Mobile: Shows as cards with key information
class ResponsiveDataTable<T> extends StatelessWidget {
  final List<T> items;
  final List<DataColumn> columns;
  final List<DataCell> Function(T item) buildCells;
  final Widget Function(T item)? buildMobileCard;
  final Function(T item)? onRowTap;
  final bool sortAscending;
  final int? sortColumnIndex;
  final Function(int columnIndex, bool ascending)? onSort;
  final double mobileBreakpoint;
  final Color? headingRowColor;
  final double? dataRowHeight;
  final double? headingRowHeight;
  final bool showCheckboxColumn;

  const ResponsiveDataTable({
    Key? key,
    required this.items,
    required this.columns,
    required this.buildCells,
    this.buildMobileCard,
    this.onRowTap,
    this.sortAscending = true,
    this.sortColumnIndex,
    this.onSort,
    this.mobileBreakpoint = 900,
    this.headingRowColor,
    this.dataRowHeight,
    this.headingRowHeight,
    this.showCheckboxColumn = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use table layout for wide screens, cards for mobile
        if (constraints.maxWidth >= mobileBreakpoint) {
          return _buildDataTable();
        } else {
          return _buildMobileList();
        }
      },
    );
  }

  Widget _buildDataTable() {
    final verticalController = ScrollController();
    final horizontalController = ScrollController();
    
    return ScrollbarTheme(
      data: ScrollbarThemeData(
        thumbVisibility: MaterialStateProperty.all(true),
        thickness: MaterialStateProperty.all(8.0),
        thumbColor: MaterialStateProperty.all(Colors.grey.shade400),
        radius: const Radius.circular(4),
        minThumbLength: 40,
      ),
      child: Scrollbar(
        controller: verticalController,
        thumbVisibility: true,
        thickness: 8.0,
        child: SingleChildScrollView(
          controller: verticalController,
          child: Scrollbar(
            controller: horizontalController,
            thumbVisibility: true,
            thickness: 8.0,
            child: SingleChildScrollView(
              controller: horizontalController,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 800),
                child: Theme(
                  data: ThemeData(
                    dividerColor: Colors.grey.shade200,
                  ),
                  child: DataTable(
                    sortAscending: sortAscending,
                    sortColumnIndex: sortColumnIndex,
                    showCheckboxColumn: showCheckboxColumn,
                    headingRowColor: headingRowColor != null
                        ? MaterialStateProperty.all(headingRowColor!)
                        : MaterialStateProperty.all(Colors.grey.shade100),
                    dataRowHeight: dataRowHeight ?? 72,
                    headingRowHeight: headingRowHeight ?? 56,
                    columns: columns,
                    rows: items.map((item) {
                      return DataRow(
                        onSelectChanged: onRowTap != null ? (_) => onRowTap!(item) : null,
                        cells: buildCells(item),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList() {
    final scrollController = ScrollController();
    
    if (buildMobileCard != null) {
      return ScrollbarTheme(
        data: ScrollbarThemeData(
          thumbVisibility: MaterialStateProperty.all(true),
          thickness: MaterialStateProperty.all(8.0),
          thumbColor: MaterialStateProperty.all(Colors.grey.shade400),
          radius: const Radius.circular(4),
          minThumbLength: 40,
        ),
        child: Scrollbar(
          controller: scrollController,
          thumbVisibility: true,
          thickness: 8.0,
          child: ListView.builder(
            controller: scrollController,
            itemCount: items.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: buildMobileCard!(items[index]),
              );
            },
          ),
        ),
      );
    }

    // Fallback: simple list view
    final fallbackController = ScrollController();
    return ScrollbarTheme(
      data: ScrollbarThemeData(
        thumbVisibility: MaterialStateProperty.all(true),
        thickness: MaterialStateProperty.all(8.0),
        thumbColor: MaterialStateProperty.all(Colors.grey.shade400),
        radius: const Radius.circular(4),
        minThumbLength: 40,
      ),
      child: Scrollbar(
        controller: fallbackController,
        thumbVisibility: true,
        thickness: 8.0,
        child: ListView.builder(
          controller: fallbackController,
          itemCount: items.length,
          itemBuilder: (context, index) {
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: buildCells(items[index])
                      .map((cell) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: cell.child,
                          ))
                      .toList(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A modern data row card for mobile view
class DataRowCard extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final List<Widget>? details;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? statusColor;
  final String? statusText;
  final Gradient? gradient;

  const DataRowCard({
    Key? key,
    this.leading,
    required this.title,
    this.subtitle,
    this.details,
    this.trailing,
    this.onTap,
    this.statusColor,
    this.statusText,
    this.gradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: gradient != null
              ? BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (statusText != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor?.withOpacity(0.1) ??
                                  Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: statusColor ?? Colors.grey,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              statusText!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: statusColor ?? Colors.grey.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    if (details != null && details!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ...details!,
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A detail row for DataRowCard
class DetailRow extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String value;
  final Color? valueColor;
  final FontWeight? valueFontWeight;

  const DetailRow({
    Key? key,
    this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueFontWeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
          ],
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: valueColor ?? Colors.black87,
                fontWeight: valueFontWeight ?? FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
