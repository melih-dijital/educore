/// Student Database Service
/// Supabase'de öğrenci, sınıf ve şube CRUD işlemleri

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/school_models.dart';

/// Supabase öğrenci veritabanı servisi
class StudentDbService {
  // Singleton pattern
  static final StudentDbService _instance = StudentDbService._internal();
  factory StudentDbService() => _instance;
  StudentDbService._internal();

  /// Supabase client
  SupabaseClient get _client => Supabase.instance.client;

  /// Mevcut kullanıcı ID
  String? get _userId => _client.auth.currentUser?.id;

  // ==================== GRADES (SINIFLAR) ====================

  /// Tüm sınıfları getir (şubeler ve öğrencilerle birlikte)
  Future<List<SchoolGrade>> getGrades() async {
    if (_userId == null) return [];

    try {
      // Sınıfları getir
      final gradesResponse = await _client
          .from('school_grades')
          .select()
          .eq('user_id', _userId!)
          .order('level');

      final grades = <SchoolGrade>[];

      for (final gradeJson in gradesResponse) {
        final gradeId = gradeJson['id'].toString();

        // Bu sınıfın şubelerini getir
        final sectionsResponse = await _client
            .from('school_sections')
            .select()
            .eq('grade_id', gradeId)
            .order('name');

        final sections = <SchoolSection>[];

        for (final sectionJson in sectionsResponse) {
          final sectionId = sectionJson['id'].toString();

          // Bu şubenin öğrencilerini getir
          final studentsResponse = await _client
              .from('school_students')
              .select()
              .eq('section_id', sectionId)
              .order('last_name');

          final students = (studentsResponse as List)
              .map((s) => _studentFromJson(s, sectionId))
              .toList();

          sections.add(
            SchoolSection(
              id: sectionId,
              gradeId: gradeId,
              name: sectionJson['name'] ?? '',
              students: students,
            ),
          );
        }

        grades.add(
          SchoolGrade(
            id: gradeId,
            name: gradeJson['name'] ?? '',
            level: gradeJson['level'] ?? 9,
            sections: sections,
          ),
        );
      }

      return grades;
    } catch (e) {
      print('Error getting grades: $e');
      return [];
    }
  }

  /// Sınıf ekle
  Future<SchoolGrade?> addGrade(int level) async {
    if (_userId == null) return null;

    try {
      final response = await _client
          .from('school_grades')
          .insert({'user_id': _userId, 'name': '$level. Sınıf', 'level': level})
          .select()
          .single();

      return SchoolGrade(
        id: response['id'].toString(),
        name: response['name'] ?? '',
        level: response['level'] ?? level,
        sections: [],
      );
    } catch (e) {
      print('Error adding grade: $e');
      return null;
    }
  }

  /// Sınıf sil (şubeleri ve öğrencileri de siler - CASCADE)
  Future<bool> deleteGrade(String gradeId) async {
    if (_userId == null) return false;

    try {
      await _client
          .from('school_grades')
          .delete()
          .eq('id', gradeId)
          .eq('user_id', _userId!);
      return true;
    } catch (e) {
      print('Error deleting grade: $e');
      return false;
    }
  }

  // ==================== SECTIONS (ŞUBELER) ====================

  /// Şube ekle
  Future<SchoolSection?> addSection(String gradeId, String name) async {
    if (_userId == null) return null;

    try {
      final response = await _client
          .from('school_sections')
          .insert({'grade_id': gradeId, 'name': name.toUpperCase()})
          .select()
          .single();

      return SchoolSection(
        id: response['id'].toString(),
        gradeId: gradeId,
        name: response['name'] ?? '',
        students: [],
      );
    } catch (e) {
      print('Error adding section: $e');
      return null;
    }
  }

  /// Şube sil (öğrencileri de siler - CASCADE)
  Future<bool> deleteSection(String sectionId) async {
    if (_userId == null) return false;

    try {
      await _client.from('school_sections').delete().eq('id', sectionId);
      return true;
    } catch (e) {
      print('Error deleting section: $e');
      return false;
    }
  }

  // ==================== STUDENTS (ÖĞRENCİLER) ====================

  /// Öğrenci ekle
  Future<SchoolStudent?> addStudent(
    String sectionId,
    String firstName,
    String lastName, {
    String studentNumber = '',
  }) async {
    if (_userId == null) return null;

    try {
      final response = await _client
          .from('school_students')
          .insert({
            'section_id': sectionId,
            'first_name': firstName.trim(),
            'last_name': lastName.trim(),
            'student_number': studentNumber.trim(),
          })
          .select()
          .single();

      return _studentFromJson(response, sectionId);
    } catch (e) {
      print('Error adding student: $e');
      return null;
    }
  }

  /// Toplu öğrenci ekle
  Future<int> addStudents(
    String sectionId,
    List<Map<String, String>> students,
  ) async {
    if (_userId == null) return 0;

    try {
      final data = students
          .map(
            (s) => {
              'section_id': sectionId,
              'first_name': (s['firstName'] ?? '').trim(),
              'last_name': (s['lastName'] ?? '').trim(),
              'student_number': (s['studentNumber'] ?? '').trim(),
            },
          )
          .toList();

      await _client.from('school_students').insert(data);
      return students.length;
    } catch (e) {
      print('Error adding students: $e');
      return 0;
    }
  }

  /// Öğrenci sil
  Future<bool> deleteStudent(String studentId) async {
    if (_userId == null) return false;

    try {
      await _client.from('school_students').delete().eq('id', studentId);
      return true;
    } catch (e) {
      print('Error deleting student: $e');
      return false;
    }
  }

  /// Şubedeki tüm öğrencileri sil
  Future<bool> deleteAllStudentsInSection(String sectionId) async {
    if (_userId == null) return false;

    try {
      await _client
          .from('school_students')
          .delete()
          .eq('section_id', sectionId);
      return true;
    } catch (e) {
      print('Error deleting students: $e');
      return false;
    }
  }

  // ==================== HELPERS ====================

  /// JSON'dan Student oluştur
  SchoolStudent _studentFromJson(Map<String, dynamic> json, String sectionId) {
    return SchoolStudent(
      id: json['id'].toString(),
      sectionId: sectionId,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      studentNumber: json['student_number'] ?? '',
    );
  }
}
