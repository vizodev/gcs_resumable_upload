import 'package:gcs_resumable_upload/gcs_resumable_upload.dart';

class _FileMeta {
  List<String> checksums;
  int chunkSize;
  int fileSize;
  bool started;

  _FileMeta({
    required this.checksums,
    required this.chunkSize,
    required this.fileSize,
    required this.started,
  });
}

class FileMeta {
  int chunkSize;
  int fileSize;

  late _FileMeta _meta;

  FileMeta({
    required String id,
    required IStorage storage,
    required this.chunkSize,
    required this.fileSize,
  }) {
    _meta = _FileMeta(
      checksums: [],
      chunkSize: chunkSize,
      fileSize: fileSize,
      started: false,
    );
  }

  isResumable() {
    final meta = _getMeta();
    return meta.started && chunkSize == meta.chunkSize;
  }

  getFileSize() {
    final meta = _getMeta();
    return meta.fileSize;
  }

  reset() {
    // TODO: Reset meta in storage
    _meta = _FileMeta(
      checksums: [],
      chunkSize: chunkSize,
      fileSize: fileSize,
      started: false,
    );
  }

  _FileMeta _getMeta() {
    return _meta;
  }

  addChecksum(int index, String checksum) {
    final meta = _getMeta();
    if (meta.checksums.length == index) {
      meta.checksums.add(checksum);
    } else {
      meta.checksums[index] = checksum;
    }
    meta.started = true;
    setMeta(meta);
  }

  setMeta(_FileMeta meta) {
    _meta = meta;
  }

  getChecksum(int index) {
    final meta = _getMeta();
    return meta.checksums[index];
  }

  getResumeIndex() {
    final meta = _getMeta();
    return meta.checksums.length;
  }
}
