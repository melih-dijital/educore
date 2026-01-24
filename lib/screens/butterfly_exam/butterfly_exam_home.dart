/// Butterfly Exam Home Screen
/// Kelebek sınav sistemi ana ekranı - adım wizard

import 'package:flutter/material.dart';
import '../../models/butterfly_exam_models.dart';
import '../../theme/duty_planner_theme.dart';
import 'section_entry_screen.dart';
import 'student_entry_screen.dart';
import 'room_config_screen.dart';
import 'distribution_screen.dart';

/// Kelebek sınav ana ekranı - wizard yapısı
class ButterflyExamHomeScreen extends StatefulWidget {
  const ButterflyExamHomeScreen({super.key});

  @override
  State<ButterflyExamHomeScreen> createState() =>
      _ButterflyExamHomeScreenState();
}

class _ButterflyExamHomeScreenState extends State<ButterflyExamHomeScreen> {
  int _currentStep = 0;

  // Paylaşılan veri
  List<ExamSection> _sections = [];
  List<ExamRoom> _rooms = [];
  String _examName = 'Sınav';
  ExamPlan? _generatedPlan;

  final List<String> _stepTitles = [
    'Şubeler',
    'Öğrenciler',
    'Salonlar',
    'Dağıtım',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelebek Sınav Dağıtımı'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Adım göstergesi
          _buildStepIndicator(),

          // İçerik
          Expanded(child: _buildCurrentStep()),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: DutyPlannerColors.tableHeader,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_stepTitles.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Bağlantı çizgisi
            return Expanded(
              child: Container(
                height: 2,
                color: index ~/ 2 < _currentStep
                    ? DutyPlannerColors.primary
                    : DutyPlannerColors.tableBorder,
              ),
            );
          }

          final stepIndex = index ~/ 2;
          final isActive = stepIndex == _currentStep;
          final isCompleted = stepIndex < _currentStep;

          return GestureDetector(
            onTap: isCompleted ? () => _goToStep(stepIndex) : null,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? DutyPlannerColors.success
                        : isActive
                        ? DutyPlannerColors.primary
                        : DutyPlannerColors.tableBorder,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : Text(
                            '${stepIndex + 1}',
                            style: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : DutyPlannerColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _stepTitles[stepIndex],
                  style: TextStyle(
                    fontSize: 11,
                    color: isActive
                        ? DutyPlannerColors.primary
                        : DutyPlannerColors.textSecondary,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return SectionEntryScreen(
          sections: _sections,
          onSectionsChanged: (sections) {
            setState(() => _sections = sections);
          },
          onNext: () => _goToStep(1),
        );
      case 1:
        return StudentEntryScreen(
          sections: _sections,
          onSectionsChanged: (sections) {
            setState(() => _sections = sections);
          },
          onNext: () => _goToStep(2),
          onBack: () => _goToStep(0),
        );
      case 2:
        return RoomConfigScreen(
          rooms: _rooms,
          examName: _examName,
          onRoomsChanged: (rooms) {
            setState(() => _rooms = rooms);
          },
          onExamNameChanged: (name) {
            setState(() => _examName = name);
          },
          onNext: () => _goToStep(3),
          onBack: () => _goToStep(1),
        );
      case 3:
        return DistributionScreen(
          sections: _sections,
          rooms: _rooms,
          examName: _examName,
          generatedPlan: _generatedPlan,
          onPlanGenerated: (plan) {
            setState(() => _generatedPlan = plan);
          },
          onBack: () => _goToStep(2),
          onRestart: _restart,
        );
      default:
        return const SizedBox();
    }
  }

  void _goToStep(int step) {
    if (step >= 0 && step < _stepTitles.length) {
      setState(() => _currentStep = step);
    }
  }

  void _restart() {
    setState(() {
      _currentStep = 0;
      _sections = [];
      _rooms = [];
      _examName = 'Sınav';
      _generatedPlan = null;
    });
  }
}
