/// Auth Service
/// Supabase authentication servisi

import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase kimlik doğrulama servisi
class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Supabase client
  SupabaseClient get _client => Supabase.instance.client;

  /// Mevcut oturum
  Session? get currentSession => _client.auth.currentSession;

  /// Mevcut kullanıcı
  User? get currentUser => _client.auth.currentUser;

  /// Oturum açık mı?
  bool get isAuthenticated => currentUser != null;

  /// Auth state değişikliklerini dinle
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// E-posta ile kayıt ol
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
    String? schoolName,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        if (displayName != null) 'display_name': displayName,
        if (schoolName != null) 'school_name': schoolName,
      },
    );
  }

  /// E-posta ile giriş yap
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Google ile giriş
  Future<bool> signInWithGoogle() async {
    try {
      final response = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _getRedirectUrl(),
      );
      return response;
    } catch (e) {
      print('Google sign in error: $e');
      return false;
    }
  }

  /// GitHub ile giriş
  Future<bool> signInWithGithub() async {
    try {
      final response = await _client.auth.signInWithOAuth(
        OAuthProvider.github,
        redirectTo: _getRedirectUrl(),
      );
      return response;
    } catch (e) {
      print('GitHub sign in error: $e');
      return false;
    }
  }

  /// Şifre sıfırlama e-postası gönder
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: _getRedirectUrl(),
    );
  }

  /// Çıkış yap
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Redirect URL'ini al (platform'a göre)
  String _getRedirectUrl() {
    // Web için
    return 'http://localhost:8080/auth/callback';
  }
}
