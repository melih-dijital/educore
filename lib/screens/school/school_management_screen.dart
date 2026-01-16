/// School Management Screen
/// Okul yönetimi ve öğretmen kaydetme ekranı

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import '../../models/duty_planner_models.dart';
import '../../services/teacher_db_service.dart';
import '../../services/file_parser_service.dart';
import '../../theme/duty_planner_theme.dart';

/// Okul yönetimi ekranı
class SchoolManagementScreen extends StatefulWidget {
  const SchoolManagementScreen({super.key});

  @override
  State<SchoolManagementScreen> createState() => _SchoolManagementScreenState();
}

class _SchoolManagementScreenState extends State<SchoolManagementScreen> {
  final TeacherDbService _teacherDbService = TeacherDbService();
  final FileParserService _fileParser = FileParserService();

  List<Teacher> _teachers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final teachers = await _teacherDbService.getTeachers();
      setState(() {
        _teachers = teachers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Öğretmenler yüklenemedi: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Okul Yönetimi'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTeachers,
            tooltip: 'Yenile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddOptionsDialog,
        icon: const Icon(Icons.add),
        label: const Text('Öğretmen Ekle'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTeachers,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Özet kartı
              _buildSummaryCard(),
              const SizedBox(height: 24),

              // Öğretmen listesi
              _buildTeacherList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DutyPlannerColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.people,
                size: 32,
                color: DutyPlannerColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_teachers.length} Öğretmen Kayıtlı',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Bu öğretmenler nöbet planlayıcıda kullanılabilir',
                    style: TextStyle(color: DutyPlannerColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (_teachers.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_sweep, color: Colors.red),
                onPressed: _showDeleteAllDialog,
                tooltip: 'Tümünü Sil',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherList() {
    if (_teachers.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            children: [
              Icon(
                Icons.people_outline,
                size: 64,
                color: DutyPlannerColors.textHint,
              ),
              const SizedBox(height: 16),
              const Text(
                'Henüz öğretmen eklenmedi',
                style: TextStyle(
                  fontSize: 16,
                  color: DutyPlannerColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _showAddOptionsDialog,
                icon: const Icon(Icons.add),
                label: const Text('İlk Öğretmeni Ekle'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Kayıtlı Öğretmenler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _teachers.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final teacher = _teachers[index];
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
                subtitle: Text(teacher.branch),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (teacher.unavailableDays.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
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
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showEditDialog(teacher),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteTeacher(teacher),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddOptionsDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Öğretmen Ekle',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('Manuel Ekle'),
                subtitle: const Text('Tek tek öğretmen ekleyin'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('Excel/CSV Yükle'),
                subtitle: const Text('Toplu import yapın'),
                onTap: () {
                  Navigator.pop(context);
                  _importFromFile();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final branchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Öğretmen Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Ad Soyad',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: branchController,
              decoration: const InputDecoration(
                labelText: 'Branş',
                prefixIcon: Icon(Icons.school),
              ),
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
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                await _addTeacher(
                  nameController.text.trim(),
                  branchController.text.trim(),
                );
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Teacher teacher) {
    final nameController = TextEditingController(text: teacher.name);
    final branchController = TextEditingController(text: teacher.branch);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Öğretmen Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Ad Soyad',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: branchController,
              decoration: const InputDecoration(
                labelText: 'Branş',
                prefixIcon: Icon(Icons.school),
              ),
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
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                await _updateTeacher(
                  teacher.id,
                  nameController.text.trim(),
                  branchController.text.trim(),
                  teacher.unavailableDays,
                );
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> _addTeacher(String name, String branch) async {
    final teacher = Teacher(id: '', name: name, branch: branch);

    final result = await _teacherDbService.addTeacher(teacher);
    if (result != null) {
      _loadTeachers();
      _showSuccess('Öğretmen eklendi');
    } else {
      _showError('Öğretmen eklenemedi');
    }
  }

  Future<void> _updateTeacher(
    String id,
    String name,
    String branch,
    List<int> unavailableDays,
  ) async {
    final teacher = Teacher(
      id: id,
      name: name,
      branch: branch,
      unavailableDays: unavailableDays,
    );

    final result = await _teacherDbService.updateTeacher(id, teacher);
    if (result) {
      _loadTeachers();
      _showSuccess('Öğretmen güncellendi');
    } else {
      _showError('Öğretmen güncellenemedi');
    }
  }

  Future<void> _deleteTeacher(Teacher teacher) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Öğretmeni Sil'),
        content: Text('${teacher.name} silinecek. Emin misiniz?'),
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
      final result = await _teacherDbService.deleteTeacher(teacher.id);
      if (result) {
        _loadTeachers();
        _showSuccess('Öğretmen silindi');
      } else {
        _showError('Öğretmen silinemedi');
      }
    }
  }

  void _showDeleteAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tüm Öğretmenleri Sil'),
        content: const Text(
          'Tüm kayıtlı öğretmenler silinecek. Bu işlem geri alınamaz!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await _teacherDbService.deleteAllTeachers();
              if (result) {
                _loadTeachers();
                _showSuccess('Tüm öğretmenler silindi');
              } else {
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

  Future<void> _importFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;

      List<Teacher> teachers;
      final isExcel = file.name.toLowerCase().endsWith('.xlsx');

      if (isExcel) {
        teachers = _fileParser.parseExcel(bytes);
      } else {
        String content;
        try {
          content = utf8.decode(bytes);
        } catch (_) {
          content = String.fromCharCodes(bytes);
        }
        teachers = _fileParser.parseCsv(content);
      }

      if (teachers.isEmpty) {
        _showError('Dosyada öğretmen bulunamadı');
        return;
      }

      final count = await _teacherDbService.addTeachers(teachers);
      if (count > 0) {
        _loadTeachers();
        _showSuccess('$count öğretmen eklendi');
      } else {
        _showError('Öğretmenler eklenemedi');
      }
    } catch (e) {
      _showError('Dosya okunamadı: $e');
    }
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

  String _formatDays(List<int> days) {
    const dayNames = ['', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return days.map((d) => dayNames[d]).join(', ');
  }
}
