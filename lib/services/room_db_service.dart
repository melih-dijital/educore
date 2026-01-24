/// Room Database Service
/// Supabase'de salon CRUD işlemleri

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/school_models.dart';

/// Supabase salon veritabanı servisi
class RoomDbService {
  // Singleton pattern
  static final RoomDbService _instance = RoomDbService._internal();
  factory RoomDbService() => _instance;
  RoomDbService._internal();

  /// Supabase client
  SupabaseClient get _client => Supabase.instance.client;

  /// Mevcut kullanıcı ID
  String? get _userId => _client.auth.currentUser?.id;

  /// Tüm salonları getir
  Future<List<SchoolRoom>> getRooms() async {
    if (_userId == null) return [];

    try {
      final response = await _client
          .from('school_rooms')
          .select()
          .eq('user_id', _userId!)
          .order('name');

      return (response as List).map((json) => _roomFromJson(json)).toList();
    } catch (e) {
      print('Error getting rooms: $e');
      return [];
    }
  }

  /// Salon ekle
  Future<SchoolRoom?> addRoom(
    String name, {
    int rowCount = 5,
    int columnCount = 6,
  }) async {
    if (_userId == null) return null;

    try {
      final response = await _client
          .from('school_rooms')
          .insert({
            'user_id': _userId,
            'name': name.trim(),
            'row_count': rowCount,
            'column_count': columnCount,
          })
          .select()
          .single();

      return _roomFromJson(response);
    } catch (e) {
      print('Error adding room: $e');
      return null;
    }
  }

  /// Salon güncelle
  Future<bool> updateRoom(SchoolRoom room) async {
    if (_userId == null) return false;

    try {
      await _client
          .from('school_rooms')
          .update({
            'name': room.name,
            'row_count': room.rowCount,
            'column_count': room.columnCount,
          })
          .eq('id', room.id)
          .eq('user_id', _userId!);

      return true;
    } catch (e) {
      print('Error updating room: $e');
      return false;
    }
  }

  /// Salon sil
  Future<bool> deleteRoom(String roomId) async {
    if (_userId == null) return false;

    try {
      await _client
          .from('school_rooms')
          .delete()
          .eq('id', roomId)
          .eq('user_id', _userId!);

      return true;
    } catch (e) {
      print('Error deleting room: $e');
      return false;
    }
  }

  /// Tüm salonları sil
  Future<bool> deleteAllRooms() async {
    if (_userId == null) return false;

    try {
      await _client.from('school_rooms').delete().eq('user_id', _userId!);
      return true;
    } catch (e) {
      print('Error deleting all rooms: $e');
      return false;
    }
  }

  /// JSON'dan Room oluştur
  SchoolRoom _roomFromJson(Map<String, dynamic> json) {
    return SchoolRoom(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      rowCount: json['row_count'] ?? 5,
      columnCount: json['column_count'] ?? 6,
    );
  }
}
