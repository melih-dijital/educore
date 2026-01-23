/// School Models
/// Okul yönetimi için öğrenci ve salon modelleri

/// Sınıf seviyesi modeli (9, 10, 11, 12. sınıflar)
class SchoolGrade {
  final String id;
  final String name; // "9. Sınıf"
  final int level; // 9, 10, 11, 12
  final List<SchoolSection> sections;

  SchoolGrade({
    required this.id,
    required this.name,
    required this.level,
    List<SchoolSection>? sections,
  }) : sections = sections ?? [];

  /// Toplam öğrenci sayısı
  int get studentCount => sections.fold(0, (sum, s) => sum + s.studentCount);

  /// Kopyala (sections ile)
  SchoolGrade copyWith({List<SchoolSection>? sections}) {
    return SchoolGrade(
      id: id,
      name: name,
      level: level,
      sections: sections ?? this.sections,
    );
  }

  @override
  String toString() => 'SchoolGrade($name, ${sections.length} şube)';
}

/// Şube modeli (A, B, C şubeleri)
class SchoolSection {
  final String id;
  final String gradeId;
  final String name; // "A", "B", "C"
  final List<SchoolStudent> students;

  SchoolSection({
    required this.id,
    required this.gradeId,
    required this.name,
    List<SchoolStudent>? students,
  }) : students = students ?? [];

  /// Öğrenci sayısı
  int get studentCount => students.length;

  /// Şube görüntüleme adı (9-A formatı için grade bilgisi gerekli)
  String displayName(int gradeLevel) => '$gradeLevel-$name';

  /// Kopyala (students ile)
  SchoolSection copyWith({List<SchoolStudent>? students}) {
    return SchoolSection(
      id: id,
      gradeId: gradeId,
      name: name,
      students: students ?? this.students,
    );
  }

  @override
  String toString() => 'SchoolSection($name, $studentCount öğrenci)';
}

/// Öğrenci modeli
class SchoolStudent {
  final String id;
  final String sectionId;
  final String firstName;
  final String lastName;
  final String studentNumber;

  SchoolStudent({
    required this.id,
    required this.sectionId,
    required this.firstName,
    required this.lastName,
    this.studentNumber = '',
  });

  /// Tam ad
  String get fullName => '$firstName $lastName';

  /// Kısa görüntüleme adı
  String get displayName =>
      '$firstName ${lastName.isNotEmpty ? lastName[0] : ''}.';

  @override
  String toString() => 'SchoolStudent($fullName)';
}

/// Salon modeli
class SchoolRoom {
  final String id;
  final String name;
  final int rowCount;
  final int columnCount;

  SchoolRoom({
    required this.id,
    required this.name,
    required this.rowCount,
    required this.columnCount,
  });

  /// Toplam kapasite
  int get capacity => rowCount * columnCount;

  /// Kopyala
  SchoolRoom copyWith({String? name, int? rowCount, int? columnCount}) {
    return SchoolRoom(
      id: id,
      name: name ?? this.name,
      rowCount: rowCount ?? this.rowCount,
      columnCount: columnCount ?? this.columnCount,
    );
  }

  @override
  String toString() => 'SchoolRoom($name, $capacity koltuk)';
}
