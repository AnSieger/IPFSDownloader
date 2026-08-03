import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../domain/app_settings.dart';
import '../domain/download_task.dart';

/// A persisted snapshot of the application's download queue and settings.
class StoredAppState {
  StoredAppState({
    List<DownloadTask> tasks = const <DownloadTask>[],
    this.settings,
  }) : tasks = List<DownloadTask>.unmodifiable(tasks);

  factory StoredAppState.empty() => StoredAppState();

  final List<DownloadTask> tasks;
  final AppSettings? settings;
}

/// Persists and restores all user-owned application state.
abstract class AppStorage {
  Future<StoredAppState> load();

  Future<void> save({
    required List<DownloadTask> tasks,
    required AppSettings settings,
  });
}

/// JSON-file based [AppStorage] for desktop platforms.
///
/// When [baseDirectory] is omitted, the platform's application support
/// directory is used. Tests can inject an isolated temporary directory.
class FileAppStorage implements AppStorage {
  FileAppStorage({String? baseDirectory}) : _baseDirectory = baseDirectory;

  static const int schemaVersion = 1;
  static const String fileName = 'app_state.json';

  static const JsonEncoder _encoder = JsonEncoder.withIndent('  ');

  final String? _baseDirectory;

  // Serializing writes makes invocation order deterministic and prevents two
  // saves from racing their final rename.
  Future<void> _writeTail = Future<void>.value();

  @override
  Future<StoredAppState> load() async {
    // A load issued after save() should observe that save.
    await _writeTail;

    final File file = await _stateFile();
    if (!await file.exists()) {
      return StoredAppState.empty();
    }

    // I/O errors should remain visible to the caller. Only decoding/model
    // errors below identify a broken state file.
    final String contents = await file.readAsString();

    try {
      return _decode(contents);
    } on Object {
      await _preserveBrokenFile(file);
      return StoredAppState.empty();
    }
  }

  @override
  Future<void> save({
    required List<DownloadTask> tasks,
    required AppSettings settings,
  }) {
    final StoredAppState snapshot = StoredAppState(
      tasks: tasks,
      settings: settings,
    );

    final Future<void> operation = _writeTail.then((_) => _saveNow(snapshot));

    // Keep the queue usable after a failed save while still returning the
    // original failure to that save's caller.
    _writeTail = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  StoredAppState _decode(String contents) {
    final Object? decoded = jsonDecode(contents);
    if (decoded is! Map) {
      throw const FormatException('The persisted app state must be an object.');
    }

    final Map<String, dynamic> document = Map<String, dynamic>.from(decoded);
    if (document['schemaVersion'] != schemaVersion) {
      throw FormatException(
        'Unsupported app-state schema: ${document['schemaVersion']}.',
      );
    }

    final Object? rawTasks = document['tasks'];
    if (rawTasks is! List) {
      throw const FormatException('The persisted task list is invalid.');
    }

    final List<DownloadTask> tasks = rawTasks
        .map((Object? rawTask) {
          if (rawTask is! Map) {
            throw const FormatException(
              'A persisted download task is invalid.',
            );
          }
          return DownloadTask.fromJson(Map<String, dynamic>.from(rawTask));
        })
        .toList(growable: false);

    final Object? rawSettings = document['settings'];
    final AppSettings? settings;
    if (rawSettings == null) {
      settings = null;
    } else if (rawSettings is Map) {
      settings = AppSettings.fromJson(Map<String, dynamic>.from(rawSettings));
    } else {
      throw const FormatException('The persisted settings are invalid.');
    }

    return StoredAppState(tasks: tasks, settings: settings);
  }

  Future<void> _saveNow(StoredAppState snapshot) async {
    final File target = await _stateFile();
    await target.parent.create(recursive: true);

    final String contents = _encoder.convert(<String, Object?>{
      'schemaVersion': schemaVersion,
      'tasks': snapshot.tasks
          .map((DownloadTask task) => task.toJson())
          .toList(growable: false),
      'settings': snapshot.settings?.toJson(),
    });

    final File temporaryFile = await _newTemporaryFile(target);
    try {
      await temporaryFile.writeAsString(contents, flush: true);
      await temporaryFile.rename(target.path);
    } finally {
      // The path no longer exists after a successful rename.
      if (await temporaryFile.exists()) {
        await temporaryFile.delete();
      }
    }
  }

  Future<File> _stateFile() async {
    final Directory directory;
    if (_baseDirectory case final String baseDirectory) {
      directory = Directory(baseDirectory);
    } else {
      directory = await getApplicationSupportDirectory();
    }
    return File(path.join(directory.path, fileName));
  }

  Future<File> _newTemporaryFile(File target) async {
    final String timestamp = DateTime.now()
        .toUtc()
        .microsecondsSinceEpoch
        .toString();
    var attempt = 0;

    while (true) {
      final File candidate = File(
        path.join(
          target.parent.path,
          '.${path.basename(target.path)}.$pid-$timestamp-$attempt.tmp',
        ),
      );
      if (!await candidate.exists()) {
        return candidate;
      }
      attempt++;
    }
  }

  Future<void> _preserveBrokenFile(File file) async {
    final String extension = path.extension(file.path);
    final String baseName = path.basenameWithoutExtension(file.path);
    final String timestamp = DateTime.now()
        .toUtc()
        .microsecondsSinceEpoch
        .toString();
    var attempt = 0;

    while (true) {
      final String suffix = attempt == 0 ? '' : '-$attempt';
      final File brokenFile = File(
        path.join(
          file.parent.path,
          '$baseName.broken-$timestamp$suffix$extension',
        ),
      );
      if (!await brokenFile.exists()) {
        await file.rename(brokenFile.path);
        return;
      }
      attempt++;
    }
  }
}
