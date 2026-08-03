import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ipfs_downloader/src/data/download_engine.dart';
import 'package:ipfs_downloader/src/domain/app_settings.dart';
import 'package:ipfs_downloader/src/domain/download_task.dart';
import 'package:path/path.dart' as path;

void main() {
  late Directory temporaryDirectory;
  final gateways = <_LocalGateway>[];
  final engines = <DownloadEngine>[];

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'ipfs-downloader-engine-',
    );
  });

  tearDown(() async {
    for (final engine in engines) {
      engine.close();
    }
    for (final gateway in gateways) {
      await gateway.close();
    }
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
    gateways.clear();
    engines.clear();
  });

  DownloadEngine createEngine({Duration progressInterval = Duration.zero}) {
    final engine = DownloadEngine(progressInterval: progressInterval);
    engines.add(engine);
    return engine;
  }

  Future<_LocalGateway> startGateway(
    Future<void> Function(HttpRequest request) handler,
  ) async {
    final gateway = await _LocalGateway.start(handler);
    gateways.add(gateway);
    return gateway;
  }

  AppSettings settingsFor(List<_LocalGateway> selectedGateways) => AppSettings(
    defaultDownloadDirectory: temporaryDirectory.path,
    gateways: selectedGateways
        .map((gateway) => gateway.origin)
        .toList(growable: false),
    connectionTimeoutSeconds: 5,
  );

  DownloadTask task({
    String id = 'task-1',
    String ipfsPath = 'folder/file.bin',
    String fileName = 'file.bin',
    DownloadStatus status = DownloadStatus.queued,
    int receivedBytes = 0,
    int? totalBytes,
    String? gateway,
    bool isDirectoryArchive = false,
    bool fileNameIsProvisional = false,
  }) => DownloadTask(
    id: id,
    cid: 'bafy-test-cid',
    ipfsPath: ipfsPath,
    fileName: fileName,
    destinationDirectory: temporaryDirectory.path,
    createdAt: DateTime.utc(2026, 7, 31),
    status: status,
    receivedBytes: receivedBytes,
    totalBytes: totalBytes,
    gateway: gateway,
    isDirectoryArchive: isDirectoryArchive,
    fileNameIsProvisional: fileNameIsProvisional,
  );

  test('streams a 200 response and atomically replaces the partial', () async {
    final payload = Uint8List.fromList(
      List<int>.generate(16384, (index) => index % 251),
    );
    String? requestedPath;
    String? acceptedEncoding;
    final gateway = await startGateway((request) async {
      requestedPath = request.uri.path;
      acceptedEncoding = request.headers.value(
        HttpHeaders.acceptEncodingHeader,
      );
      request.response.contentLength = payload.length;
      request.response.add(payload.sublist(0, 4096));
      request.response.add(payload.sublist(4096));
      await request.response.close();
    });
    final engine = createEngine();
    final updates = <DownloadTask>[];

    final completed = await engine.download(
      task(fileName: 'CON.txt'),
      settingsFor(<_LocalGateway>[gateway]),
      onProgress: updates.add,
    );

    expect(requestedPath, '/ipfs/bafy-test-cid/folder/file.bin');
    expect(acceptedEncoding, 'identity');
    expect(completed.status, DownloadStatus.completed);
    expect(completed.fileName, '_CON.txt');
    expect(completed.receivedBytes, payload.length);
    expect(completed.totalBytes, payload.length);
    expect(completed.gateway, gateway.origin);
    expect(completed.completedAt, isNotNull);
    expect(await File(completed.finalPath).readAsBytes(), payload);
    expect(await File(completed.partialPath).exists(), isFalse);
    expect(
      updates.map((update) => update.status),
      containsAllInOrder([
        DownloadStatus.resolving,
        DownloadStatus.downloading,
        DownloadStatus.completed,
      ]),
    );
  });

  group('automatic file type detection', () {
    test('renames a provisional CID download from JPEG magic bytes', () async {
      final payload = _jpegPayload(5890);
      final gateway = await startGateway((request) async {
        request.response.headers.set(
          HttpHeaders.contentTypeHeader,
          ContentType.binary.mimeType,
        );
        request.response.contentLength = payload.length;
        request.response.add(payload);
        await request.response.close();
      });
      const initialName = 'bafkreihhx7pzvesno.bin';
      final original = task(
        ipfsPath: '',
        fileName: initialName,
        fileNameIsProvisional: true,
      );

      final completed = await createEngine().download(
        original,
        settingsFor(<_LocalGateway>[gateway]),
        onProgress: (_) {},
      );

      expect(completed.fileName, 'bafkreihhx7pzvesno.jpg');
      expect(completed.fileNameIsProvisional, isFalse);
      expect(await File(completed.finalPath).readAsBytes(), payload);
      expect(await File(original.partialPath).exists(), isFalse);
      expect(
        await File(
          '${path.join(temporaryDirectory.path, completed.fileName)}.part',
        ).exists(),
        isFalse,
      );
    });

    test('prefers strong magic bytes over a conflicting HTTP type', () async {
      final payload = _jpegPayload(512);
      final gateway = await startGateway((request) async {
        request.response.headers.contentType = ContentType.text;
        request.response.contentLength = payload.length;
        request.response.add(payload);
        await request.response.close();
      });

      final completed = await createEngine().download(
        task(
          ipfsPath: '',
          fileName: 'content.bin',
          fileNameIsProvisional: true,
        ),
        settingsFor(<_LocalGateway>[gateway]),
        onProgress: (_) {},
      );

      expect(completed.fileName, 'content.jpg');
    });

    test(
      'uses a specific Content-Type when no signature is available',
      () async {
        final payload = Uint8List.fromList(<int>[1, 2, 3, 4, 5, 6]);
        final gateway = await startGateway((request) async {
          request.response.headers.set(
            HttpHeaders.contentTypeHeader,
            'application/pdf; charset=binary',
          );
          request.response.contentLength = payload.length;
          request.response.add(payload);
          await request.response.close();
        });

        final completed = await createEngine().download(
          task(
            ipfsPath: '',
            fileName: 'document.bin',
            fileNameIsProvisional: true,
          ),
          settingsFor(<_LocalGateway>[gateway]),
          onProgress: (_) {},
        );

        expect(completed.fileName, 'document.pdf');
        expect(await File(completed.finalPath).readAsBytes(), payload);
      },
    );

    test('uses only the safe extension from Content-Disposition', () async {
      final payload = Uint8List.fromList(<int>[0, 1, 2, 3, 4, 5]);
      final gateway = await startGateway((request) async {
        request.response.headers.set(
          HttpHeaders.contentTypeHeader,
          ContentType.binary.mimeType,
        );
        request.response.headers.set(
          'content-disposition',
          "attachment; filename*=UTF-8''..%2Fholiday%20photo.png",
        );
        request.response.contentLength = payload.length;
        request.response.add(payload);
        await request.response.close();
      });

      final completed = await createEngine().download(
        task(
          ipfsPath: '',
          fileName: 'safe-cid-name.bin',
          fileNameIsProvisional: true,
        ),
        settingsFor(<_LocalGateway>[gateway]),
        onProgress: (_) {},
      );

      expect(completed.fileName, 'safe-cid-name.png');
      expect(completed.fileName, isNot(contains('holiday')));
      expect(completed.fileName, isNot(contains('..')));
    });

    test('keeps an explicit IPFS path extension unchanged', () async {
      final payload = _jpegPayload(256);
      final gateway = await startGateway((request) async {
        request.response.headers.contentType = ContentType('image', 'jpeg');
        request.response.contentLength = payload.length;
        request.response.add(payload);
        await request.response.close();
      });

      final completed = await createEngine().download(
        task(ipfsPath: 'images/firmware.bin', fileName: 'firmware.bin'),
        settingsFor(<_LocalGateway>[gateway]),
        onProgress: (_) {},
      );

      expect(completed.fileName, 'firmware.bin');
      expect(await File(completed.finalPath).readAsBytes(), payload);
    });

    test('detects the type after resuming the original bin partial', () async {
      final payload = _jpegPayload(4096);
      const offset = 777;
      String? rangeHeader;
      final gateway = await startGateway((request) async {
        rangeHeader = request.headers.value(HttpHeaders.rangeHeader);
        request.response.statusCode = HttpStatus.partialContent;
        request.response.headers.set(
          HttpHeaders.contentRangeHeader,
          'bytes $offset-${payload.length - 1}/${payload.length}',
        );
        request.response.headers.set(
          HttpHeaders.contentTypeHeader,
          ContentType.binary.mimeType,
        );
        request.response.contentLength = payload.length - offset;
        request.response.add(payload.sublist(offset));
        await request.response.close();
      });
      final original = task(
        ipfsPath: '',
        fileName: 'resumable.bin',
        status: DownloadStatus.paused,
        receivedBytes: offset,
        totalBytes: payload.length,
        gateway: gateway.origin,
        fileNameIsProvisional: true,
      );
      await File(original.partialPath).writeAsBytes(payload.sublist(0, offset));

      final completed = await createEngine().download(
        original,
        settingsFor(<_LocalGateway>[gateway]),
        onProgress: (_) {},
      );

      expect(rangeHeader, 'bytes=$offset-');
      expect(completed.fileName, 'resumable.jpg');
      expect(await File(completed.finalPath).readAsBytes(), payload);
      expect(await File(original.partialPath).exists(), isFalse);
    });

    test(
      'ignores error-representation metadata from a validated 416',
      () async {
        final payload = Uint8List.fromList(<int>[0, 255, 2, 253, 4, 251]);
        String? rangeHeader;
        final gateway = await startGateway((request) async {
          rangeHeader = request.headers.value(HttpHeaders.rangeHeader);
          request.response.statusCode = HttpStatus.requestedRangeNotSatisfiable;
          request.response.headers.set(
            HttpHeaders.contentRangeHeader,
            'bytes */${payload.length}',
          );
          request.response.headers.set(
            HttpHeaders.contentTypeHeader,
            'text/plain',
          );
          await request.response.close();
        });
        final original = task(
          ipfsPath: '',
          fileName: 'complete.bin',
          status: DownloadStatus.paused,
          receivedBytes: payload.length,
          totalBytes: payload.length,
          gateway: gateway.origin,
          fileNameIsProvisional: true,
        );
        await File(original.partialPath).writeAsBytes(payload);

        final completed = await createEngine().download(
          original,
          settingsFor(<_LocalGateway>[gateway]),
          onProgress: (_) {},
        );

        expect(rangeHeader, 'bytes=${payload.length}-');
        expect(completed.fileName, 'complete.bin');
        expect(await File(completed.finalPath).readAsBytes(), payload);
      },
    );

    test('keeps the bin fallback when the type remains unknown', () async {
      final payload = Uint8List.fromList(<int>[0, 255, 2, 253, 4, 251]);
      final gateway = await startGateway((request) async {
        request.response.headers.contentType = ContentType.binary;
        request.response.contentLength = payload.length;
        request.response.add(payload);
        await request.response.close();
      });

      final completed = await createEngine().download(
        task(
          ipfsPath: '',
          fileName: 'unknown.bin',
          fileNameIsProvisional: true,
        ),
        settingsFor(<_LocalGateway>[gateway]),
        onProgress: (_) {},
      );

      expect(completed.fileName, 'unknown.bin');
    });

    test(
      'resolves final and partial collisions after changing extension',
      () async {
        final payload = _jpegPayload(512);
        final occupiedFinal = File(
          path.join(temporaryDirectory.path, 'collision.jpg'),
        );
        final occupiedPartial = File(
          '${path.join(temporaryDirectory.path, 'collision (1).jpg')}.part',
        );
        await occupiedFinal.writeAsBytes(<int>[9, 9, 9]);
        await occupiedPartial.writeAsBytes(<int>[8, 8, 8]);
        final gateway = await startGateway((request) async {
          request.response.contentLength = payload.length;
          request.response.add(payload);
          await request.response.close();
        });

        final completed = await createEngine().download(
          task(
            ipfsPath: '',
            fileName: 'collision.bin',
            fileNameIsProvisional: true,
          ),
          settingsFor(<_LocalGateway>[gateway]),
          onProgress: (_) {},
        );

        expect(completed.fileName, 'collision (2).jpg');
        expect(await File(completed.finalPath).readAsBytes(), payload);
        expect(await occupiedFinal.readAsBytes(), <int>[9, 9, 9]);
        expect(await occupiedPartial.readAsBytes(), <int>[8, 8, 8]);
      },
    );
  });

  test('resumes a partial file only from a matching 206 range', () async {
    final payload = Uint8List.fromList(
      List<int>.generate(12000, (index) => (index * 3) % 256),
    );
    const offset = 3777;
    String? rangeHeader;
    final gateway = await startGateway((request) async {
      rangeHeader = request.headers.value(HttpHeaders.rangeHeader);
      request.response.statusCode = HttpStatus.partialContent;
      request.response.headers.set(
        HttpHeaders.contentRangeHeader,
        'bytes $offset-${payload.length - 1}/${payload.length}',
      );
      request.response.contentLength = payload.length - offset;
      request.response.add(payload.sublist(offset));
      await request.response.close();
    });
    final original = task(
      status: DownloadStatus.paused,
      receivedBytes: offset,
      totalBytes: payload.length,
      gateway: gateway.origin,
    );
    await File(original.partialPath).writeAsBytes(payload.sublist(0, offset));

    final completed = await createEngine().download(
      original,
      settingsFor(<_LocalGateway>[gateway]),
      onProgress: (_) {},
    );

    expect(rangeHeader, 'bytes=$offset-');
    expect(await File(completed.finalPath).readAsBytes(), payload);
    expect(completed.receivedBytes, payload.length);
    expect(completed.retryCount, 0);
  });

  test('truncates the partial when a gateway ignores Range with 200', () async {
    final payload = Uint8List.fromList(
      List<int>.generate(5000, (index) => 255 - (index % 255)),
    );
    String? rangeHeader;
    final gateway = await startGateway((request) async {
      rangeHeader = request.headers.value(HttpHeaders.rangeHeader);
      request.response.statusCode = HttpStatus.ok;
      request.response.contentLength = payload.length;
      request.response.add(payload);
      await request.response.close();
    });
    final original = task(
      status: DownloadStatus.paused,
      receivedBytes: 4,
      totalBytes: payload.length,
      gateway: gateway.origin,
    );
    await File(original.partialPath).writeAsBytes(<int>[1, 2, 3, 4]);

    final completed = await createEngine().download(
      original,
      settingsFor(<_LocalGateway>[gateway]),
      onProgress: (_) {},
    );

    expect(rangeHeader, 'bytes=4-');
    expect(await File(completed.finalPath).readAsBytes(), payload);
    expect(completed.receivedBytes, payload.length);
  });

  test('rejects a mismatched Content-Range and falls back safely', () async {
    final payload = Uint8List.fromList(
      List<int>.generate(8192, (index) => index % 199),
    );
    const offset = 1024;
    var firstRequests = 0;
    String? secondRange;
    final badGateway = await startGateway((request) async {
      firstRequests++;
      request.response.statusCode = HttpStatus.partialContent;
      request.response.headers.set(
        HttpHeaders.contentRangeHeader,
        'bytes 0-${payload.length - 1}/${payload.length}',
      );
      request.response.contentLength = payload.length;
      request.response.add(payload);
      await request.response.close();
    });
    final goodGateway = await startGateway((request) async {
      secondRange = request.headers.value(HttpHeaders.rangeHeader);
      request.response.statusCode = HttpStatus.partialContent;
      request.response.headers.set(
        HttpHeaders.contentRangeHeader,
        'bytes $offset-${payload.length - 1}/${payload.length}',
      );
      request.response.contentLength = payload.length - offset;
      request.response.add(payload.sublist(offset));
      await request.response.close();
    });
    final original = task(
      status: DownloadStatus.paused,
      receivedBytes: offset,
      totalBytes: payload.length,
      gateway: badGateway.origin,
    );
    await File(original.partialPath).writeAsBytes(payload.sublist(0, offset));

    final completed = await createEngine().download(
      original,
      settingsFor(<_LocalGateway>[badGateway, goodGateway]),
      onProgress: (_) {},
    );

    expect(firstRequests, 1);
    expect(secondRange, 'bytes=$offset-');
    expect(completed.gateway, goodGateway.origin);
    expect(completed.retryCount, 1);
    expect(await File(completed.finalPath).readAsBytes(), payload);
  });

  test('pause keeps the partial and a later call resumes it', () async {
    final payload = Uint8List.fromList(
      List<int>.generate(65536, (index) => (index * 7) % 256),
    );
    var requestCount = 0;
    final seenRanges = <String?>[];
    final gateway = await startGateway((request) async {
      final requestNumber = ++requestCount;
      final rawRange = request.headers.value(HttpHeaders.rangeHeader);
      seenRanges.add(rawRange);
      final offset = _rangeStart(rawRange);

      if (offset > 0) {
        request.response.statusCode = HttpStatus.partialContent;
        request.response.headers.set(
          HttpHeaders.contentRangeHeader,
          'bytes $offset-${payload.length - 1}/${payload.length}',
        );
      }
      request.response.contentLength = payload.length - offset;
      request.response.bufferOutput = false;

      if (requestNumber == 1) {
        for (
          var position = offset;
          position < payload.length;
          position += 1024
        ) {
          final end = (position + 1024).clamp(0, payload.length);
          try {
            request.response.add(payload.sublist(position, end));
            await request.response.flush();
            await Future<void>.delayed(const Duration(milliseconds: 8));
          } on Object {
            break;
          }
        }
      } else {
        request.response.add(payload.sublist(offset));
      }
      try {
        await request.response.close();
      } on Object {
        // The first response is intentionally disconnected by pause().
      }
    });

    final engine = createEngine();
    final enoughData = Completer<void>();
    final firstFuture = engine.download(
      task(),
      settingsFor(<_LocalGateway>[gateway]),
      onProgress: (update) {
        if (update.receivedBytes >= 2048 && !enoughData.isCompleted) {
          enoughData.complete();
        }
      },
    );
    await enoughData.future.timeout(const Duration(seconds: 2));
    engine.pause('task-1');

    DownloadPausedException? pauseFailure;
    try {
      await firstFuture;
      fail('The paused download unexpectedly completed.');
    } on DownloadPausedException catch (error) {
      pauseFailure = error;
    }

    final paused = pauseFailure.task;
    final partial = File(paused.partialPath);
    expect(paused.status, DownloadStatus.paused);
    expect(await partial.exists(), isTrue);
    final retainedBytes = await partial.length();
    expect(retainedBytes, greaterThan(0));
    expect(retainedBytes, lessThan(payload.length));
    expect(await File(paused.finalPath).exists(), isFalse);

    final completed = await engine.download(
      paused,
      settingsFor(<_LocalGateway>[gateway]),
      onProgress: (_) {},
    );

    expect(requestCount, 2);
    expect(seenRanges.last, 'bytes=$retainedBytes-');
    expect(await File(completed.finalPath).readAsBytes(), payload);
    expect(await partial.exists(), isFalse);
  });

  test(
    'requests directory archives explicitly and can delete the partial',
    () async {
      final payload = Uint8List.fromList(<int>[1, 2, 3, 4, 5]);
      String? format;
      String? accept;
      final gateway = await startGateway((request) async {
        format = request.uri.queryParameters['format'];
        accept = request.headers.value(HttpHeaders.acceptHeader);
        request.response.contentLength = payload.length;
        request.response.add(payload);
        await request.response.close();
      });
      final archiveTask = task(
        fileName: 'folder',
        ipfsPath: '',
        isDirectoryArchive: true,
      );
      final engine = createEngine();

      final completed = await engine.download(
        archiveTask,
        settingsFor(<_LocalGateway>[gateway]),
        onProgress: (_) {},
      );

      expect(format, 'tar');
      expect(accept, 'application/x-tar');
      expect(completed.fileName, 'folder.tar');
      expect(await File(completed.finalPath).readAsBytes(), payload);

      final paused = archiveTask.copyWith(
        fileName: 'another-folder',
        status: DownloadStatus.paused,
      );
      final partial = File(
        '${path.join(temporaryDirectory.path, 'another-folder.tar')}.part',
      );
      await partial.writeAsBytes(<int>[9, 8, 7]);
      await engine.deletePartial(paused);
      expect(await partial.exists(), isFalse);
    },
  );

  test('encodes already-decoded IPFS path segments exactly once', () async {
    List<String>? observedSegments;
    String? rawTarget;
    final gateway = await startGateway((request) async {
      observedSegments = request.uri.pathSegments;
      rawTarget = request.uri.toString();
      request.response.contentLength = 1;
      request.response.add(<int>[42]);
      await request.response.close();
    });

    await createEngine().download(
      task(ipfsPath: 'folder/literal%2Fname.bin'),
      settingsFor(<_LocalGateway>[gateway]),
      onProgress: (_) {},
    );

    expect(observedSegments!.last, 'literal%2Fname.bin');
    expect(rawTarget, contains('literal%252Fname.bin'));
  });

  test('filename sanitizing prevents traversal and Windows device names', () {
    final traversal = DownloadEngine.sanitizeFileName('../bad\\name?.txt');
    final reserved = DownloadEngine.sanitizeFileName('NUL.txt');

    expect(traversal, isNot(contains('/')));
    expect(traversal, isNot(contains(r'\')));
    expect(traversal, isNot(contains('?')));
    expect(traversal, isNot(anyOf('.', '..')));
    expect(reserved, '_NUL.txt');
  });
}

int _rangeStart(String? value) {
  if (value == null) return 0;
  final match = RegExp(r'^bytes=(\d+)-$').firstMatch(value);
  return match == null ? 0 : int.parse(match.group(1)!);
}

Uint8List _jpegPayload(int length) {
  if (length < 20) {
    throw ArgumentError.value(length, 'length', 'must be at least 20');
  }
  final bytes = Uint8List.fromList(
    List<int>.generate(length, (index) => (index * 37) % 256),
  );
  bytes.setRange(0, 20, <int>[
    0xff,
    0xd8,
    0xff,
    0xe0,
    0x00,
    0x10,
    0x4a,
    0x46,
    0x49,
    0x46,
    0x00,
    0x01,
    0x02,
    0x00,
    0x00,
    0x01,
    0x00,
    0x01,
    0x00,
    0x00,
  ]);
  return bytes;
}

class _LocalGateway {
  _LocalGateway(this._server);

  final HttpServer _server;

  String get origin => 'http://${_server.address.address}:${_server.port}';

  static Future<_LocalGateway> start(
    Future<void> Function(HttpRequest request) handler,
  ) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      try {
        await handler(request);
      } on Object {
        try {
          await request.response.close();
        } on Object {
          // The client may already have closed a deliberately bad response.
        }
      }
    });
    return _LocalGateway(server);
  }

  Future<void> close() => _server.close(force: true);
}
