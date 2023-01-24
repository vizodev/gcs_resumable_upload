class InvalidChunkSizeError extends Error {
  final int chunkSize;

  InvalidChunkSizeError(this.chunkSize);

  @override
  String toString() => 'Invalid chunk size: $chunkSize';
}

class UploadIncompleteError extends Error {
  final String url;

  UploadIncompleteError(this.url);

  @override
  String toString() => 'Upload incomplete';
}

class UploadAlreadyFinishedError extends Error {
  UploadAlreadyFinishedError();

  @override
  String toString() => 'Upload already finished';
}

class DifferentChunkError extends Error {
  final int index;
  final String checksum;
  final String newChecksum;

  DifferentChunkError(this.index, this.checksum, this.newChecksum);

  @override
  String toString() =>
      'Different chunk at index: $index; checksum: $checksum; newChecksum: $newChecksum';
}
