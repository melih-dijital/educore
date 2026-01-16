/// Auth Gate
/// Oturum durumuna göre yönlendirme

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

/// Auth durumunu kontrol eden ve yönlendiren widget
class AuthGate extends StatelessWidget {
  final Widget child;

  const AuthGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Yükleniyor durumu
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Oturum kontrolü
        final session = Supabase.instance.client.auth.currentSession;

        if (session != null) {
          // Kullanıcı giriş yapmış
          return child;
        } else {
          // Kullanıcı giriş yapmamış
          return const LoginScreen();
        }
      },
    );
  }
}
