/// Locked Panel Screen
/// Giriş yapmayan kullanıcılar için kilitli panel önizlemesi

import 'package:flutter/material.dart';
import '../../theme/duty_planner_theme.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// Giriş yapmayan kullanıcılar için kilitli panel ekranı
class LockedPanelScreen extends StatelessWidget {
  const LockedPanelScreen({super.key});

  /// Login sayfasına animasyonlu geçiş
  void _navigateToLogin(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return const LoginScreen();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Fade + Slide transition
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.0, 0.1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  /// Register sayfasına animasyonlu geçiş
  void _navigateToRegister(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return const RegisterScreen();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.0, 0.1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OkulAsistan Pro'),
        centerTitle: true,
        actions: [
          // Giriş yap butonu
          TextButton.icon(
            onPressed: () => _navigateToLogin(context),
            icon: const Icon(Icons.login, color: Colors.white),
            label: const Text(
              'Giriş Yap',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Main content with max width
            Padding(
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
                          color: DutyPlannerColors.warning.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: DutyPlannerColors.warning.withValues(
                              alpha: 0.3,
                            ),
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Nöbet Planlayıcı (kilitli)
                      _AnimatedLockedCard(
                        icon: Icons.calendar_month,
                        title: 'Kat Nöbetçi Öğretmen Planlayıcı',
                        subtitle: 'Adil ve otomatik nöbet çizelgesi oluşturun',
                        color: DutyPlannerColors.primary,
                      ),
                      const SizedBox(height: 12),

                      // Kelebek Sınav Sistemi (kilitli)
                      _AnimatedLockedCard(
                        icon: Icons.shuffle,
                        title: 'Kelebek Sınav Dağıtım Sistemi',
                        subtitle: 'Öğrencileri sınava adil şekilde yerleştirin',
                        color: Colors.indigo,
                      ),
                      const SizedBox(height: 24),

                      // Yönetim başlığı
                      const Text(
                        'Yönetim',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Okul Yönetimi (kilitli)
                      _AnimatedLockedCard(
                        icon: Icons.school,
                        title: 'Okul Yönetimi',
                        subtitle:
                            'Öğretmenleri ve katları kalıcı olarak kaydedin',
                        color: Colors.teal,
                      ),
                      const SizedBox(height: 12),

                      // Ayarlar (kilitli)
                      _AnimatedLockedCard(
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
                              onPressed: () => _navigateToRegister(context),
                              icon: const Icon(Icons.person_add),
                              label: const Text('Kayıt Ol'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _navigateToLogin(context),
                              icon: const Icon(Icons.login),
                              label: const Text('Giriş Yap'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
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
            // Footer - sitenin tamamını kaplar
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  /// Footer widget
  Widget _buildFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: DutyPlannerColors.primary.withValues(alpha: 0.05),
        border: Border(
          top: BorderSide(color: DutyPlannerColors.tableBorder, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo ve İsim
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school, size: 20, color: DutyPlannerColors.primary),
              const SizedBox(width: 8),
              Text(
                'OkulAsistan Pro',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: DutyPlannerColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Copyright
          Text(
            '© 2026 OkulAsistan Pro. Tüm hakları saklıdır.',
            style: TextStyle(
              fontSize: 12,
              color: DutyPlannerColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          // Version
          Text(
            'Versiyon 1.0.0',
            style: TextStyle(fontSize: 11, color: DutyPlannerColors.textHint),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Animasyonlu kilitli kart widget'ı
class _AnimatedLockedCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _AnimatedLockedCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  State<_AnimatedLockedCard> createState() => _AnimatedLockedCardState();
}

class _AnimatedLockedCardState extends State<_AnimatedLockedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _positionAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.4,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _positionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHover(bool hovering) {
    if (hovering) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: Card(
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
                        color: widget.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(widget.icon, color: widget.color, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle,
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
            // Animasyonlu kilit overlay
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                // Kartın boyutlarını al
                return LayoutBuilder(
                  builder: (context, constraints) {
                    // Başlangıç pozisyonu: sağ üst köşe
                    const double startTop = 8;
                    const double startRight = 8;

                    // Bitiş pozisyonu: kartın ortası
                    final double cardWidth = constraints.maxWidth;
                    final double cardHeight = 80; // Yaklaşık kart yüksekliği
                    final double endLeft = (cardWidth - 40) / 2;
                    final double endTop = (cardHeight - 40) / 2;

                    // Mevcut pozisyon hesapla
                    final double currentRight =
                        startRight +
                        (cardWidth - startRight - endLeft - 40) *
                            (1 - _positionAnimation.value);
                    final double currentTop =
                        startTop +
                        (endTop - startTop) * _positionAnimation.value;

                    return Positioned(
                      top: currentTop,
                      right: _positionAnimation.value < 0.5
                          ? currentRight
                          : null,
                      left: _positionAnimation.value >= 0.5
                          ? endLeft * _positionAnimation.value * 2 - endLeft
                          : null,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            // Renk değişimi yok - sadece büyüme
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.lock,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
