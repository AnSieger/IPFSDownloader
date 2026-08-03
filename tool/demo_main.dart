import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ipfs_downloader/src/app.dart';
import 'package:ipfs_downloader/src/application/download_controller.dart';
import 'package:ipfs_downloader/src/data/app_storage.dart';
import 'package:ipfs_downloader/src/data/download_engine.dart';
import 'package:ipfs_downloader/src/domain/app_settings.dart';
import 'package:ipfs_downloader/src/domain/download_task.dart';

const _cid = 'bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi';
const _screenshotPath = String.fromEnvironment('SCREENSHOT_PATH');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final screenshotBoundaryKey = GlobalKey();
  runApp(
    RepaintBoundary(
      key: screenshotBoundaryKey,
      child: IPFSDownloaderApp(
        controller: DownloadController(
          storage: _DemoStorage(),
          engine: DownloadEngine(),
          settings: const AppSettings(
            defaultDownloadDirectory: '/Users/demo/Downloads',
            autoStart: false,
            themePreference: AppThemePreference.light,
            localePreference: AppLocalePreference.en,
          ),
          tasks: _tasks,
        ),
      ),
    ),
  );
  if (_screenshotPath.isNotEmpty) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _writeScreenshot(screenshotBoundaryKey);
    });
  }
}

Future<void> _writeScreenshot(GlobalKey boundaryKey) async {
  await Future<void>.delayed(const Duration(seconds: 2));
  final boundary =
      boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) {
    throw StateError('The screenshot boundary is not available.');
  }
  final image = await boundary.toImage(pixelRatio: 1);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (data == null) throw StateError('The screenshot could not be encoded.');
  await File(_screenshotPath).writeAsBytes(data.buffer.asUint8List());
  debugPrint('Screenshot written to $_screenshotPath');
}

final List<DownloadTask> _tasks = <DownloadTask>[
  DownloadTask(
    id: 'active-preview',
    cid: _cid,
    ipfsPath: 'archives/orbit-observations.zip',
    fileName: 'orbit-observations.zip',
    destinationDirectory: '/Users/demo/Downloads',
    status: DownloadStatus.downloading,
    receivedBytes: 748683264,
    totalBytes: 1207959552,
    speedBytesPerSecond: 13002342,
    createdAt: DateTime.utc(2026, 8, 3, 8, 30),
    gateway: 'https://dweb.link',
  ),
  DownloadTask(
    id: 'paused-preview',
    cid: _cid,
    ipfsPath: 'design/design-assets',
    fileName: 'design-assets.tar',
    destinationDirectory: '/Users/demo/Downloads',
    status: DownloadStatus.paused,
    receivedBytes: 314572800,
    totalBytes: 838860800,
    createdAt: DateTime.utc(2026, 8, 3, 8, 28),
    gateway: 'http://127.0.0.1:8080',
    isDirectoryArchive: true,
  ),
  DownloadTask(
    id: 'completed-preview',
    cid: _cid,
    ipfsPath: 'papers/distributed-systems.pdf',
    fileName: 'distributed-systems.pdf',
    destinationDirectory: '/Users/demo/Downloads',
    status: DownloadStatus.completed,
    receivedBytes: 19084083,
    totalBytes: 19084083,
    createdAt: DateTime.utc(2026, 8, 3, 8, 27),
    completedAt: DateTime.utc(2026, 8, 3, 8, 31),
    gateway: 'https://ipfs.io',
  ),
];

class _DemoStorage implements AppStorage {
  @override
  Future<StoredAppState> load() async => StoredAppState.empty();

  @override
  Future<void> save({
    required List<DownloadTask> tasks,
    required AppSettings settings,
  }) async {}
}
