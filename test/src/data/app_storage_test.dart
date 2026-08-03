import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ipfs_downloader/src/data/app_storage.dart';
import 'package:ipfs_downloader/src/domain/app_settings.dart';
import 'package:ipfs_downloader/src/domain/download_task.dart';
import 'package:path/path.dart' as path;

void main() {
  late Directory temporaryDirectory;
  late FileAppStorage storage;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'ipfs-downloader-storage-',
    );
    storage = FileAppStorage(baseDirectory: temporaryDirectory.path);
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('returns an empty state when no state file exists', () async {
    final StoredAppState state = await storage.load();

    expect(state.tasks, isEmpty);
    expect(state.settings, isNull);
    expect(
      await File(
        path.join(temporaryDirectory.path, FileAppStorage.fileName),
      ).exists(),
      isFalse,
    );
  });

  test('round-trips tasks and settings through JSON', () async {
    final DownloadTask task = _task(
      id: 'download-1',
      status: DownloadStatus.paused,
      destinationDirectory: path.join(temporaryDirectory.path, 'downloads'),
    );
    final AppSettings settings = _settings(
      downloadDirectory: path.join(temporaryDirectory.path, 'downloads'),
    );

    await storage.save(tasks: <DownloadTask>[task], settings: settings);
    final StoredAppState restored = await storage.load();

    expect(restored.tasks, hasLength(1));
    expect(restored.tasks.single.toJson(), task.toJson());
    expect(restored.settings, isNotNull);
    expect(restored.settings!.toJson(), settings.toJson());
  });

  test('writes a versioned document and leaves no temporary file', () async {
    final String nestedDirectory = path.join(
      temporaryDirectory.path,
      'not',
      'created',
      'yet',
    );
    final FileAppStorage nestedStorage = FileAppStorage(
      baseDirectory: nestedDirectory,
    );

    await nestedStorage.save(
      tasks: <DownloadTask>[_task(id: 'download-1')],
      settings: _settings(),
    );

    final File stateFile = File(
      path.join(nestedDirectory, FileAppStorage.fileName),
    );
    final Object? decoded = jsonDecode(await stateFile.readAsString());

    expect(decoded, isA<Map<String, dynamic>>());
    final Map<String, dynamic> document = decoded! as Map<String, dynamic>;
    expect(document['schemaVersion'], FileAppStorage.schemaVersion);
    expect(document['tasks'], hasLength(1));
    expect(document['settings'], isA<Map<String, dynamic>>());

    final List<FileSystemEntity> files = await Directory(
      nestedDirectory,
    ).list().toList();
    expect(
      files.where((FileSystemEntity entity) => entity.path.endsWith('.tmp')),
      isEmpty,
    );
  });

  test('moves corrupt JSON aside and returns an empty state', () async {
    const String corruptContents = '{"schemaVersion": 1, not-json';
    final File stateFile = File(
      path.join(temporaryDirectory.path, FileAppStorage.fileName),
    );
    await stateFile.writeAsString(corruptContents);

    final StoredAppState state = await storage.load();

    expect(state.tasks, isEmpty);
    expect(state.settings, isNull);
    expect(await stateFile.exists(), isFalse);

    final List<File> brokenFiles = await temporaryDirectory
        .list()
        .where(
          (FileSystemEntity entity) =>
              entity is File &&
              path.basename(entity.path).startsWith('app_state.broken-') &&
              entity.path.endsWith('.json'),
        )
        .cast<File>()
        .toList();
    expect(brokenFiles, hasLength(1));
    expect(await brokenFiles.single.readAsString(), corruptContents);
  });

  test('treats invalid model data as a broken state file', () async {
    final File stateFile = File(
      path.join(temporaryDirectory.path, FileAppStorage.fileName),
    );
    await stateFile.writeAsString(
      jsonEncode(<String, Object?>{
        'schemaVersion': FileAppStorage.schemaVersion,
        'tasks': <Object?>[
          <String, Object?>{'id': 'missing-required-task-properties'},
        ],
        'settings': _settings().toJson(),
      }),
    );

    final StoredAppState state = await storage.load();

    expect(state.tasks, isEmpty);
    expect(state.settings, isNull);
    expect(await stateFile.exists(), isFalse);
  });

  test('serializes concurrent saves so the last invocation wins', () async {
    final Future<void> firstSave = storage.save(
      tasks: <DownloadTask>[_task(id: 'first')],
      settings: _settings(downloadDirectory: '/first'),
    );
    final Future<void> secondSave = storage.save(
      tasks: <DownloadTask>[_task(id: 'second')],
      settings: _settings(downloadDirectory: '/second'),
    );

    await Future.wait(<Future<void>>[firstSave, secondSave]);
    final StoredAppState state = await storage.load();

    expect(state.tasks.single.id, 'second');
    expect(state.settings!.defaultDownloadDirectory, '/second');
  });
}

DownloadTask _task({
  required String id,
  DownloadStatus status = DownloadStatus.downloading,
  String destinationDirectory = '/downloads',
}) {
  return DownloadTask(
    id: id,
    cid: 'bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi',
    ipfsPath: 'folder/archive.zip',
    fileName: 'archive.zip',
    destinationDirectory: destinationDirectory,
    status: status,
    receivedBytes: 4096,
    totalBytes: 8192,
    speedBytesPerSecond: 1024.5,
    createdAt: DateTime.utc(2026, 7, 31, 8, 30),
    error: status == DownloadStatus.failed ? 'Gateway timeout' : null,
    gateway: 'https://dweb.link',
    retryCount: 2,
    isDirectoryArchive: true,
  );
}

AppSettings _settings({String downloadDirectory = '/downloads'}) {
  return AppSettings(
    defaultDownloadDirectory: downloadDirectory,
    gateways: const <String>['http://127.0.0.1:8080', 'https://dweb.link'],
    maxConcurrentDownloads: 4,
    autoStart: false,
    themePreference: AppThemePreference.dark,
    connectionTimeoutSeconds: 45,
  );
}
