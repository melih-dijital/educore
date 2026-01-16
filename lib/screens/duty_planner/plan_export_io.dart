/// Plan Export IO Helper
/// Mobile/Desktop platformları için dosya indirme yardımcısı
import 'dart:typed_data';

/// IO platformlarında bu fonksiyon kullanılmaz
/// (Printing paketi kullanılır)
void downloadFile(Uint8List bytes, String fileName, String mimeType) {
  // Bu fonksiyon IO platformlarında çağrılmaz
  // Sadece conditional import için gerekli
  throw UnsupportedError('downloadFile is only supported on web');
}
