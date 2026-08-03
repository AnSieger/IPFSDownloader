import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ipfs_downloader/src/application/download_controller.dart';
import 'package:ipfs_downloader/src/data/app_storage.dart';
import 'package:ipfs_downloader/src/data/download_engine.dart';
import 'package:ipfs_downloader/src/domain/app_settings.dart';
import 'package:ipfs_downloader/src/domain/download_task.dart';
import 'package:path/path.dart' as path;

const String _cidV0 = 'QmYwAPJzv5CZsnAzt8auVZRnGiVvWjF34VQ9F4sY5k2zKx';
const String _cidV1 =
    'bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi';

void main() {
  late _FakeAppStorage storage;
  late _FakeDownloadEngine engine;
  late DownloadController controller;

  setUp(() {
    storage = _FakeAppStorage();
    engine = _FakeDownloadEngine();
  });

  tearDown(() {
    controller.dispose();
  });

  group('adding downloads', () {
    test('adds unique inputs and counts duplicates', () async {
      controller = _controller(
        storage: storage,
        engine: engine,
        autoStart: false,
      );

      final AddDownloadsResult first = controller.addDownloads(
        '$_cidV1\nipfs://$_cidV1',
      );
      final AddDownloadsResult second = controller.addDownloads(_cidV1);

      expect(first.added, 1);
      expect(first.duplicates, 1);
      expect(second.added, 0);
      expect(second.duplicates, 1);
      expect(controller.tasks, hasLength(1));
      expect(controller.tasks.single.cid, _cidV1);
      expect(engine.downloadCalls, isEmpty);

      await controller.flush();
      expect(storage.lastTasks, hasLength(1));
    });

    test('allows the same source for a different destination or mode', () {
      controller = _controller(
        storage: storage,
        engine: engine,
        autoStart: false,
      );
      final String firstDestination = _destination('first');
      final String secondDestination = _destination('second');

      final AddDownloadsResult first = controller.addDownloads(
        _cidV0,
        destinationDirectory: firstDestination,
      );
      final AddDownloadsResult second = controller.addDownloads(
        _cidV0,
        destinationDirectory: secondDestination,
      );
      final AddDownloadsResult archive = controller.addDownloads(
        _cidV0,
        destinationDirectory: firstDestination,
        directoryArchive: true,
      );

      expect(first.added, 1);
      expect(second.added, 1);
      expect(archive.added, 1);
      expect(controller.tasks, hasLength(3));
    });

    test('marks only names without an explicit extension as provisional', () {
      controller = _controller(
        storage: storage,
        engine: engine,
        autoStart: false,
      );

      controller.addDownloads(_cidV1);
      controller.addDownloads('ipfs://$_cidV1/photos/summer');
      controller.addDownloads('ipfs://$_cidV1/releases/firmware.bin');
      controller.addDownloads(
        'ipfs://$_cidV1/folder-without-extension',
        directoryArchive: true,
      );

      final Map<String, DownloadTask> tasksByPath = <String, DownloadTask>{
        for (final DownloadTask task in controller.tasks) task.ipfsPath: task,
      };
      expect(tasksByPath['']?.fileNameIsProvisional, isTrue);
      expect(tasksByPath['photos/summer']?.fileNameIsProvisional, isTrue);
      expect(
        tasksByPath['releases/firmware.bin']?.fileNameIsProvisional,
        isFalse,
      );
      expect(
        tasksByPath['folder-without-extension']?.fileNameIsProvisional,
        isFalse,
      );
    });

    test('rejects adding a task without any destination', () {
      controller = DownloadController(
        storage: storage,
        engine: engine,
        settings: AppSettings.defaults(),
      );

      expect(
        () => controller.addDownloads(_cidV1),
        throwsA(isA<FileSystemException>()),
      );
      expect(controller.tasks, isEmpty);
    });
  });

  group('autostart', () {
    test('keeps newly added tasks queued when autostart is disabled', () async {
      controller = _controller(
        storage: storage,
        engine: engine,
        autoStart: false,
      );

      controller.addDownloads(_cidV1);
      await pumpEventQueue();

      expect(controller.tasks.single.status, DownloadStatus.queued);
      expect(controller.queuedCount, 1);
      expect(controller.activeCount, 0);
      expect(engine.downloadCalls, isEmpty);
    });

    test('pauses restored active tasks when initial autostart is disabled', () {
      controller = _controller(
        storage: storage,
        engine: engine,
        autoStart: false,
        tasks: <DownloadTask>[
          _task(id: 'resolving', status: DownloadStatus.resolving),
          _task(id: 'downloading', status: DownloadStatus.downloading),
          _task(id: 'completed', status: DownloadStatus.completed),
        ],
      );

      controller.startInitialQueue();

      expect(
        controller.tasks.map((DownloadTask task) => task.status),
        <DownloadStatus>[
          DownloadStatus.paused,
          DownloadStatus.paused,
          DownloadStatus.completed,
        ],
      );
      expect(engine.downloadCalls, isEmpty);
    });
  });

  group('pause and resume', () {
    test('transitions through resolving, paused and resolving again', () async {
      controller = _controller(
        storage: storage,
        engine: engine,
        autoStart: false,
        tasks: <DownloadTask>[_task(id: 'task-1')],
      );

      controller.startTask('task-1');

      expect(controller.tasks.single.status, DownloadStatus.resolving);
      expect(engine.downloadCalls, <String>['task-1']);
      expect(controller.activeCount, 1);

      controller.pauseTask('task-1');
      expect(controller.tasks.single.status, DownloadStatus.paused);
      expect(engine.pauseCalls, <String>['task-1']);

      await pumpEventQueue();
      expect(controller.tasks.single.status, DownloadStatus.paused);
      expect(controller.pausedCount, 1);

      controller.resumeAll();
      expect(controller.tasks.single.status, DownloadStatus.resolving);
      expect(engine.downloadCalls, <String>['task-1', 'task-1']);

      controller.pauseTask('task-1');
      await pumpEventQueue();
      expect(controller.tasks.single.status, DownloadStatus.paused);
      await controller.flush();
    });

    test('waits for a paused run to unwind before restarting it', () async {
      engine.holdPauses = true;
      controller = _controller(
        storage: storage,
        engine: engine,
        autoStart: false,
        maxConcurrentDownloads: 3,
        tasks: <DownloadTask>[_task(id: 'task-1')],
      );

      controller.startTask('task-1');
      controller.pauseTask('task-1');
      controller.startTask('task-1');

      expect(controller.tasks.single.status, DownloadStatus.queued);
      expect(engine.downloadCalls, <String>['task-1']);

      engine.completePausedDownload('task-1');
      await pumpEventQueue();

      expect(controller.tasks.single.status, DownloadStatus.resolving);
      expect(engine.downloadCalls, <String>['task-1', 'task-1']);

      engine.holdPauses = false;
      controller.pauseTask('task-1');
      await pumpEventQueue();
      expect(controller.tasks.single.status, DownloadStatus.paused);
    });
  });

  group('settings', () {
    test('updates and persists settings without starting a queue', () async {
      controller = _controller(
        storage: storage,
        engine: engine,
        autoStart: false,
      );
      final AppSettings updated = controller.settings.copyWith(
        defaultDownloadDirectory: _destination('updated'),
        maxConcurrentDownloads: 6,
        connectionTimeoutSeconds: 60,
        themePreference: AppThemePreference.dark,
      );

      controller.updateSettings(updated);
      await controller.flush();

      expect(controller.settings.toJson(), updated.toJson());
      expect(storage.lastSettings?.toJson(), updated.toJson());
      expect(engine.downloadCalls, isEmpty);
    });

    test(
      'notifies when a storage error clears after a successful save',
      () async {
        controller = _controller(
          storage: storage,
          engine: engine,
          autoStart: false,
        );
        storage.failuresRemaining = 1;

        await controller.flush();
        expect(controller.storageError, isNotNull);

        var notifications = 0;
        controller.addListener(() => notifications++);
        await controller.flush();

        expect(controller.storageError, isNull);
        expect(notifications, 1);
      },
    );
  });

  group('queue order', () {
    test('moves tasks by offset and persists the resulting order', () async {
      controller = _controller(
        storage: storage,
        engine: engine,
        autoStart: false,
        tasks: <DownloadTask>[
          _task(id: 'first', createdAt: DateTime.utc(2026, 7, 31, 8)),
          _task(id: 'second', createdAt: DateTime.utc(2026, 7, 31, 9)),
          _task(id: 'third', createdAt: DateTime.utc(2026, 7, 31, 10)),
        ],
      );

      controller.moveTask('third', -2);
      expect(controller.tasks.map((DownloadTask task) => task.id), <String>[
        'third',
        'first',
        'second',
      ]);

      controller.moveTask('third', -99);
      controller.moveTask('first', 99);
      expect(controller.tasks.map((DownloadTask task) => task.id), <String>[
        'third',
        'second',
        'first',
      ]);

      await controller.flush();
      expect(storage.lastTasks.map((DownloadTask task) => task.id), <String>[
        'third',
        'second',
        'first',
      ]);
      expect(engine.downloadCalls, isEmpty);
    });

    test('preserves manual priority and multi-line import order', () {
      controller = _controller(
        storage: storage,
        engine: engine,
        autoStart: false,
        tasks: <DownloadTask>[
          _task(id: 'first'),
          _task(id: 'second'),
          _task(id: 'completed', status: DownloadStatus.completed),
        ],
      );
      controller.moveTask('second', -1);

      controller.addDownloads(
        'ipfs://$_cidV1/imports/alpha.bin\n'
        'ipfs://$_cidV1/imports/beta.bin',
      );

      expect(
        controller.tasks.map(
          (DownloadTask task) =>
              task.ipfsPath.isEmpty ? task.id : task.ipfsPath,
        ),
        <String>[
          'second',
          'first',
          'imports/alpha.bin',
          'imports/beta.bin',
          'completed',
        ],
      );
    });
  });
}

DownloadController _controller({
  required _FakeAppStorage storage,
  required _FakeDownloadEngine engine,
  required bool autoStart,
  int maxConcurrentDownloads = 1,
  List<DownloadTask> tasks = const <DownloadTask>[],
}) {
  return DownloadController(
    storage: storage,
    engine: engine,
    settings: AppSettings.defaults(downloadDirectory: _destination('default'))
        .copyWith(
          autoStart: autoStart,
          maxConcurrentDownloads: maxConcurrentDownloads,
        ),
    tasks: tasks,
  );
}

DownloadTask _task({
  required String id,
  DownloadStatus status = DownloadStatus.queued,
  DateTime? createdAt,
}) {
  return DownloadTask(
    id: id,
    cid: _cidV1,
    fileName: '$id.bin',
    destinationDirectory: _destination('default'),
    createdAt: createdAt ?? DateTime.utc(2026, 7, 31, 8),
    status: status,
  );
}

String _destination(String name) => path.join(
  Directory.systemTemp.path,
  'ipfs-downloader-controller-tests',
  name,
);

class _FakeAppStorage implements AppStorage {
  var saveCalls = 0;
  var failuresRemaining = 0;
  List<DownloadTask> lastTasks = const <DownloadTask>[];
  AppSettings? lastSettings;

  @override
  Future<StoredAppState> load() async => StoredAppState.empty();

  @override
  Future<void> save({
    required List<DownloadTask> tasks,
    required AppSettings settings,
  }) async {
    saveCalls++;
    if (failuresRemaining > 0) {
      failuresRemaining--;
      throw const FileSystemException('simulated save failure');
    }
    lastTasks = List<DownloadTask>.unmodifiable(tasks);
    lastSettings = settings;
  }
}

class _FakeDownloadEngine extends DownloadEngine {
  final List<String> downloadCalls = <String>[];
  final List<String> pauseCalls = <String>[];
  final List<String> deletePartialCalls = <String>[];
  final Map<String, _PendingDownload> _pending = <String, _PendingDownload>{};

  bool wasClosed = false;
  bool holdPauses = false;

  @override
  Future<DownloadTask> download(
    DownloadTask task,
    AppSettings settings, {
    required DownloadProgressCallback onProgress,
  }) {
    downloadCalls.add(task.id);
    final Completer<DownloadTask> completer = Completer<DownloadTask>();
    _pending[task.id] = _PendingDownload(task, completer);
    return completer.future;
  }

  @override
  void pause(String taskId) {
    pauseCalls.add(taskId);
    if (holdPauses) return;
    completePausedDownload(taskId);
  }

  void completePausedDownload(String taskId) {
    final _PendingDownload? pending = _pending.remove(taskId);
    if (pending == null || pending.completer.isCompleted) return;
    pending.completer.completeError(
      DownloadPausedException(
        pending.task.copyWith(status: DownloadStatus.paused),
      ),
    );
  }

  @override
  Future<void> deletePartial(DownloadTask task) async {
    deletePartialCalls.add(task.id);
  }

  @override
  void close() {
    wasClosed = true;
  }
}

class _PendingDownload {
  const _PendingDownload(this.task, this.completer);

  final DownloadTask task;
  final Completer<DownloadTask> completer;
}
