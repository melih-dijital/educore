import '../models/planning_models.dart';

/// Service to manage planning logic and data.
class PlanningService {
  // Singleton pattern for easy access in this simple example
  static final PlanningService _instance = PlanningService._internal();
  factory PlanningService() => _instance;
  PlanningService._internal();

  // In-memory storage for demo purposes
  final List<AcademicYear> _years = [];
  final List<Term> _terms = [];
  final List<Holiday> _holidays = [];
  DataLockRule? _activeLockRule;

  /// Creates and registers a new Academic Year.
  AcademicYear createAcademicYear(String name, DateTime start, DateTime end) {
    // Determine status based on current date (simplified logic)
    var status = AcademicYearStatus.draft;
    final now = DateTime.now();
    if (now.isAfter(start) && now.isBefore(end)) {
      status = AcademicYearStatus.active;
    }

    final newYear = AcademicYear(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Simple ID gen
      name: name,
      startDate: start,
      endDate: end,
      status: status,
    );
    _years.add(newYear);
    return newYear;
  }

  /// Adds a term to an academic year.
  void addTerm(String yearId, String name, DateTime start, DateTime end) {
    final term = Term(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      academicYearId: yearId,
      name: name,
      startDate: start,
      endDate: end,
    );
    _terms.add(term);
  }

  /// Adds a holiday to an academic year.
  void addHoliday(
    String yearId,
    String name,
    DateTime start,
    DateTime end,
    HolidayType type,
  ) {
    final holiday = Holiday(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      academicYearId: yearId,
      name: name,
      startDate: start,
      endDate: end,
      type: type,
    );
    _holidays.add(holiday);
  }

  /// Sets the data locking rule for the system.
  void setLockRule(DataLockRule rule) {
    _activeLockRule = rule;
  }

  /// Checks if data for a specific date is currently locked.
  bool isDataLocked(DateTime date) {
    if (_activeLockRule == null) return false;

    // Example logic for Monthly locking
    if (_activeLockRule!.lockFrequency == LockFrequency.monthly) {
      final now = DateTime.now();

      // If the date is in a previous month relative to now
      if (date.year < now.year ||
          (date.year == now.year && date.month < now.month)) {
        // Calculate when that month should have been locked
        // End of that month + offset
        final nextMonth = DateTime(date.year, date.month + 1, 1);
        final endOfMonth = nextMonth.subtract(Duration(days: 1));
        final lockDate = _activeLockRule!.calculateLockDate(endOfMonth);

        // If we are past the lock date, it's locked
        if (now.isAfter(lockDate)) {
          return true;
        }
      }
    }
    return false;
  }
}
