/// PDF Export Service
/// Nöbet planını PDF olarak dışa aktarma servisi

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/duty_planner_models.dart';

/// PDF oluşturma servisi
class PdfExportService {
  // Singleton pattern
  static final PdfExportService _instance = PdfExportService._internal();
  factory PdfExportService() => _instance;
  PdfExportService._internal();

  /// Nöbet planını PDF olarak oluştur
  Future<Uint8List> generatePdf({
    required DutyPlan plan,
    required List<Floor> floors,
    String? schoolName,
  }) async {
    final pdf = pw.Document();

    // Türkçe tarih formatı
    final dateFormat = DateFormat('dd.MM.yyyy', 'tr');

    // Başlık bilgisi
    final title = 'Nöbet Planı - ${plan.type.displayName}';
    final dateRange =
        '${dateFormat.format(plan.startDate)} - ${dateFormat.format(plan.endDate)}';

    // Katları sırala
    final sortedFloors = List<Floor>.from(floors)
      ..sort((a, b) => a.order.compareTo(b.order));

    // Günleri al
    final schoolDays = plan.getSchoolDays();

    // Haftalık görünüm için günlere göre grupla
    final weeklyGroups = _groupByWeek(schoolDays);

    for (int weekIndex = 0; weekIndex < weeklyGroups.length; weekIndex++) {
      final weekDays = weeklyGroups[weekIndex];

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Başlık
                pw.Center(
                  child: pw.Text(
                    title,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Text(
                    dateRange,
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ),
                if (schoolName != null) ...[
                  pw.SizedBox(height: 5),
                  pw.Center(
                    child: pw.Text(
                      schoolName,
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ),
                ],
                pw.SizedBox(height: 10),

                // Hafta numarası
                if (weeklyGroups.length > 1)
                  pw.Text(
                    '${weekIndex + 1}. Hafta',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                pw.SizedBox(height: 10),

                // Tablo
                _buildWeekTable(weekDays, sortedFloors, plan, dateFormat),

                pw.Spacer(),

                // Alt bilgi
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Oluşturma Tarihi: ${dateFormat.format(plan.createdAt)}',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.Text(
                      'Sayfa ${weekIndex + 1} / ${weeklyGroups.length}',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  /// Haftalık tablo oluştur
  pw.Widget _buildWeekTable(
    List<DateTime> days,
    List<Floor> floors,
    DutyPlan plan,
    DateFormat dateFormat,
  ) {
    // Gün başlıkları
    final dayHeaders = <String>['Kat'];
    for (final day in days) {
      dayHeaders.add(_getDayName(day.weekday));
      dayHeaders.add(DateFormat('dd.MM').format(day));
    }

    // Tablo satırları
    final tableRows = <pw.TableRow>[];

    // Header satırı
    tableRows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE3F2FD)),
        children: [
          _headerCell('Kat'),
          for (final day in days) ...[
            _headerCell(
              '${_getDayName(day.weekday)}\n${DateFormat('dd.MM').format(day)}',
            ),
          ],
        ],
      ),
    );

    // Her kat için satır
    for (final floor in floors) {
      final cells = <pw.Widget>[_dataCell(floor.name, isFloor: true)];

      for (final day in days) {
        final assignments = plan.assignments.where(
          (a) =>
              a.floorId == floor.id &&
              a.date.year == day.year &&
              a.date.month == day.month &&
              a.date.day == day.day,
        );

        final teacherNames = assignments.map((a) => a.teacherName).join('\n');
        cells.add(_dataCell(teacherNames.isEmpty ? '-' : teacherNames));
      }

      tableRows.add(pw.TableRow(children: cells));
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      children: tableRows,
    );
  }

  /// Header hücresi
  pw.Widget _headerCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// Veri hücresi
  pw.Widget _dataCell(String text, {bool isFloor = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      alignment: pw.Alignment.center,
      decoration: isFloor
          ? const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF5F5F5))
          : null,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isFloor ? pw.FontWeight.bold : null,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// Günleri haftalara göre grupla
  List<List<DateTime>> _groupByWeek(List<DateTime> days) {
    if (days.isEmpty) return [];

    final weeks = <List<DateTime>>[];
    var currentWeek = <DateTime>[];

    for (final day in days) {
      if (currentWeek.isEmpty || day.weekday >= currentWeek.last.weekday) {
        currentWeek.add(day);
      } else {
        weeks.add(currentWeek);
        currentWeek = [day];
      }
    }

    if (currentWeek.isNotEmpty) {
      weeks.add(currentWeek);
    }

    return weeks;
  }

  /// Gün adını getir
  String _getDayName(int weekday) {
    const days = ['', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return days[weekday];
  }
}
