/// Step Progress Indicator Widget
/// 5 adımlı ilerleme göstergesi

import 'package:flutter/material.dart';
import '../theme/duty_planner_theme.dart';

/// Adım durumu
enum StepStatus { completed, active, inactive }

/// Adım veri modeli
class StepData {
  final String title;
  final IconData icon;
  final StepStatus status;

  const StepData({
    required this.title,
    required this.icon,
    required this.status,
  });
}

/// 5 adımlı ilerleme göstergesi widget'ı
class StepProgressIndicator extends StatelessWidget {
  final int currentStep;
  final List<StepData> steps;
  final Function(int)? onStepTapped;

  const StepProgressIndicator({
    super.key,
    required this.currentStep,
    required this.steps,
    this.onStepTapped,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = DutyPlannerTheme.isMobile(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 16,
        vertical: 16,
      ),
      child: isMobile
          ? _buildMobileIndicator(context)
          : _buildDesktopIndicator(context),
    );
  }

  /// Mobil görünüm - sadece noktalar ve çizgiler
  Widget _buildMobileIndicator(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(steps.length * 2 - 1, (index) {
            if (index.isEven) {
              final stepIndex = index ~/ 2;
              return _buildStepCircle(context, stepIndex, compact: true);
            } else {
              final stepIndex = index ~/ 2;
              return _buildConnectorLine(stepIndex);
            }
          }),
        ),
        const SizedBox(height: 8),
        Text(
          steps[currentStep].title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: DutyPlannerColors.primary,
          ),
        ),
      ],
    );
  }

  /// Masaüstü görünüm - tam genişlik
  Widget _buildDesktopIndicator(BuildContext context) {
    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isEven) {
          final stepIndex = index ~/ 2;
          return _buildStepItem(context, stepIndex);
        } else {
          return _buildExpandedConnectorLine(index ~/ 2);
        }
      }),
    );
  }

  /// Adım öğesi (masaüstü)
  Widget _buildStepItem(BuildContext context, int stepIndex) {
    final step = steps[stepIndex];
    final isCompleted = stepIndex < currentStep;
    final isActive = stepIndex == currentStep;

    return GestureDetector(
      onTap: isCompleted || isActive
          ? () => onStepTapped?.call(stepIndex)
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStepCircle(context, stepIndex),
          const SizedBox(height: 8),
          Text(
            step.title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive
                  ? DutyPlannerColors.primary
                  : isCompleted
                  ? DutyPlannerColors.success
                  : DutyPlannerColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  /// Adım dairesi
  Widget _buildStepCircle(
    BuildContext context,
    int stepIndex, {
    bool compact = false,
  }) {
    final step = steps[stepIndex];
    final isCompleted = stepIndex < currentStep;
    final isActive = stepIndex == currentStep;

    Color backgroundColor;
    Color iconColor;

    if (isCompleted) {
      backgroundColor = DutyPlannerColors.success;
      iconColor = Colors.white;
    } else if (isActive) {
      backgroundColor = DutyPlannerColors.primary;
      iconColor = Colors.white;
    } else {
      backgroundColor = DutyPlannerColors.stepInactive;
      iconColor = DutyPlannerColors.textHint;
    }

    final size = compact ? 28.0 : 40.0;
    final iconSize = compact ? 16.0 : 20.0;

    return GestureDetector(
      onTap: isCompleted || isActive
          ? () => onStepTapped?.call(stepIndex)
          : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: DutyPlannerColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          isCompleted ? Icons.check : step.icon,
          color: iconColor,
          size: iconSize,
        ),
      ),
    );
  }

  /// Bağlantı çizgisi (compact)
  Widget _buildConnectorLine(int beforeStepIndex) {
    final isCompleted = beforeStepIndex < currentStep;

    return Container(
      width: 24,
      height: 2,
      color: isCompleted
          ? DutyPlannerColors.success
          : DutyPlannerColors.stepInactive,
    );
  }

  /// Genişleyen bağlantı çizgisi (masaüstü)
  Widget _buildExpandedConnectorLine(int beforeStepIndex) {
    final isCompleted = beforeStepIndex < currentStep;

    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 28),
        color: isCompleted
            ? DutyPlannerColors.success
            : DutyPlannerColors.stepInactive,
      ),
    );
  }
}

/// Varsayılan adımlar
List<StepData> getDefaultDutyPlannerSteps(int currentStep) {
  return [
    StepData(
      title: 'Öğretmenler',
      icon: Icons.people_outline,
      status: currentStep > 0
          ? StepStatus.completed
          : currentStep == 0
          ? StepStatus.active
          : StepStatus.inactive,
    ),
    StepData(
      title: 'Katlar',
      icon: Icons.layers_outlined,
      status: currentStep > 1
          ? StepStatus.completed
          : currentStep == 1
          ? StepStatus.active
          : StepStatus.inactive,
    ),
    StepData(
      title: 'Plan Türü',
      icon: Icons.calendar_today_outlined,
      status: currentStep > 2
          ? StepStatus.completed
          : currentStep == 2
          ? StepStatus.active
          : StepStatus.inactive,
    ),
    StepData(
      title: 'Oluştur',
      icon: Icons.auto_fix_high_outlined,
      status: currentStep > 3
          ? StepStatus.completed
          : currentStep == 3
          ? StepStatus.active
          : StepStatus.inactive,
    ),
    StepData(
      title: 'İndir',
      icon: Icons.download_outlined,
      status: currentStep > 4
          ? StepStatus.completed
          : currentStep == 4
          ? StepStatus.active
          : StepStatus.inactive,
    ),
  ];
}
