/// Duty Scheduler Service
/// Adil nöbet dağıtım algoritması

import '../models/duty_planner_models.dart';

/// Nöbet planlama servisi
/// Adil ve dengeli nöbet dağıtımı sağlar
class DutySchedulerService {
  // Singleton pattern
  static final DutySchedulerService _instance =
      DutySchedulerService._internal();
  factory DutySchedulerService() => _instance;
  DutySchedulerService._internal();

  /// Ana planlama fonksiyonu
  ///
  /// Kurallar:
  /// 1. Her öğretmen mümkün olduğunca eşit sayıda nöbet almalı
  /// 2. Aynı öğretmen üst üste aynı katta nöbetçi olmamalı
  /// 3. Öğretmenin müsait olmadığı günlerde nöbet atanmamalı
  DutyPlan generatePlan({
    required List<Teacher> teachers,
    required List<Floor> floors,
    required DutyPlanType planType,
    required DateTime startDate,
  }) {
    if (teachers.isEmpty) {
      throw ArgumentError('En az bir öğretmen gerekli');
    }
    if (floors.isEmpty) {
      throw ArgumentError('En az bir kat gerekli');
    }

    // Bitiş tarihini hesapla
    final endDate = _calculateEndDate(startDate, planType);

    // Tüm okul günlerini hesapla (Pazartesi-Cuma)
    final schoolDays = _getSchoolDays(startDate, endDate);

    // Sıralı katları al
    final sortedFloors = List<Floor>.from(floors)
      ..sort((a, b) => a.order.compareTo(b.order));

    // Nöbet atamalarını oluştur
    final assignments = <DutyAssignment>[];

    // Her öğretmenin son atandığı kat (aynı kat tekrarını engellemek için)
    final lastFloorPerTeacher = <String, String>{};

    // Her öğretmenin toplam nöbet sayısı
    final dutyCountPerTeacher = <String, int>{};
    for (final teacher in teachers) {
      dutyCountPerTeacher[teacher.id] = 0;
    }

    // Round-robin indeksi
    int teacherIndex = 0;

    // Her gün için
    for (final day in schoolDays) {
      final dayOfWeek = day.weekday;

      // Bu gün için müsait öğretmenler
      final availableTeachers = teachers
          .where((t) => t.isAvailableOn(dayOfWeek))
          .toList();

      if (availableTeachers.isEmpty) {
        continue; // Bu gün için atama yapılamaz
      }

      // Her kat için öğretmen ata
      for (final floor in sortedFloors) {
        // En az nöbet alan ve bu kata son atanmamış öğretmeni bul
        final teacher = _selectBestTeacher(
          availableTeachers: availableTeachers,
          dutyCountPerTeacher: dutyCountPerTeacher,
          lastFloorPerTeacher: lastFloorPerTeacher,
          floorId: floor.id,
          startIndex: teacherIndex,
        );

        if (teacher != null) {
          // DEBUG: Atama değerlerini kontrol et
          print(
            'DEBUG: Assigning teacher: id=${teacher.id}, name=${teacher.name}, floor=${floor.name}',
          );

          // Atama oluştur
          assignments.add(
            DutyAssignment(
              date: day,
              floorId: floor.id,
              floorName: floor.name,
              teacherId: teacher.id,
              teacherName: teacher.name,
            ),
          );

          // Sayaçları güncelle
          dutyCountPerTeacher[teacher.id] =
              (dutyCountPerTeacher[teacher.id] ?? 0) + 1;
          lastFloorPerTeacher[teacher.id] = floor.id;

          // Round-robin indeksini ilerlet
          teacherIndex = (teacherIndex + 1) % availableTeachers.length;
        }
      }
    }

    // DEBUG: Son kontrol
    print('DEBUG: Total assignments: ${assignments.length}');
    if (assignments.isNotEmpty) {
      final first = assignments.first;
      print(
        'DEBUG: First assignment - teacherName: "${first.teacherName}", teacherId: "${first.teacherId}"',
      );
    }

    // Plan oluştur
    return DutyPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: planType,
      startDate: startDate,
      endDate: endDate,
      assignments: assignments,
    );
  }

  /// En uygun öğretmeni seç
  Teacher? _selectBestTeacher({
    required List<Teacher> availableTeachers,
    required Map<String, int> dutyCountPerTeacher,
    required Map<String, String> lastFloorPerTeacher,
    required String floorId,
    required int startIndex,
  }) {
    if (availableTeachers.isEmpty) return null;

    // Öncelik sıralaması:
    // 1. Daha az nöbet alan
    // 2. Son olarak bu kata atanmamış

    // Öğretmenleri nöbet sayısına göre sırala
    final sortedTeachers = List<Teacher>.from(availableTeachers)
      ..sort((a, b) {
        final countA = dutyCountPerTeacher[a.id] ?? 0;
        final countB = dutyCountPerTeacher[b.id] ?? 0;
        return countA.compareTo(countB);
      });

    // En az nöbet alanlar arasından son bu kata atanmayanı bul
    final minCount = dutyCountPerTeacher[sortedTeachers.first.id] ?? 0;
    final candidatesWithMinCount = sortedTeachers
        .where((t) => (dutyCountPerTeacher[t.id] ?? 0) == minCount)
        .toList();

    // Bu kata son atanmamış olanı tercih et
    for (final teacher in candidatesWithMinCount) {
      if (lastFloorPerTeacher[teacher.id] != floorId) {
        return teacher;
      }
    }

    // Hepsi bu kata atanmışsa, en az nöbet alanı seç
    return candidatesWithMinCount.first;
  }

  /// Bitiş tarihini hesapla
  DateTime _calculateEndDate(DateTime startDate, DutyPlanType planType) {
    switch (planType) {
      case DutyPlanType.weekly:
        // Haftanın Cuma gününü bul
        var end = startDate;
        while (end.weekday != DateTime.friday) {
          end = end.add(const Duration(days: 1));
        }
        return end;

      case DutyPlanType.monthly:
        // Ayın son gününü bul
        return DateTime(startDate.year, startDate.month + 1, 0);

      case DutyPlanType.yearly:
        // Yılın son gününü bul
        return DateTime(startDate.year, 12, 31);
    }
  }

  /// Okul günlerini getir (Pazartesi-Cuma)
  List<DateTime> _getSchoolDays(DateTime start, DateTime end) {
    final days = <DateTime>[];
    var current = DateTime(start.year, start.month, start.day);
    final endNormalized = DateTime(end.year, end.month, end.day);

    while (!current.isAfter(endNormalized)) {
      if (current.weekday >= DateTime.monday &&
          current.weekday <= DateTime.friday) {
        days.add(current);
      }
      current = current.add(const Duration(days: 1));
    }

    return days;
  }

  /// Plan istatistiklerini hesapla
  Map<String, dynamic> calculateStatistics(DutyPlan plan) {
    final teacherCounts = plan.getTeacherDutyCounts();

    if (teacherCounts.isEmpty) {
      return {
        'totalAssignments': 0,
        'teacherCount': 0,
        'minDuties': 0,
        'maxDuties': 0,
        'averageDuties': 0.0,
        'isBalanced': true,
      };
    }

    final counts = teacherCounts.values.toList();
    final minDuties = counts.reduce((a, b) => a < b ? a : b);
    final maxDuties = counts.reduce((a, b) => a > b ? a : b);
    final avgDuties = counts.reduce((a, b) => a + b) / counts.length;

    return {
      'totalAssignments': plan.assignments.length,
      'teacherCount': teacherCounts.length,
      'minDuties': minDuties,
      'maxDuties': maxDuties,
      'averageDuties': avgDuties,
      'isBalanced': (maxDuties - minDuties) <= 1,
    };
  }
}
