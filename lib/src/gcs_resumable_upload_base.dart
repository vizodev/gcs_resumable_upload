import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:gcs_resumable_upload/src/errors/errors.dart';
import 'package:gcs_resumable_upload/src/file_meta.dart';
import 'package:gcs_resumable_upload/src/file_processor.dart';
import 'package:gcs_resumable_upload/src/helpers/http.dart';

abstract class IStorage {}

class DartStorage implements IStorage {}

const MIN_CHUNK_SIZE = 262144;

bool finished = false;

class Upload {
  late FileMeta _meta;
  late FileProcessor _processor;
  UploadOptions? options;
  String url;

  late String _location;

  Function(int bytesSent, int totalBytes)? onProgress;

  Upload(
    String id,
    this.url,
    File file, {
    this.options,
    IStorage? storage,
    this.onProgress,
  }) {
    _meta = FileMeta(
      id: id,
      storage: storage ?? DartStorage(),
      fileSize: file.lengthSync(),
      chunkSize: options?.chunkSize ?? MIN_CHUNK_SIZE,
    );

    _processor = FileProcessor(
      file: file,
      chunkSize: _meta.chunkSize,
      fileSize: _meta.fileSize,
    );
  }

  Future<void> start() async {
    //

    if (finished) {
      throw UploadAlreadyFinishedError();
    }

    if (_meta.isResumable() && _meta.getFileSize() == _meta.fileSize) {
      await _resumeUpload();
    } else {
      await _startUpload();
    }

    _meta.reset();
    finished = true;
  }

  Future<void> _resumeUpload() async {
    int localResumeIndex = _meta.getResumeIndex();
    int remoteResumeIndex = await _getRemoteResumeIndex();

    final resumeIndex = min(localResumeIndex, remoteResumeIndex);

    try {
      await _processor.run(_validateChunk,
          startIndex: 0, endIndex: resumeIndex);
    } catch (e) {
      await _processor.run(_uploadChunk);
      return;
    }
  }

  Future<bool> _uploadChunk({
    required List<int> chunk,
    required int index,
    required String checksum,
  }) async {
    final total = _meta.fileSize;
    final start = index * _meta.chunkSize;
    final end = start + chunk.length - 1;

    print('Uploading chunk $index ($start-$end/$total)');
    print('Checksum: $checksum');
    print('Chunk size: ${chunk.length}');

    final headers = {
      'content-type': options?.contentType ?? 'application/octet-stream',
      'content-range': 'bytes $start-$end/$total',
      'x-goog-hash': 'crc32c=$checksum',
      'x-goog-resumable': 'start',
    };

    if (options?.metadata != null) {
      options!.metadata!.forEach((key, value) {
        headers['x-goog-meta-$key'] = value;
      });
    }

    final res = await HttpProvider.put(
      url: _location,
      headers: headers,
      data: Stream.fromIterable(chunk.map((e) => [e])),
    );

    _meta.addChecksum(index, checksum);

    onProgress?.call(end + 1, total);

    return true;
  }

  Future<bool> _validateChunk({
    required List<int> chunk,
    required int index,
    required String checksum,
  }) async {
    final originalChecksum = await _meta.getChecksum(index);
    final isChunkValid = checksum == originalChecksum;
    if (!isChunkValid) {
      _meta.reset();
      throw DifferentChunkError(index, originalChecksum, checksum);
    }
    return true;
  }

  Future<int> _getRemoteResumeIndex() async {
    final headers = {
      'content-range': 'bytes */${_meta.fileSize}',
    };

    final res = await HttpProvider.put(
      url: url,
      headers: headers,
    );

    final header = res.headers.value('range')!;

    final range = RegExp('(d+?)-(d+?)').allMatches(header);
    final bytesReceived = (int.tryParse(range.elementAt(2).input) ?? -1) + 1;
    return (bytesReceived / _meta.chunkSize).floor();
  }

  _startUpload() async {
    Map<String, String> headers = {
      'x-goog-resumable': 'start',
      'content-type': options?.contentType ?? 'application/octet-stream',
    };
    if (options?.metadata != null) {
      options!.metadata!.forEach((key, value) {
        headers['x-goog-meta-$key'] = value;
      });
    }

    final res = await HttpProvider.post(
      url: url,
      headers: headers,
    );

    _location = res.headers.value('location')!;

    await _processor.run(_uploadChunk);
  }
}

class UploadOptions {
  int? chunkSize;
  String? contentType;
  Map<String, String>? metadata;

  UploadOptions({
    this.chunkSize,
    this.contentType,
    this.metadata,
  }) {
    _validateChunkSize(chunkSize);
  }

  _validateChunkSize(int? chunkSize) {
    if (chunkSize != null &&
        (chunkSize < 256 * 1024 || chunkSize > 32 * 1024 * 1024)) {
      throw InvalidChunkSizeError(chunkSize);
    }
  }
}
