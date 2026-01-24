/// School Management Screen
/// Okul yönetimi ve öğretmen/kat/öğrenci/salon kaydetme ekranı

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' hide Border;
import 'dart:convert';
import '../../models/duty_planner_models.dart';
import '../../models/school_models.dart';
import '../../services/teacher_db_service.dart';
import '../../services/floor_db_service.dart';
import '../../services/student_db_service.dart';
import '../../services/room_db_service.dart';
import '../../services/file_parser_service.dart';
import '../../theme/duty_planner_theme.dart';
import 'section_students_screen.dart';

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
  final StudentDbService _studentDbService = StudentDbService();
  final RoomDbService _roomDbService = RoomDbService();
  final FileParserService _fileParser = FileParserService();

  late TabController _tabController;

  List<Teacher> _teachers = [];
  List<Floor> _floors = [];
  List<SchoolGrade> _grades = [];
  List<SchoolRoom> _rooms = [];
  bool _isLoadingTeachers = true;
  bool _isLoadingFloors = true;
  bool _isLoadingStudents = true;
  bool _isLoadingRooms = true;
  String? _teacherError;
  String? _floorError;
  String? _studentError;
  String? _roomError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTeachers();
    _loadFloors();
    _loadStudents();
    _loadRooms();
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
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Öğretmenler'),
            Tab(icon: Icon(Icons.layers), text: 'Katlar'),
            Tab(icon: Icon(Icons.school), text: 'Öğrenciler'),
            Tab(icon: Icon(Icons.meeting_room), text: 'Salonlar'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadTeachers();
              _loadFloors();
              _loadStudents();
              _loadRooms();
            },
            tooltip: 'Yenile',
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTeachersTab(),
          _buildFloorsTab(),
          _buildStudentsTab(),
          _buildRoomsTab(),
        ],
      ),
    );
  }

  Widget _buildFab() {
    // Tab'a göre farklı FAB göster
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        switch (_tabController.index) {
          case 0:
            return FloatingActionButton.extended(
              heroTag: 'teacher_fab',
              onPressed: _showAddTeacherOptionsDialog,
              icon: const Icon(Icons.add),
              label: const Text('Öğretmen Ekle'),
            );
          case 1:
            return FloatingActionButton.extended(
              heroTag: 'floor_fab',
              onPressed: _showAddFloorDialog,
              icon: const Icon(Icons.add),
              label: const Text('Kat Ekle'),
            );
          case 2:
            return FloatingActionButton.extended(
              heroTag: 'student_fab',
              onPressed: _showAddGradeDialog,
              icon: const Icon(Icons.add),
              label: const Text('Sınıf Ekle'),
            );
          case 3:
            return FloatingActionButton.extended(
              heroTag: 'room_fab',
              onPressed: _showAddRoomDialog,
              icon: const Icon(Icons.add),
              label: const Text('Salon Ekle'),
            );
          default:
            return const SizedBox.shrink();
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

  // ==================== STUDENTS TAB ====================

  Future<void> _loadStudents() async {
    setState(() {
      _isLoadingStudents = true;
      _studentError = null;
    });

    try {
      final grades = await _studentDbService.getGrades();
      setState(() {
        _grades = grades;
        _isLoadingStudents = false;
      });
    } catch (e) {
      setState(() {
        _studentError = 'Öğrenciler yüklenemedi: $e';
        _isLoadingStudents = false;
      });
    }
  }

  Widget _buildStudentsTab() {
    if (_isLoadingStudents) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_studentError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_studentError!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStudents,
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
              _buildStudentSummaryCard(),
              const SizedBox(height: 16),
              _buildImportStudentsButton(),
              const SizedBox(height: 24),
              if (_grades.isEmpty) _buildEmptyStudentsState(),
              ..._grades.map((grade) => _buildGradeCard(grade)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentSummaryCard() {
    final totalStudents = _grades.fold(0, (sum, g) => sum + g.studentCount);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.school, size: 32, color: Colors.indigo),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$totalStudents Öğrenci, ${_grades.length} Sınıf',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sınıf ve şubelere göre düzenlenmiş',
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

  Widget _buildImportStudentsButton() {
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
                  'Dosyadan Öğrenci Yükle',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showStudentFileFormatHelp,
                  icon: const Icon(Icons.help_outline, size: 18),
                  label: const Text('Dosya Formatı'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Excel (.xlsx) veya CSV dosyasından toplu öğrenci ekleyin',
              style: TextStyle(
                color: DutyPlannerColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _importStudentsFromFile,
                icon: const Icon(Icons.folder_open),
                label: const Text('Dosya Seç (Excel/CSV)'),
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

  void _showStudentFileFormatHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Dosya Formatı'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Desteklenen Formatlar:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildFormatChip('Excel (.xlsx)'),
              const SizedBox(height: 4),
              _buildFormatChip('CSV (.csv)'),
              const SizedBox(height: 16),

              const Text(
                'Sütun Yapısı (4 sütun gerekli):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildColumnInfo('1. Sütun', 'Ad', 'Ahmet'),
              _buildColumnInfo('2. Sütun', 'Soyad', 'Yılmaz'),
              _buildColumnInfo('3. Sütun', 'Sınıf', '9, 10, 11 veya 12'),
              _buildColumnInfo('4. Sütun', 'Şube', 'A, B, C...'),
              const SizedBox(height: 16),

              const Text(
                'Örnek Excel/CSV:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ad       | Soyad    | Sınıf | Şube',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '---------|----------|-------|------',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                    Text(
                      'Ahmet    | Yılmaz   | 9     | A',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                    Text(
                      'Ayşe     | Demir    | 9     | A',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                    Text(
                      'Mehmet   | Kaya     | 10    | B',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.amber,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'İlk satır başlık satırıysa otomatik atlanır',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anladım'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.indigo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.indigo,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildColumnInfo(String column, String name, String example) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(column, style: const TextStyle(fontSize: 12)),
          ),
          SizedBox(
            width: 60,
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
          ),
          Text(
            '(örn: $example)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStudentsState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: DutyPlannerColors.textHint,
            ),
            const SizedBox(height: 16),
            const Text(
              'Henüz sınıf eklenmedi',
              style: TextStyle(
                fontSize: 16,
                color: DutyPlannerColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddGradeDialog,
              icon: const Icon(Icons.add),
              label: const Text('İlk Sınıfı Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeCard(SchoolGrade grade) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getGradeColor(grade.level).withValues(alpha: 0.2),
          child: Text(
            '${grade.level}',
            style: TextStyle(
              color: _getGradeColor(grade.level),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(grade.name),
        subtitle: Text(
          '${grade.sections.length} şube, ${grade.studentCount} öğrenci',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.green),
              onPressed: () => _showAddSectionDialog(grade),
              tooltip: 'Şube Ekle',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteGrade(grade),
              tooltip: 'Sınıfı Sil',
            ),
          ],
        ),
        children: grade.sections
            .map((section) => _buildSectionTile(grade, section))
            .toList(),
      ),
    );
  }

  Widget _buildSectionTile(SchoolGrade grade, SchoolSection section) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 72, right: 16),
      onTap: () => _openStudentDetails(grade, section),
      leading: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getGradeColor(grade.level).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          section.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _getGradeColor(grade.level),
          ),
        ),
      ),
      title: Row(
        children: [
          Text('${section.studentCount} öğrenci'),
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward_ios,
            size: 12,
            color: DutyPlannerColors.textHint,
          ),
        ],
      ),
      subtitle: section.students.isNotEmpty
          ? Text(
              section.students.take(3).map((s) => s.fullName).join(', ') +
                  (section.students.length > 3 ? '...' : ''),
              style: const TextStyle(fontSize: 12),
            )
          : const Text(
              'Detaylar için tıklayın',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.person_add, size: 20),
            onPressed: () => _showAddStudentDialog(section),
            tooltip: 'Öğrenci Ekle',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
            onPressed: () => _deleteSection(section),
            tooltip: 'Şubeyi Sil',
          ),
        ],
      ),
    );
  }

  void _openStudentDetails(SchoolGrade grade, SchoolSection section) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SectionStudentsScreen(
          grade: grade,
          section: section,
          onStudentsChanged: _loadStudents,
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

  void _showAddGradeDialog() {
    int selectedLevel = 9;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Sınıf Ekle'),
          content: DropdownButtonFormField<int>(
            value: selectedLevel,
            decoration: const InputDecoration(
              labelText: 'Sınıf Seviyesi',
              prefixIcon: Icon(Icons.school),
            ),
            items: [9, 10, 11, 12].map((level) {
              return DropdownMenuItem(
                value: level,
                child: Text('$level. Sınıf'),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) setDialogState(() => selectedLevel = value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final result = await _studentDbService.addGrade(selectedLevel);
                if (result != null) {
                  _loadStudents();
                  _showSuccess('Sınıf eklendi');
                } else {
                  _showError('Sınıf eklenemedi');
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSectionDialog(SchoolGrade grade) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${grade.name} - Şube Ekle'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Şube Adı',
            hintText: 'A, B, C...',
            prefixIcon: Icon(Icons.class_),
          ),
          textCapitalization: TextCapitalization.characters,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context);
                final result = await _studentDbService.addSection(
                  grade.id,
                  controller.text.trim(),
                );
                if (result != null) {
                  _loadStudents();
                  _showSuccess('Şube eklendi');
                } else {
                  _showError('Şube eklenemedi');
                }
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _showAddStudentDialog(SchoolSection section) {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${section.name} Şubesine Öğrenci Ekle'),
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
                final result = await _studentDbService.addStudent(
                  section.id,
                  firstNameController.text.trim(),
                  lastNameController.text.trim(),
                );
                if (result != null) {
                  _loadStudents();
                  _showSuccess('Öğrenci eklendi');
                } else {
                  _showError('Öğrenci eklenemedi');
                }
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGrade(SchoolGrade grade) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sınıfı Sil'),
        content: Text('${grade.name} ve tüm şubeleri silinecek. Emin misiniz?'),
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
      final result = await _studentDbService.deleteGrade(grade.id);
      if (result) {
        _loadStudents();
        _showSuccess('Sınıf silindi');
      } else {
        _showError('Sınıf silinemedi');
      }
    }
  }

  Future<void> _deleteSection(SchoolSection section) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Şubeyi Sil'),
        content: Text(
          '${section.name} şubesi ve öğrencileri silinecek. Emin misiniz?',
        ),
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
      final result = await _studentDbService.deleteSection(section.id);
      if (result) {
        _loadStudents();
        _showSuccess('Şube silindi');
      } else {
        _showError('Şube silinemedi');
      }
    }
  }

  Future<void> _importStudentsFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;

      List<List<dynamic>> rows;
      final isExcel = file.name.toLowerCase().endsWith('.xlsx');

      if (isExcel) {
        // Excel dosyasını parse et
        final excel = Excel.decodeBytes(bytes);
        final sheetName = excel.tables.keys.first;
        final sheet = excel.tables[sheetName];

        if (sheet == null || sheet.rows.isEmpty) {
          _showError('Excel dosyası boş');
          return;
        }

        rows = sheet.rows.map((row) {
          return row.map((cell) => cell?.value?.toString() ?? '').toList();
        }).toList();
      } else {
        // CSV dosyasını parse et
        String content;
        try {
          content = utf8.decode(bytes);
        } catch (_) {
          content = String.fromCharCodes(bytes);
        }

        // Ayracı algıla
        String separator = ';';
        if (content.contains(',') && !content.contains(';')) {
          separator = ',';
        } else if (content.split(';').length < content.split(',').length) {
          separator = ',';
        }

        rows = const CsvToListConverter().convert(
          content,
          fieldDelimiter: separator,
        );
      }

      if (rows.isEmpty) {
        _showError('Dosyada veri bulunamadı');
        return;
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

      // Her satır için öğrenci ekle
      int addedCount = 0;
      for (int i = startRow; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 4) continue;

        final firstName = row[0].toString().trim();
        final lastName = row[1].toString().trim();
        final gradeLevel = int.tryParse(row[2].toString().trim());
        final sectionName = row[3].toString().trim().toUpperCase();

        if (firstName.isEmpty || gradeLevel == null) continue;

        // Sınıf var mı?
        var grade = _grades.firstWhere(
          (g) => g.level == gradeLevel,
          orElse: () => SchoolGrade(id: '', name: '', level: 0),
        );

        if (grade.id.isEmpty) {
          // Sınıf oluştur
          final newGrade = await _studentDbService.addGrade(gradeLevel);
          if (newGrade != null) {
            grade = newGrade;
            _grades.add(grade);
          } else {
            continue;
          }
        }

        // Şube var mı?
        var section = grade.sections.firstWhere(
          (s) => s.name == sectionName,
          orElse: () => SchoolSection(id: '', gradeId: '', name: ''),
        );

        if (section.id.isEmpty) {
          // Şube oluştur
          final newSection = await _studentDbService.addSection(
            grade.id,
            sectionName,
          );
          if (newSection != null) {
            section = newSection;
          } else {
            continue;
          }
        }

        // Öğrenci ekle
        final student = await _studentDbService.addStudent(
          section.id,
          firstName,
          lastName,
        );
        if (student != null) addedCount++;
      }

      _loadStudents();
      if (addedCount > 0) {
        _showSuccess('$addedCount öğrenci eklendi');
      } else {
        _showError('Öğrenci eklenemedi. Dosya formatını kontrol edin.');
      }
    } catch (e) {
      _showError('Dosya okunamadı: $e');
    }
  }

  // ==================== ROOMS TAB ====================

  Future<void> _loadRooms() async {
    setState(() {
      _isLoadingRooms = true;
      _roomError = null;
    });

    try {
      final rooms = await _roomDbService.getRooms();
      setState(() {
        _rooms = rooms;
        _isLoadingRooms = false;
      });
    } catch (e) {
      setState(() {
        _roomError = 'Salonlar yüklenemedi: $e';
        _isLoadingRooms = false;
      });
    }
  }

  Widget _buildRoomsTab() {
    if (_isLoadingRooms) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_roomError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_roomError!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRooms,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    final totalCapacity = _rooms.fold(0, (sum, r) => sum + r.capacity);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildRoomSummaryCard(totalCapacity),
              const SizedBox(height: 24),
              if (_rooms.isEmpty) _buildEmptyRoomsState(),
              ..._rooms.map((room) => _buildRoomCard(room)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomSummaryCard(int totalCapacity) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.meeting_room,
                size: 32,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_rooms.length} Salon, $totalCapacity Koltuk',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sınav salonları',
                    style: TextStyle(color: DutyPlannerColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (_rooms.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_sweep, color: Colors.red),
                onPressed: _showDeleteAllRoomsDialog,
                tooltip: 'Tümünü Sil',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRoomsState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(
              Icons.meeting_room_outlined,
              size: 64,
              color: DutyPlannerColors.textHint,
            ),
            const SizedBox(height: 16),
            const Text(
              'Henüz salon eklenmedi',
              style: TextStyle(
                fontSize: 16,
                color: DutyPlannerColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddRoomDialog,
              icon: const Icon(Icons.add),
              label: const Text('İlk Salonu Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard(SchoolRoom room) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.deepPurple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.meeting_room, color: Colors.deepPurple),
        ),
        title: Text(room.name),
        subtitle: Text(
          '${room.rowCount} × ${room.columnCount} = ${room.capacity} koltuk',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showEditRoomDialog(room),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteRoom(room),
            ),
          ],
        ),
      ),
    );
  }

  /// Salon önizleme widget'ı - Tahta ve koltuk grid'i gösterir
  Widget _buildRoomPreviewWidget(int rowCount, int columnCount) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DutyPlannerColors.tableHeader,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DutyPlannerColors.tableBorder),
      ),
      child: Column(
        children: [
          // Önizleme başlığı
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.visibility, size: 16, color: Colors.deepPurple),
              const SizedBox(width: 8),
              const Text(
                'Salon Önizlemesi',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Tahta
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Center(
              child: Text(
                'TAHTA',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Grid - Koltuklar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              children: List.generate(rowCount.clamp(1, 10), (row) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(columnCount.clamp(1, 10), (col) {
                    return Container(
                      width: 24,
                      height: 20,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: Colors.deepPurple.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${row * columnCount + col + 1}',
                          style: TextStyle(
                            fontSize: 7,
                            color: Colors.deepPurple.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          // Kapasite bilgisi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$rowCount sıra × $columnCount sütun = ${rowCount * columnCount} koltuk',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddRoomDialog() {
    final nameController = TextEditingController(
      text: 'Salon ${_rooms.length + 1}',
    );
    int rowCount = 5;
    int columnCount = 6;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Salon Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Salon Adı',
                    prefixIcon: Icon(Icons.meeting_room),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sıra: $rowCount'),
                          Slider(
                            value: rowCount.toDouble(),
                            min: 1,
                            max: 15,
                            divisions: 14,
                            onChanged: (v) =>
                                setDialogState(() => rowCount = v.round()),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sütun: $columnCount'),
                          Slider(
                            value: columnCount.toDouble(),
                            min: 1,
                            max: 12,
                            divisions: 11,
                            onChanged: (v) =>
                                setDialogState(() => columnCount = v.round()),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Text(
                  'Kapasite: ${rowCount * columnCount} koltuk',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                // Salon Önizlemesi
                _buildRoomPreviewWidget(rowCount, columnCount),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final result = await _roomDbService.addRoom(
                  nameController.text.trim(),
                  rowCount: rowCount,
                  columnCount: columnCount,
                );
                if (result != null) {
                  _loadRooms();
                  _showSuccess('Salon eklendi');
                } else {
                  _showError('Salon eklenemedi');
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRoomDialog(SchoolRoom room) {
    final nameController = TextEditingController(text: room.name);
    int rowCount = room.rowCount;
    int columnCount = room.columnCount;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Salon Düzenle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Salon Adı',
                    prefixIcon: Icon(Icons.meeting_room),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sıra: $rowCount'),
                          Slider(
                            value: rowCount.toDouble(),
                            min: 1,
                            max: 15,
                            divisions: 14,
                            onChanged: (v) =>
                                setDialogState(() => rowCount = v.round()),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sütun: $columnCount'),
                          Slider(
                            value: columnCount.toDouble(),
                            min: 1,
                            max: 12,
                            divisions: 11,
                            onChanged: (v) =>
                                setDialogState(() => columnCount = v.round()),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Text(
                  'Kapasite: ${rowCount * columnCount} koltuk',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                // Salon Önizlemesi
                _buildRoomPreviewWidget(rowCount, columnCount),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final updatedRoom = room.copyWith(
                  name: nameController.text.trim(),
                  rowCount: rowCount,
                  columnCount: columnCount,
                );
                final result = await _roomDbService.updateRoom(updatedRoom);
                if (result) {
                  _loadRooms();
                  _showSuccess('Salon güncellendi');
                } else {
                  _showError('Salon güncellenemedi');
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteRoom(SchoolRoom room) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Salonu Sil'),
        content: Text('${room.name} silinecek. Emin misiniz?'),
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
      final result = await _roomDbService.deleteRoom(room.id);
      if (result) {
        _loadRooms();
        _showSuccess('Salon silindi');
      } else {
        _showError('Salon silinemedi');
      }
    }
  }

  void _showDeleteAllRoomsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tüm Salonları Sil'),
        content: const Text('Tüm salonlar silinecek. Bu işlem geri alınamaz!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await _roomDbService.deleteAllRooms();
              if (result) {
                _loadRooms();
                _showSuccess('Tüm salonlar silindi');
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
}
