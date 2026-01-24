import 'dart:math';

/// Represents a student to be placed.
class ExamStudent {
  final String id;
  final String groupCode; // e.g. "9-A" - Critical for butterfly logic

  ExamStudent({required this.id, required this.groupCode});
}

/// Represents a seat in a hall.
class ExamSeat {
  final String hallId;
  final int seatNumber;
  ExamStudent? occupiedBy;

  ExamSeat({required this.hallId, required this.seatNumber});
}

/// Service to handle Butterfly Exam Placement logic.
class ButterflyService {
  /// Main function to distribute students into halls using Butterfly Logic.
  ///
  /// [students]: List of all students to be placed.
  /// [halls]: Map where Key is Hall ID and Value is Capacity.
  /// Returns a list of [ExamSeat] with assignments.
  List<ExamSeat> distributeStudents(
    List<ExamStudent> students,
    Map<String, int> halls,
  ) {
    // 1. Prepare Seats
    List<ExamSeat> allSeats = [];
    halls.forEach((hallId, capacity) {
      for (int i = 1; i <= capacity; i++) {
        allSeats.add(ExamSeat(hallId: hallId, seatNumber: i));
      }
    });

    if (students.length > allSeats.length) {
      throw Exception(
        'Yetersiz Kapasite: ${students.length} öğrenci var ama ${allSeats.length} koltuk var.',
      );
    }

    // 2. Group Students by Class (e.g. "9-A": [s1, s2...])
    Map<String, List<ExamStudent>> studentsByGroup = {};
    for (var s in students) {
      studentsByGroup.putIfAbsent(s.groupCode, () => []).add(s);
    }

    // 3. Sort groups by size (Largest first - Greedy approach)
    var sortedGroups = studentsByGroup.keys.toList()
      ..sort(
        (a, b) =>
            studentsByGroup[b]!.length.compareTo(studentsByGroup[a]!.length),
      );

    // 4. Round-Robin Distribution (Modified)
    // We will iterate through seats and pick students from different groups cyclically.
    int currentGroupIndex = 0;

    // Shuffle sorted groups slightly if we want more randomness,
    // but strict round robin (Group A, Group B, Group C...) guarantees separation
    // better than random if groups are balanced.

    for (var seat in allSeats) {
      // If no students left, break
      if (studentsByGroup.values.every((list) => list.isEmpty)) break;

      // Try to find a valid student for this seat
      bool placed = false;
      int attempts = 0;
      int maxAttempts = sortedGroups.length;

      while (!placed && attempts < maxAttempts) {
        String candidateGroup = sortedGroups[currentGroupIndex];
        List<ExamStudent>? candidates = studentsByGroup[candidateGroup];

        if (candidates != null && candidates.isNotEmpty) {
          seat.occupiedBy = candidates.removeLast();
          placed = true;
        }

        // Move to next group for the next seat
        currentGroupIndex = (currentGroupIndex + 1) % sortedGroups.length;
        attempts++;
      }
    }

    return allSeats.where((s) => s.occupiedBy != null).toList();
  }
}
