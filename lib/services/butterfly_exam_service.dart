/// Butterfly Exam Distribution Service
/// Kelebek sınav dağıtım algoritması servisi

import '../models/butterfly_exam_models.dart';

/// Kelebek sınav dağıtım servisi
///
/// Öğrencileri sınav salonlarına aşağıdaki kurallara göre dağıtır:
/// 1. Yan yana (aynı sırada) aynı sınıf seviyesinden öğrenci oturamaz
/// 2. Aynı şubeden (örn: 9-A) en fazla 3 öğrenci aynı salona atanabilir
/// 3. Dengeli dağıtım için round-robin mantığı kullanılır
class ButterflyExamService {
  // Singleton pattern
  static final ButterflyExamService _instance =
      ButterflyExamService._internal();
  factory ButterflyExamService() => _instance;
  ButterflyExamService._internal();

  /// Öğrencileri salonlara dağıt
  DistributionResult distribute({
    required List<ExamSection> sections,
    required List<ExamRoom> rooms,
    required String examName,
    int maxSameSectionPerRoom = 3,
  }) {
    // Tüm öğrencileri topla
    final allStudents = <ExamStudent>[];
    for (final section in sections) {
      allStudents.addAll(section.students);
    }

    if (allStudents.isEmpty) {
      return DistributionResult.failure('Dağıtılacak öğrenci bulunamadı.');
    }

    // Toplam kapasiteyi kontrol et
    final totalCapacity = rooms.fold(0, (sum, room) => sum + room.capacity);
    if (allStudents.length > totalCapacity) {
      return DistributionResult.failure(
        'Yetersiz kapasite: ${allStudents.length} öğrenci için ${totalCapacity} koltuk var.',
      );
    }

    // Öğrencileri şubeye göre grupla ve karıştır
    final studentsBySection = <String, List<ExamStudent>>{};
    for (final student in allStudents) {
      studentsBySection.putIfAbsent(student.sectionId, () => []).add(student);
    }

    // Her grubu karıştır
    for (final students in studentsBySection.values) {
      students.shuffle();
    }

    // Şubeleri sınıf seviyesine göre sırala (farklı seviyeleri dönüşümlü almak için)
    final sectionIds = studentsBySection.keys.toList()
      ..sort((a, b) {
        final gradeA = studentsBySection[a]!.first.gradeLevel;
        final gradeB = studentsBySection[b]!.first.gradeLevel;
        return gradeA.compareTo(gradeB);
      });

    // Salonları hazırla
    final assignments = <SeatAssignment>[];
    final sectionCountPerRoom =
        <String, Map<String, int>>{}; // roomId -> sectionId -> count
    final warnings = <String>[];

    for (final room in rooms) {
      sectionCountPerRoom[room.id] = {};
    }

    // Kuyruk oluştur - round robin için
    final studentQueue = <ExamStudent>[];
    int maxStudentsInAnySection = studentsBySection.values
        .map((list) => list.length)
        .fold(0, (a, b) => a > b ? a : b);

    // Round-robin: Her turda her şubeden bir öğrenci al
    for (int i = 0; i < maxStudentsInAnySection; i++) {
      for (final sectionId in sectionIds) {
        final students = studentsBySection[sectionId]!;
        if (i < students.length) {
          studentQueue.add(students[i]);
        }
      }
    }

    // Salonları sırayla doldur
    int studentIndex = 0;
    for (final room in rooms) {
      final grid = List<List<ExamStudent?>>.generate(
        room.rowCount,
        (_) => List<ExamStudent?>.filled(room.columnCount, null),
      );

      for (
        int row = 0;
        row < room.rowCount && studentIndex < studentQueue.length;
        row++
      ) {
        for (
          int col = 0;
          col < room.columnCount && studentIndex < studentQueue.length;
          col++
        ) {
          // Bu koltuğa uygun öğrenci bul
          ExamStudent? selectedStudent;
          int searchIndex = studentIndex;
          int attempts = 0;
          final maxAttempts = studentQueue.length - studentIndex;

          while (selectedStudent == null && attempts < maxAttempts) {
            final candidate = studentQueue[searchIndex];

            // Kısıtları kontrol et
            final isValid = _checkConstraints(
              candidate: candidate,
              room: room,
              row: row,
              col: col,
              grid: grid,
              sectionCountPerRoom: sectionCountPerRoom,
              maxSameSectionPerRoom: maxSameSectionPerRoom,
            );

            if (isValid) {
              selectedStudent = candidate;
              // Kuyruktan çıkar
              studentQueue.removeAt(searchIndex);
            } else {
              searchIndex++;
              if (searchIndex >= studentQueue.length) {
                searchIndex = studentIndex;
              }
              attempts++;
            }
          }

          // Eğer kısıtları sağlayan bulunamadıysa, sıradakini al (soft constraint)
          if (selectedStudent == null && studentIndex < studentQueue.length) {
            selectedStudent = studentQueue.removeAt(studentIndex);
            warnings.add(
              '${selectedStudent.fullName} için ideal yerleşim bulunamadı, kısıtlar esnetildi.',
            );
          }

          if (selectedStudent != null) {
            grid[row][col] = selectedStudent;

            // Salonpaşına şube sayısını güncelle
            final sectionId = selectedStudent.sectionId;
            sectionCountPerRoom[room.id]![sectionId] =
                (sectionCountPerRoom[room.id]![sectionId] ?? 0) + 1;

            assignments.add(
              SeatAssignment(
                roomId: room.id,
                row: row,
                column: col,
                student: selectedStudent,
              ),
            );
          }
        }
      }
    }

    // Yerleştirilemeyen öğrencileri kontrol et
    if (studentQueue.isNotEmpty) {
      warnings.add(
        '${studentQueue.length} öğrenci yerleştirilemedi (kapasite yetersiz).',
      );
    }

    final plan = ExamPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      examName: examName,
      createdAt: DateTime.now(),
      rooms: rooms,
      assignments: assignments,
      sections: sections,
    );

    return DistributionResult.success(plan, warnings: warnings);
  }

  /// Kısıtları kontrol et
  bool _checkConstraints({
    required ExamStudent candidate,
    required ExamRoom room,
    required int row,
    required int col,
    required List<List<ExamStudent?>> grid,
    required Map<String, Map<String, int>> sectionCountPerRoom,
    required int maxSameSectionPerRoom,
  }) {
    // Kısıt 1: Yan yana aynı sınıf seviyesi yasak
    // Sol komşu
    if (col > 0) {
      final leftNeighbor = grid[row][col - 1];
      if (leftNeighbor != null &&
          leftNeighbor.gradeLevel == candidate.gradeLevel) {
        return false;
      }
    }

    // Kısıt 2: Salonda aynı şubeden max N öğrenci
    final currentCount =
        sectionCountPerRoom[room.id]![candidate.sectionId] ?? 0;
    if (currentCount >= maxSameSectionPerRoom) {
      return false;
    }

    return true;
  }

  /// İstatistik: Salon başına şube dağılımı
  Map<String, Map<String, int>> getSectionDistributionByRoom(ExamPlan plan) {
    final result = <String, Map<String, int>>{};

    for (final room in plan.rooms) {
      result[room.id] = {};
      final roomAssignments = plan.getAssignmentsForRoom(room.id);

      for (final assignment in roomAssignments) {
        final sectionId = assignment.student.sectionId;
        result[room.id]![sectionId] = (result[room.id]![sectionId] ?? 0) + 1;
      }
    }

    return result;
  }
}
