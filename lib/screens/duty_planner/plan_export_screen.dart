/// Plan Export Screen
/// Adım 5: PDF ve CSV dışa aktarma ekranı

import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../models/duty_planner_models.dart';
import '../../services/pdf_export_service.dart';
import '../../services/csv_export_service.dart';
import '../../theme/duty_planner_theme.dart';

// Conditional import for web
import 'plan_export_web.dart'
    if (dart.library.io) 'plan_export_io.dart'
    as platform;

/// Plan dışa aktarma ekranı
class PlanExportScreen extends StatefulWidget {
  final DutyPlan plan;
  final List<Floor> floors;
  final List<Teacher> teachers;
  final VoidCallback onBack;
  final VoidCallback onRestart;

  const PlanExportScreen({
    super.key,
    required this.plan,
    required this.floors,
    required this.teachers,
    required this.onBack,
    required this.onRestart,
  });

  @override
  State<PlanExportScreen> createState() => _PlanExportScreenState();
}

class _PlanExportScreenState extends State<PlanExportScreen> {
  final PdfExportService _pdfService = PdfExportService();
  final CsvExportService _csvService = CsvExportService();
  bool _isLoadingPdf = false;
  bool _isLoadingCsv = false;

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

              // Tamamlandı kartı
              _buildCompletionCard(),
              const SizedBox(height: 24),

              // Export seçenekleri
              _buildExportOptions(),
              const SizedBox(height: 24),

              // Yeniden başla
              OutlinedButton.icon(
                onPressed: widget.onRestart,
                icon: const Icon(Icons.refresh),
                label: const Text('Yeni Plan Oluştur'),
              ),
              const SizedBox(height: 16),

              // Geri butonu
              TextButton(
                onPressed: widget.onBack,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back),
                    SizedBox(width: 8),
                    Text('Plana Geri Dön'),
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
                color: DutyPlannerColors.success.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.download,
                color: DutyPlannerColors.success,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Adım 5: Planı İndirin',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Nöbet planını PDF veya CSV olarak indirin',
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

  Widget _buildCompletionCard() {
    return Card(
      color: DutyPlannerColors.success.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: DutyPlannerColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Plan Hazır!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: DutyPlannerColors.success,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.plan.assignments.length} nöbet ataması oluşturuldu',
              style: const TextStyle(color: DutyPlannerColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOptions() {
    return Column(
      children: [
        // PDF Export
        _buildExportCard(
          icon: Icons.picture_as_pdf,
          title: 'PDF Olarak İndir',
          subtitle: 'Yazdırılabilir format, tablo görünümü',
          color: Colors.red,
          isLoading: _isLoadingPdf,
          onTap: _exportPdf,
        ),
        const SizedBox(height: 12),

        // CSV Export - Detaylı
        _buildExportCard(
          icon: Icons.table_chart,
          title: 'CSV Olarak İndir (Detaylı)',
          subtitle: 'Tarih, gün, kat, öğretmen listesi',
          color: Colors.green,
          isLoading: _isLoadingCsv,
          onTap: () => _exportCsv('detailed'),
        ),
        const SizedBox(height: 12),

        // CSV Export - Özet
        _buildExportCard(
          icon: Icons.summarize,
          title: 'CSV Olarak İndir (Özet)',
          subtitle: 'Öğretmen bazlı nöbet sayıları',
          color: Colors.blue,
          isLoading: false,
          onTap: () => _exportCsv('summary'),
        ),
        const SizedBox(height: 12),

        // CSV Export - Grid
        _buildExportCard(
          icon: Icons.grid_on,
          title: 'CSV Olarak İndir (Grid)',
          subtitle: 'Kat bazlı tablo formatı',
          color: Colors.orange,
          isLoading: false,
          onTap: () => _exportCsv('grid'),
        ),
      ],
    );
  }

  Widget _buildExportCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: DutyPlannerColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.download, color: color),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportPdf() async {
    setState(() => _isLoadingPdf = true);

    try {
      final pdfBytes = await _pdfService.generatePdf(
        plan: widget.plan,
        floors: widget.floors,
      );

      if (kIsWeb) {
        // Web için doğrudan indirme
        platform.downloadFile(pdfBytes, 'nobet_plani.pdf', 'application/pdf');
      } else {
        // Mobil/Desktop için print dialog
        await Printing.layoutPdf(
          onLayout: (_) async => pdfBytes,
          name: 'Nöbet Planı',
        );
      }

      _showSuccess('PDF oluşturuldu');
    } catch (e) {
      _showError('PDF oluşturulurken hata: $e');
    } finally {
      setState(() => _isLoadingPdf = false);
    }
  }

  Future<void> _exportCsv(String type) async {
    setState(() => _isLoadingCsv = true);

    try {
      String csvContent;
      String fileName;

      switch (type) {
        case 'detailed':
          csvContent = _csvService.generateCsv(
            plan: widget.plan,
            floors: widget.floors,
          );
          fileName = 'nobet_plani_detayli.csv';
          break;
        case 'summary':
          csvContent = _csvService.generateTeacherSummaryCsv(
            plan: widget.plan,
            teachers: widget.teachers,
          );
          fileName = 'nobet_plani_ozet.csv';
          break;
        case 'grid':
          csvContent = _csvService.generateFloorSummaryCsv(
            plan: widget.plan,
            floors: widget.floors,
          );
          fileName = 'nobet_plani_grid.csv';
          break;
        default:
          return;
      }

      final bytes = Uint8List.fromList(csvContent.codeUnits);

      if (kIsWeb) {
        platform.downloadFile(bytes, fileName, 'text/csv');
      } else {
        // Mobil/Desktop için share dialog
        await Printing.sharePdf(bytes: bytes, filename: fileName);
      }

      _showSuccess('CSV oluşturuldu');
    } catch (e) {
      _showError('CSV oluşturulurken hata: $e');
    } finally {
      setState(() => _isLoadingCsv = false);
    }
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
