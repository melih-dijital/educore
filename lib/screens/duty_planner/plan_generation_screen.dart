/// Plan Generation Screen
/// Adım 4: Plan oluşturma ekranı

import 'package:flutter/material.dart';
import '../../models/duty_planner_models.dart';
import '../../services/duty_scheduler_service.dart';
import '../../theme/duty_planner_theme.dart';
import '../../widgets/duty_plan_grid.dart';

/// Plan oluşturma ekranı
class PlanGenerationScreen extends StatefulWidget {
  final List<Teacher> teachers;
  final List<Floor> floors;
  final DutyPlanType planType;
  final DateTime startDate;
  final DateTime endDate;
  final Function(DutyPlan) onPlanGenerated;
  final DutyPlan? generatedPlan;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const PlanGenerationScreen({
    super.key,
    required this.teachers,
    required this.floors,
    required this.planType,
    required this.startDate,
    required this.endDate,
    required this.onPlanGenerated,
    required this.generatedPlan,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<PlanGenerationScreen> createState() => _PlanGenerationScreenState();
}

class _PlanGenerationScreenState extends State<PlanGenerationScreen> {
  final DutySchedulerService _scheduler = DutySchedulerService();
  bool _isGenerating = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final padding = DutyPlannerTheme.screenPadding(context);
    final maxWidth = DutyPlannerTheme.maxContentWidth(context);

    return SingleChildScrollView(
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Başlık
              _buildHeader(),
              const SizedBox(height: 24),

              // Plan henüz oluşturulmadıysa
              if (widget.generatedPlan == null) ...[
                _buildGenerateCard(),
              ] else ...[
                // Plan oluşturulduysa
                _buildSuccessCard(),
                const SizedBox(height: 16),

                // İstatistikler
                DutyPlanStatisticsWidget(
                  plan: widget.generatedPlan!,
                  teachers: widget.teachers,
                ),
                const SizedBox(height: 16),

                // Plan grid
                DutyPlanGridWidget(
                  plan: widget.generatedPlan!,
                  floors: widget.floors,
                ),
                const SizedBox(height: 16),

                // Yeniden oluştur butonu
                OutlinedButton.icon(
                  onPressed: _generatePlan,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Yeniden Oluştur'),
                ),
              ],

              if (_error != null) ...[
                const SizedBox(height: 16),
                Card(
                  color: DutyPlannerColors.error.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: DutyPlannerColors.error,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: DutyPlannerColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Navigasyon butonları
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onBack,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_back),
                          SizedBox(width: 8),
                          Text('Geri'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.generatedPlan != null
                          ? widget.onNext
                          : null,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('PDF İndir'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DutyPlannerColors.primaryLight.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_fix_high,
                color: DutyPlannerColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Adım 4: Plan Oluşturma',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Adil dağıtım algoritması ile nöbet planı oluşturun',
                    style: TextStyle(color: DutyPlannerColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            // Özet bilgiler
            _buildSummaryRow(
              Icons.people,
              'Öğretmen Sayısı',
              '${widget.teachers.length}',
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              Icons.layers,
              'Kat Sayısı',
              '${widget.floors.length}',
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              Icons.calendar_today,
              'Plan Türü',
              widget.planType.displayName,
            ),
            const SizedBox(height: 24),

            // Oluştur butonu
            if (_isGenerating)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Plan oluşturuluyor...'),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: _generatePlan,
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('Plan Oluştur'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Card(
      color: DutyPlannerColors.success.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DutyPlannerColors.success,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Plan Başarıyla Oluşturuldu!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: DutyPlannerColors.success,
                    ),
                  ),
                  Text(
                    '${widget.generatedPlan!.assignments.length} nöbet ataması yapıldı',
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
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: DutyPlannerColors.tableHeader,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: DutyPlannerColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(color: DutyPlannerColors.textSecondary),
        ),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Future<void> _generatePlan() async {
    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      // Kısa bir gecikme ekleyelim (UX için)
      await Future.delayed(const Duration(milliseconds: 500));

      final plan = _scheduler.generatePlan(
        teachers: widget.teachers,
        floors: widget.floors,
        planType: widget.planType,
        startDate: widget.startDate,
        endDate: widget.endDate,
      );

      widget.onPlanGenerated(plan);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }
}
