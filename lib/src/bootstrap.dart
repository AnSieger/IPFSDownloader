import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'application/download_controller.dart';
import 'data/app_storage.dart';
import 'data/download_engine.dart';
import 'domain/app_settings.dart';

Future<Widget> bootstrapApplication() async {
  final storage = FileAppStorage();
  final storedState = await storage.load();
  final downloadsDirectory = await _defaultDownloadsDirectory();
  final storedSettings = storedState.settings;
  final settings = storedSettings == null
      ? AppSettings.defaults(downloadDirectory: downloadsDirectory)
      : storedSettings.defaultDownloadDirectory.isEmpty
      ? storedSettings.copyWith(defaultDownloadDirectory: downloadsDirectory)
      : storedSettings.copyWith(
          defaultDownloadDirectory: await _canonicalDirectoryPath(
            storedSettings.defaultDownloadDirectory,
          ),
        );

  final controller = DownloadController(
    storage: storage,
    engine: DownloadEngine(),
    settings: settings,
    tasks: storedState.tasks,
  );
  controller.startInitialQueue();
  return IPFSDownloaderApp(controller: controller);
}

Future<String> _defaultDownloadsDirectory() async {
  try {
    final directory = await getDownloadsDirectory();
    if (directory != null) {
      return await _canonicalDirectoryPath(directory.path);
    }
  } on UnsupportedError {
    // Fall through to a useful desktop fallback.
  }
  return Directory.current.path;
}

Future<String> _canonicalDirectoryPath(String directoryPath) async {
  try {
    return await Directory(directoryPath).resolveSymbolicLinks();
  } on FileSystemException {
    return directoryPath;
  }
}
