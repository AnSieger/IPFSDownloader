import 'package:flutter_test/flutter_test.dart';
import 'package:ipfs_downloader/src/core/formatters.dart';

void main() {
  group('formatBytes', () {
    test('formats unavailable and byte values', () {
      expect(formatBytes(null), '–');
      expect(formatBytes(-1), '–');
      expect(formatBytes(0), '0 B');
      expect(formatBytes(1023), '1023 B');
      expect(formatBytes(1.5), '2 B');
    });

    test('selects binary-scaled units and precision', () {
      expect(formatBytes(1024), '1.0 KB');
      expect(formatBytes(1536), '1.5 KB');
      expect(formatBytes(100 * 1024), '100 KB');
      expect(formatBytes(1.25 * 1024 * 1024), '1.3 MB');
      expect(formatBytes(3 * 1024 * 1024 * 1024), '3.0 GB');
    });

    test('honors an explicit decimal count below 100 units', () {
      expect(formatBytes(1536, decimals: 2), '1.50 KB');
    });
  });

  group('formatSpeed', () {
    test('formats inactive and active transfer rates', () {
      expect(formatSpeed(-1), '–');
      expect(formatSpeed(0), '–');
      expect(formatSpeed(1536), '1.5 KB/s');
    });
  });

  group('formatDuration', () {
    test('formats unavailable, zero and negative durations', () {
      expect(formatDuration(null), '–');
      expect(formatDuration(Duration.zero), '0 s');
      expect(formatDuration(const Duration(seconds: -5)), '0 s');
    });

    test('formats seconds, minutes and hours', () {
      expect(formatDuration(const Duration(seconds: 42)), '42 Sek.');
      expect(
        formatDuration(const Duration(minutes: 2, seconds: 7)),
        '2 Min. 7 Sek.',
      );
      expect(
        formatDuration(const Duration(hours: 3, minutes: 4, seconds: 5)),
        '3 Std. 4 Min.',
      );
    });
  });

  group('compactCid', () {
    test('keeps short values unchanged', () {
      expect(compactCid('abcdefgh', leading: 4, trailing: 3), 'abcdefgh');
    });

    test('compacts the middle of long values', () {
      expect(
        compactCid('abcdefghijklmnop', leading: 4, trailing: 3),
        'abcd…nop',
      );
    });
  });

  group('formatCount', () {
    test('uses singular only for exactly one item', () {
      expect(formatCount(0, 'Datei', 'Dateien'), '0 Dateien');
      expect(formatCount(1, 'Datei', 'Dateien'), '1 Datei');
      expect(formatCount(2, 'Datei', 'Dateien'), '2 Dateien');
    });
  });
}
