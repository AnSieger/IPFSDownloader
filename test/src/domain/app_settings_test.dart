import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ipfs_downloader/src/domain/app_settings.dart';

void main() {
  group('AppSettings.defaults', () {
    test('provides the expected safe application defaults', () {
      final AppSettings settings = AppSettings.defaults(
        downloadDirectory: '/downloads',
      );

      expect(settings.defaultDownloadDirectory, '/downloads');
      expect(settings.gateways, AppSettings.defaultGateways);
      expect(settings.maxConcurrentDownloads, 3);
      expect(settings.autoStart, isTrue);
      expect(settings.themePreference, AppThemePreference.system);
      expect(settings.localePreference, AppLocalePreference.system);
      expect(settings.connectionTimeoutSeconds, 20);
    });
  });

  group('AppSettings JSON', () {
    test('round-trips all settings through real JSON', () {
      const AppSettings original = AppSettings(
        defaultDownloadDirectory: '/data/ipfs',
        gateways: <String>['http://127.0.0.1:8080', 'https://dweb.link'],
        maxConcurrentDownloads: 5,
        autoStart: false,
        themePreference: AppThemePreference.dark,
        localePreference: AppLocalePreference.fr,
        connectionTimeoutSeconds: 45,
      );
      final Map<String, dynamic> encoded =
          jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>;

      final AppSettings restored = AppSettings.fromJson(encoded);

      expect(restored.toJson(), original.toJson());
    });

    test('normalizes gateways and filters unusable entries', () {
      final AppSettings settings = AppSettings.fromJson(<String, dynamic>{
        'defaultDownloadDirectory': '/downloads',
        'gateways': <Object?>[
          ' https://dweb.link/// ',
          '',
          42,
          'http://127.0.0.1:8080/',
        ],
      });

      expect(settings.gateways, <String>[
        'https://dweb.link',
        'http://127.0.0.1:8080',
      ]);
    });

    test('falls back to default gateways when none are usable', () {
      final AppSettings settings = AppSettings.fromJson(<String, dynamic>{
        'gateways': <Object?>['', 42, null],
      });

      expect(settings.gateways, AppSettings.defaultGateways);
    });

    test('clamps concurrency and timeout to supported ranges', () {
      final AppSettings lower = AppSettings.fromJson(<String, dynamic>{
        'maxConcurrentDownloads': 0,
        'connectionTimeoutSeconds': 1,
      });
      final AppSettings upper = AppSettings.fromJson(<String, dynamic>{
        'maxConcurrentDownloads': 99,
        'connectionTimeoutSeconds': 999,
      });

      expect(lower.maxConcurrentDownloads, 1);
      expect(lower.connectionTimeoutSeconds, 5);
      expect(upper.maxConcurrentDownloads, 8);
      expect(upper.connectionTimeoutSeconds, 120);
    });

    test('migrates the legacy darkMode setting', () {
      final AppSettings dark = AppSettings.fromJson(<String, dynamic>{
        'darkMode': true,
      });
      final AppSettings system = AppSettings.fromJson(<String, dynamic>{
        'themePreference': 'unknown-future-value',
      });

      expect(dark.themePreference, AppThemePreference.dark);
      expect(system.themePreference, AppThemePreference.system);
    });

    test('falls back to the system locale for unknown values', () {
      final AppSettings settings = AppSettings.fromJson(<String, dynamic>{
        'localePreference': 'unknown-future-value',
      });

      expect(settings.localePreference, AppLocalePreference.system);
    });
  });

  group('AppSettings helpers', () {
    test('normalizes surrounding whitespace and trailing slashes', () {
      expect(
        AppSettings.normalizeGateway(' https://ipfs.io/// '),
        'https://ipfs.io',
      );
      expect(AppSettings.normalizeGateway('   '), isEmpty);
    });

    test('copyWith updates values and applies range limits', () {
      final AppSettings copied = AppSettings.defaults().copyWith(
        defaultDownloadDirectory: '/new',
        maxConcurrentDownloads: 20,
        connectionTimeoutSeconds: 2,
        autoStart: false,
        themePreference: AppThemePreference.light,
        localePreference: AppLocalePreference.en,
      );

      expect(copied.defaultDownloadDirectory, '/new');
      expect(copied.maxConcurrentDownloads, 8);
      expect(copied.connectionTimeoutSeconds, 5);
      expect(copied.autoStart, isFalse);
      expect(copied.themePreference, AppThemePreference.light);
      expect(copied.localePreference, AppLocalePreference.en);
    });
  });
}
