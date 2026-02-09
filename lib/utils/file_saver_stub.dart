import 'dart:typed_data';

void saveBytes({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) {
  throw UnsupportedError('File download is not supported on this platform.');
}
