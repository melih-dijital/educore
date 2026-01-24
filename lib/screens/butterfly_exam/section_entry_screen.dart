/// Section Entry Screen
/// Şube ekleme ekranı

import 'package:flutter/material.dart';
import '../../models/butterfly_exam_models.dart';
import '../../theme/duty_planner_theme.dart';

/// Şube ekleme ekranı
class SectionEntryScreen extends StatefulWidget {
  final List<ExamSection> sections;
  final Function(List<ExamSection>) onSectionsChanged;
  final VoidCallback onNext;

  const SectionEntryScreen({
    super.key,
    required this.sections,
    required this.onSectionsChanged,
    required this.onNext,
  });

  @override
  State<SectionEntryScreen> createState() => _SectionEntryScreenState();
}

class _SectionEntryScreenState extends State<SectionEntryScreen> {
  final _gradeController = TextEditingController();
  final _sectionController = TextEditingController();
  int _selectedGrade = 9;

  final List<int> _gradeOptions = [9, 10, 11, 12];

  @override
  void dispose() {
    _gradeController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = DutyPlannerTheme.screenPadding(context);
    final maxWidth = DutyPlannerTheme.maxContentWidth(context);

    return SingleChildScrollView(
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Başlık
              _buildHeader(),
              const SizedBox(height: 24),

              // Şube ekleme formu
              _buildAddSectionForm(),
              const SizedBox(height: 24),

              // Hızlı ekleme
              _buildQuickAdd(),
              const SizedBox(height: 24),

              // Mevcut şubeler
              if (widget.sections.isNotEmpty) ...[
                _buildSectionsList(),
                const SizedBox(height: 24),
              ],

              // Devam butonu
              ElevatedButton(
                onPressed: widget.sections.isNotEmpty ? widget.onNext : null,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Devam Et'),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.class_, color: Colors.indigo, size: 32),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Adım 1: Şubeleri Ekleyin',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Sınava girecek şubeleri tanımlayın',
                    style: TextStyle(color: DutyPlannerColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddSectionForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Şube Ekle',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Sınıf seçimi
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedGrade,
                    decoration: const InputDecoration(
                      labelText: 'Sınıf',
                      border: OutlineInputBorder(),
                    ),
                    items: _gradeOptions.map((grade) {
                      return DropdownMenuItem(
                        value: grade,
                        child: Text('$grade. Sınıf'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedGrade = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Şube adı
                Expanded(
                  child: TextField(
                    controller: _sectionController,
                    decoration: const InputDecoration(
                      labelText: 'Şube',
                      hintText: 'Örn: A, B, C',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                const SizedBox(width: 16),
                // Ekle butonu
                ElevatedButton.icon(
                  onPressed: _addSection,
                  icon: const Icon(Icons.add),
                  label: const Text('Ekle'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAdd() {
    return Card(
      color: DutyPlannerColors.tableHeader,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.flash_on, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Text(
                  'Hızlı Ekle',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _quickAddButton(
                  '9. Sınıf A-B-C',
                  () => _quickAddSections(9, ['A', 'B', 'C']),
                ),
                _quickAddButton(
                  '10. Sınıf A-B-C',
                  () => _quickAddSections(10, ['A', 'B', 'C']),
                ),
                _quickAddButton(
                  '11. Sınıf A-B',
                  () => _quickAddSections(11, ['A', 'B']),
                ),
                _quickAddButton(
                  '12. Sınıf A-B',
                  () => _quickAddSections(12, ['A', 'B']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAddButton(String label, VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildSectionsList() {
    // Sınıf seviyesine göre grupla
    final byGrade = <int, List<ExamSection>>{};
    for (final section in widget.sections) {
      byGrade.putIfAbsent(section.gradeLevel, () => []).add(section);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Eklenen Şubeler (${widget.sections.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                TextButton.icon(
                  onPressed: _clearAll,
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Tümünü Temizle'),
                  style: TextButton.styleFrom(
                    foregroundColor: DutyPlannerColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...byGrade.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getGradeColor(entry.key).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${entry.key}. Sınıf',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getGradeColor(entry.key),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        children: entry.value.map((section) {
                          return Chip(
                            label: Text(section.sectionName),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () => _removeSection(section),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getGradeColor(int grade) {
    switch (grade) {
      case 9:
        return Colors.blue;
      case 10:
        return Colors.green;
      case 11:
        return Colors.orange;
      case 12:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _addSection() {
    final sectionName = _sectionController.text.trim().toUpperCase();
    if (sectionName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Şube adı girin')));
      return;
    }

    final id = ExamSection.createId(_selectedGrade, sectionName);

    // Zaten var mı kontrol et
    if (widget.sections.any((s) => s.id == id)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$id şubesi zaten ekli')));
      return;
    }

    final newSection = ExamSection(
      id: id,
      gradeLevel: _selectedGrade,
      sectionName: sectionName,
    );

    widget.onSectionsChanged([...widget.sections, newSection]);
    _sectionController.clear();
  }

  void _quickAddSections(int grade, List<String> sectionNames) {
    final newSections = <ExamSection>[];

    for (final name in sectionNames) {
      final id = ExamSection.createId(grade, name);
      if (!widget.sections.any((s) => s.id == id)) {
        newSections.add(
          ExamSection(id: id, gradeLevel: grade, sectionName: name),
        );
      }
    }

    if (newSections.isNotEmpty) {
      widget.onSectionsChanged([...widget.sections, ...newSections]);
    }
  }

  void _removeSection(ExamSection section) {
    final updated = widget.sections.where((s) => s.id != section.id).toList();
    widget.onSectionsChanged(updated);
  }

  void _clearAll() {
    widget.onSectionsChanged([]);
  }
}
