/// Duty Plan Grid Widget
/// Kat ve gün bazlı nöbet planı grid görünümü

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/duty_planner_models.dart';
import '../theme/duty_planner_theme.dart';

/// Nöbet planı grid widget'ı
class DutyPlanGridWidget extends StatelessWidget {
  final DutyPlan plan;
  final List<Floor> floors;

  const DutyPlanGridWidget({
    super.key,
    required this.plan,
    required this.floors,
  });

  @override
  Widget build(BuildContext context) {
    final schoolDays = plan.getSchoolDays();
    final sortedFloors = List<Floor>.from(floors)
      ..sort((a, b) => a.order.compareTo(b.order));

    // Haftalara göre grupla
    final weeks = _groupByWeek(schoolDays);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: weeks.length,
      itemBuilder: (context, weekIndex) {
        return _buildWeekCard(
          context,
          weeks[weekIndex],
          sortedFloors,
          weekIndex,
        );
      },
    );
  }

  Widget _buildWeekCard(
    BuildContext context,
    List<DateTime> weekDays,
    List<Floor> sortedFloors,
    int weekIndex,
  ) {
    final dateFormat = DateFormat('dd.MM');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hafta başlığı
          if (_groupByWeek(plan.getSchoolDays()).length > 1)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: DutyPlannerColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Text(
                '${weekIndex + 1}. Hafta',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),

          // Tablo
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                DutyPlannerColors.tableHeader,
              ),
              dataRowMinHeight: 48,
              dataRowMaxHeight: 80,
              columnSpacing: 16,
              columns: [
                const DataColumn(
                  label: Text(
                    'Kat',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ...weekDays.map(
                  (day) => DataColumn(
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getDayName(day.weekday),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          dateFormat.format(day),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              rows: sortedFloors.map((floor) {
                return DataRow(
                  cells: [
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: DutyPlannerColors.primaryLight.withValues(
                            alpha: 0.2,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          floor.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    ...weekDays.map((day) {
                      // FloorName ile eşleştir (daha güvenilir)
                      final assignments = plan.assignments.where(
                        (a) =>
                            (a.floorId == floor.id ||
                                a.floorName == floor.name) &&
                            a.date.year == day.year &&
                            a.date.month == day.month &&
                            a.date.day == day.day,
                      );

                      // DEBUG: Grid değerlerini kontrol et
                      if (assignments.isNotEmpty) {
                        for (final a in assignments) {
                          print(
                            'GRID DEBUG: Showing teacherName="${a.teacherName}" for floor=${floor.name}, date=${day.day}/${day.month}',
                          );
                        }
                      }

                      return DataCell(
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: assignments.isEmpty
                              ? [
                                  const Text(
                                    '-',
                                    style: TextStyle(
                                      color: DutyPlannerColors.textHint,
                                    ),
                                  ),
                                ]
                              : assignments
                                    .map(
                                      (a) => _buildTeacherChip(a.teacherName),
                                    )
                                    .toList(),
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherChip(String name) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: DutyPlannerColors.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DutyPlannerColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        name,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: DutyPlannerColors.textPrimary,
        ),
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ['', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return days[weekday];
  }

  List<List<DateTime>> _groupByWeek(List<DateTime> days) {
    if (days.isEmpty) return [];

    final weeks = <List<DateTime>>[];
    var currentWeek = <DateTime>[];

    for (final day in days) {
      if (currentWeek.isEmpty || day.weekday >= currentWeek.last.weekday) {
        currentWeek.add(day);
      } else {
        weeks.add(currentWeek);
        currentWeek = [day];
      }
    }

    if (currentWeek.isNotEmpty) {
      weeks.add(currentWeek);
    }

    return weeks;
  }
}

/// Plan istatistikleri widget'ı
class DutyPlanStatisticsWidget extends StatelessWidget {
  final DutyPlan plan;
  final List<Teacher> teachers;

  const DutyPlanStatisticsWidget({
    super.key,
    required this.plan,
    required this.teachers,
  });

  @override
  Widget build(BuildContext context) {
    final dutyCounts = plan.getTeacherDutyCounts();

    if (dutyCounts.isEmpty) {
      return const SizedBox.shrink();
    }

    final counts = dutyCounts.values.toList();
    final minDuties = counts.reduce((a, b) => a < b ? a : b);
    final maxDuties = counts.reduce((a, b) => a > b ? a : b);
    final avgDuties = counts.reduce((a, b) => a + b) / counts.length;
    final isBalanced = (maxDuties - minDuties) <= 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: DutyPlannerColors.primary,
                ),
                SizedBox(width: 8),
                Text(
                  'Plan İstatistikleri',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // İstatistik satırları
            _buildStatRow('Toplam Atama', '${plan.assignments.length}'),
            _buildStatRow('Öğretmen Sayısı', '${dutyCounts.length}'),
            _buildStatRow('Min Nöbet', '$minDuties'),
            _buildStatRow('Max Nöbet', '$maxDuties'),
            _buildStatRow('Ortalama', avgDuties.toStringAsFixed(1)),

            const SizedBox(height: 12),

            // Denge durumu
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isBalanced
                    ? DutyPlannerColors.success.withValues(alpha: 0.1)
                    : DutyPlannerColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isBalanced ? Icons.check_circle : Icons.info,
                    color: isBalanced
                        ? DutyPlannerColors.success
                        : DutyPlannerColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isBalanced
                        ? 'Dağılım dengeli ✓'
                        : 'Dağılımda fark var (${maxDuties - minDuties} nöbet)',
                    style: TextStyle(
                      color: isBalanced
                          ? DutyPlannerColors.success
                          : DutyPlannerColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Öğretmen bazlı detay
            const Text(
              'Öğretmen Bazlı Dağılım',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ...teachers.take(10).map((teacher) {
              final count = dutyCounts[teacher.id] ?? 0;
              final percentage = maxDuties > 0 ? count / maxDuties : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        teacher.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: DutyPlannerColors.stepInactive,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          DutyPlannerColors.primary,
                        ),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$count',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (teachers.length > 10)
              Text(
                '... ve ${teachers.length - 10} öğretmen daha',
                style: const TextStyle(
                  fontSize: 12,
                  color: DutyPlannerColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: DutyPlannerColors.textSecondary),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
