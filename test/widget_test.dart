import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ipfs_downloader/src/app.dart';
import 'package:ipfs_downloader/src/application/download_controller.dart';
import 'package:ipfs_downloader/src/data/app_storage.dart';
import 'package:ipfs_downloader/src/data/download_engine.dart';
import 'package:ipfs_downloader/src/domain/app_settings.dart';
import 'package:ipfs_downloader/src/domain/download_task.dart';

void main() {
  testWidgets('shows the desktop download workspace', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = DownloadController(
      storage: _MemoryStorage(),
      engine: DownloadEngine(),
      settings: AppSettings.defaults(
        downloadDirectory: '/tmp/ipfs-downloader-tests',
      ).copyWith(autoStart: false, localePreference: AppLocalePreference.de),
    );

    await tester.pumpWidget(IPFSDownloaderApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('IPFSDownloader'), findsOneWidget);
    expect(find.text('Downloads'), findsOneWidget);
    expect(find.byKey(const Key('quick-add-card')), findsOneWidget);
    expect(find.text('Deine Warteschlange ist leer'), findsOneWidget);
  });

  testWidgets('adds a valid CID to the queue', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = DownloadController(
      storage: _MemoryStorage(),
      engine: DownloadEngine(),
      settings: AppSettings.defaults(
        downloadDirectory: '/tmp/ipfs-downloader-tests',
      ).copyWith(autoStart: false, localePreference: AppLocalePreference.de),
    );

    await tester.pumpWidget(IPFSDownloaderApp(controller: controller));
    await tester.enterText(
      find.byKey(const Key('cid-input')),
      'QmYwAPJzv5CZsnAzt8auVZRnGi6S9mR8zXf6fkmY5QnN2j',
    );
    await tester.tap(find.byKey(const Key('start-download-button')));
    await tester.pumpAndSettle();

    expect(controller.tasks, hasLength(1));
    expect(controller.tasks.single.status, DownloadStatus.queued);
    expect(find.text('Wartend'), findsOneWidget);
  });

  testWidgets('uses compact navigation without layout overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(780, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = DownloadController(
      storage: _MemoryStorage(),
      engine: DownloadEngine(),
      settings: AppSettings.defaults(
        downloadDirectory: '/tmp/ipfs-downloader-tests',
      ).copyWith(autoStart: false, localePreference: AppLocalePreference.de),
    );

    await tester.pumpWidget(IPFSDownloaderApp(controller: controller));
    await tester.pump();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final (locale, expectedTitle) in <(AppLocalePreference, String)>[
    (AppLocalePreference.de, 'Deine Warteschlange ist leer'),
    (AppLocalePreference.en, 'Your queue is empty'),
    (AppLocalePreference.fr, 'Votre file d’attente est vide'),
  ]) {
    testWidgets('renders the ${locale.name} interface', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = DownloadController(
        storage: _MemoryStorage(),
        engine: DownloadEngine(),
        settings: AppSettings.defaults(
          downloadDirectory: '/tmp/ipfs-downloader-tests',
        ).copyWith(autoStart: false, localePreference: locale),
      );

      await tester.pumpWidget(IPFSDownloaderApp(controller: controller));
      await tester.pumpAndSettle();

      expect(find.text(expectedTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('switches the interface language at runtime', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = DownloadController(
      storage: _MemoryStorage(),
      engine: DownloadEngine(),
      settings: AppSettings.defaults(
        downloadDirectory: '/tmp/ipfs-downloader-tests',
      ).copyWith(autoStart: false, localePreference: AppLocalePreference.en),
    );

    await tester.pumpWidget(IPFSDownloaderApp(controller: controller));
    await tester.pumpAndSettle();
    expect(find.text('Your queue is empty'), findsOneWidget);

    controller.updateSettings(
      controller.settings.copyWith(localePreference: AppLocalePreference.fr),
    );
    await tester.pumpAndSettle();

    expect(find.text('Votre file d’attente est vide'), findsOneWidget);
    expect(find.text('Your queue is empty'), findsNothing);
  });
}

class _MemoryStorage implements AppStorage {
  @override
  Future<StoredAppState> load() async => StoredAppState.empty();

  @override
  Future<void> save({
    required List<DownloadTask> tasks,
    required AppSettings settings,
  }) async {}
}
