/// Teacher Upload Screen
/// Adım 1: Öğretmen yükleme ekranı

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/duty_planner_models.dart';
import '../../services/file_parser_service.dart';
import '../../services/teacher_db_service.dart';
import '../../theme/duty_planner_theme.dart';
import '../../widgets/file_preview_widget.dart';

/// Öğretmen yükleme ekranı
class TeacherUploadScreen extends StatefulWidget {
  final List<Teacher> teachers;
  final Function(List<Teacher>) onTeachersUpdated;
  final VoidCallback onNext;

  const TeacherUploadScreen({
    super.key,
    required this.teachers,
    required this.onTeachersUpdated,
    required this.onNext,
  });

  @override
  State<TeacherUploadScreen> createState() => _TeacherUploadScreenState();
}

class _TeacherUploadScreenState extends State<TeacherUploadScreen> {
  final FileParserService _fileParser = FileParserService();
  FilePreviewResult? _preview;
  bool _isLoading = false;
  String? _selectedFileName;

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
              // Başlık ve açıklama
              _buildHeader(),
              const SizedBox(height: 24),

              // Dosya yükleme kartı
              _buildUploadCard(),
              const SizedBox(height: 16),

              // Dosya önizleme
              if (_preview != null) ...[
                FilePreviewWidget(preview: _preview!, onClear: _clearFile),
                const SizedBox(height: 16),
              ],

              // Yüklenen öğretmenler
              TeacherListPreview(
                teachers: widget.teachers,
                onRemove: _removeTeacher,
              ),
              const SizedBox(height: 24),

              // Manuel ekleme butonu
              OutlinedButton.icon(
                onPressed: _showManualAddDialog,
                icon: const Icon(Icons.person_add),
                label: const Text('Manuel Öğretmen Ekle'),
              ),
              const SizedBox(height: 12),

              // Kayıtlı öğretmenleri kullan butonu
              OutlinedButton.icon(
                onPressed: _loadSavedTeachers,
                icon: const Icon(Icons.cloud_download),
                label: const Text('Kayıtlı Öğretmenleri Kullan'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.teal),
              ),
              const SizedBox(height: 24),

              // Sonraki adım butonu
              ElevatedButton(
                onPressed: widget.teachers.isNotEmpty ? widget.onNext : null,
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
                color: DutyPlannerColors.primaryLight.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.people,
                color: DutyPlannerColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Adım 1: Öğretmen Yükleme',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Excel veya CSV dosyası ile öğretmenleri yükleyin',
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

  Widget _buildUploadCard() {
    return Card(
      child: InkWell(
        onTap: _isLoading ? null : _pickFile,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 64,
                  color: DutyPlannerColors.primary.withValues(alpha: 0.7),
                ),
              const SizedBox(height: 16),
              Text(
                _selectedFileName ?? 'Dosya Seçmek için Tıklayın',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: _selectedFileName != null
                      ? FontWeight.w600
                      : null,
                  color: _selectedFileName != null
                      ? DutyPlannerColors.textPrimary
                      : DutyPlannerColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Desteklenen formatlar: .xlsx, .csv',
                style: TextStyle(
                  fontSize: 12,
                  color: DutyPlannerColors.textHint,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DutyPlannerColors.tableHeader,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Beklenen Sütunlar:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '1. Öğretmen Adı\n2. Branş\n3. Müsait Olmayan Günler (opsiyonel, örn: 1;5)',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    setState(() => _isLoading = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        _selectedFileName = file.name;

        final bytes = file.bytes;
        if (bytes == null) {
          _showError('Dosya okunamadı');
          return;
        }

        await _processFile(file.name, bytes);
      }
    } catch (e) {
      _showError('Dosya seçilirken hata oluştu: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processFile(String fileName, Uint8List bytes) async {
    final isExcel = fileName.toLowerCase().endsWith('.xlsx');

    FilePreviewResult preview;
    List<Teacher> teachers;

    if (isExcel) {
      preview = _fileParser.previewExcel(bytes);
      teachers = _fileParser.parseExcel(bytes);
    } else {
      // CSV için UTF-8 encoding kullan (Türkçe karakterler için)
      String content;
      try {
        content = utf8.decode(bytes);
      } catch (_) {
        // Eğer UTF-8 decode başarısız olursa, Latin1 dene
        content = latin1.decode(bytes);
      }
      preview = _fileParser.previewCsv(content);
      teachers = _fileParser.parseCsv(content);
    }

    setState(() {
      _preview = preview;
    });

    if (teachers.isNotEmpty) {
      // Mevcut listeye ekle
      final updatedList = [...widget.teachers, ...teachers];
      widget.onTeachersUpdated(updatedList);

      _showSuccess('${teachers.length} öğretmen eklendi');
    } else if (!preview.hasError) {
      _showError('Dosyada öğretmen bulunamadı');
    }
  }

  void _clearFile() {
    setState(() {
      _preview = null;
      _selectedFileName = null;
    });
  }

  Future<void> _loadSavedTeachers() async {
    final teacherDbService = TeacherDbService();

    try {
      final savedTeachers = await teacherDbService.getTeachers();

      if (savedTeachers.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Kayıtlı öğretmen bulunamadı. Önce Okul Yönetimi\'nden öğretmen ekleyin.',
              ),
              backgroundColor: DutyPlannerColors.warning,
            ),
          );
        }
        return;
      }

      // Mevcut listeye ekle (duplicate kontrol edilir)
      final existingIds = widget.teachers.map((t) => t.id).toSet();
      final newTeachers = savedTeachers
          .where((t) => !existingIds.contains(t.id))
          .toList();

      if (newTeachers.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Tüm kayıtlı öğretmenler zaten listede'),
              backgroundColor: Colors.blue[600],
            ),
          );
        }
        return;
      }

      final updatedList = [...widget.teachers, ...newTeachers];
      widget.onTeachersUpdated(updatedList);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newTeachers.length} öğretmen eklendi'),
            backgroundColor: DutyPlannerColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Öğretmenler yüklenemedi: $e'),
            backgroundColor: DutyPlannerColors.error,
          ),
        );
      }
    }
  }

  void _removeTeacher(Teacher teacher) {
    final updatedList = widget.teachers
        .where((t) => t.id != teacher.id)
        .toList();
    widget.onTeachersUpdated(updatedList);
  }

  void _showManualAddDialog() {
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
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                final teacher = Teacher.fromRow(
                  name: nameController.text,
                  branch: branchController.text,
                );
                widget.onTeachersUpdated([...widget.teachers, teacher]);
                Navigator.pop(context);
              }
            },
            child: const Text('Ekle'),
          ),
        ],
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

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DutyPlannerColors.success,
      ),
    );
  }
}
