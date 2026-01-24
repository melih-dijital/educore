/// Teacher Database Service
/// Supabase'de öğretmen CRUD işlemleri

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/duty_planner_models.dart';

/// Supabase öğretmen veritabanı servisi
class TeacherDbService {
  // Singleton pattern
  static final TeacherDbService _instance = TeacherDbService._internal();
  factory TeacherDbService() => _instance;
  TeacherDbService._internal();

  /// Supabase client
  SupabaseClient get _client => Supabase.instance.client;

  /// Mevcut kullanıcı ID
  String? get _userId => _client.auth.currentUser?.id;

  /// Tüm öğretmenleri getir
  Future<List<Teacher>> getTeachers() async {
    if (_userId == null) return [];

    try {
      final response = await _client
          .from('teachers')
          .select()
          .eq('user_id', _userId!)
          .order('name');

      return (response as List).map((json) => _teacherFromJson(json)).toList();
    } catch (e) {
      print('Error getting teachers: $e');
      return [];
    }
  }

  /// Öğretmen ekle
  Future<Teacher?> addTeacher(Teacher teacher) async {
    if (_userId == null) return null;

    try {
      final response = await _client
          .from('teachers')
          .insert({
            'user_id': _userId,
            'name': teacher.name,
            'branch': teacher.branch,
            'unavailable_days': teacher.unavailableDays,
          })
          .select()
          .single();

      return _teacherFromJson(response);
    } catch (e) {
      print('Error adding teacher: $e');
      return null;
    }
  }

  /// Birden fazla öğretmen ekle (toplu import)
  Future<int> addTeachers(List<Teacher> teachers) async {
    if (_userId == null) return 0;

    try {
      final data = teachers
          .map(
            (t) => {
              'user_id': _userId,
              'name': t.name,
              'branch': t.branch,
              'unavailable_days': t.unavailableDays,
            },
          )
          .toList();

      await _client.from('teachers').insert(data);
      return teachers.length;
    } catch (e) {
      print('Error adding teachers: $e');
      return 0;
    }
  }

  /// Öğretmen güncelle
  Future<bool> updateTeacher(String id, Teacher teacher) async {
    if (_userId == null) return false;

    try {
      await _client
          .from('teachers')
          .update({
            'name': teacher.name,
            'branch': teacher.branch,
            'unavailable_days': teacher.unavailableDays,
          })
          .eq('id', id)
          .eq('user_id', _userId!);

      return true;
    } catch (e) {
      print('Error updating teacher: $e');
      return false;
    }
  }

  /// Öğretmen sil
  Future<bool> deleteTeacher(String id) async {
    if (_userId == null) return false;

    try {
      await _client
          .from('teachers')
          .delete()
          .eq('id', id)
          .eq('user_id', _userId!);

      return true;
    } catch (e) {
      print('Error deleting teacher: $e');
      return false;
    }
  }

  /// Tüm öğretmenleri sil
  Future<bool> deleteAllTeachers() async {
    if (_userId == null) return false;

    try {
      await _client.from('teachers').delete().eq('user_id', _userId!);
      return true;
    } catch (e) {
      print('Error deleting all teachers: $e');
      return false;
    }
  }

  /// JSON'dan Teacher oluştur
  Teacher _teacherFromJson(Map<String, dynamic> json) {
    List<int> unavailableDays = [];
    if (json['unavailable_days'] != null) {
      unavailableDays = (json['unavailable_days'] as List)
          .map((e) => e as int)
          .toList();
    }

    return Teacher(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      branch: json['branch'] ?? '',
      unavailableDays: unavailableDays,
    );
  }
}
