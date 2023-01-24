import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class FileProcessor {
  File file;
  int chunkSize;
  int fileSize;

  bool paused = false;

  List<Function> _unpauseHandlers = [];

  FileProcessor({
    required this.file,
    required this.chunkSize,
    required this.fileSize,
  });

  Future<void> run(
    Future<bool> Function(
            {required List<int> chunk,
            required int index,
            required String checksum})
        fn, {
    int startIndex = 0,
    int? endIndex,
  }) async {
    final totalChunks = (fileSize / chunkSize).ceil();

    await _processIndex(
      index: startIndex,
      totalChunks: totalChunks,
      fn: fn,
    );
  }

  Future<bool> _processIndex({
    required int index,
    required int totalChunks,
    required Future<bool> Function(
            {required List<int> chunk,
            required int index,
            required String checksum})
        fn,
    int? endIndex,
  }) async {
    if (index == totalChunks || index == endIndex) {
      return true;
    }

    if (paused) {
      await _waitForUnpause();
    }
    print(
        'Processing chunk $index/$totalChunks (endIndex: $endIndex; chunkSize: $chunkSize;)');
    final start = index * chunkSize;
    final chunk =
        Uint8List.fromList(await _readFile(file, start, start + chunkSize));
    print('Read chunk $index; ${chunk.length} bytes');
    final checksum = getChecksum(chunk);

    final shouldContinue = await fn(
      chunk: chunk,
      index: index,
      checksum: checksum,
    );

    if (!shouldContinue) {
      return false;
    }

    return _processIndex(
      index: index + 1,
      totalChunks: totalChunks,
      fn: fn,
      endIndex: endIndex,
    );
  }

  Future<List<int>> _readFile(File file, int start, int end) {
    final completer = Completer<List<int>>();
    int size = 0;
    List<int> data = [];
    file.openRead(start, end).listen((event) {
      size += event.length;
      data.addAll(event);
      if (size >= chunkSize) {
        completer.isCompleted ? null : completer.complete(data);
      }
    }, onDone: () {
      completer.isCompleted ? null : completer.complete(data);
    });

    return completer.future;
  }

  Future<void> _waitForUnpause() async {
    final completer = Completer<void>();

    _unpauseHandlers.add(() {
      completer.complete();
    });

    return completer.future;
  }

  pause() {
    paused = true;
  }

  unpause() {
    paused = false;

    for (final handler in _unpauseHandlers) {
      handler();
    }

    _unpauseHandlers = [];
  }

  String getChecksum(List<int> chunk) {
    return md5.convert(chunk).toString();
  }
}
