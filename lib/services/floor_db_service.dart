/// Floor Database Service
/// Supabase'de kat CRUD işlemleri

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/duty_planner_models.dart';

/// Supabase kat veritabanı servisi
class FloorDbService {
  // Singleton pattern
  static final FloorDbService _instance = FloorDbService._internal();
  factory FloorDbService() => _instance;
  FloorDbService._internal();

  /// Supabase client
  SupabaseClient get _client => Supabase.instance.client;

  /// Mevcut kullanıcı ID
  String? get _userId => _client.auth.currentUser?.id;

  /// Tüm katları getir
  Future<List<Floor>> getFloors() async {
    if (_userId == null) return [];

    try {
      final response = await _client
          .from('floors')
          .select()
          .eq('user_id', _userId!)
          .order('floor_order');

      return (response as List).map((json) => _floorFromJson(json)).toList();
    } catch (e) {
      print('Error getting floors: $e');
      return [];
    }
  }

  /// Kat ekle
  Future<Floor?> addFloor(Floor floor) async {
    if (_userId == null) return null;

    try {
      final response = await _client
          .from('floors')
          .insert({
            'user_id': _userId,
            'name': floor.name,
            'floor_order': floor.order,
          })
          .select()
          .single();

      return _floorFromJson(response);
    } catch (e) {
      print('Error adding floor: $e');
      return null;
    }
  }

  /// Birden fazla kat ekle (toplu import)
  Future<int> addFloors(List<Floor> floors) async {
    if (_userId == null) return 0;

    try {
      final data = floors
          .map(
            (f) => {'user_id': _userId, 'name': f.name, 'floor_order': f.order},
          )
          .toList();

      await _client.from('floors').insert(data);
      return floors.length;
    } catch (e) {
      print('Error adding floors: $e');
      return 0;
    }
  }

  /// Kat güncelle
  Future<bool> updateFloor(String id, Floor floor) async {
    if (_userId == null) return false;

    try {
      await _client
          .from('floors')
          .update({'name': floor.name, 'floor_order': floor.order})
          .eq('id', id)
          .eq('user_id', _userId!);

      return true;
    } catch (e) {
      print('Error updating floor: $e');
      return false;
    }
  }

  /// Kat sil
  Future<bool> deleteFloor(String id) async {
    if (_userId == null) return false;

    try {
      await _client
          .from('floors')
          .delete()
          .eq('id', id)
          .eq('user_id', _userId!);

      return true;
    } catch (e) {
      print('Error deleting floor: $e');
      return false;
    }
  }

  /// Tüm katları sil
  Future<bool> deleteAllFloors() async {
    if (_userId == null) return false;

    try {
      await _client.from('floors').delete().eq('user_id', _userId!);
      return true;
    } catch (e) {
      print('Error deleting all floors: $e');
      return false;
    }
  }

  /// Tüm katların sırasını güncelle
  Future<bool> updateFloorOrders(List<Floor> floors) async {
    if (_userId == null) return false;

    try {
      for (final floor in floors) {
        await _client
            .from('floors')
            .update({'floor_order': floor.order})
            .eq('id', floor.id)
            .eq('user_id', _userId!);
      }
      return true;
    } catch (e) {
      print('Error updating floor orders: $e');
      return false;
    }
  }

  /// JSON'dan Floor oluştur
  Floor _floorFromJson(Map<String, dynamic> json) {
    return Floor(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      order: json['floor_order'] ?? 1,
    );
  }
}
