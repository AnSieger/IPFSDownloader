import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../core/ipfs_input_parser.dart';
import '../data/app_storage.dart';
import '../data/download_engine.dart';
import '../domain/app_settings.dart';
import '../domain/download_task.dart';

class AddDownloadsResult {
  const AddDownloadsResult({required this.added, required this.duplicates});

  final int added;
  final int duplicates;
}

class DownloadController extends ChangeNotifier {
  DownloadController({
    required AppStorage storage,
    required DownloadEngine engine,
    required AppSettings settings,
    List<DownloadTask> tasks = const <DownloadTask>[],
  }) : _storage = storage,
       _engine = engine,
       _settings = settings,
       _tasks = List<DownloadTask>.from(tasks);

  final AppStorage _storage;
  final DownloadEngine _engine;
  final List<DownloadTask> _tasks;
  final Map<String, Future<void>> _running = <String, Future<void>>{};

  AppSettings _settings;
  Timer? _saveTimer;
  bool _disposed = false;
  String? _storageError;
  var _idSequence = 0;

  List<DownloadTask> get tasks => List<DownloadTask>.unmodifiable(_tasks);
  AppSettings get settings => _settings;
  String? get storageError => _storageError;

  int get activeCount => _tasks.where((task) => task.status.isActive).length;
  int get queuedCount =>
      _tasks.where((task) => task.status == DownloadStatus.queued).length;
  int get completedCount =>
      _tasks.where((task) => task.status == DownloadStatus.completed).length;
  int get failedCount =>
      _tasks.where((task) => task.status == DownloadStatus.failed).length;
  int get pausedCount =>
      _tasks.where((task) => task.status == DownloadStatus.paused).length;
  double get totalSpeed => _tasks
      .where((task) => task.status == DownloadStatus.downloading)
      .fold<double>(0, (sum, task) => sum + task.speedBytesPerSecond);

  void startInitialQueue() {
    for (var index = 0; index < _tasks.length; index++) {
      final task = _tasks[index];
      if (task.status.isActive) {
        _tasks[index] = task.copyWith(
          status: _settings.autoStart
              ? DownloadStatus.queued
              : DownloadStatus.paused,
          speedBytesPerSecond: 0,
        );
      }
    }
    notifyListeners();
    _scheduleSave();
    if (_settings.autoStart) _processQueue();
  }

  AddDownloadsResult addDownloads(
    String input, {
    String? destinationDirectory,
    bool directoryArchive = false,
  }) {
    final references = IpfsInputParser.parseMany(input);
    final destination =
        destinationDirectory ?? _settings.defaultDownloadDirectory;
    if (destination.trim().isEmpty) {
      throw const FileSystemException(
        'Bitte zuerst einen Zielordner auswählen.',
      );
    }

    var added = 0;
    var duplicates = 0;
    var insertionIndex = _tasks.lastIndexWhere(
      (task) => task.status != DownloadStatus.completed,
    );
    insertionIndex++;
    for (final reference in references) {
      final duplicate = _tasks.any(
        (task) =>
            task.cid == reference.cid &&
            task.ipfsPath == reference.ipfsPath &&
            task.destinationDirectory == destination &&
            task.isDirectoryArchive == directoryArchive &&
            task.status != DownloadStatus.canceled,
      );
      if (duplicate) {
        duplicates++;
        continue;
      }

      final proposedName = reference.suggestedFileName(
        directoryArchive: directoryArchive,
      );
      final fileName = _availableFileName(destination, proposedName);
      final sourceExtension = reference.ipfsPath.isEmpty
          ? ''
          : path.extension(path.basename(reference.ipfsPath));
      final fileNameIsProvisional =
          !directoryArchive &&
          (reference.ipfsPath.isEmpty ||
              sourceExtension.isEmpty ||
              sourceExtension == '.');
      _tasks.insert(
        insertionIndex,
        DownloadTask(
          id: _newId(),
          cid: reference.cid,
          ipfsPath: reference.ipfsPath,
          fileName: fileName,
          destinationDirectory: destination,
          createdAt: DateTime.now().toUtc(),
          isDirectoryArchive: directoryArchive,
          fileNameIsProvisional: fileNameIsProvisional,
        ),
      );
      insertionIndex++;
      added++;
    }

    if (added > 0) {
      notifyListeners();
      _scheduleSave();
      if (_settings.autoStart) _processQueue();
    }
    return AddDownloadsResult(added: added, duplicates: duplicates);
  }

  void startTask(String id) {
    final task = _find(id);
    if (task == null ||
        task.status == DownloadStatus.completed ||
        task.status.isActive) {
      return;
    }
    _replace(
      task.copyWith(
        status: DownloadStatus.queued,
        error: null,
        completedAt: null,
        speedBytesPerSecond: 0,
      ),
    );
    _processQueue();
  }

  void pauseTask(String id) {
    final task = _find(id);
    if (task == null) return;
    _engine.pause(id);
    if (task.status.isActive || task.status == DownloadStatus.queued) {
      _replace(
        task.copyWith(status: DownloadStatus.paused, speedBytesPerSecond: 0),
      );
    }
  }

  void pauseAll() {
    for (final task in List<DownloadTask>.from(_tasks)) {
      if (task.status.isActive || task.status == DownloadStatus.queued) {
        pauseTask(task.id);
      }
    }
  }

  void resumeAll() {
    var changed = false;
    for (var index = 0; index < _tasks.length; index++) {
      final task = _tasks[index];
      if (task.status == DownloadStatus.paused ||
          task.status == DownloadStatus.failed) {
        _tasks[index] = task.copyWith(
          status: DownloadStatus.queued,
          error: null,
          completedAt: null,
        );
        changed = true;
      }
    }
    if (!changed) return;
    notifyListeners();
    _scheduleSave();
    _processQueue();
  }

  Future<void> cancelTask(String id, {bool deletePartial = false}) async {
    final task = _find(id);
    if (task == null || task.status == DownloadStatus.completed) return;
    _engine.pause(id);
    _replace(
      task.copyWith(
        status: DownloadStatus.canceled,
        speedBytesPerSecond: 0,
        error: null,
      ),
    );
    if (deletePartial) {
      await _engine.deletePartial(task);
    }
  }

  Future<void> removeTask(String id, {bool deletePartial = false}) async {
    final task = _find(id);
    if (task == null) return;
    _engine.pause(id);
    if (deletePartial && task.status != DownloadStatus.completed) {
      await _engine.deletePartial(task);
    }
    _tasks.removeWhere((candidate) => candidate.id == id);
    notifyListeners();
    await _saveNow();
    _processQueue();
  }

  Future<void> clearCompleted() async {
    _tasks.removeWhere((task) => task.status == DownloadStatus.completed);
    notifyListeners();
    await _saveNow();
  }

  void moveTask(String id, int offset) {
    final oldIndex = _tasks.indexWhere((task) => task.id == id);
    if (oldIndex < 0) return;
    final newIndex = (oldIndex + offset).clamp(0, _tasks.length - 1).toInt();
    if (newIndex == oldIndex) return;
    final task = _tasks.removeAt(oldIndex);
    _tasks.insert(newIndex, task);
    notifyListeners();
    _scheduleSave();
  }

  void updateSettings(AppSettings settings) {
    _settings = settings;
    notifyListeners();
    _scheduleSave();
    if (_settings.autoStart) _processQueue();
  }

  Future<void> flush() => _saveNow();

  DownloadTask? _find(String id) {
    final index = _tasks.indexWhere((task) => task.id == id);
    return index < 0 ? null : _tasks[index];
  }

  void _replace(DownloadTask task, {bool save = true}) {
    final index = _tasks.indexWhere((candidate) => candidate.id == task.id);
    if (index < 0) return;
    _tasks[index] = task;
    notifyListeners();
    if (save) _scheduleSave();
  }

  void _processQueue() {
    if (_disposed) return;
    while (_running.length < _settings.maxConcurrentDownloads) {
      final next = _tasks
          .where(
            (task) =>
                task.status == DownloadStatus.queued &&
                !_running.containsKey(task.id),
          )
          .firstOrNull;
      if (next == null) return;

      final resolving = next.copyWith(
        status: DownloadStatus.resolving,
        error: null,
        completedAt: null,
      );
      _replace(resolving);
      final operation = _run(resolving);
      _running[next.id] = operation;
    }
  }

  Future<void> _run(DownloadTask initialTask) async {
    try {
      final result = await _engine.download(
        initialTask,
        _settings,
        onProgress: (update) {
          final current = _find(update.id);
          if (current == null ||
              current.status == DownloadStatus.paused ||
              current.status == DownloadStatus.canceled) {
            return;
          }
          _replace(update);
        },
      );
      final current = _find(initialTask.id);
      if (current != null &&
          current.status != DownloadStatus.paused &&
          current.status != DownloadStatus.canceled) {
        _replace(result);
      }
    } on DownloadPausedException {
      final current = _find(initialTask.id);
      if (current != null &&
          current.status != DownloadStatus.canceled &&
          current.status != DownloadStatus.queued) {
        _replace(
          current.copyWith(
            status: DownloadStatus.paused,
            speedBytesPerSecond: 0,
          ),
        );
      }
    } on DownloadFailure catch (error) {
      final current = _find(initialTask.id);
      if (current != null &&
          current.status != DownloadStatus.paused &&
          current.status != DownloadStatus.canceled) {
        _replace(
          current.copyWith(
            status: DownloadStatus.failed,
            speedBytesPerSecond: 0,
            error: error.message,
          ),
        );
      }
    } on Object catch (error) {
      final current = _find(initialTask.id);
      if (current != null &&
          current.status != DownloadStatus.paused &&
          current.status != DownloadStatus.canceled) {
        _replace(
          current.copyWith(
            status: DownloadStatus.failed,
            speedBytesPerSecond: 0,
            error: 'Unerwarteter Fehler: $error',
          ),
        );
      }
    } finally {
      _running.remove(initialTask.id);
      await _saveNow();
      scheduleMicrotask(_processQueue);
    }
  }

  String _availableFileName(String destination, String proposed) {
    final extension = path.extension(proposed);
    final stem = path.basenameWithoutExtension(proposed);
    var candidate = proposed;
    var suffix = 2;
    bool isTaken() {
      final fullPath = path.join(destination, candidate);
      return File(fullPath).existsSync() ||
          File('$fullPath.part').existsSync() ||
          _tasks.any(
            (task) =>
                task.destinationDirectory == destination &&
                task.fileName.toLowerCase() == candidate.toLowerCase(),
          );
    }

    while (isTaken()) {
      candidate = '$stem ($suffix)$extension';
      suffix++;
    }
    return candidate;
  }

  String _newId() {
    _idSequence++;
    return '${DateTime.now().toUtc().microsecondsSinceEpoch}-$_idSequence';
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 450), _saveNow);
  }

  Future<void> _saveNow() async {
    if (_disposed) return;
    _saveTimer?.cancel();
    try {
      final hadStorageError = _storageError != null;
      await _storage.save(tasks: _tasks, settings: _settings);
      _storageError = null;
      if (hadStorageError && !_disposed) notifyListeners();
    } on Object catch (error) {
      _storageError = 'Status konnte nicht gespeichert werden: $error';
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _saveTimer?.cancel();
    _engine.close();
    super.dispose();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
