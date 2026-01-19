/// Locked Panel Screen
/// Giriş yapmayan kullanıcılar için kilitli panel önizlemesi

import 'package:flutter/material.dart';
import '../../theme/duty_planner_theme.dart';

/// Giriş yapmayan kullanıcılar için kilitli panel ekranı
class LockedPanelScreen extends StatelessWidget {
  const LockedPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OkulAsistan Pro'),
        centerTitle: true,
        actions: [
          // Giriş yap butonu
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            icon: const Icon(Icons.login, color: Colors.white),
            label: const Text(
              'Giriş Yap',
              style: TextStyle(color: Colors.white),
            ),
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
                // Uyarı banner'ı
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DutyPlannerColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: DutyPlannerColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        color: DutyPlannerColors.warning,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Önizleme Modu',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tüm özellikleri kullanmak için giriş yapın veya kayıt olun.',
                              style: TextStyle(
                                color: DutyPlannerColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Hoşgeldin kartı (kilitli)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: DutyPlannerColors.primaryLight
                                    .withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.school,
                                size: 48,
                                color: DutyPlannerColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'OkulAsistan Pro\'ya Hoş Geldiniz!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
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

                // Nöbet Planlayıcı (kilitli)
                _buildLockedCard(
                  icon: Icons.calendar_month,
                  title: 'Kat Nöbetçi Öğretmen Planlayıcı',
                  subtitle: 'Adil ve otomatik nöbet çizelgesi oluşturun',
                  color: DutyPlannerColors.primary,
                ),
                const SizedBox(height: 12),

                // Kelebek Sınav Sistemi (kilitli)
                _buildLockedCard(
                  icon: Icons.shuffle,
                  title: 'Kelebek Sınav Dağıtım Sistemi',
                  subtitle: 'Öğrencileri sınava adil şekilde yerleştirin',
                  color: Colors.indigo,
                ),
                const SizedBox(height: 24),

                // Yönetim başlığı
                const Text(
                  'Yönetim',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Okul Yönetimi (kilitli)
                _buildLockedCard(
                  icon: Icons.school,
                  title: 'Okul Yönetimi',
                  subtitle: 'Öğretmenleri ve katları kalıcı olarak kaydedin',
                  color: Colors.teal,
                ),
                const SizedBox(height: 12),

                // Ayarlar (kilitli)
                _buildLockedCard(
                  icon: Icons.settings,
                  title: 'Profil ve Ayarlar',
                  subtitle: 'Hesap bilgilerinizi yönetin',
                  color: Colors.blueGrey,
                ),
                const SizedBox(height: 32),

                // Giriş/Kayıt butonları
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/register'),
                        icon: const Icon(Icons.person_add),
                        label: const Text('Kayıt Ol'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                        icon: const Icon(Icons.login),
                        label: const Text('Giriş Yap'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockedCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      child: Stack(
        children: [
          // Ana içerik (soluk)
          Opacity(
            opacity: 0.5,
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
                ],
              ),
            ),
          ),
          // Kilit overlay
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.lock, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
