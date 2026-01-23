/// Distribution Screen
/// Dağıtım sonucu ve oturma planı ekranı

import 'package:flutter/material.dart';
import 'dart:html' as html;
import '../../models/butterfly_exam_models.dart';
import '../../services/butterfly_exam_service.dart';
import '../../services/exam_pdf_service.dart';
import '../../theme/duty_planner_theme.dart';

/// Dağıtım sonucu ekranı
class DistributionScreen extends StatefulWidget {
  final List<ExamSection> sections;
  final List<ExamRoom> rooms;
  final String examName;
  final ExamPlan? generatedPlan;
  final Function(ExamPlan) onPlanGenerated;
  final VoidCallback onBack;
  final VoidCallback onRestart;

  const DistributionScreen({
    super.key,
    required this.sections,
    required this.rooms,
    required this.examName,
    required this.generatedPlan,
    required this.onPlanGenerated,
    required this.onBack,
    required this.onRestart,
  });

  @override
  State<DistributionScreen> createState() => _DistributionScreenState();
}

class _DistributionScreenState extends State<DistributionScreen> {
  final ButterflyExamService _service = ButterflyExamService();
  final ExamPdfService _pdfService = ExamPdfService();

  bool _isGenerating = false;
  bool _isExporting = false;
  String? _error;
  List<String> _warnings = [];
  String? _selectedRoomId;

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
              // Başlık
              _buildHeader(),
              const SizedBox(height: 24),

              // Plan henüz oluşturulmadıysa
              if (widget.generatedPlan == null) ...[
                _buildGenerateCard(),
              ] else ...[
                // Başarı mesajı
                _buildSuccessCard(),
                const SizedBox(height: 16),

                // Uyarılar
                if (_warnings.isNotEmpty) _buildWarningsCard(),

                // Salon seçici
                _buildRoomSelector(),
                const SizedBox(height: 16),

                // Oturma planı grid
                _buildSeatingGrid(),
                const SizedBox(height: 16),

                // PDF indirme
                _buildPdfExportCard(),
                const SizedBox(height: 16),

                // Yeniden oluştur
                OutlinedButton.icon(
                  onPressed: _generatePlan,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Yeniden Dağıt'),
                ),
              ],

              // Hata mesajı
              if (_error != null) ...[
                const SizedBox(height: 16),
                _buildErrorCard(),
              ],

              const SizedBox(height: 24),

              // Navigasyon
              Row(
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
                    child: ElevatedButton.icon(
                      onPressed: widget.onRestart,
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Yeni Sınav'),
                    ),
                  ),
                ],
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
              child: const Icon(Icons.shuffle, color: Colors.indigo, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Adım 4: Kelebek Dağıtım',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_totalStudents öğrenci → ${widget.rooms.length} salon',
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

  Widget _buildGenerateCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            // Özet
            _buildSummaryRow(Icons.people, 'Öğrenci', '$_totalStudents'),
            const SizedBox(height: 12),
            _buildSummaryRow(Icons.class_, 'Şube', '${widget.sections.length}'),
            const SizedBox(height: 12),
            _buildSummaryRow(
              Icons.meeting_room,
              'Salon',
              '${widget.rooms.length}',
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              Icons.event_seat,
              'Toplam Kapasite',
              '${widget.rooms.fold(0, (sum, r) => sum + r.capacity)}',
            ),
            const SizedBox(height: 24),

            // Oluştur butonu
            if (_isGenerating)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Dağıtım yapılıyor...'),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: _generatePlan,
                icon: const Icon(Icons.shuffle),
                label: const Text('Kelebek Dağıtımı Başlat'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: DutyPlannerColors.tableHeader,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.indigo, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(color: DutyPlannerColors.textSecondary),
        ),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSuccessCard() {
    return Card(
      color: DutyPlannerColors.success.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DutyPlannerColors.success,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dağıtım Tamamlandı!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: DutyPlannerColors.success,
                    ),
                  ),
                  Text(
                    '${widget.generatedPlan!.totalStudents} öğrenci yerleştirildi',
                    style: const TextStyle(
                      fontSize: 12,
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

  Widget _buildWarningsCard() {
    return Card(
      color: DutyPlannerColors.warning.withValues(alpha: 0.1),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber, color: DutyPlannerColors.warning),
                SizedBox(width: 8),
                Text('Uyarılar', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            ..._warnings.map(
              (w) => Padding(
                padding: const EdgeInsets.only(left: 32, bottom: 4),
                child: Text('• $w', style: const TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Salon Seçin',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.rooms.map((room) {
                final isSelected = room.id == _selectedRoomId;
                final assignments = widget.generatedPlan!.getAssignmentsForRoom(
                  room.id,
                );
                return ChoiceChip(
                  label: Text(
                    '${room.name} (${assignments.length}/${room.capacity})',
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedRoomId = room.id);
                    }
                  },
                  selectedColor: Colors.indigo.withValues(alpha: 0.3),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeatingGrid() {
    if (_selectedRoomId == null && widget.rooms.isNotEmpty) {
      _selectedRoomId = widget.rooms.first.id;
    }

    if (_selectedRoomId == null) return const SizedBox();

    final room = widget.rooms.firstWhere((r) => r.id == _selectedRoomId);
    final grid = widget.generatedPlan!.getRoomGrid(room);

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
                  'Oturma Planı: ${room.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: DutyPlannerColors.tableHeader,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('⬆️ TAHTA', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Grid
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                children: List.generate(room.rowCount, (row) {
                  return Row(
                    children: List.generate(room.columnCount, (col) {
                      final assignment = grid[row][col];
                      return _buildSeatCell(assignment, row, col);
                    }),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            // Renk açıklaması
            _buildColorLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildSeatCell(SeatAssignment? assignment, int row, int col) {
    final isEmpty = assignment == null;
    final color = isEmpty
        ? Colors.grey.shade200
        : _getGradeColor(assignment.student.gradeLevel);

    return Container(
      width: 100,
      height: 70,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isEmpty ? 0.3 : 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: isEmpty ? 1 : 2,
        ),
      ),
      child: isEmpty
          ? Center(
              child: Text(
                '${row + 1}-${col + 1}',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    assignment.student.displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      assignment.student.sectionId,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (assignment.student.studentNumber.isNotEmpty)
                    Text(
                      assignment.student.studentNumber,
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildColorLegend() {
    final grades = widget.sections.map((s) => s.gradeLevel).toSet().toList()
      ..sort();

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: grades.map((grade) {
        final color = _getGradeColor(grade);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 4),
            Text('$grade. Sınıf', style: const TextStyle(fontSize: 12)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildPdfExportCard() {
    return Card(
      color: Colors.indigo.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.picture_as_pdf, color: Colors.red, size: 32),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PDF Olarak İndir',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Tüm salonların oturma planını PDF olarak indirin',
                    style: TextStyle(
                      fontSize: 12,
                      color: DutyPlannerColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportPdf,
              icon: _isExporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: Text(_isExporting ? 'İndiriliyor...' : 'İndir'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
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
                _error!,
                style: const TextStyle(color: DutyPlannerColors.error),
              ),
            ),
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

  Future<void> _generatePlan() async {
    setState(() {
      _isGenerating = true;
      _error = null;
      _warnings = [];
    });

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final result = _service.distribute(
        sections: widget.sections,
        rooms: widget.rooms,
        examName: widget.examName,
      );

      if (result.success && result.plan != null) {
        widget.onPlanGenerated(result.plan!);
        setState(() {
          _warnings = result.warnings;
          if (widget.rooms.isNotEmpty) {
            _selectedRoomId = widget.rooms.first.id;
          }
        });
      } else {
        setState(() {
          _error = result.errorMessage ?? 'Bilinmeyen hata';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _exportPdf() async {
    if (widget.generatedPlan == null) return;

    setState(() {
      _isExporting = true;
    });

    try {
      final pdfBytes = await _pdfService.generateExamPdf(
        plan: widget.generatedPlan!,
      );

      // Web için indirme
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute(
          'download',
          'sinav_oturma_plani_${DateTime.now().millisecondsSinceEpoch}.pdf',
        )
        ..click();
      html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF başarıyla indirildi!'),
            backgroundColor: DutyPlannerColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF oluşturma hatası: $e'),
            backgroundColor: DutyPlannerColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }
}
