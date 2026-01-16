/// Duty Planner Models
/// Okul Kat Nöbetçi Öğretmen Planlayıcı için veri modelleri

import 'package:flutter/foundation.dart';

/// Öğretmen modeli
class Teacher {
  final String id;
  final String name;
  final String branch;
  final List<int> unavailableDays; // 1=Pazartesi, 5=Cuma

  Teacher({
    required this.id,
    required this.name,
    required this.branch,
    this.unavailableDays = const [],
  });

  /// Belirtilen günde müsait mi?
  bool isAvailableOn(int dayOfWeek) {
    return !unavailableDays.contains(dayOfWeek);
  }

  /// CSV veya Excel satırından öğretmen oluştur
  factory Teacher.fromRow({
    required String name,
    required String branch,
    String? unavailableDaysStr,
  }) {
    List<int> days = [];
    if (unavailableDaysStr != null && unavailableDaysStr.isNotEmpty) {
      days = unavailableDaysStr
          .split(';')
          .where((s) => s.trim().isNotEmpty)
          .map((s) => int.tryParse(s.trim()) ?? 0)
          .where((d) => d >= 1 && d <= 7)
          .toList();
    }

    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final trimmedName = name.trim();
    final trimmedBranch = branch.trim();

    // DEBUG: Öğretmen oluşturma değerlerini kontrol et
    print(
      'TEACHER DEBUG: Creating teacher - id=$id, name="$trimmedName", branch="$trimmedBranch"',
    );

    return Teacher(
      id: id,
      name: trimmedName,
      branch: trimmedBranch,
      unavailableDays: days,
    );
  }

  @override
  String toString() => 'Teacher($name, $branch)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Teacher && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Kat modeli
class Floor {
  final String id;
  final String name;
  final int order;

  Floor({required this.id, required this.name, required this.order});

  /// Yeni kat oluştur
  factory Floor.create(String name, int order) {
    return Floor(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      order: order,
    );
  }

  /// Sıralama için kopya oluştur
  Floor copyWith({String? name, int? order}) {
    return Floor(id: id, name: name ?? this.name, order: order ?? this.order);
  }

  @override
  String toString() => 'Floor($name, order: $order)';
}

/// Nöbet ataması
class DutyAssignment {
  final DateTime date;
  final String floorId;
  final String floorName;
  final String teacherId;
  final String teacherName;

  DutyAssignment({
    required this.date,
    required this.floorId,
    required this.floorName,
    required this.teacherId,
    required this.teacherName,
  });

  /// Haftanın hangi günü (1=Pazartesi, 7=Pazar)
  int get dayOfWeek => date.weekday;

  /// Gün adını döndür
  String get dayName {
    const days = [
      '',
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];
    return days[dayOfWeek];
  }

  @override
  String toString() => 'DutyAssignment($teacherName @ $floorName on $dayName)';
}

/// Nöbet planı türleri
enum DutyPlanType {
  weekly('Haftalık', 7),
  monthly('Aylık', 30),
  yearly('Yıllık', 365);

  final String displayName;
  final int defaultDays;

  const DutyPlanType(this.displayName, this.defaultDays);
}

/// Nöbet planı
class DutyPlan {
  final String id;
  final DutyPlanType type;
  final DateTime startDate;
  final DateTime endDate;
  final List<DutyAssignment> assignments;
  final DateTime createdAt;

  DutyPlan({
    required this.id,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.assignments,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Belirli bir gün için atamaları getir
  List<DutyAssignment> getAssignmentsForDate(DateTime date) {
    return assignments
        .where(
          (a) =>
              a.date.year == date.year &&
              a.date.month == date.month &&
              a.date.day == date.day,
        )
        .toList();
  }

  /// Belirli bir kat için atamaları getir
  List<DutyAssignment> getAssignmentsForFloor(String floorId) {
    return assignments.where((a) => a.floorId == floorId).toList();
  }

  /// Belirli bir öğretmen için atamaları getir
  List<DutyAssignment> getAssignmentsForTeacher(String teacherId) {
    return assignments.where((a) => a.teacherId == teacherId).toList();
  }

  /// Öğretmen başına nöbet sayılarını hesapla
  Map<String, int> getTeacherDutyCounts() {
    final counts = <String, int>{};
    for (final assignment in assignments) {
      counts[assignment.teacherId] = (counts[assignment.teacherId] ?? 0) + 1;
    }
    return counts;
  }

  /// Plan içindeki tüm günleri getir (sadece okul günleri: Pazartesi-Cuma)
  List<DateTime> getSchoolDays() {
    final days = <DateTime>[];
    var current = startDate;
    while (!current.isAfter(endDate)) {
      if (current.weekday >= 1 && current.weekday <= 5) {
        days.add(current);
      }
      current = current.add(const Duration(days: 1));
    }
    return days;
  }

  @override
  String toString() =>
      'DutyPlan(${type.displayName}, ${assignments.length} assignments)';
}

/// Dosya önizleme için satır verisi
class PreviewRow {
  final List<String> cells;
  final bool isHeader;

  PreviewRow({required this.cells, this.isHeader = false});
}

/// Dosya önizleme sonucu
class FilePreviewResult {
  final List<PreviewRow> rows;
  final int totalRows;
  final String? error;

  FilePreviewResult({required this.rows, required this.totalRows, this.error});

  bool get hasError => error != null;
  bool get isEmpty => rows.isEmpty;
}
