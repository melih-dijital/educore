/// Student Entry Screen
/// Öğrenci ekleme ekranı - Ad, Soyad, Sınıf, Şube

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import '../../models/butterfly_exam_models.dart';
import '../../models/school_models.dart';
import '../../services/student_db_service.dart';
import '../../theme/duty_planner_theme.dart';

/// Öğrenci ekleme ekranı
class StudentEntryScreen extends StatefulWidget {
  final List<ExamSection> sections;
  final Function(List<ExamSection>) onSectionsChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const StudentEntryScreen({
    super.key,
    required this.sections,
    required this.onSectionsChanged,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<StudentEntryScreen> createState() => _StudentEntryScreenState();
}

class _StudentEntryScreenState extends State<StudentEntryScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _bulkController = TextEditingController();
  int _selectedGrade = 9;
  String _selectedSection = 'A';
  bool _isLoadingFile = false;
  bool _isLoadingSchoolStudents = false;

  final StudentDbService _studentDbService = StudentDbService();

  final List<int> _gradeOptions = [9, 10, 11, 12];
  final List<String> _sectionOptions = ['A', 'B', 'C', 'D', 'E', 'F'];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bulkController.dispose();
    super.dispose();
  }

  int get _totalStudents {
    return widget.sections.fold(0, (sum, s) => sum + s.students.length);
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
              _buildHeader(),
              const SizedBox(height: 24),

              // Okul yönetiminden öğrenci aktarma
              _buildSchoolStudentsCard(),
              const SizedBox(height: 16),

              // Dosya yükleme (CSV)
              _buildFileUploadCard(),
              const SizedBox(height: 16),

              // Tek öğrenci ekleme
              _buildSingleStudentForm(),
              const SizedBox(height: 16),

              // Toplu ekleme
              _buildBulkAddForm(),
              const SizedBox(height: 24),

              // Öğrenci listesi
              _buildStudentsList(),
              const SizedBox(height: 24),

              // Navigasyon
              _buildNavigationButtons(),
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
              child: const Icon(Icons.people, color: Colors.indigo, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Adım 2: Öğrencileri Ekleyin',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Toplam $_totalStudents öğrenci eklendi',
                    style: const TextStyle(
                      color: DutyPlannerColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileUploadCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.upload_file, color: Colors.indigo),
                const SizedBox(width: 8),
                const Text(
                  'CSV Dosyasından Yükle',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showFileFormatHelp,
                  icon: const Icon(Icons.help_outline, size: 18),
                  label: const Text('Format'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'CSV formatı: Ad;Soyad;Sınıf;Şube (örn: Ahmet;Yılmaz;9;A)',
              style: TextStyle(
                color: DutyPlannerColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoadingFile ? null : _pickAndParseFile,
                icon: _isLoadingFile
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.folder_open),
                label: Text(
                  _isLoadingFile ? 'Yükleniyor...' : 'CSV Dosyası Seç',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolStudentsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.school, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  'Kayıtlı Öğrencilerden Ekle',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Okul yönetiminde kayıtlı öğrencileri sınıf seçerek ekleyin',
              style: TextStyle(
                color: DutyPlannerColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoadingSchoolStudents
                    ? null
                    : _showSelectSectionsDialog,
                icon: _isLoadingSchoolStudents
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.group_add),
                label: Text(
                  _isLoadingSchoolStudents
                      ? 'Yükleniyor...'
                      : 'Sınıf Seç ve Ekle',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSelectSectionsDialog() async {
    setState(() => _isLoadingSchoolStudents = true);

    try {
      // Okul yönetiminden sınıfları çek
      final grades = await _studentDbService.getGrades();

      if (!mounted) return;

      if (grades.isEmpty) {
        setState(() => _isLoadingSchoolStudents = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Okul yönetiminde kayıtlı öğrenci bulunamadı'),
            backgroundColor: DutyPlannerColors.warning,
          ),
        );
        return;
      }

      setState(() => _isLoadingSchoolStudents = false);

      // Seçili sınıfları takip et
      final selectedSections = <String>{};

      await showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Sınıf Seçin'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Eklemek istediğiniz sınıfları seçin:',
                        style: TextStyle(
                          color: DutyPlannerColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...grades.map((grade) {
                        final allSectionsSelected = grade.sections.every(
                          (s) => selectedSections.contains(s.id),
                        );

                        return ExpansionTile(
                          leading: Checkbox(
                            value:
                                allSectionsSelected &&
                                grade.sections.isNotEmpty,
                            tristate: true,
                            onChanged: (value) {
                              setDialogState(() {
                                if (value == true) {
                                  for (final s in grade.sections) {
                                    selectedSections.add(s.id);
                                  }
                                } else {
                                  for (final s in grade.sections) {
                                    selectedSections.remove(s.id);
                                  }
                                }
                              });
                            },
                          ),
                          title: Text('${grade.level}. Sınıf'),
                          subtitle: Text(
                            '${grade.sections.length} şube, ${grade.sections.fold(0, (sum, s) => sum + s.students.length)} öğrenci',
                            style: const TextStyle(fontSize: 12),
                          ),
                          children: grade.sections.map((section) {
                            return CheckboxListTile(
                              value: selectedSections.contains(section.id),
                              onChanged: (value) {
                                setDialogState(() {
                                  if (value == true) {
                                    selectedSections.add(section.id);
                                  } else {
                                    selectedSections.remove(section.id);
                                  }
                                });
                              },
                              title: Text('${grade.level}-${section.name}'),
                              subtitle: Text(
                                '${section.students.length} öğrenci',
                              ),
                              secondary: CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.teal.withValues(
                                  alpha: 0.1,
                                ),
                                child: Text(
                                  section.name,
                                  style: const TextStyle(
                                    color: Colors.teal,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                ElevatedButton.icon(
                  onPressed: selectedSections.isEmpty
                      ? null
                      : () {
                          Navigator.pop(context, selectedSections);
                        },
                  icon: const Icon(Icons.add),
                  label: Text('Ekle (${selectedSections.length} şube)'),
                ),
              ],
            );
          },
        ),
      ).then((result) {
        if (result != null && result is Set<String>) {
          _addSchoolStudents(grades, result);
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSchoolStudents = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: DutyPlannerColors.error,
          ),
        );
      }
    }
  }

  void _addSchoolStudents(
    List<SchoolGrade> grades,
    Set<String> selectedSectionIds,
  ) {
    List<ExamSection> updatedSections = List.from(widget.sections);
    int addedCount = 0;

    for (final grade in grades) {
      for (final section in grade.sections) {
        if (!selectedSectionIds.contains(section.id)) continue;

        for (final student in section.students) {
          final sectionId = ExamSection.createId(grade.level, section.name);

          // Şube var mı kontrol et
          int sectionIndex = updatedSections.indexWhere(
            (s) => s.id == sectionId,
          );

          if (sectionIndex < 0) {
            // Yeni şube oluştur
            final newSection = ExamSection(
              id: sectionId,
              gradeLevel: grade.level,
              sectionName: section.name,
              students: [],
            );
            updatedSections.add(newSection);
            sectionIndex = updatedSections.length - 1;
          }

          final existingSection = updatedSections[sectionIndex];
          final examStudent = ExamStudent(
            id: '${DateTime.now().microsecondsSinceEpoch}_$addedCount',
            firstName: student.firstName,
            lastName: student.lastName,
            studentNumber: student.studentNumber,
            sectionId: sectionId,
            gradeLevel: grade.level,
          );

          final updatedSection = ExamSection(
            id: existingSection.id,
            gradeLevel: existingSection.gradeLevel,
            sectionName: existingSection.sectionName,
            students: [...existingSection.students, examStudent],
          );

          updatedSections[sectionIndex] = updatedSection;
          addedCount++;
        }
      }
    }

    if (addedCount > 0) {
      widget.onSectionsChanged(updatedSections);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$addedCount öğrenci eklendi'),
          backgroundColor: DutyPlannerColors.success,
        ),
      );
    }
  }

  Widget _buildSingleStudentForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tek Öğrenci Ekle',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 16),
            // Ad ve Soyad
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'Ad',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Soyad',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Sınıf ve Şube
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedGrade,
                    decoration: const InputDecoration(
                      labelText: 'Sınıf',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _gradeOptions.map((grade) {
                      return DropdownMenuItem(
                        value: grade,
                        child: Text('$grade. Sınıf'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedGrade = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSection,
                    decoration: const InputDecoration(
                      labelText: 'Şube',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _sectionOptions.map((section) {
                      return DropdownMenuItem(
                        value: section,
                        child: Text(section),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null)
                        setState(() => _selectedSection = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _addSingleStudent,
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

  Widget _buildBulkAddForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Toplu Ekle (Metin)',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Her satıra: Ad;Soyad;Sınıf;Şube formatında yazın',
              style: TextStyle(
                color: DutyPlannerColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bulkController,
              decoration: const InputDecoration(
                hintText: 'Ahmet;Yılmaz;9;A\nAyşe;Demir;10;B',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _bulkController.clear(),
                  icon: const Icon(Icons.clear),
                  label: const Text('Temizle'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _addBulkStudents,
                  icon: const Icon(Icons.group_add),
                  label: const Text('Tümünü Ekle'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsList() {
    // Öğrencileri sınıf/şubeye göre grupla
    final allStudents = <ExamStudent>[];
    for (final section in widget.sections) {
      allStudents.addAll(section.students);
    }

    if (allStudents.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Henüz öğrenci eklenmedi',
                  style: TextStyle(color: DutyPlannerColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Sınıf seviyesine göre grupla
    final byGrade = <int, List<ExamStudent>>{};
    for (final student in allStudents) {
      byGrade.putIfAbsent(student.gradeLevel, () => []).add(student);
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
                  'Eklenen Öğrenciler (${allStudents.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                TextButton.icon(
                  onPressed: _clearAllStudents,
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
              final grade = entry.key;
              final students = entry.value;
              // Şubeye göre alt grupla
              final bySection = <String, List<ExamStudent>>{};
              for (final s in students) {
                bySection.putIfAbsent(s.sectionId, () => []).add(s);
              }

              return ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: _getGradeColor(grade).withValues(alpha: 0.2),
                  child: Text(
                    '$grade',
                    style: TextStyle(color: _getGradeColor(grade)),
                  ),
                ),
                title: Text('$grade. Sınıf (${students.length} öğrenci)'),
                children: bySection.entries.map((sectionEntry) {
                  return ListTile(
                    dense: true,
                    leading: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getGradeColor(grade).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        sectionEntry.key,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getGradeColor(grade),
                        ),
                      ),
                    ),
                    title: Text('${sectionEntry.value.length} öğrenci'),
                    subtitle: Text(
                      sectionEntry.value
                              .take(3)
                              .map((s) => s.fullName)
                              .join(', ') +
                          (sectionEntry.value.length > 3 ? '...' : ''),
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onBack,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_back),
                SizedBox(width: 8),
                Text('Geri'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _totalStudents > 0 ? widget.onNext : null,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Devam Et'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward),
              ],
            ),
          ),
        ),
      ],
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

  void _addSingleStudent() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    if (firstName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Öğrenci adı girin')));
      return;
    }

    _addStudentToSection(firstName, lastName, _selectedGrade, _selectedSection);
    _firstNameController.clear();
    _lastNameController.clear();
  }

  void _addStudentToSection(
    String firstName,
    String lastName,
    int grade,
    String sectionName,
  ) {
    final sectionId = ExamSection.createId(grade, sectionName);

    // Şube var mı kontrol et, yoksa oluştur
    int sectionIndex = widget.sections.indexWhere((s) => s.id == sectionId);

    List<ExamSection> updatedSections = List.from(widget.sections);

    if (sectionIndex < 0) {
      // Yeni şube oluştur
      final newSection = ExamSection(
        id: sectionId,
        gradeLevel: grade,
        sectionName: sectionName,
        students: [],
      );
      updatedSections.add(newSection);
      sectionIndex = updatedSections.length - 1;
    }

    final section = updatedSections[sectionIndex];
    final student = ExamStudent(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      firstName: firstName,
      lastName: lastName,
      studentNumber: '',
      sectionId: sectionId,
      gradeLevel: grade,
    );

    final updatedSection = ExamSection(
      id: section.id,
      gradeLevel: section.gradeLevel,
      sectionName: section.sectionName,
      students: [...section.students, student],
    );

    updatedSections[sectionIndex] = updatedSection;
    widget.onSectionsChanged(updatedSections);
  }

  void _addBulkStudents() {
    final text = _bulkController.text.trim();
    if (text.isEmpty) return;

    final lines = text.split('\n').where((line) => line.trim().isNotEmpty);

    // Mevcut sections'ı kopyala
    List<ExamSection> updatedSections = List.from(widget.sections);
    int addedCount = 0;

    for (final line in lines) {
      final parsed = _parseLine(line);
      if (parsed != null) {
        final firstName = parsed['firstName'] as String;
        final lastName = parsed['lastName'] as String;
        final grade = parsed['grade'] as int;
        final sectionName = parsed['section'] as String;
        final sectionId = ExamSection.createId(grade, sectionName);

        // Şube var mı kontrol et
        int sectionIndex = updatedSections.indexWhere((s) => s.id == sectionId);

        if (sectionIndex < 0) {
          // Yeni şube oluştur
          final newSection = ExamSection(
            id: sectionId,
            gradeLevel: grade,
            sectionName: sectionName,
            students: [],
          );
          updatedSections.add(newSection);
          sectionIndex = updatedSections.length - 1;
        }

        final section = updatedSections[sectionIndex];
        final student = ExamStudent(
          id: '${DateTime.now().microsecondsSinceEpoch}_$addedCount',
          firstName: firstName,
          lastName: lastName,
          studentNumber: '',
          sectionId: sectionId,
          gradeLevel: grade,
        );

        final updatedSection = ExamSection(
          id: section.id,
          gradeLevel: section.gradeLevel,
          sectionName: section.sectionName,
          students: [...section.students, student],
        );

        updatedSections[sectionIndex] = updatedSection;
        addedCount++;
      }
    }

    if (addedCount > 0) {
      widget.onSectionsChanged(updatedSections);
      _bulkController.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$addedCount öğrenci eklendi')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Geçerli öğrenci bulunamadı. Format: Ad;Soyad;Sınıf;Şube',
          ),
        ),
      );
    }
  }

  Map<String, dynamic>? _parseLine(String line) {
    // Ayracı algıla
    String separator = ';';
    if (!line.contains(';') && line.contains(',')) {
      separator = ',';
    }

    final parts = line.split(separator).map((p) => p.trim()).toList();
    if (parts.length < 4) return null;

    final grade = int.tryParse(parts[2]);
    if (grade == null || grade < 9 || grade > 12) return null;

    return {
      'firstName': parts[0],
      'lastName': parts[1],
      'grade': grade,
      'section': parts[3].toUpperCase(),
    };
  }

  Future<void> _pickAndParseFile() async {
    setState(() => _isLoadingFile = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isLoadingFile = false);
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes;

      if (bytes == null) {
        throw Exception('Dosya okunamadı');
      }

      // Türkçe karakter desteği - farklı encoding dene
      String content;
      try {
        content = utf8.decode(bytes);
      } catch (e) {
        // UTF-8 başarısız - Windows-1254 (Turkish) veya Latin-1 dene
        try {
          content = latin1.decode(bytes);
        } catch (e2) {
          content = String.fromCharCodes(bytes);
        }
      }

      // CSV ayracını algıla
      String separator = ';';
      if (content.contains(',') && !content.contains(';')) {
        separator = ',';
      } else if (content.split(';').length < content.split(',').length) {
        separator = ',';
      }

      final rows = const CsvToListConverter().convert(
        content,
        fieldDelimiter: separator,
        shouldParseNumbers: false,
      );

      if (rows.isEmpty) {
        throw Exception('Dosyada veri bulunamadı');
      }

      // Başlık satırını atla
      int startRow = 0;
      if (rows.isNotEmpty && rows[0].isNotEmpty) {
        final firstCell = rows[0][0].toString().toLowerCase();
        if (firstCell.contains('ad') ||
            firstCell.contains('name') ||
            firstCell.contains('öğrenci') ||
            firstCell.contains('isim')) {
          startRow = 1;
        }
      }

      // Tüm öğrencileri tek bir listede topla ve sonunda state'i güncelle
      List<ExamSection> updatedSections = List.from(widget.sections);
      int addedCount = 0;

      for (int i = startRow; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 4) continue;

        final firstName = row[0].toString().trim();
        final lastName = row[1].toString().trim();
        final grade = int.tryParse(row[2].toString().trim());
        final sectionName = row[3].toString().trim().toUpperCase();

        if (firstName.isNotEmpty &&
            grade != null &&
            grade >= 9 &&
            grade <= 12 &&
            sectionName.isNotEmpty) {
          // Şube ID oluştur
          final sectionId = ExamSection.createId(grade, sectionName);

          // Şube var mı kontrol et
          int sectionIndex = updatedSections.indexWhere(
            (s) => s.id == sectionId,
          );

          if (sectionIndex < 0) {
            // Yeni şube oluştur
            final newSection = ExamSection(
              id: sectionId,
              gradeLevel: grade,
              sectionName: sectionName,
              students: [],
            );
            updatedSections.add(newSection);
            sectionIndex = updatedSections.length - 1;
          }

          final section = updatedSections[sectionIndex];
          final student = ExamStudent(
            id: '${DateTime.now().microsecondsSinceEpoch}_$addedCount',
            firstName: firstName,
            lastName: lastName,
            studentNumber: '',
            sectionId: sectionId,
            gradeLevel: grade,
          );

          final updatedSection = ExamSection(
            id: section.id,
            gradeLevel: section.gradeLevel,
            sectionName: section.sectionName,
            students: [...section.students, student],
          );

          updatedSections[sectionIndex] = updatedSection;
          addedCount++;
        }
      }

      // Tek seferde state'i güncelle
      if (addedCount > 0) {
        widget.onSectionsChanged(updatedSections);
      }

      if (addedCount == 0) {
        throw Exception(
          'Geçerli öğrenci verisi bulunamadı. Format: Ad;Soyad;Sınıf;Şube',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$addedCount öğrenci başarıyla eklendi'),
            backgroundColor: DutyPlannerColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: DutyPlannerColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingFile = false);
      }
    }
  }

  void _showFileFormatHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CSV Dosya Formatı'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CSV dosyanızda 4 sütun olmalı:'),
            SizedBox(height: 12),
            Text('Sütun 1: Ad', style: TextStyle(fontFamily: 'monospace')),
            Text('Sütun 2: Soyad', style: TextStyle(fontFamily: 'monospace')),
            Text(
              'Sütun 3: Sınıf (9-12)',
              style: TextStyle(fontFamily: 'monospace'),
            ),
            Text(
              'Sütun 4: Şube (A, B, C...)',
              style: TextStyle(fontFamily: 'monospace'),
            ),
            SizedBox(height: 12),
            Text('Örnek:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              'Ahmet;Yılmaz;9;A',
              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            Text(
              'Ayşe;Demir;10;B',
              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            Text(
              'Mehmet;Kaya;9;A',
              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            SizedBox(height: 12),
            Text(
              'Ayraç: ; veya , kullanabilirsiniz.',
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _clearAllStudents() {
    // Tüm şubelerdeki öğrencileri temizle
    final clearedSections = widget.sections
        .map(
          (s) => ExamSection(
            id: s.id,
            gradeLevel: s.gradeLevel,
            sectionName: s.sectionName,
            students: [],
          ),
        )
        .toList();
    widget.onSectionsChanged(clearedSections);
  }
}
