/// File Preview Widget
/// Excel/CSV dosya önizleme tablosu

import 'package:flutter/material.dart';
import '../models/duty_planner_models.dart';
import '../theme/duty_planner_theme.dart';

/// Dosya önizleme widget'ı - genişletilebilir
class FilePreviewWidget extends StatefulWidget {
  final FilePreviewResult preview;
  final VoidCallback? onClear;
  final int initialRowCount;

  const FilePreviewWidget({
    super.key,
    required this.preview,
    this.onClear,
    this.initialRowCount = 5,
  });

  @override
  State<FilePreviewWidget> createState() => _FilePreviewWidgetState();
}

class _FilePreviewWidgetState extends State<FilePreviewWidget> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    if (widget.preview.hasError) {
      return _buildErrorState(context);
    }

    if (widget.preview.isEmpty) {
      return _buildEmptyState(context);
    }

    // Gösterilecek satır sayısını hesapla (header hariç)
    final dataRows = widget.preview.rows.skip(1).toList();
    final visibleRowCount = _showAll
        ? dataRows.length
        : dataRows.length.clamp(0, widget.initialRowCount);
    final hasMore = dataRows.length > widget.initialRowCount;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Başlık
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: DutyPlannerColors.tableHeader,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.preview_outlined,
                  color: DutyPlannerColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Dosya Önizleme (${widget.preview.totalRows} satır)',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: DutyPlannerColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (widget.onClear != null)
                  IconButton(
                    onPressed: widget.onClear,
                    icon: const Icon(Icons.close),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: DutyPlannerColors.textSecondary,
                  ),
              ],
            ),
          ),

          // Tablo
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                DutyPlannerColors.tableHeader,
              ),
              dataRowColor: WidgetStateProperty.resolveWith((states) {
                return DutyPlannerColors.tableRowOdd;
              }),
              columns: widget.preview.rows.isNotEmpty
                  ? widget.preview.rows.first.cells
                        .asMap()
                        .entries
                        .map(
                          (entry) => DataColumn(
                            label: Text(
                              entry.value.isEmpty
                                  ? 'Sütun ${entry.key + 1}'
                                  : entry.value,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                        .toList()
                  : [],
              rows: dataRows.take(visibleRowCount).map((row) {
                return DataRow(
                  cells: row.cells
                      .map(
                        (cell) => DataCell(
                          Text(
                            cell.isEmpty ? '-' : cell,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
                );
              }).toList(),
            ),
          ),

          // Daha Fazla/Daha Az butonu
          if (hasMore)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showAll = !_showAll;
                      });
                    },
                    icon: Icon(
                      _showAll ? Icons.expand_less : Icons.expand_more,
                    ),
                    label: Text(
                      _showAll
                          ? 'Daha Az Göster'
                          : 'Daha Fazla Göster (${dataRows.length - widget.initialRowCount} satır daha)',
                    ),
                  ),
                ],
              ),
            ),

          // Not
          if (!_showAll &&
              widget.preview.totalRows > widget.preview.rows.length)
            Container(
              padding: const EdgeInsets.all(12),
              child: Text(
                '* Önizlemede ${widget.preview.rows.length - 1} satır gösterilmektedir. Dosyada toplam ${widget.preview.totalRows} satır var.',
                style: const TextStyle(
                  fontSize: 12,
                  color: DutyPlannerColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Card(
      color: DutyPlannerColors.error.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: DutyPlannerColors.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.preview.error!,
                style: const TextStyle(color: DutyPlannerColors.error),
              ),
            ),
            if (widget.onClear != null)
              IconButton(
                onPressed: widget.onClear,
                icon: const Icon(Icons.close),
                color: DutyPlannerColors.error,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.table_chart_outlined,
              size: 48,
              color: DutyPlannerColors.textHint,
            ),
            const SizedBox(height: 16),
            const Text(
              'Henüz dosya yüklenmedi',
              style: TextStyle(color: DutyPlannerColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Öğretmen listesi önizleme widget'ı
class TeacherListPreview extends StatefulWidget {
  final List<Teacher> teachers;
  final Function(Teacher)? onRemove;
  final int initialCount;

  const TeacherListPreview({
    super.key,
    required this.teachers,
    this.onRemove,
    this.initialCount = 5,
  });

  @override
  State<TeacherListPreview> createState() => _TeacherListPreviewState();
}

class _TeacherListPreviewState extends State<TeacherListPreview> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    if (widget.teachers.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.people_outline,
                size: 48,
                color: DutyPlannerColors.textHint,
              ),
              const SizedBox(height: 16),
              const Text(
                'Henüz öğretmen eklenmedi',
                style: TextStyle(color: DutyPlannerColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final visibleCount = _showAll
        ? widget.teachers.length
        : widget.teachers.length.clamp(0, widget.initialCount);
    final hasMore = widget.teachers.length > widget.initialCount;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Başlık
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: DutyPlannerColors.tableHeader,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.people,
                  color: DutyPlannerColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Yüklenen Öğretmenler (${widget.teachers.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: DutyPlannerColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Liste
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visibleCount,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final teacher = widget.teachers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: DutyPlannerColors.primaryLight.withValues(
                    alpha: 0.2,
                  ),
                  child: Text(
                    teacher.name.isNotEmpty
                        ? teacher.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: DutyPlannerColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(teacher.name),
                subtitle: Row(
                  children: [
                    Text(teacher.branch),
                    if (teacher.unavailableDays.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: DutyPlannerColors.warning.withValues(
                            alpha: 0.2,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Müsait değil: ${_formatDays(teacher.unavailableDays)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: DutyPlannerColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: widget.onRemove != null
                    ? IconButton(
                        onPressed: () => widget.onRemove!(teacher),
                        icon: const Icon(Icons.delete_outline),
                        color: DutyPlannerColors.error,
                      )
                    : null,
              );
            },
          ),

          // Daha Fazla/Daha Az butonu
          if (hasMore)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showAll = !_showAll;
                  });
                },
                icon: Icon(_showAll ? Icons.expand_less : Icons.expand_more),
                label: Text(
                  _showAll
                      ? 'Daha Az Göster'
                      : 'Daha Fazla Göster (${widget.teachers.length - widget.initialCount} öğretmen daha)',
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDays(List<int> days) {
    const dayNames = ['', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return days.map((d) => dayNames[d]).join(', ');
  }
}
