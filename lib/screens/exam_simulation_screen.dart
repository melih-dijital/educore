import 'package:flutter/material.dart';
import '../services/butterfly_service.dart';

class ExamSimulationScreen extends StatefulWidget {
  const ExamSimulationScreen({super.key});

  @override
  State<ExamSimulationScreen> createState() => _ExamSimulationScreenState();
}

class _ExamSimulationScreenState extends State<ExamSimulationScreen> {
  final ButterflyService _service = ButterflyService();
  List<ExamSeat> _seats = [];
  String? _error;

  void _runSimulation() {
    setState(() {
      _error = null;
    });

    try {
      // Mock Data: 20 Students from mixture of 9-A, 9-B, 10-A
      List<ExamStudent> students = [];

      // 8 students from 9-A
      for (int i = 0; i < 8; i++)
        students.add(ExamStudent(id: '9A-$i', groupCode: '9-A'));

      // 7 students from 10-B
      for (int i = 0; i < 7; i++)
        students.add(ExamStudent(id: '10B-$i', groupCode: '10-B'));

      // 5 students from 11-C
      for (int i = 0; i < 5; i++)
        students.add(ExamStudent(id: '11C-$i', groupCode: '11-C'));

      // 1 Hall with capacity 20 (Grid 4x5)
      Map<String, int> halls = {'Salon 1': 20};

      final result = _service.distributeStudents(students, halls);

      setState(() {
        _seats = result..sort((a, b) => a.seatNumber.compareTo(b.seatNumber));
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelebek Sınav Dağıtım Simülasyonu'),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Senaryo: 20 Öğrenci (8x 9-A, 7x 10-B, 5x 11-C)',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _runSimulation,
                  icon: const Icon(Icons.shuffle),
                  label: const Text('Dağıtımı Başlat'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _seats.isEmpty
                ? const Center(child: Text('Başlamak için butona basın'))
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5, // 5 columns
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.5,
                          ),
                      itemCount: _seats.length,
                      itemBuilder: (context, index) {
                        final seat = _seats[index];
                        final group = seat.occupiedBy?.groupCode ?? '-';

                        // Color coding for groups
                        Color color = Colors.grey.shade200;
                        if (group == '9-A') color = Colors.blue.shade100;
                        if (group == '10-B') color = Colors.orange.shade100;
                        if (group == '11-C') color = Colors.green.shade100;

                        return Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Sıra ${seat.seatNumber}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                group,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
