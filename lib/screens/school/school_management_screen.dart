/// School Management Screen
/// Okul yönetimi ve öğretmen/kat kaydetme ekranı

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import '../../models/duty_planner_models.dart';
import '../../services/teacher_db_service.dart';
import '../../services/floor_db_service.dart';
import '../../services/file_parser_service.dart';
import '../../theme/duty_planner_theme.dart';

/// Okul yönetimi ekranı
class SchoolManagementScreen extends StatefulWidget {
  const SchoolManagementScreen({super.key});

  @override
  State<SchoolManagementScreen> createState() => _SchoolManagementScreenState();
}

class _SchoolManagementScreenState extends State<SchoolManagementScreen>
    with SingleTickerProviderStateMixin {
  final TeacherDbService _teacherDbService = TeacherDbService();
  final FloorDbService _floorDbService = FloorDbService();
  final FileParserService _fileParser = FileParserService();

  late TabController _tabController;

  List<Teacher> _teachers = [];
  List<Floor> _floors = [];
  bool _isLoadingTeachers = true;
  bool _isLoadingFloors = true;
  String? _teacherError;
  String? _floorError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTeachers();
    _loadFloors();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTeachers() async {
    setState(() {
      _isLoadingTeachers = true;
      _teacherError = null;
    });

    try {
      final teachers = await _teacherDbService.getTeachers();
      setState(() {
        _teachers = teachers;
        _isLoadingTeachers = false;
      });
    } catch (e) {
      setState(() {
        _teacherError = 'Öğretmenler yüklenemedi: $e';
        _isLoadingTeachers = false;
      });
    }
  }

  Future<void> _loadFloors() async {
    setState(() {
      _isLoadingFloors = true;
      _floorError = null;
    });

    try {
      final floors = await _floorDbService.getFloors();
      setState(() {
        _floors = floors;
        _isLoadingFloors = false;
      });
    } catch (e) {
      setState(() {
        _floorError = 'Katlar yüklenemedi: $e';
        _isLoadingFloors = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Okul Yönetimi'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Öğretmenler'),
            Tab(icon: Icon(Icons.layers), text: 'Katlar'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadTeachers();
              _loadFloors();
            },
            tooltip: 'Yenile',
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
      body: TabBarView(
        controller: _tabController,
        children: [_buildTeachersTab(), _buildFloorsTab()],
      ),
    );
  }

  Widget _buildFab() {
    // Tab'a göre farklı FAB göster
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        if (_tabController.index == 0) {
          return FloatingActionButton.extended(
            heroTag: 'teacher_fab',
            onPressed: _showAddTeacherOptionsDialog,
            icon: const Icon(Icons.add),
            label: const Text('Öğretmen Ekle'),
          );
        } else {
          return FloatingActionButton.extended(
            heroTag: 'floor_fab',
            onPressed: _showAddFloorDialog,
            icon: const Icon(Icons.add),
            label: const Text('Kat Ekle'),
          );
        }
      },
    );
  }

  // ==================== TEACHERS TAB ====================

  Widget _buildTeachersTab() {
    if (_isLoadingTeachers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_teacherError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_teacherError!, style: const TextStyle(color: Colors.red)),
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
              _buildTeacherSummaryCard(),
              const SizedBox(height: 24),
              _buildTeacherList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeacherSummaryCard() {
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
                onPressed: _showDeleteAllTeachersDialog,
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
                onPressed: _showAddTeacherOptionsDialog,
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
                      onPressed: () => _showEditTeacherDialog(teacher),
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

  // ==================== FLOORS TAB ====================

  Widget _buildFloorsTab() {
    if (_isLoadingFloors) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_floorError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_floorError!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFloors,
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
              _buildFloorSummaryCard(),
              const SizedBox(height: 24),
              if (_floors.isEmpty) _buildDefaultFloorsButton(),
              if (_floors.isEmpty) const SizedBox(height: 16),
              _buildFloorList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloorSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.layers, size: 32, color: Colors.teal),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_floors.length} Kat Kayıtlı',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Bu katlar nöbet planlayıcıda kullanılabilir',
                    style: TextStyle(color: DutyPlannerColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (_floors.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_sweep, color: Colors.red),
                onPressed: _showDeleteAllFloorsDialog,
                tooltip: 'Tümünü Sil',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultFloorsButton() {
    return OutlinedButton.icon(
      onPressed: _addDefaultFloors,
      icon: const Icon(Icons.auto_fix_high),
      label: const Text('Örnek Katları Ekle (Zemin + 1-3. Kat)'),
    );
  }

  Widget _buildFloorList() {
    if (_floors.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            children: [
              Icon(
                Icons.layers_clear,
                size: 64,
                color: DutyPlannerColors.textHint,
              ),
              const SizedBox(height: 16),
              const Text(
                'Henüz kat eklenmedi',
                style: TextStyle(
                  fontSize: 16,
                  color: DutyPlannerColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _showAddFloorDialog,
                icon: const Icon(Icons.add),
                label: const Text('İlk Katı Ekle'),
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
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Kayıtlı Katlar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  'Sıralamak için sürükleyin',
                  style: TextStyle(
                    fontSize: 12,
                    color: DutyPlannerColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _floors.length,
            onReorder: _reorderFloors,
            itemBuilder: (context, index) {
              final floor = _floors[index];
              return ListTile(
                key: ValueKey(floor.id),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${floor.order}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                ),
                title: Text(floor.name),
                subtitle: Text('Sıra: ${floor.order}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showEditFloorDialog(floor),
                      color: Colors.teal,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteFloor(floor),
                    ),
                    ReorderableDragStartListener(
                      index: index,
                      child: const Icon(
                        Icons.drag_handle,
                        color: DutyPlannerColors.textHint,
                      ),
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

  // ==================== TEACHER ACTIONS ====================

  void _showAddTeacherOptionsDialog() {
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
                  _showAddTeacherDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('Excel/CSV Yükle'),
                subtitle: const Text('Toplu import yapın'),
                onTap: () {
                  Navigator.pop(context);
                  _importTeachersFromFile();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddTeacherDialog() {
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

  void _showEditTeacherDialog(Teacher teacher) {
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

  void _showDeleteAllTeachersDialog() {
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

  Future<void> _importTeachersFromFile() async {
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

  // ==================== FLOOR ACTIONS ====================

  void _showAddFloorDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kat Ekle'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Kat Adı',
            hintText: 'örn: 1. Kat, Zemin Kat',
            prefixIcon: Icon(Icons.layers_outlined),
          ),
          autofocus: true,
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
                await _addFloor(nameController.text.trim());
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _showEditFloorDialog(Floor floor) {
    final nameController = TextEditingController(text: floor.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kat Düzenle'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Kat Adı',
            prefixIcon: Icon(Icons.layers_outlined),
          ),
          autofocus: true,
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
                await _updateFloor(floor, nameController.text.trim());
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> _addFloor(String name) async {
    final floor = Floor(id: '', name: name, order: _floors.length + 1);

    final result = await _floorDbService.addFloor(floor);
    if (result != null) {
      _loadFloors();
      _showSuccess('Kat eklendi');
    } else {
      _showError('Kat eklenemedi');
    }
  }

  Future<void> _updateFloor(Floor floor, String newName) async {
    final updatedFloor = Floor(id: floor.id, name: newName, order: floor.order);

    final result = await _floorDbService.updateFloor(floor.id, updatedFloor);
    if (result) {
      _loadFloors();
      _showSuccess('Kat güncellendi');
    } else {
      _showError('Kat güncellenemedi');
    }
  }

  Future<void> _deleteFloor(Floor floor) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Katı Sil'),
        content: Text('${floor.name} silinecek. Emin misiniz?'),
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
      final result = await _floorDbService.deleteFloor(floor.id);
      if (result) {
        _loadFloors();
        _showSuccess('Kat silindi');
      } else {
        _showError('Kat silinemedi');
      }
    }
  }

  void _showDeleteAllFloorsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tüm Katları Sil'),
        content: const Text(
          'Tüm kayıtlı katlar silinecek. Bu işlem geri alınamaz!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await _floorDbService.deleteAllFloors();
              if (result) {
                _loadFloors();
                _showSuccess('Tüm katlar silindi');
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

  Future<void> _addDefaultFloors() async {
    final defaultFloors = [
      Floor(id: '', name: 'Zemin Kat', order: 1),
      Floor(id: '', name: '1. Kat', order: 2),
      Floor(id: '', name: '2. Kat', order: 3),
      Floor(id: '', name: '3. Kat', order: 4),
    ];

    final count = await _floorDbService.addFloors(defaultFloors);
    if (count > 0) {
      _loadFloors();
      _showSuccess('$count varsayılan kat eklendi');
    } else {
      _showError('Katlar eklenemedi');
    }
  }

  Future<void> _reorderFloors(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    setState(() {
      final floor = _floors.removeAt(oldIndex);
      _floors.insert(newIndex, floor);

      // Sıra numaralarını güncelle
      for (int i = 0; i < _floors.length; i++) {
        _floors[i] = Floor(
          id: _floors[i].id,
          name: _floors[i].name,
          order: i + 1,
        );
      }
    });

    // Supabase'e kaydet
    final result = await _floorDbService.updateFloorOrders(_floors);
    if (!result) {
      _showError('Sıralama kaydedilemedi');
      _loadFloors(); // Geri al
    }
  }

  // ==================== HELPERS ====================

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
