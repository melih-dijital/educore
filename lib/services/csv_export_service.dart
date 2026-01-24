/// CSV Export Service
/// Nöbet planını CSV olarak dışa aktarma servisi

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import '../models/duty_planner_models.dart';

/// CSV dışa aktarma servisi
class CsvExportService {
  // Singleton pattern
  static final CsvExportService _instance = CsvExportService._internal();
  factory CsvExportService() => _instance;
  CsvExportService._internal();

  // UTF-8 BOM - Excel'in Türkçe karakterleri doğru okuması için
  static const String _utf8Bom = '\uFEFF';

  /// Nöbet planını CSV string olarak oluştur
  String generateCsv({required DutyPlan plan, required List<Floor> floors}) {
    final dateFormat = DateFormat('dd.MM.yyyy');

    // Satırları oluştur
    final rows = <List<String>>[];

    // Header satırı
    rows.add(['Tarih', 'Gün', 'Kat', 'Öğretmen']);

    // Atamaları tarihe göre sırala
    final sortedAssignments = List<DutyAssignment>.from(plan.assignments)
      ..sort((a, b) {
        final dateCompare = a.date.compareTo(b.date);
        if (dateCompare != 0) return dateCompare;
        // Aynı gün ise kata göre sırala
        final floorA = floors.firstWhere(
          (f) => f.id == a.floorId,
          orElse: () => Floor(id: '', name: '', order: 0),
        );
        final floorB = floors.firstWhere(
          (f) => f.id == b.floorId,
          orElse: () => Floor(id: '', name: '', order: 0),
        );
        return floorA.order.compareTo(floorB.order);
      });

    // Veri satırları
    for (final assignment in sortedAssignments) {
      rows.add([
        dateFormat.format(assignment.date),
        assignment.dayName,
        assignment.floorName,
        assignment.teacherName,
      ]);
    }

    // CSV formatına dönüştür (UTF-8 BOM ile)
    return _utf8Bom + const ListToCsvConverter().convert(rows);
  }

  /// Öğretmen bazlı özet CSV oluştur
  String generateTeacherSummaryCsv({
    required DutyPlan plan,
    required List<Teacher> teachers,
  }) {
    final rows = <List<String>>[];

    // Header satırı
    rows.add(['Öğretmen', 'Branş', 'Toplam Nöbet']);

    // Nöbet sayılarını hesapla
    final dutyCounts = plan.getTeacherDutyCounts();

    // Öğretmenleri nöbet sayısına göre sırala
    final sortedTeachers = List<Teacher>.from(teachers)
      ..sort((a, b) {
        final countA = dutyCounts[a.id] ?? 0;
        final countB = dutyCounts[b.id] ?? 0;
        return countB.compareTo(countA); // Azalan sıra
      });

    // Veri satırları
    for (final teacher in sortedTeachers) {
      final count = dutyCounts[teacher.id] ?? 0;
      rows.add([teacher.name, teacher.branch, count.toString()]);
    }

    // CSV formatına dönüştür (UTF-8 BOM ile)
    return _utf8Bom + const ListToCsvConverter().convert(rows);
  }

  /// Kat bazlı özet CSV oluştur
  String generateFloorSummaryCsv({
    required DutyPlan plan,
    required List<Floor> floors,
  }) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final rows = <List<String>>[];

    // Katları sırala
    final sortedFloors = List<Floor>.from(floors)
      ..sort((a, b) => a.order.compareTo(b.order));

    // Günleri al
    final schoolDays = plan.getSchoolDays();

    // Header satırı: Kat + tüm günler
    final header = <String>['Kat'];
    for (final day in schoolDays) {
      header.add(dateFormat.format(day));
    }
    rows.add(header);

    // Her kat için satır
    for (final floor in sortedFloors) {
      final row = <String>[floor.name];

      for (final day in schoolDays) {
        final assignments = plan.assignments.where(
          (a) =>
              a.floorId == floor.id &&
              a.date.year == day.year &&
              a.date.month == day.month &&
              a.date.day == day.day,
        );

        final teacherNames = assignments.map((a) => a.teacherName).join(', ');
        row.add(teacherNames.isEmpty ? '-' : teacherNames);
      }

      rows.add(row);
    }

    // CSV formatına dönüştür (UTF-8 BOM ile)
    return _utf8Bom + const ListToCsvConverter().convert(rows);
  }
}
