/// Butterfly Exam Models
/// Kelebek sınav dağıtım sistemi için veri modelleri

/// Öğrenci modeli - sınava girecek öğrenci bilgileri
class ExamStudent {
  final String id;
  final String firstName;
  final String lastName;
  final String studentNumber;
  final String sectionId; // Şube referansı (örn: "9-A")
  final int gradeLevel; // Sınıf seviyesi (9, 10, 11, 12)

  ExamStudent({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.studentNumber,
    required this.sectionId,
    required this.gradeLevel,
  });

  String get fullName => '$firstName $lastName';

  /// Kısa görüntüleme adı
  String get displayName =>
      '$firstName ${lastName.isNotEmpty ? lastName[0] : ''}.';

  /// CSV/Excel satırından oluştur
  factory ExamStudent.fromRow(
    List<String> row,
    String sectionId,
    int gradeLevel,
  ) {
    return ExamStudent(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      firstName: row.isNotEmpty ? row[0].trim() : '',
      lastName: row.length > 1 ? row[1].trim() : '',
      studentNumber: row.length > 2 ? row[2].trim() : '',
      sectionId: sectionId,
      gradeLevel: gradeLevel,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'studentNumber': studentNumber,
    'sectionId': sectionId,
    'gradeLevel': gradeLevel,
  };
}

/// Şube modeli - örn: 9-A, 10-B
class ExamSection {
  final String id; // Örn: "9-A"
  final int gradeLevel; // Sınıf seviyesi: 9, 10, 11, 12
  final String sectionName; // Şube adı: A, B, C...
  final List<ExamStudent> students;

  ExamSection({
    required this.id,
    required this.gradeLevel,
    required this.sectionName,
    List<ExamStudent>? students,
  }) : students = students ?? [];

  String get displayName => '$gradeLevel-$sectionName';

  int get studentCount => students.length;

  /// Şube ID'si oluştur
  static String createId(int gradeLevel, String sectionName) {
    return '$gradeLevel-$sectionName';
  }
}

/// Sınav salonu modeli
class ExamRoom {
  final String id;
  final String name;
  final int rowCount; // Sıra sayısı (ön-arka)
  final int columnCount; // Sütun sayısı (yan yana)

  ExamRoom({
    required this.id,
    required this.name,
    required this.rowCount,
    required this.columnCount,
  });

  /// Toplam kapasite
  int get capacity => rowCount * columnCount;

  /// Koltuk indeksini sıra/sütuna çevir
  (int row, int col) indexToPosition(int index) {
    return (index ~/ columnCount, index % columnCount);
  }

  /// Sıra/sütunu indekse çevir
  int positionToIndex(int row, int col) {
    return row * columnCount + col;
  }
}

/// Koltuk ataması - bir koltuğa atanan öğrenci
class SeatAssignment {
  final String roomId;
  final int row; // 0-indexed sıra
  final int column; // 0-indexed sütun
  final ExamStudent student;

  SeatAssignment({
    required this.roomId,
    required this.row,
    required this.column,
    required this.student,
  });

  /// Görüntüleme için koltuk numarası (1-indexed)
  String get seatLabel => 'Sıra ${row + 1}, Sütun ${column + 1}';

  /// Koltuk numarası (soldan sağa, önden arkaya)
  int get seatNumber => row * 100 + column + 1; // Örn: Sıra 2, Sütun 3 = 203
}

/// Sınav planı - tüm salonların oturma düzeni
class ExamPlan {
  final String id;
  final String examName;
  final DateTime createdAt;
  final List<ExamRoom> rooms;
  final List<SeatAssignment> assignments;
  final List<ExamSection> sections;

  ExamPlan({
    required this.id,
    required this.examName,
    required this.createdAt,
    required this.rooms,
    required this.assignments,
    required this.sections,
  });

  /// Toplam öğrenci sayısı
  int get totalStudents => assignments.length;

  /// Toplam kapasite
  int get totalCapacity => rooms.fold(0, (sum, room) => sum + room.capacity);

  /// Belirli bir salon için atamaları getir
  List<SeatAssignment> getAssignmentsForRoom(String roomId) {
    return assignments.where((a) => a.roomId == roomId).toList();
  }

  /// Belirli bir salon için grid matrisi oluştur
  List<List<SeatAssignment?>> getRoomGrid(ExamRoom room) {
    final roomAssignments = getAssignmentsForRoom(room.id);
    final grid = List<List<SeatAssignment?>>.generate(
      room.rowCount,
      (_) => List<SeatAssignment?>.filled(room.columnCount, null),
    );

    for (final assignment in roomAssignments) {
      if (assignment.row < room.rowCount &&
          assignment.column < room.columnCount) {
        grid[assignment.row][assignment.column] = assignment;
      }
    }

    return grid;
  }

  /// Şubeye göre öğrenci sayısı istatistikleri
  Map<String, int> getStudentCountBySection() {
    final counts = <String, int>{};
    for (final assignment in assignments) {
      final sectionId = assignment.student.sectionId;
      counts[sectionId] = (counts[sectionId] ?? 0) + 1;
    }
    return counts;
  }
}

/// Dağıtım sonucu - algoritma çıktısı
class DistributionResult {
  final bool success;
  final ExamPlan? plan;
  final String? errorMessage;
  final List<String> warnings;

  DistributionResult({
    required this.success,
    this.plan,
    this.errorMessage,
    this.warnings = const [],
  });

  factory DistributionResult.success(ExamPlan plan, {List<String>? warnings}) {
    return DistributionResult(
      success: true,
      plan: plan,
      warnings: warnings ?? [],
    );
  }

  factory DistributionResult.failure(String message) {
    return DistributionResult(success: false, errorMessage: message);
  }
}
