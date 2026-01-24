/// Enum representing the status of an Academic Year.
enum AcademicYearStatus { draft, active, archived }

/// Enum representing the type of a holiday.
enum HolidayType {
  publicHoliday, // Resmi Tatil
  schoolBreak, // Ara Tatil / Sömestr (renamed from 'break' to avoid keyword conflict)
  administrationOnly, // Sadece idari tatil
}

/// Enum for data locking frequency.
enum LockFrequency { monthly, weekly }

/// Represents a full academic year (e.g., 2025-2026).
class AcademicYear {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final AcademicYearStatus status;
  final bool isLocked;

  AcademicYear({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.status = AcademicYearStatus.draft,
    this.isLocked = false,
  });

  /// Check if a given date falls within this academic year.
  bool containsDate(DateTime date) {
    return date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
        date.isBefore(endDate.add(const Duration(seconds: 1)));
  }
}

/// Represents a term within an academic year (e.g., Semester 1).
class Term {
  final String id;
  final String academicYearId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? reportDueDate;

  Term({
    required this.id,
    required this.academicYearId,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.reportDueDate,
  });
}

/// Represents a holiday or break period.
class Holiday {
  final String id;
  final String academicYearId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final HolidayType type;

  Holiday({
    required this.id,
    required this.academicYearId,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.type,
  });
}

/// Configuration for a specific day in a weekly cycle.
class DayConfig {
  final String dayName; // e.g., "Monday"
  final int dayOfWeek; // 1 = Monday, 7 = Sunday (ISO 8601)
  final bool isSchoolDay;
  final int lessonCount;

  DayConfig({
    required this.dayName,
    required this.dayOfWeek,
    this.isSchoolDay = true,
    this.lessonCount = 8,
  });
}

/// Represents a weekly schedule cycle (e.g., Standard Week).
class WeeklyCycle {
  final String id;
  final String academicYearId;
  final String name;
  final List<DayConfig> days;
  final DateTime validFrom;
  final DateTime? validTo;

  WeeklyCycle({
    required this.id,
    required this.academicYearId,
    required this.name,
    required this.days,
    required this.validFrom,
    this.validTo,
  });
}

/// Represents a duty assignment for a teacher.
class DutyRoster {
  final String id;
  final DateTime date;
  final String teacherId;
  final String location; // e.g., "Garden", "Corridor A"
  final String role; // e.g., "Supervisor"

  DutyRoster({
    required this.id,
    required this.date,
    required this.teacherId,
    required this.location,
    required this.role,
  });
}

/// Rules for auto-locking historical data.
class DataLockRule {
  final String id;
  final LockFrequency lockFrequency;
  final int lockDayOffset; // e.g., 5 days after the period ends
  final bool manualOverride;

  DataLockRule({
    required this.id,
    required this.lockFrequency,
    required this.lockDayOffset,
    this.manualOverride = false,
  });

  /// Calculates the lock date for a given reference date (e.g., end of month).
  DateTime calculateLockDate(DateTime periodEndDate) {
    return periodEndDate.add(Duration(days: lockDayOffset));
  }
}
