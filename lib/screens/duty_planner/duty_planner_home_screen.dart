/// Duty Planner Home Screen
/// Ana navigasyon ekranı - 5 adımlı wizard

import 'package:flutter/material.dart';
import '../../models/duty_planner_models.dart';
import '../../theme/duty_planner_theme.dart';
import '../../widgets/step_progress_indicator.dart';
import 'teacher_upload_screen.dart';
import 'floor_management_screen.dart';
import 'plan_type_screen.dart';
import 'plan_generation_screen.dart';
import 'plan_export_screen.dart';

/// Nöbet Planlayıcı Ana Ekranı
class DutyPlannerHomeScreen extends StatefulWidget {
  const DutyPlannerHomeScreen({super.key});

  @override
  State<DutyPlannerHomeScreen> createState() => _DutyPlannerHomeScreenState();
}

class _DutyPlannerHomeScreenState extends State<DutyPlannerHomeScreen> {
  int _currentStep = 0;

  // Paylaşılan veri
  List<Teacher> _teachers = [];
  List<Floor> _floors = [];
  DutyPlanType _planType = DutyPlanType.weekly;
  DateTime _startDate = DateTime.now();
  DutyPlan? _generatedPlan;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: DutyPlannerTheme.theme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kat Nöbetçi Öğretmen Planlayıcı'),
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
        ),
        body: Column(
          children: [
            // İlerleme göstergesi
            StepProgressIndicator(
              currentStep: _currentStep,
              steps: getDefaultDutyPlannerSteps(_currentStep),
              onStepTapped: _canNavigateToStep,
            ),

            const Divider(height: 1),

            // Ana içerik
            Expanded(child: _buildCurrentStep()),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return TeacherUploadScreen(
          teachers: _teachers,
          onTeachersUpdated: (teachers) {
            setState(() => _teachers = teachers);
          },
          onNext: () => _goToStep(1),
        );
      case 1:
        return FloorManagementScreen(
          floors: _floors,
          onFloorsUpdated: (floors) {
            setState(() => _floors = floors);
          },
          onNext: () => _goToStep(2),
          onBack: () => _goToStep(0),
        );
      case 2:
        return PlanTypeScreen(
          selectedType: _planType,
          startDate: _startDate,
          onTypeChanged: (type) {
            setState(() => _planType = type);
          },
          onStartDateChanged: (date) {
            setState(() => _startDate = date);
          },
          onNext: () => _goToStep(3),
          onBack: () => _goToStep(1),
        );
      case 3:
        return PlanGenerationScreen(
          teachers: _teachers,
          floors: _floors,
          planType: _planType,
          startDate: _startDate,
          onPlanGenerated: (plan) {
            setState(() => _generatedPlan = plan);
          },
          generatedPlan: _generatedPlan,
          onNext: () => _goToStep(4),
          onBack: () => _goToStep(2),
        );
      case 4:
        return PlanExportScreen(
          plan: _generatedPlan!,
          floors: _floors,
          teachers: _teachers,
          onBack: () => _goToStep(3),
          onRestart: _restart,
        );
      default:
        return const Center(child: Text('Bilinmeyen adım'));
    }
  }

  void _goToStep(int step) {
    if (step >= 0 && step <= 4) {
      // Adım 4'e gitmek için plan oluşturulmuş olmalı
      if (step == 4 && _generatedPlan == null) {
        return;
      }
      setState(() => _currentStep = step);
    }
  }

  void _canNavigateToStep(int step) {
    // Sadece tamamlanmış veya mevcut adıma gidilebilir
    if (step <= _currentStep) {
      _goToStep(step);
    }
  }

  void _restart() {
    setState(() {
      _currentStep = 0;
      _teachers = [];
      _floors = [];
      _planType = DutyPlanType.weekly;
      _startDate = DateTime.now();
      _generatedPlan = null;
    });
  }
}
