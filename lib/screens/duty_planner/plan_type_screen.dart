/// Plan Type Screen
/// Adım 3: Plan türü seçimi ekranı

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/duty_planner_models.dart';
import '../../theme/duty_planner_theme.dart';

/// Plan türü seçim ekranı
class PlanTypeScreen extends StatelessWidget {
  final DutyPlanType selectedType;
  final DateTime startDate;
  final DateTime endDate;
  final Function(DutyPlanType) onTypeChanged;
  final Function(DateTime) onStartDateChanged;
  final Function(DateTime) onEndDateChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const PlanTypeScreen({
    super.key,
    required this.selectedType,
    required this.startDate,
    required this.endDate,
    required this.onTypeChanged,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onNext,
    required this.onBack,
  });

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

              // Plan türü seçenekleri
              _buildPlanTypeCards(context),
              const SizedBox(height: 24),

              // Başlangıç ve bitiş tarihi seçimi
              _buildDatePickers(context),
              const SizedBox(height: 24),

              // Özet
              _buildSummary(context),
              const SizedBox(height: 24),

              // Navigasyon butonları
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onBack,
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
                      onPressed: _isValidDateRange() ? onNext : null,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Devam Et'),
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

  /// Tarih aralığı geçerli mi kontrol et
  bool _isValidDateRange() {
    return !endDate.isBefore(startDate);
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
                Icons.calendar_today,
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
                    'Adım 3: Plan Türü Seçimi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Oluşturulacak plan türünü ve tarih aralığını seçin',
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

  Widget _buildPlanTypeCards(BuildContext context) {
    final isMobile = DutyPlannerTheme.isMobile(context);

    final cards = DutyPlanType.values.map((type) {
      return _buildPlanTypeCard(type);
    }).toList();

    if (isMobile) {
      return Column(children: cards);
    } else {
      return Row(children: cards.map((card) => Expanded(child: card)).toList());
    }
  }

  Widget _buildPlanTypeCard(DutyPlanType type) {
    final isSelected = selectedType == type;

    IconData icon;
    String description;

    switch (type) {
      case DutyPlanType.weekly:
        icon = Icons.view_week;
        description = 'Bir haftalık (5 iş günü) nöbet planı';
        break;
      case DutyPlanType.monthly:
        icon = Icons.calendar_view_month;
        description = 'Bir aylık nöbet planı';
        break;
      case DutyPlanType.yearly:
        icon = Icons.calendar_today;
        description = 'Yıl sonuna kadar nöbet planı';
        break;
    }

    return Card(
      margin: const EdgeInsets.all(4),
      color: isSelected ? DutyPlannerColors.primary : DutyPlannerColors.card,
      child: InkWell(
        onTap: () => onTypeChanged(type),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 48,
                color: isSelected ? Colors.white : DutyPlannerColors.primary,
              ),
              const SizedBox(height: 12),
              Text(
                type.displayName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : DutyPlannerColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? Colors.white70
                      : DutyPlannerColors.textSecondary,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check,
                        size: 16,
                        color: DutyPlannerColors.primary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Seçili',
                        style: TextStyle(
                          color: DutyPlannerColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickers(BuildContext context) {
    final dateFormat = DateFormat('dd MMMM yyyy', 'tr');
    final isValidRange = _isValidDateRange();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlangıç Tarihi
            const Text(
              'Başlangıç Tarihi',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectStartDate(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: DutyPlannerColors.tableBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event, color: DutyPlannerColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      dateFormat.format(startDate),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: DutyPlannerColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bitiş Tarihi
            const Text(
              'Bitiş Tarihi',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectEndDate(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isValidRange
                        ? DutyPlannerColors.tableBorder
                        : DutyPlannerColors.error,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event,
                      color: isValidRange
                          ? DutyPlannerColors.primary
                          : DutyPlannerColors.error,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      dateFormat.format(endDate),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isValidRange
                            ? DutyPlannerColors.textPrimary
                            : DutyPlannerColors.error,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: DutyPlannerColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),

            // Hata mesajı
            if (!isValidRange) ...[
              const SizedBox(height: 8),
              const Text(
                'Bitiş tarihi başlangıç tarihinden önce olamaz',
                style: TextStyle(color: DutyPlannerColors.error, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Card(
      color: DutyPlannerColors.tableHeader,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: DutyPlannerColors.primary,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Plan Özeti',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('Plan Türü', selectedType.displayName),
            _buildSummaryRow('Başlangıç', dateFormat.format(startDate)),
            _buildSummaryRow('Bitiş', dateFormat.format(endDate)),
            _buildSummaryRow('Yaklaşık İş Günü', '${_calculateWorkDays()} gün'),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: DutyPlannerColors.textSecondary),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('tr', 'TR'),
    );

    if (picked != null) {
      onStartDateChanged(picked);
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate,
      firstDate: startDate,
      lastDate: DateTime.now().add(const Duration(days: 730)),
      locale: const Locale('tr', 'TR'),
    );

    if (picked != null) {
      onEndDateChanged(picked);
    }
  }

  int _calculateWorkDays() {
    if (endDate.isBefore(startDate)) return 0;

    int count = 0;
    var current = startDate;

    while (!current.isAfter(endDate)) {
      if (current.weekday >= DateTime.monday &&
          current.weekday <= DateTime.friday) {
        count++;
      }
      current = current.add(const Duration(days: 1));
    }

    return count;
  }
}
