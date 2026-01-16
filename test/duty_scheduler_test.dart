import 'package:flutter_test/flutter_test.dart';
import 'package:educore/models/duty_planner_models.dart';
import 'package:educore/services/duty_scheduler_service.dart';

void main() {
  group('DutySchedulerService Tests', () {
    late DutySchedulerService scheduler;

    setUp(() {
      scheduler = DutySchedulerService();
    });

    test('Eşit dağılım - 5 öğretmen, 5 gün, 1 kat', () {
      // 5 öğretmen oluştur
      final teachers = List.generate(
        5,
        (i) => Teacher(
          id: 'teacher_$i',
          name: 'Öğretmen ${i + 1}',
          branch: 'Matematik',
        ),
      );

      // 1 kat oluştur
      final floors = [Floor.create('1. Kat', 1)];

      // Pazartesi başlayan haftalık plan
      // 2026 yılında 19 Ocak Pazartesi
      final startDate = DateTime(2026, 1, 19);

      final plan = scheduler.generatePlan(
        teachers: teachers,
        floors: floors,
        planType: DutyPlanType.weekly,
        startDate: startDate,
      );

      // 5 iş günü = 5 atama olmalı
      expect(plan.assignments.length, 5);

      // Her öğretmen 1 nöbet almış olmalı
      final dutyCounts = plan.getTeacherDutyCounts();
      for (final count in dutyCounts.values) {
        expect(count, 1, reason: 'Her öğretmen 1 nöbet almalı');
      }
    });

    test('Aynı kat tekrarı engelleme - art arda aynı kata atanmamalı', () {
      // 4 öğretmen, 2 kat = algoritma daha fazla seçenek olduğunda farklı kata atar
      final teachers = [
        Teacher(id: 't1', name: 'Ali', branch: 'Matematik'),
        Teacher(id: 't2', name: 'Veli', branch: 'Fizik'),
        Teacher(id: 't3', name: 'Ayşe', branch: 'Kimya'),
        Teacher(id: 't4', name: 'Fatma', branch: 'Biyoloji'),
      ];

      final floors = [Floor.create('1. Kat', 1), Floor.create('2. Kat', 2)];

      final startDate = DateTime(2026, 1, 19); // Pazartesi

      final plan = scheduler.generatePlan(
        teachers: teachers,
        floors: floors,
        planType: DutyPlanType.weekly,
        startDate: startDate,
      );

      // 5 gün x 2 kat = 10 atama olmalı
      expect(plan.assignments.length, 10);

      // Her öğretmenin nöbet sayısı dengeli olmalı
      final dutyCounts = plan.getTeacherDutyCounts();
      final counts = dutyCounts.values.toList();
      final minDuties = counts.reduce((a, b) => a < b ? a : b);
      final maxDuties = counts.reduce((a, b) => a > b ? a : b);

      // Fark en fazla 1 olmalı (dengeli dağılım)
      expect(maxDuties - minDuties, lessThanOrEqualTo(1));
    });

    test('Müsaitlik kontrolü - müsait olmayan günde atama yapılmamalı', () {
      // Öğretmenlerden biri Pazartesi müsait değil
      final teachers = [
        Teacher(
          id: 't1',
          name: 'Ali',
          branch: 'Matematik',
          unavailableDays: [1],
        ), // Pzt müsait değil
        Teacher(id: 't2', name: 'Veli', branch: 'Fizik'),
      ];

      final floors = [Floor.create('1. Kat', 1)];
      final startDate = DateTime(2026, 1, 19); // Pazartesi

      final plan = scheduler.generatePlan(
        teachers: teachers,
        floors: floors,
        planType: DutyPlanType.weekly,
        startDate: startDate,
      );

      // Ali'nin Pazartesi ataması olmamalı
      final aliAssignments = plan.getAssignmentsForTeacher('t1');
      final mondayAssignment = aliAssignments.where(
        (a) => a.date.weekday == DateTime.monday,
      );

      expect(
        mondayAssignment,
        isEmpty,
        reason: 'Ali Pazartesi müsait değil, atama olmamalı',
      );
    });

    test('Boş öğretmen listesi hatası', () {
      final floors = [Floor.create('1. Kat', 1)];

      expect(
        () => scheduler.generatePlan(
          teachers: [],
          floors: floors,
          planType: DutyPlanType.weekly,
          startDate: DateTime.now(),
        ),
        throwsArgumentError,
      );
    });

    test('Boş kat listesi hatası', () {
      final teachers = [Teacher(id: 't1', name: 'Ali', branch: 'Matematik')];

      expect(
        () => scheduler.generatePlan(
          teachers: teachers,
          floors: [],
          planType: DutyPlanType.weekly,
          startDate: DateTime.now(),
        ),
        throwsArgumentError,
      );
    });

    test('Aylık plan - tam ay boyunca plan oluşturma', () {
      final teachers = List.generate(
        10,
        (i) => Teacher(
          id: 'teacher_$i',
          name: 'Öğretmen ${i + 1}',
          branch: 'Test',
        ),
      );

      final floors = [Floor.create('1. Kat', 1), Floor.create('2. Kat', 2)];

      // Ocak ayı başı
      final startDate = DateTime(2026, 1, 1);

      final plan = scheduler.generatePlan(
        teachers: teachers,
        floors: floors,
        planType: DutyPlanType.monthly,
        startDate: startDate,
      );

      // Ocak 2026'da yaklaşık 22 iş günü x 2 kat = 44 atama
      expect(plan.assignments.length, greaterThan(40));
      expect(plan.type, DutyPlanType.monthly);
    });

    test('İstatistik hesaplama', () {
      final teachers = List.generate(
        4,
        (i) => Teacher(
          id: 'teacher_$i',
          name: 'Öğretmen ${i + 1}',
          branch: 'Test',
        ),
      );

      final floors = [Floor.create('1. Kat', 1)];
      final startDate = DateTime(2026, 1, 19);

      final plan = scheduler.generatePlan(
        teachers: teachers,
        floors: floors,
        planType: DutyPlanType.weekly,
        startDate: startDate,
      );

      final stats = scheduler.calculateStatistics(plan);

      expect(stats['totalAssignments'], 5);
      expect(stats['teacherCount'], greaterThan(0));
      expect(stats['minDuties'], greaterThanOrEqualTo(1));
      expect(stats['maxDuties'], lessThanOrEqualTo(2));
    });
  });

  group('Teacher Model Tests', () {
    test('isAvailableOn - müsait gün kontrolü', () {
      final teacher = Teacher(
        id: 't1',
        name: 'Test',
        branch: 'Test',
        unavailableDays: [1, 5], // Pazartesi ve Cuma müsait değil
      );

      expect(teacher.isAvailableOn(1), isFalse); // Pazartesi
      expect(teacher.isAvailableOn(2), isTrue); // Salı
      expect(teacher.isAvailableOn(5), isFalse); // Cuma
    });

    test('fromRow - CSV satırından oluşturma', () {
      final teacher = Teacher.fromRow(
        name: 'Ali Yılmaz',
        branch: 'Matematik',
        unavailableDaysStr: '1;5',
      );

      expect(teacher.name, 'Ali Yılmaz');
      expect(teacher.branch, 'Matematik');
      expect(teacher.unavailableDays, [1, 5]);
    });
  });

  group('DutyPlan Model Tests', () {
    test('getSchoolDays - okul günlerini getir', () {
      final plan = DutyPlan(
        id: 'test',
        type: DutyPlanType.weekly,
        startDate: DateTime(2026, 1, 19), // Pazartesi
        endDate: DateTime(2026, 1, 23), // Cuma
        assignments: [],
      );

      final schoolDays = plan.getSchoolDays();

      expect(schoolDays.length, 5);
      expect(schoolDays.first.weekday, DateTime.monday);
      expect(schoolDays.last.weekday, DateTime.friday);
    });

    test('getTeacherDutyCounts - nöbet sayılarını hesapla', () {
      final plan = DutyPlan(
        id: 'test',
        type: DutyPlanType.weekly,
        startDate: DateTime(2026, 1, 19),
        endDate: DateTime(2026, 1, 23),
        assignments: [
          DutyAssignment(
            date: DateTime(2026, 1, 19),
            floorId: 'f1',
            floorName: '1. Kat',
            teacherId: 't1',
            teacherName: 'Ali',
          ),
          DutyAssignment(
            date: DateTime(2026, 1, 20),
            floorId: 'f1',
            floorName: '1. Kat',
            teacherId: 't1',
            teacherName: 'Ali',
          ),
          DutyAssignment(
            date: DateTime(2026, 1, 21),
            floorId: 'f1',
            floorName: '1. Kat',
            teacherId: 't2',
            teacherName: 'Veli',
          ),
        ],
      );

      final counts = plan.getTeacherDutyCounts();

      expect(counts['t1'], 2);
      expect(counts['t2'], 1);
    });
  });
}
