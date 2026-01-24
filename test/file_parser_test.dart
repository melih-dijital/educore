import 'package:flutter_test/flutter_test.dart';
import 'package:educore/services/file_parser_service.dart';
import 'package:educore/models/duty_planner_models.dart';

void main() {
  group('FileParserService Tests', () {
    late FileParserService parser;

    setUp(() {
      parser = FileParserService();
    });

    group('CSV Parsing', () {
      test('Geçerli CSV dosyasından öğretmen listesi', () {
        const csvContent = '''Öğretmen Adı,Branş,Müsait Olmayan Günler
Ali Yılmaz,Matematik,
Ayşe Kaya,Türkçe,1
Mehmet Demir,Fizik,1;5
Fatma Şahin,Kimya,''';

        final teachers = parser.parseCsv(csvContent);

        expect(teachers.length, 4);
        expect(teachers[0].name, 'Ali Yılmaz');
        expect(teachers[0].branch, 'Matematik');
        expect(teachers[0].unavailableDays, isEmpty);

        expect(teachers[1].name, 'Ayşe Kaya');
        expect(teachers[1].unavailableDays, [1]);

        expect(teachers[2].name, 'Mehmet Demir');
        expect(teachers[2].unavailableDays, [1, 5]);
      });

      test('Sadece header olan CSV - boş liste döner', () {
        const csvContent = 'Öğretmen Adı,Branş,Müsait Olmayan Günler';

        final teachers = parser.parseCsv(csvContent);

        expect(teachers, isEmpty);
      });

      test('Boş CSV - boş liste döner', () {
        const csvContent = '';

        final teachers = parser.parseCsv(csvContent);

        expect(teachers, isEmpty);
      });

      test('İsim eksik satırlar atlanır', () {
        const csvContent = '''Öğretmen Adı,Branş,Müsait Olmayan Günler
Ali Yılmaz,Matematik,
,Türkçe,1
Mehmet Demir,Fizik,''';

        final teachers = parser.parseCsv(csvContent);

        expect(teachers.length, 2);
        expect(teachers[0].name, 'Ali Yılmaz');
        expect(teachers[1].name, 'Mehmet Demir');
      });

      test('CSV önizleme', () {
        const csvContent = '''Öğretmen Adı,Branş,Müsait Olmayan Günler
Ali Yılmaz,Matematik,
Ayşe Kaya,Türkçe,1
Mehmet Demir,Fizik,1;5
Fatma Şahin,Kimya,
Ahmet Kara,Biyoloji,''';

        final preview = parser.previewCsv(csvContent, maxRows: 3);

        expect(preview.hasError, isFalse);
        expect(preview.totalRows, 6); // Header + 5 veri
        expect(preview.rows.length, 4); // Header + 3 veri (maxRows)
        expect(preview.rows.first.isHeader, isTrue);
      });
    });

    group('Teacher.fromRow', () {
      test('Müsaitlik günleri doğru parse edilmeli', () {
        final teacher = Teacher.fromRow(
          name: 'Test',
          branch: 'Test',
          unavailableDaysStr: '1;3;5',
        );

        expect(teacher.unavailableDays, [1, 3, 5]);
      });

      test('Boş müsaitlik string - boş liste', () {
        final teacher = Teacher.fromRow(
          name: 'Test',
          branch: 'Test',
          unavailableDaysStr: '',
        );

        expect(teacher.unavailableDays, isEmpty);
      });

      test('Null müsaitlik string - boş liste', () {
        final teacher = Teacher.fromRow(
          name: 'Test',
          branch: 'Test',
          unavailableDaysStr: null,
        );

        expect(teacher.unavailableDays, isEmpty);
      });

      test('Geçersiz gün numaraları filtrelenmeli', () {
        final teacher = Teacher.fromRow(
          name: 'Test',
          branch: 'Test',
          unavailableDaysStr: '0;1;8;abc;3',
        );

        // Sadece 1-7 arası geçerli
        expect(teacher.unavailableDays, [1, 3]);
      });

      test('Boşluklar temizlenmeli', () {
        final teacher = Teacher.fromRow(
          name: '  Ali Yılmaz  ',
          branch: '  Matematik  ',
          unavailableDaysStr: ' 1 ; 3 ; 5 ',
        );

        expect(teacher.name, 'Ali Yılmaz');
        expect(teacher.branch, 'Matematik');
        expect(teacher.unavailableDays, [1, 3, 5]);
      });
    });

    group('Floor Model', () {
      test('Floor.create - yeni kat oluşturma', () {
        final floor = Floor.create('1. Kat', 1);

        expect(floor.name, '1. Kat');
        expect(floor.order, 1);
        expect(floor.id, isNotEmpty);
      });

      test('Floor.copyWith - sıra güncelleme', () {
        final floor = Floor.create('1. Kat', 1);
        final updated = floor.copyWith(order: 3);

        expect(updated.id, floor.id);
        expect(updated.name, '1. Kat');
        expect(updated.order, 3);
      });
    });

    group('FilePreviewResult', () {
      test('Hata durumu', () {
        final result = FilePreviewResult(
          rows: [],
          totalRows: 0,
          error: 'Test hatası',
        );

        expect(result.hasError, isTrue);
        expect(result.isEmpty, isTrue);
      });

      test('Başarılı önizleme', () {
        final result = FilePreviewResult(
          rows: [
            PreviewRow(cells: ['A', 'B'], isHeader: true),
            PreviewRow(cells: ['1', '2']),
          ],
          totalRows: 10,
        );

        expect(result.hasError, isFalse);
        expect(result.isEmpty, isFalse);
        expect(result.rows.first.isHeader, isTrue);
      });
    });
  });
}
