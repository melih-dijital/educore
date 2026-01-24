/// File Parser Service
/// Excel ve CSV dosya okuma servisi

import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import '../models/duty_planner_models.dart';

/// Dosya okuma ve öğretmen listesi oluşturma servisi
class FileParserService {
  // Singleton pattern
  static final FileParserService _instance = FileParserService._internal();
  factory FileParserService() => _instance;
  FileParserService._internal();

  /// Excel dosyasını parse et ve önizleme döndür
  /// maxRows: Önizleme için yüklenecek maksimum satır (tüm satırlar için null)
  FilePreviewResult previewExcel(Uint8List bytes, {int? maxRows = 100}) {
    try {
      final excel = Excel.decodeBytes(bytes);
      final rows = <PreviewRow>[];
      int totalRows = 0;

      // İlk sheet'i al
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];

      if (sheet == null || sheet.rows.isEmpty) {
        return FilePreviewResult(rows: [], totalRows: 0, error: 'Dosya boş');
      }

      totalRows = sheet.rows.length;
      final rowLimit = maxRows ?? sheet.rows.length;

      // Header ve tüm satırları al
      for (int i = 0; i < sheet.rows.length && i < rowLimit; i++) {
        final row = sheet.rows[i];
        final cells = row.map((cell) => cell?.value?.toString() ?? '').toList();
        rows.add(PreviewRow(cells: cells, isHeader: i == 0));
      }

      return FilePreviewResult(rows: rows, totalRows: totalRows);
    } catch (e) {
      return FilePreviewResult(
        rows: [],
        totalRows: 0,
        error: 'Excel dosyası okunamadı: $e',
      );
    }
  }

  /// CSV dosyasını parse et ve önizleme döndür
  FilePreviewResult previewCsv(String content, {int maxRows = 5}) {
    try {
      // Handle both Windows (\r\n) and Unix (\n) line endings
      final normalizedContent = content.replaceAll('\r\n', '\n');
      final csvRows = const CsvToListConverter(
        eol: '\n',
      ).convert(normalizedContent);
      final rows = <PreviewRow>[];

      if (csvRows.isEmpty) {
        return FilePreviewResult(rows: [], totalRows: 0, error: 'Dosya boş');
      }

      // Header ve ilk N satırı al
      for (int i = 0; i < csvRows.length && i <= maxRows; i++) {
        final cells = csvRows[i].map((cell) => cell.toString()).toList();
        rows.add(PreviewRow(cells: cells, isHeader: i == 0));
      }

      return FilePreviewResult(rows: rows, totalRows: csvRows.length);
    } catch (e) {
      return FilePreviewResult(
        rows: [],
        totalRows: 0,
        error: 'CSV dosyası okunamadı: $e',
      );
    }
  }

  /// Excel dosyasından öğretmen listesi oluştur
  /// Beklenen format: Öğretmen Adı, Branş, Müsait Olmayan Günler (opsiyonel)
  /// Not: İlk sütun sıra numarası ise otomatik atlanır
  List<Teacher> parseExcel(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    final teachers = <Teacher>[];

    // İlk sheet'i al
    final sheetName = excel.tables.keys.first;
    final sheet = excel.tables[sheetName];

    if (sheet == null || sheet.rows.length < 2) {
      return teachers;
    }

    // İlk sütunun sıra numarası olup olmadığını kontrol et
    // Eğer ilk veri satırındaki ilk hücre sayı ise, sütunları 1'den başlat
    int nameCol = 0;
    int branchCol = 1;
    int unavailableCol = 2;

    // İlk veri satırını kontrol et
    if (sheet.rows.length > 1 && sheet.rows[1].isNotEmpty) {
      final firstCellValue = sheet.rows[1][0]?.value;
      final firstCellStr = firstCellValue?.toString() ?? '';
      // İlk hücre sıra numarası gibi görünüyorsa (sadece rakam) sütunları kaydır
      if (firstCellStr.isNotEmpty && int.tryParse(firstCellStr) != null) {
        nameCol = 1;
        branchCol = 2;
        unavailableCol = 3;
        print(
          'DEBUG: First column appears to be row numbers, shifting columns',
        );
      }
    }

    // Header'ı atla, veri satırlarını işle
    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.isEmpty) continue;

      final name = row.length > nameCol
          ? row[nameCol]?.value?.toString() ?? ''
          : '';
      final branch = row.length > branchCol
          ? row[branchCol]?.value?.toString() ?? ''
          : '';
      final unavailable = row.length > unavailableCol
          ? row[unavailableCol]?.value?.toString()
          : null;

      if (name.trim().isEmpty) continue;

      teachers.add(
        Teacher.fromRow(
          name: name,
          branch: branch,
          unavailableDaysStr: unavailable,
        ),
      );
    }

    return teachers;
  }

  /// CSV dosyasından öğretmen listesi oluştur
  /// Beklenen format: Öğretmen Adı, Branş, Müsait Olmayan Günler (opsiyonel)
  List<Teacher> parseCsv(String content) {
    // Handle both Windows (\r\n) and Unix (\n) line endings
    final normalizedContent = content.replaceAll('\r\n', '\n');
    final csvRows = const CsvToListConverter(
      eol: '\n',
    ).convert(normalizedContent);
    final teachers = <Teacher>[];

    if (csvRows.length < 2) {
      return teachers;
    }

    // Header'ı atla, veri satırlarını işle
    for (int i = 1; i < csvRows.length; i++) {
      final row = csvRows[i];
      if (row.isEmpty) continue;

      final name = row.length > 0 ? row[0].toString() : '';
      final branch = row.length > 1 ? row[1].toString() : '';
      final unavailable = row.length > 2 ? row[2].toString() : null;

      if (name.trim().isEmpty) continue;

      teachers.add(
        Teacher.fromRow(
          name: name,
          branch: branch,
          unavailableDaysStr: unavailable,
        ),
      );
    }

    return teachers;
  }
}
