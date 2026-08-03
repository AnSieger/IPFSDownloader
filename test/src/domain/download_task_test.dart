import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ipfs_downloader/src/domain/download_task.dart';
import 'package:path/path.dart' as path;

const String _cid =
    'bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi';

void main() {
  group('DownloadStatusInfo', () {
    test('classifies active and finished states', () {
      expect(DownloadStatus.queued.isActive, isFalse);
      expect(DownloadStatus.resolving.isActive, isTrue);
      expect(DownloadStatus.downloading.isActive, isTrue);
      expect(DownloadStatus.paused.isActive, isFalse);

      expect(DownloadStatus.completed.isFinished, isTrue);
      expect(DownloadStatus.failed.isFinished, isTrue);
      expect(DownloadStatus.canceled.isFinished, isTrue);
      expect(DownloadStatus.downloading.isFinished, isFalse);
    });
  });

  group('DownloadTask JSON', () {
    test('round-trips every persisted property', () {
      final DownloadTask original = _fullTask();
      final Map<String, dynamic> encoded =
          jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>;

      final DownloadTask restored = DownloadTask.fromJson(encoded);

      expect(restored.toJson(), original.toJson());
      expect(encoded['createdAt'], '2026-07-31T08:15:00.000Z');
      expect(encoded['completedAt'], '2026-07-31T08:45:00.000Z');
    });

    test('uses safe defaults for optional and unknown values', () {
      final Map<String, dynamic> json = _fullTask().toJson()
        ..remove('ipfsPath')
        ..remove('receivedBytes')
        ..remove('totalBytes')
        ..remove('speedBytesPerSecond')
        ..remove('retryCount')
        ..remove('isDirectoryArchive')
        ..remove('fileNameIsProvisional')
        ..['status'] = 'future-status';

      final DownloadTask restored = DownloadTask.fromJson(json);

      expect(restored.ipfsPath, isEmpty);
      expect(restored.status, DownloadStatus.queued);
      expect(restored.receivedBytes, 0);
      expect(restored.totalBytes, isNull);
      expect(restored.speedBytesPerSecond, 0);
      expect(restored.retryCount, 0);
      expect(restored.isDirectoryArchive, isFalse);
      expect(restored.fileNameIsProvisional, isFalse);
    });

    test('restores an explicitly persisted provisional-name marker', () {
      final Map<String, dynamic> json = _fullTask().toJson()
        ..['fileNameIsProvisional'] = true;

      final DownloadTask restored = DownloadTask.fromJson(json);

      expect(restored.fileNameIsProvisional, isTrue);
      expect(restored.toJson()['fileNameIsProvisional'], isTrue);
    });

    test('infers provisional bare-CID .bin names from legacy data', () {
      final Map<String, dynamic> json = _fullTask().toJson()
        ..remove('fileNameIsProvisional')
        ..['status'] = DownloadStatus.queued.name
        ..['ipfsPath'] = ''
        ..['fileName'] = 'bafy-placeholder.BIN'
        ..['isDirectoryArchive'] = false;

      expect(DownloadTask.fromJson(json).fileNameIsProvisional, isTrue);
    });

    test('infers provisional extensionless IPFS paths from legacy data', () {
      final Map<String, dynamic> json = _fullTask().toJson()
        ..remove('fileNameIsProvisional')
        ..['status'] = DownloadStatus.paused.name
        ..['ipfsPath'] = 'documents/README'
        ..['fileName'] = 'README'
        ..['isDirectoryArchive'] = false;

      expect(DownloadTask.fromJson(json).fileNameIsProvisional, isTrue);
    });

    test('does not infer provisional names for ineligible legacy tasks', () {
      Map<String, dynamic> legacyJson({
        required DownloadStatus status,
        required String ipfsPath,
        required String fileName,
        required bool isDirectoryArchive,
      }) {
        return _fullTask().toJson()
          ..remove('fileNameIsProvisional')
          ..['status'] = status.name
          ..['ipfsPath'] = ipfsPath
          ..['fileName'] = fileName
          ..['isDirectoryArchive'] = isDirectoryArchive;
      }

      final List<Map<String, dynamic>> cases = <Map<String, dynamic>>[
        legacyJson(
          status: DownloadStatus.completed,
          ipfsPath: '',
          fileName: 'download.bin',
          isDirectoryArchive: false,
        ),
        legacyJson(
          status: DownloadStatus.queued,
          ipfsPath: '',
          fileName: 'download.bin',
          isDirectoryArchive: true,
        ),
        legacyJson(
          status: DownloadStatus.queued,
          ipfsPath: 'firmware.bin',
          fileName: 'firmware.bin',
          isDirectoryArchive: false,
        ),
        legacyJson(
          status: DownloadStatus.queued,
          ipfsPath: 'documents/README',
          fileName: 'README.txt',
          isDirectoryArchive: false,
        ),
        legacyJson(
          status: DownloadStatus.queued,
          ipfsPath: '',
          fileName: 'download.jpg',
          isDirectoryArchive: false,
        ),
      ];

      expect(
        cases.map(
          (Map<String, dynamic> json) =>
              DownloadTask.fromJson(json).fileNameIsProvisional,
        ),
        everyElement(isFalse),
      );
    });

    test('rejects missing required string properties', () {
      final Map<String, dynamic> json = _fullTask().toJson()..['cid'] = '';

      expect(
        () => DownloadTask.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('DownloadTask derived values', () {
    test('builds destination and canonical IPFS paths', () {
      final DownloadTask task = _fullTask();

      expect(task.finalPath, path.join('/downloads', 'archive.zip'));
      expect(task.partialPath, '${task.finalPath}.part');
      expect(task.canonicalSource, '/ipfs/$_cid/releases/archive.zip');
      expect(task.copyWith(ipfsPath: '').canonicalSource, '/ipfs/$_cid');
    });

    test('calculates and clamps progress', () {
      final DownloadTask task = _fullTask();

      expect(task.copyWith(receivedBytes: 250, totalBytes: 1000).progress, .25);
      expect(task.copyWith(receivedBytes: 1200, totalBytes: 1000).progress, 1);
      expect(task.copyWith(receivedBytes: -10, totalBytes: 1000).progress, 0);
      expect(task.copyWith(totalBytes: 0).progress, isNull);
      expect(task.copyWith(totalBytes: null).progress, isNull);
    });

    test('calculates a rounded-up remaining duration', () {
      final DownloadTask task = _fullTask();

      expect(
        task
            .copyWith(
              receivedBytes: 100,
              totalBytes: 1000,
              speedBytesPerSecond: 350,
            )
            .estimatedTimeRemaining,
        const Duration(seconds: 3),
      );
      expect(
        task
            .copyWith(receivedBytes: 1000, totalBytes: 1000)
            .estimatedTimeRemaining,
        Duration.zero,
      );
      expect(
        task.copyWith(speedBytesPerSecond: 0).estimatedTimeRemaining,
        isNull,
      );
      expect(task.copyWith(totalBytes: null).estimatedTimeRemaining, isNull);
    });
  });

  group('DownloadTask.copyWith', () {
    test('updates values and can explicitly clear nullable fields', () {
      final DownloadTask copied = _fullTask().copyWith(
        status: DownloadStatus.paused,
        totalBytes: null,
        completedAt: null,
        error: null,
        gateway: null,
        fileNameIsProvisional: true,
      );

      expect(copied.status, DownloadStatus.paused);
      expect(copied.totalBytes, isNull);
      expect(copied.completedAt, isNull);
      expect(copied.error, isNull);
      expect(copied.gateway, isNull);
      expect(copied.fileNameIsProvisional, isTrue);
      expect(copied.id, 'task-1');
      expect(copied.cid, _cid);
    });
  });
}

DownloadTask _fullTask() {
  return DownloadTask(
    id: 'task-1',
    cid: _cid,
    ipfsPath: 'releases/archive.zip',
    fileName: 'archive.zip',
    destinationDirectory: '/downloads',
    status: DownloadStatus.completed,
    receivedBytes: 8192,
    totalBytes: 8192,
    speedBytesPerSecond: 2048.5,
    createdAt: DateTime.parse('2026-07-31T10:15:00+02:00'),
    completedAt: DateTime.parse('2026-07-31T10:45:00+02:00'),
    error: 'previous retry',
    gateway: 'https://dweb.link',
    retryCount: 2,
    isDirectoryArchive: true,
  );
}
