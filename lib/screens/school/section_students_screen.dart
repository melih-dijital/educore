/// Section Students Screen
/// Şubedeki tüm öğrencileri gösteren detay ekranı

import 'package:flutter/material.dart';
import '../../models/school_models.dart';
import '../../services/student_db_service.dart';
import '../../theme/duty_planner_theme.dart';

/// Şube öğrenci detay ekranı
class SectionStudentsScreen extends StatefulWidget {
  final SchoolGrade grade;
  final SchoolSection section;
  final VoidCallback onStudentsChanged;

  const SectionStudentsScreen({
    super.key,
    required this.grade,
    required this.section,
    required this.onStudentsChanged,
  });

  @override
  State<SectionStudentsScreen> createState() => _SectionStudentsScreenState();
}

class _SectionStudentsScreenState extends State<SectionStudentsScreen> {
  final StudentDbService _studentDbService = StudentDbService();
  late List<SchoolStudent> _students;
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _students = List.from(widget.section.students);
  }

  List<SchoolStudent> get _filteredStudents {
    if (_searchQuery.isEmpty) return _students;
    final query = _searchQuery.toLowerCase();
    return _students.where((s) {
      return s.fullName.toLowerCase().contains(query) ||
          s.studentNumber.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.grade.name} - ${widget.section.name} Şubesi'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showAddStudentDialog,
            tooltip: 'Öğrenci Ekle',
          ),
        ],
      ),
      body: Column(
        children: [
          // Özet ve arama
          Container(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getGradeColor(
                          widget.grade.level,
                        ).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.people,
                        color: _getGradeColor(widget.grade.level),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_students.length} Öğrenci',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${widget.grade.name} - ${widget.section.name} Şubesi',
                            style: const TextStyle(
                              color: DutyPlannerColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_students.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.delete_sweep, color: Colors.red),
                        onPressed: _showDeleteAllStudentsDialog,
                        tooltip: 'Tümünü Sil',
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Öğrenci ara...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ],
            ),
          ),

          // Öğrenci listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredStudents.isEmpty
                ? _buildEmptyState()
                : _buildStudentList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStudentDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Öğrenci Ekle'),
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: DutyPlannerColors.textHint),
            const SizedBox(height: 16),
            Text(
              '"$_searchQuery" için sonuç bulunamadı',
              style: const TextStyle(color: DutyPlannerColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: DutyPlannerColors.textHint,
          ),
          const SizedBox(height: 16),
          const Text(
            'Bu şubede henüz öğrenci yok',
            style: TextStyle(
              fontSize: 16,
              color: DutyPlannerColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddStudentDialog,
            icon: const Icon(Icons.add),
            label: const Text('İlk Öğrenciyi Ekle'),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredStudents.length,
      itemBuilder: (context, index) {
        final student = _filteredStudents[index];
        return _buildStudentCard(student, index + 1);
      },
    );
  }

  Widget _buildStudentCard(SchoolStudent student, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getGradeColor(
            widget.grade.level,
          ).withValues(alpha: 0.2),
          child: Text(
            '$index',
            style: TextStyle(
              color: _getGradeColor(widget.grade.level),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          student.fullName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: student.studentNumber.isNotEmpty
            ? Text('No: ${student.studentNumber}')
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => _showEditStudentDialog(student),
              tooltip: 'Düzenle',
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 20,
                color: Colors.red,
              ),
              onPressed: () => _deleteStudent(student),
              tooltip: 'Sil',
            ),
          ],
        ),
      ),
    );
  }

  Color _getGradeColor(int level) {
    switch (level) {
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

  void _showAddStudentDialog() {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final studentNumberController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Öğrenci Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(
                labelText: 'Ad',
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(
                labelText: 'Soyad',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: studentNumberController,
              decoration: const InputDecoration(
                labelText: 'Öğrenci No (opsiyonel)',
                prefixIcon: Icon(Icons.badge),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (firstNameController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                await _addStudent(
                  firstNameController.text.trim(),
                  lastNameController.text.trim(),
                  studentNumberController.text.trim(),
                );
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _showEditStudentDialog(SchoolStudent student) {
    final firstNameController = TextEditingController(text: student.firstName);
    final lastNameController = TextEditingController(text: student.lastName);
    final studentNumberController = TextEditingController(
      text: student.studentNumber,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Öğrenci Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(
                labelText: 'Ad',
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(
                labelText: 'Soyad',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: studentNumberController,
              decoration: const InputDecoration(
                labelText: 'Öğrenci No (opsiyonel)',
                prefixIcon: Icon(Icons.badge),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (firstNameController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                await _updateStudent(
                  student,
                  firstNameController.text.trim(),
                  lastNameController.text.trim(),
                  studentNumberController.text.trim(),
                );
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> _addStudent(
    String firstName,
    String lastName,
    String studentNumber,
  ) async {
    setState(() => _isLoading = true);

    final result = await _studentDbService.addStudent(
      widget.section.id,
      firstName,
      lastName,
      studentNumber: studentNumber,
    );

    if (result != null) {
      setState(() {
        _students.add(result);
        _isLoading = false;
      });
      widget.onStudentsChanged();
      _showSuccess('Öğrenci eklendi');
    } else {
      setState(() => _isLoading = false);
      _showError('Öğrenci eklenemedi');
    }
  }

  Future<void> _updateStudent(
    SchoolStudent student,
    String firstName,
    String lastName,
    String studentNumber,
  ) async {
    setState(() => _isLoading = true);

    // Öğrenciyi sil ve yeniden ekle (update metodu eklenebilir)
    final deleted = await _studentDbService.deleteStudent(student.id);
    if (deleted) {
      final result = await _studentDbService.addStudent(
        widget.section.id,
        firstName,
        lastName,
        studentNumber: studentNumber,
      );

      if (result != null) {
        setState(() {
          _students.removeWhere((s) => s.id == student.id);
          _students.add(result);
          _isLoading = false;
        });
        widget.onStudentsChanged();
        _showSuccess('Öğrenci güncellendi');
      } else {
        setState(() => _isLoading = false);
        _showError('Öğrenci güncellenemedi');
      }
    } else {
      setState(() => _isLoading = false);
      _showError('Öğrenci güncellenemedi');
    }
  }

  Future<void> _deleteStudent(SchoolStudent student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Öğrenciyi Sil'),
        content: Text('${student.fullName} silinecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      final result = await _studentDbService.deleteStudent(student.id);
      if (result) {
        setState(() {
          _students.removeWhere((s) => s.id == student.id);
          _isLoading = false;
        });
        widget.onStudentsChanged();
        _showSuccess('Öğrenci silindi');
      } else {
        setState(() => _isLoading = false);
        _showError('Öğrenci silinemedi');
      }
    }
  }

  void _showDeleteAllStudentsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tüm Öğrencileri Sil'),
        content: Text(
          '${widget.section.name} şubesindeki tüm öğrenciler silinecek. Bu işlem geri alınamaz!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);

              final result = await _studentDbService.deleteAllStudentsInSection(
                widget.section.id,
              );

              if (result) {
                setState(() {
                  _students.clear();
                  _isLoading = false;
                });
                widget.onStudentsChanged();
                _showSuccess('Tüm öğrenciler silindi');
              } else {
                setState(() => _isLoading = false);
                _showError('Silme işlemi başarısız');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Tümünü Sil'),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DutyPlannerColors.success,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DutyPlannerColors.error,
      ),
    );
  }
}
