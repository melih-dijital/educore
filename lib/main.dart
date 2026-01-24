import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/butterfly_exam/butterfly_exam_home.dart';
import 'screens/duty_planner/duty_planner_home_screen.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/settings/profile_screen.dart';
import 'screens/school/school_management_screen.dart';
import 'theme/duty_planner_theme.dart';
import 'services/auth_service.dart';

// Supabase yapılandırması - Bu değerleri kendi Supabase projenizden alın
const supabaseUrl = 'https://xbaqyelgopuwmrdpwmte.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhiYXF5ZWxnb3B1d21yZHB3bXRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg1NzQ4NDAsImV4cCI6MjA4NDE1MDg0MH0.GKGyOt-UbKfacJ-RA3fnZR3iq8tleH5nfUX7a9mOJLs';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Türkçe tarih formatı için
  await initializeDateFormatting('tr', null);

  // Supabase initialization
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OkulAsistan Pro',
      debugShowCheckedModeBanner: false,
      theme: DutyPlannerTheme.theme,
      // Türkçe localization için
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr', 'TR'), Locale('en', 'US')],
      locale: const Locale('tr', 'TR'),
      home: const AuthGate(child: MainMenuScreen()),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/school': (context) => const SchoolManagementScreen(),
        '/butterfly-exam': (context) => const ButterflyExamHomeScreen(),
        '/exam-simulation': (context) =>
            const ButterflyExamHomeScreen(), // Yeni sisteme yönlendir
        '/duty-planner': (context) => const DutyPlannerHomeScreen(),
      },
    );
  }
}

/// Ana menü ekranı
class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OkulAsistan Pro'),
        centerTitle: true,
        actions: [
          // Kullanıcı menüsü
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: DutyPlannerColors.primaryLight,
              child: Text(
                user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  color: DutyPlannerColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onSelected: (value) async {
              if (value == 'logout') {
                await authService.signOut();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Text(
                  user?.email ?? 'Kullanıcı',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: DutyPlannerColors.textPrimary,
                  ),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: DutyPlannerColors.error),
                    SizedBox(width: 8),
                    Text('Çıkış Yap'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hoşgeldin kartı
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: DutyPlannerColors.primaryLight.withValues(
                              alpha: 0.2,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.school,
                            size: 48,
                            color: DutyPlannerColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Hoş Geldiniz, ${user?.userMetadata?['display_name'] ?? user?.email?.split('@').first ?? 'Kullanıcı'}!',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Okul yönetimi için akıllı çözümler',
                          style: TextStyle(
                            color: DutyPlannerColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Mini uygulamalar başlığı
                const Text(
                  'Mini Uygulamalar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Nöbet Planlayıcı
                _buildAppCard(
                  context,
                  icon: Icons.calendar_month,
                  title: 'Kat Nöbetçi Öğretmen Planlayıcı',
                  subtitle: 'Adil ve otomatik nöbet çizelgesi oluşturun',
                  color: DutyPlannerColors.primary,
                  onTap: () => Navigator.pushNamed(context, '/duty-planner'),
                ),
                const SizedBox(height: 12),

                // Kelebek Sınav Sistemi
                _buildAppCard(
                  context,
                  icon: Icons.shuffle,
                  title: 'Kelebek Sınav Dağıtım Sistemi',
                  subtitle: 'Öğrencileri sınava adil şekilde yerleştirin',
                  color: Colors.indigo,
                  onTap: () => Navigator.pushNamed(context, '/exam-simulation'),
                ),
                const SizedBox(height: 24),

                // Yönetim başlığı
                const Text(
                  'Yönetim',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Okul Yönetimi
                _buildAppCard(
                  context,
                  icon: Icons.school,
                  title: 'Okul Yönetimi',
                  subtitle: 'Öğretmenleri kalıcı olarak kaydedin',
                  color: Colors.teal,
                  onTap: () => Navigator.pushNamed(context, '/school'),
                ),
                const SizedBox(height: 12),

                // Ayarlar
                _buildAppCard(
                  context,
                  icon: Icons.settings,
                  title: 'Profil ve Ayarlar',
                  subtitle: 'Hesap bilgilerinizi yönetin',
                  color: Colors.blueGrey,
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback? onTap,
    bool enabled = true,
  }) {
    return Card(
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.5,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: DutyPlannerColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (enabled)
                  Icon(Icons.arrow_forward_ios, color: color, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
