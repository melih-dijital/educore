/// Exam PDF Export Service
/// Sınav oturma planı PDF servisi

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/butterfly_exam_models.dart';

/// Sınav PDF oluşturma servisi
class ExamPdfService {
  // Singleton pattern
  static final ExamPdfService _instance = ExamPdfService._internal();
  factory ExamPdfService() => _instance;
  ExamPdfService._internal();

  // Türkçe karakter desteği için font
  pw.Font? _regularFont;
  pw.Font? _boldFont;

  /// Türkçe font yükle
  Future<void> _loadFonts() async {
    if (_regularFont != null && _boldFont != null) return;

    try {
      // Roboto fontları - Türkçe karakter destekler
      final regularData = await rootBundle.load(
        'assets/fonts/Roboto-Regular.ttf',
      );
      final boldData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
      _regularFont = pw.Font.ttf(regularData);
      _boldFont = pw.Font.ttf(boldData);
    } catch (e) {
      // Font yüklenemezse varsayılan fontları kullan
      print('Font yüklenemedi: $e');
      _regularFont = pw.Font.helvetica();
      _boldFont = pw.Font.helveticaBold();
    }
  }

  /// Sınav oturma planını PDF olarak oluştur
  Future<Uint8List> generateExamPdf({required ExamPlan plan}) async {
    // Türkçe font yükle
    await _loadFonts();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: _regularFont ?? pw.Font.helvetica(),
        bold: _boldFont ?? pw.Font.helveticaBold(),
      ),
    );
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm', 'tr');

    // Her salon için bir sayfa
    for (final room in plan.rooms) {
      final grid = plan.getRoomGrid(room);
      final assignments = plan.getAssignmentsForRoom(room.id);

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
                    plan.examName,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Text(
                    '${room.name} - Oturma Planı',
                    style: const pw.TextStyle(fontSize: 16),
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Text(
                    '${assignments.length} / ${room.capacity} Öğrenci',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ),
                pw.SizedBox(height: 10),

                // Tahta göstergesi
                pw.Center(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 5,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey300,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'TAHTA',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),

                // Oturma grid'i
                pw.Expanded(
                  child: pw.Center(child: _buildSeatingGrid(grid, room)),
                ),

                // Alt bilgi
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Oluşturma: ${dateFormat.format(plan.createdAt)}',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    _buildColorLegend(plan.sections),
                    pw.Text(
                      '${room.name}',
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

    // Şube bazlı öğrenci-salon listeleri
    for (final section in plan.sections) {
      // Bu şubedeki öğrencilerin atamalarını bul
      final sectionAssignments = plan.assignments
          .where((a) => a.student.sectionId == section.id)
          .toList();

      // Öğrenci adına göre sırala
      sectionAssignments.sort(
        (a, b) => a.student.fullName.compareTo(b.student.fullName),
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Başlık
                pw.Center(
                  child: pw.Text(
                    plan.examName,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Text(
                    '${section.displayName} Sınıfı - Salon Listesi',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Text(
                    '${sectionAssignments.length} Öğrenci',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
                pw.SizedBox(height: 15),

                // Öğrenci-Salon Tablosu
                pw.Expanded(
                  child: _buildStudentRoomTable(sectionAssignments, plan.rooms),
                ),

                // Alt bilgi
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Oluşturma: ${dateFormat.format(plan.createdAt)}',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.Text(
                      section.displayName,
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

    // Özet sayfası
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  '${plan.examName} - Özet',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Genel bilgiler
              _buildSummarySection('Genel Bilgiler', [
                'Toplam Öğrenci: ${plan.totalStudents}',
                'Toplam Salon: ${plan.rooms.length}',
                'Toplam Kapasite: ${plan.totalCapacity}',
              ]),
              pw.SizedBox(height: 20),

              // Şube dağılımı
              _buildSummarySection(
                'Şube Dağılımı',
                plan.sections
                    .map((s) => '${s.displayName}: ${s.studentCount} öğrenci')
                    .toList(),
              ),
              pw.SizedBox(height: 20),

              // Salon dağılımı
              _buildSummarySection(
                'Salon Dağılımı',
                plan.rooms.map((r) {
                  final count = plan.getAssignmentsForRoom(r.id).length;
                  return '${r.name}: $count / ${r.capacity} (${r.rowCount}×${r.columnCount})';
                }).toList(),
              ),

              pw.Spacer(),

              pw.Center(
                child: pw.Text(
                  'OkulAsistan Pro - Kelebek Sınav Dağıtım Sistemi',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Oturma grid'i oluştur
  pw.Widget _buildSeatingGrid(List<List<SeatAssignment?>> grid, ExamRoom room) {
    // Table yerine Column/Row kullanarak kutucuklar arasında boşluk bırak
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: List.generate(room.rowCount, (row) {
        return pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          children: List.generate(room.columnCount, (col) {
            final assignment = grid[row][col];
            return pw.Padding(
              padding: const pw.EdgeInsets.all(3), // Kutucuklar arası boşluk
              child: _buildSeatCell(assignment, row, col),
            );
          }),
        );
      }),
    );
  }

  /// Koltuk hücresi
  pw.Widget _buildSeatCell(SeatAssignment? assignment, int row, int col) {
    // Sabit boyutlar - kutucuk genişleyemez
    const double cellWidth = 70;
    const double cellHeight = 50;

    if (assignment == null) {
      return pw.Container(
        width: cellWidth,
        height: cellHeight,
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(4),
          border: pw.Border.all(color: PdfColors.grey300, width: 1),
        ),
        child: pw.Center(
          child: pw.Text(
            '${row + 1}-${col + 1}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey400),
          ),
        ),
      );
    }

    final gradeColor = _getGradeColor(assignment.student.gradeLevel);
    // Açık arka plan rengi - renk tonunu hafif yap
    final lightBgColor = _getLightColor(gradeColor);

    return pw.Container(
      width: cellWidth,
      height: cellHeight,
      decoration: pw.BoxDecoration(
        color: lightBgColor,
        border: pw.Border.all(color: gradeColor, width: 2),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.ClipRRect(
        horizontalRadius: 4,
        verticalRadius: 4,
        child: pw.Padding(
          padding: const pw.EdgeInsets.all(2),
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                assignment.student.displayName,
                style: pw.TextStyle(
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
                textAlign: pw.TextAlign.center,
                maxLines: 1,
                overflow: pw.TextOverflow.clip,
              ),
              pw.SizedBox(height: 2),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 1,
                ),
                decoration: pw.BoxDecoration(
                  color: gradeColor,
                  borderRadius: pw.BorderRadius.circular(2),
                ),
                child: pw.Text(
                  assignment.student.sectionId,
                  style: const pw.TextStyle(
                    fontSize: 6,
                    color: PdfColors.white,
                  ),
                ),
              ),
              if (assignment.student.studentNumber.isNotEmpty)
                pw.Text(
                  assignment.student.studentNumber,
                  style: const pw.TextStyle(
                    fontSize: 5,
                    color: PdfColors.grey600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Açık arka plan rengi oluştur
  PdfColor _getLightColor(PdfColor color) {
    // Rengi beyaza karıştırarak açık ton oluştur
    return PdfColor(
      0.85 + color.red * 0.15,
      0.85 + color.green * 0.15,
      0.85 + color.blue * 0.15,
    );
  }

  /// Renk açıklaması
  pw.Widget _buildColorLegend(List<ExamSection> sections) {
    final grades = sections.map((s) => s.gradeLevel).toSet().toList()..sort();

    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: grades.map((grade) {
        return pw.Container(
          margin: const pw.EdgeInsets.only(right: 8),
          child: pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Container(
                width: 10,
                height: 10,
                decoration: pw.BoxDecoration(
                  color: _getGradeColor(grade),
                  borderRadius: pw.BorderRadius.circular(2),
                ),
              ),
              pw.SizedBox(width: 2),
              pw.Text('$grade', style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Özet bölümü
  pw.Widget _buildSummarySection(String title, List<String> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        ...items.map(
          (item) => pw.Padding(
            padding: const pw.EdgeInsets.only(left: 16, bottom: 4),
            child: pw.Text('• $item', style: const pw.TextStyle(fontSize: 11)),
          ),
        ),
      ],
    );
  }

  /// Sınıf seviyesine göre renk
  PdfColor _getGradeColor(int grade) {
    switch (grade) {
      case 9:
        return PdfColors.blue;
      case 10:
        return PdfColors.green;
      case 11:
        return PdfColors.orange;
      case 12:
        return PdfColors.purple;
      default:
        return PdfColors.grey;
    }
  }

  /// Öğrenci-Salon tablosu oluştur
  pw.Widget _buildStudentRoomTable(
    List<SeatAssignment> assignments,
    List<ExamRoom> rooms,
  ) {
    // Room ID'den Room name'e lookup map
    final roomMap = {for (var r in rooms) r.id: r.name};

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(3), // Öğrenci Adı
        1: const pw.FlexColumnWidth(2), // Okul No
        2: const pw.FlexColumnWidth(2), // Salon
      },
      children: [
        // Başlık satırı
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Öğrenci Adı',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Okul No',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Salon',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
        // Öğrenci satırları
        ...assignments.map((assignment) {
          final roomName = roomMap[assignment.roomId] ?? 'Bilinmiyor';
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  assignment.student.fullName,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  assignment.student.studentNumber.isNotEmpty
                      ? assignment.student.studentNumber
                      : '-',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  roomName,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}
