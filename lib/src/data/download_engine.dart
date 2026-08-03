import 'dart:async';
import 'dart:io';

import 'package:ipfs_downloader/src/core/file_type_detector.dart';
import 'package:ipfs_downloader/src/domain/app_settings.dart';
import 'package:ipfs_downloader/src/domain/download_task.dart';
import 'package:path/path.dart' as path;

typedef DownloadProgressCallback = void Function(DownloadTask task);

/// Streams immutable IPFS gateway responses to disk.
///
/// The partial file is the source of truth for resume offsets. A gateway may
/// ignore a Range request and answer with 200; in that case the partial file is
/// deliberately truncated before the response is written.
class DownloadEngine {
  DownloadEngine({
    HttpClient Function()? httpClientFactory,
    DateTime Function()? clock,
    Duration progressInterval = const Duration(milliseconds: 120),
  }) : _httpClientFactory = httpClientFactory ?? HttpClient.new,
       _clock = clock ?? DateTime.now,
       _progressInterval = progressInterval;

  final HttpClient Function() _httpClientFactory;
  final DateTime Function() _clock;
  final Duration _progressInterval;
  final Map<String, _DownloadControl> _active = <String, _DownloadControl>{};
  final Set<String> _reservedFinalPaths = <String>{};

  bool _closed = false;

  Future<DownloadTask> download(
    DownloadTask task,
    AppSettings settings, {
    required DownloadProgressCallback onProgress,
  }) async {
    if (_closed) {
      throw DownloadFailure('Die Download-Engine wurde bereits geschlossen.');
    }
    if (_active.containsKey(task.id)) {
      throw DownloadFailure(
        'Für diese Aufgabe läuft bereits ein Download.',
        task: task,
      );
    }

    final control = _DownloadControl();
    _active[task.id] = control;
    var current = task;
    File? partialFile;

    void publish(DownloadTask update) {
      current = update;
      onProgress(update);
    }

    try {
      final destinationDirectory = task.destinationDirectory.trim().isNotEmpty
          ? task.destinationDirectory.trim()
          : settings.defaultDownloadDirectory.trim();
      if (destinationDirectory.isEmpty) {
        throw const DownloadFailure('Es wurde kein Zielordner ausgewählt.');
      }

      final destination = Directory(destinationDirectory);
      await destination.create(recursive: true);

      final initialName = await _selectInitialFileName(
        destination: destination,
        task: task,
      );
      current = task.copyWith(
        destinationDirectory: destination.path,
        fileName: initialName,
        status: DownloadStatus.resolving,
        completedAt: null,
        error: null,
        speedBytesPerSecond: 0,
      );
      partialFile = File(current.partialPath);

      final gateways = _orderedGateways(
        settings.gateways,
        preferred: task.gateway,
      );
      if (gateways.isEmpty) {
        throw const DownloadFailure(
          'Es ist kein gültiges HTTP-Gateway konfiguriert.',
        );
      }

      final failures = <String>[];
      for (
        var gatewayIndex = 0;
        gatewayIndex < gateways.length;
        gatewayIndex++
      ) {
        if (control.paused) throw const _PauseSignal();

        final gateway = gateways[gatewayIndex];
        final previousGateway = current.gateway;

        // TAR streams are not guaranteed to have the same byte layout on
        // different gateway implementations. Never splice two such streams.
        if (current.isDirectoryArchive &&
            previousGateway != null &&
            !_sameGateway(previousGateway, gateway) &&
            await partialFile.exists()) {
          await _truncate(partialFile);
          current = current.copyWith(
            receivedBytes: 0,
            totalBytes: null,
            speedBytesPerSecond: 0,
          );
        }

        final existingBytes = await _fileLength(partialFile);
        publish(
          current.copyWith(
            status: DownloadStatus.resolving,
            receivedBytes: existingBytes,
            gateway: gateway,
            error: null,
            speedBytesPerSecond: 0,
          ),
        );

        try {
          final completed = await _downloadFromGateway(
            task: current,
            settings: settings,
            gateway: gateway,
            partialFile: partialFile,
            control: control,
            onProgress: publish,
          );
          return completed;
        } on _PauseSignal {
          rethrow;
        } catch (error) {
          if (control.paused) throw const _PauseSignal();

          final receivedBytes = await _fileLength(partialFile);
          final message = _errorMessage(error);
          failures.add('$gateway: $message');
          current = current.copyWith(
            status: DownloadStatus.resolving,
            receivedBytes: receivedBytes,
            speedBytesPerSecond: 0,
            retryCount: current.retryCount + 1,
            error: message,
          );
          publish(current);
        }
      }

      throw DownloadFailure(
        'Kein Gateway konnte den Inhalt laden. ${failures.join(' · ')}',
        task: current,
      );
    } on _PauseSignal {
      final receivedBytes = partialFile == null
          ? current.receivedBytes
          : await _fileLength(partialFile);
      final paused = current.copyWith(
        status: DownloadStatus.paused,
        receivedBytes: receivedBytes,
        speedBytesPerSecond: 0,
        error: null,
      );
      publish(paused);
      throw DownloadPausedException(paused);
    } on DownloadPausedException {
      rethrow;
    } on DownloadFailure catch (failure) {
      final failed = current.copyWith(
        status: DownloadStatus.failed,
        receivedBytes: partialFile == null
            ? current.receivedBytes
            : await _fileLength(partialFile),
        speedBytesPerSecond: 0,
        error: failure.message,
      );
      publish(failed);
      throw DownloadFailure(
        failure.message,
        task: failed,
        cause: failure.cause,
      );
    } catch (error) {
      if (control.paused) {
        final receivedBytes = partialFile == null
            ? current.receivedBytes
            : await _fileLength(partialFile);
        final paused = current.copyWith(
          status: DownloadStatus.paused,
          receivedBytes: receivedBytes,
          speedBytesPerSecond: 0,
          error: null,
        );
        publish(paused);
        throw DownloadPausedException(paused);
      }

      final message = _errorMessage(error);
      final failed = current.copyWith(
        status: DownloadStatus.failed,
        receivedBytes: partialFile == null
            ? current.receivedBytes
            : await _fileLength(partialFile),
        speedBytesPerSecond: 0,
        error: message,
      );
      publish(failed);
      throw DownloadFailure(message, task: failed, cause: error);
    } finally {
      control.client?.close(force: true);
      _active.remove(task.id);
      if (!control.done.isCompleted) control.done.complete();
    }
  }

  void pause(String taskId) {
    _active[taskId]?.pause();
  }

  Future<void> deletePartial(DownloadTask task) async {
    final active = _active[task.id];
    if (active != null) {
      active.pause();
      await active.done.future;
    }

    final safeName = _effectiveFileName(task);
    if (task.destinationDirectory.trim().isEmpty) return;
    final partial = File(
      '${path.join(task.destinationDirectory, safeName)}.part',
    );
    if (await partial.exists()) await partial.delete();
  }

  void close() {
    if (_closed) return;
    _closed = true;
    for (final control in _active.values.toList(growable: false)) {
      control.pause();
    }
  }

  Future<DownloadTask> _downloadFromGateway({
    required DownloadTask task,
    required AppSettings settings,
    required String gateway,
    required File partialFile,
    required _DownloadControl control,
    required DownloadProgressCallback onProgress,
  }) async {
    final uri = _gatewayUri(gateway, task);
    final timeout = Duration(seconds: settings.connectionTimeoutSeconds);
    final client = _httpClientFactory()
      ..autoUncompress = false
      ..connectionTimeout = timeout
      ..idleTimeout = timeout;
    control.client = client;

    var current = task;
    String? acceptedContentType;
    String? acceptedContentDisposition;
    try {
      while (true) {
        if (control.paused) throw const _PauseSignal();

        final resumeOffset = await _fileLength(partialFile);
        final request = await client.getUrl(uri).timeout(timeout);
        control.request = request;
        request.followRedirects = true;
        request.maxRedirects = 5;
        request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
        request.headers.set(
          HttpHeaders.acceptHeader,
          task.isDirectoryArchive ? 'application/x-tar' : '*/*',
        );
        request.headers.set(HttpHeaders.userAgentHeader, 'IPFSDownloader/1.0');
        if (resumeOffset > 0) {
          request.headers.set(HttpHeaders.rangeHeader, 'bytes=$resumeOffset-');
        }

        final response = await request.close().timeout(timeout);
        if (control.paused) throw const _PauseSignal();

        if (response.statusCode == 416) {
          final total = _unsatisfiedRangeTotal(
            response.headers.value(HttpHeaders.contentRangeHeader),
          );
          // Representation headers on a 416 can describe the gateway's error
          // body rather than the already stored payload. Type detection below
          // therefore relies on the completed partial file in this branch.
          await response.drain<void>();
          if (total != null && total == resumeOffset) {
            current = current.copyWith(
              status: DownloadStatus.downloading,
              receivedBytes: resumeOffset,
              totalBytes: total,
              gateway: gateway,
              error: null,
            );
            onProgress(current);
            break;
          }
          throw _GatewayResponseException(
            response.statusCode,
            'Der gespeicherte Teil passt nicht zur Dateigröße des Gateways.',
          );
        }

        if (response.statusCode != HttpStatus.ok &&
            response.statusCode != HttpStatus.partialContent) {
          final status = response.statusCode;
          await response.drain<void>();
          throw _GatewayResponseException(status, 'HTTP $status vom Gateway.');
        }

        final transfer = _validateResponse(
          response: response,
          requestedOffset: resumeOffset,
          previousTotal: current.totalBytes,
        );
        acceptedContentType = _preferredContentType(
          acceptedContentType,
          response.headers.value(HttpHeaders.contentTypeHeader),
        );
        acceptedContentDisposition ??= response.headers.value(
          'content-disposition',
        );
        if (transfer.writeMode == FileMode.write && resumeOffset > 0) {
          current = current.copyWith(
            receivedBytes: 0,
            totalBytes: transfer.totalBytes,
            speedBytesPerSecond: 0,
          );
        }

        current = current.copyWith(
          status: DownloadStatus.downloading,
          receivedBytes: transfer.startOffset,
          totalBytes: transfer.totalBytes,
          speedBytesPerSecond: 0,
          gateway: gateway,
          error: null,
        );
        onProgress(current);

        final output = await partialFile.open(mode: transfer.writeMode);
        final progressClock = Stopwatch()..start();
        var lastProgress = Duration.zero;
        var receivedBytes = transfer.startOffset;
        var bodyBytes = 0;

        try {
          await for (final chunk in response.timeout(timeout)) {
            if (control.paused) throw const _PauseSignal();
            await output.writeFrom(chunk);
            receivedBytes += chunk.length;
            bodyBytes += chunk.length;

            final elapsed = progressClock.elapsed;
            if (elapsed - lastProgress >= _progressInterval) {
              final seconds = elapsed.inMicroseconds / 1000000;
              final speed = seconds <= 0 ? 0.0 : bodyBytes / seconds;
              current = current.copyWith(
                receivedBytes: receivedBytes,
                speedBytesPerSecond: speed,
              );
              onProgress(current);
              lastProgress = elapsed;
            }
          }
          await output.flush();
        } finally {
          await output.close();
        }

        if (transfer.expectedBodyBytes != null &&
            bodyBytes != transfer.expectedBodyBytes) {
          throw _GatewayResponseException(
            response.statusCode,
            'Die Antwort endete nach $bodyBytes statt nach '
            '${transfer.expectedBodyBytes} Bytes.',
          );
        }

        final diskBytes = await _fileLength(partialFile);
        current = current.copyWith(
          receivedBytes: diskBytes,
          totalBytes: transfer.totalBytes,
          speedBytesPerSecond: 0,
        );
        onProgress(current);

        final total = transfer.totalBytes;
        if (total != null && diskBytes < total) {
          if (diskBytes <= transfer.startOffset) {
            throw _GatewayResponseException(
              response.statusCode,
              'Das Gateway lieferte keine weiteren Daten.',
            );
          }
          continue;
        }
        if (total != null && diskBytes > total) {
          throw _GatewayResponseException(
            response.statusCode,
            'Die Teildatei ist größer als der gemeldete Inhalt.',
          );
        }
        break;
      }

      if (control.paused) throw const _PauseSignal();
      final receivedBytes = await _fileLength(partialFile);
      final totalBytes = current.totalBytes ?? receivedBytes;
      if (receivedBytes != totalBytes) {
        throw _GatewayResponseException(
          HttpStatus.partialContent,
          'Der Download ist unvollständig '
          '($receivedBytes von $totalBytes Bytes).',
        );
      }

      final desiredFinalName = await _detectedFinalFileName(
        task: current,
        partialFile: partialFile,
        contentType: acceptedContentType,
        contentDisposition: acceptedContentDisposition,
      );
      final reservation = await _reserveFinalFile(
        destination: Directory(current.destinationDirectory),
        desiredName: desiredFinalName,
        sourcePartial: partialFile,
      );
      try {
        await partialFile.rename(reservation.file.path);
      } finally {
        _reservedFinalPaths.remove(reservation.key);
      }
      final completed = current.copyWith(
        fileName: reservation.fileName,
        fileNameIsProvisional: false,
        status: DownloadStatus.completed,
        receivedBytes: receivedBytes,
        totalBytes: totalBytes,
        speedBytesPerSecond: 0,
        completedAt: _clock(),
        error: null,
        gateway: gateway,
      );
      onProgress(completed);
      return completed;
    } finally {
      control.request = null;
      if (identical(control.client, client)) control.client = null;
      client.close(force: true);
    }
  }

  _TransferPlan _validateResponse({
    required HttpClientResponse response,
    required int requestedOffset,
    required int? previousTotal,
  }) {
    if (response.statusCode == HttpStatus.ok) {
      final contentLength = response.contentLength;
      return _TransferPlan(
        writeMode: FileMode.write,
        startOffset: 0,
        totalBytes: contentLength >= 0 ? contentLength : previousTotal,
        expectedBodyBytes: contentLength >= 0 ? contentLength : null,
      );
    }

    final rawContentRange = response.headers.value(
      HttpHeaders.contentRangeHeader,
    );
    final contentRange = _ContentRange.tryParse(rawContentRange);
    if (contentRange == null) {
      throw _GatewayResponseException(
        response.statusCode,
        '206-Antwort ohne gültigen Content-Range-Header.',
      );
    }
    if (contentRange.start != requestedOffset) {
      throw _GatewayResponseException(
        response.statusCode,
        'Content-Range beginnt bei ${contentRange.start}, erwartet wurde '
        '$requestedOffset.',
      );
    }

    final expectedBodyBytes = contentRange.end - contentRange.start + 1;
    if (response.contentLength >= 0 &&
        response.contentLength != expectedBodyBytes) {
      throw _GatewayResponseException(
        response.statusCode,
        'Content-Length und Content-Range widersprechen sich.',
      );
    }
    if (contentRange.total != null &&
        previousTotal != null &&
        requestedOffset > 0 &&
        contentRange.total != previousTotal) {
      throw _GatewayResponseException(
        response.statusCode,
        'Die Dateigröße hat sich gegenüber dem begonnenen Download geändert.',
      );
    }

    return _TransferPlan(
      writeMode: requestedOffset == 0 ? FileMode.write : FileMode.append,
      startOffset: requestedOffset,
      totalBytes: contentRange.total ?? previousTotal,
      expectedBodyBytes: expectedBodyBytes,
    );
  }

  static String sanitizeFileName(String value, {String fallback = 'download'}) {
    var sanitized = value
        .replaceAll(RegExp(r'[\x00-\x1F\x7F<>:"/\\|?*]'), '_')
        .trim()
        .replaceFirst(RegExp(r'[. ]+$'), '');
    sanitized = sanitized.replaceAll(RegExp(r'_+'), '_');

    if (sanitized.isEmpty || sanitized == '.' || sanitized == '..') {
      sanitized = fallback
          .replaceAll(RegExp(r'[\x00-\x1F\x7F<>:"/\\|?*]'), '_')
          .trim();
    }
    if (sanitized.isEmpty || sanitized == '.' || sanitized == '..') {
      sanitized = 'download';
    }

    final dot = sanitized.indexOf('.');
    final stem = (dot < 0 ? sanitized : sanitized.substring(0, dot))
        .toUpperCase();
    if (RegExp(r'^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$').hasMatch(stem)) {
      sanitized = '_$sanitized';
    }

    const maximumRunes = 180;
    final runes = sanitized.runes.toList(growable: false);
    if (runes.length > maximumRunes) {
      final lastDot = sanitized.lastIndexOf('.');
      final extension = lastDot > 0 && sanitized.length - lastDot <= 20
          ? sanitized.substring(lastDot)
          : '';
      final extensionRunes = extension.runes.length;
      final available = (maximumRunes - extensionRunes).clamp(1, maximumRunes);
      sanitized = '${String.fromCharCodes(runes.take(available))}$extension'
          .replaceFirst(RegExp(r'[. ]+$'), '');
    }
    return sanitized;
  }

  Future<String> _selectInitialFileName({
    required Directory destination,
    required DownloadTask task,
  }) async {
    final desired = _effectiveFileName(task);
    final finalFile = File(path.join(destination.path, desired));
    final partial = File('${finalFile.path}.part');
    if (await partial.exists()) return desired;
    if (!await finalFile.exists()) return desired;
    return _uniqueFileName(destination, desired);
  }

  static String _effectiveFileName(DownloadTask task) {
    var result = sanitizeFileName(
      task.fileName,
      fallback: task.cid.isEmpty ? 'download' : task.cid,
    );
    if (task.isDirectoryArchive && !result.toLowerCase().endsWith('.tar')) {
      result = '$result.tar';
    }
    return result;
  }

  Future<String> _detectedFinalFileName({
    required DownloadTask task,
    required File partialFile,
    required String? contentType,
    required String? contentDisposition,
  }) async {
    if (!task.fileNameIsProvisional || task.isDirectoryArchive) {
      return task.fileName;
    }

    final detectionBytes = await _readDetectionBytes(partialFile);
    final detected = FileTypeDetector.detect(
      detectionBytes,
      contentType: contentType,
      contentDisposition: contentDisposition,
    );
    if (!detected.isKnown) return task.fileName;

    final currentExtension = path.extension(task.fileName);
    final stem = currentExtension.isEmpty
        ? task.fileName
        : task.fileName.substring(
            0,
            task.fileName.length - currentExtension.length,
          );
    return sanitizeFileName(
      '$stem.${detected.extension}',
      fallback: '${task.cid}.${detected.extension}',
    );
  }

  static Future<List<int>> _readDetectionBytes(
    File file, {
    int maximumPrefixBytes = 64 * 1024,
    int maximumTailBytes = 64 * 1024,
  }) async {
    final handle = await file.open();
    try {
      final length = await handle.length();
      final prefixLength = length < maximumPrefixBytes
          ? length
          : maximumPrefixBytes;
      final result = <int>[...await handle.read(prefixLength)];
      if (length > prefixLength) {
        final tailStart = length - maximumTailBytes > prefixLength
            ? length - maximumTailBytes
            : prefixLength;
        await handle.setPosition(tailStart);
        result.addAll(await handle.read(length - tailStart));
      }
      return result;
    } finally {
      await handle.close();
    }
  }

  Future<_FinalFileReservation> _reserveFinalFile({
    required Directory destination,
    required String desiredName,
    required File sourcePartial,
  }) async {
    final extension = path.extension(desiredName);
    final stem = extension.isEmpty
        ? desiredName
        : desiredName.substring(0, desiredName.length - extension.length);

    for (var index = 0; index < 10000; index++) {
      final candidate = index == 0 ? desiredName : '$stem ($index)$extension';
      final finalFile = File(path.join(destination.path, candidate));
      final key = _normalizedReservationPath(finalFile.path);
      if (_reservedFinalPaths.contains(key) || await finalFile.exists()) {
        continue;
      }

      final candidatePartial = File('${finalFile.path}.part');
      if (!_sameFilePath(candidatePartial.path, sourcePartial.path) &&
          await candidatePartial.exists()) {
        continue;
      }

      // File-system checks yield to the event loop. Check the in-process
      // reservation again before claiming the name for this final rename.
      if (_reservedFinalPaths.contains(key)) continue;
      _reservedFinalPaths.add(key);
      return _FinalFileReservation(
        fileName: candidate,
        file: finalFile,
        key: key,
      );
    }
    throw const DownloadFailure(
      'Für den erkannten Dateinamen konnte kein freier Zielname gefunden werden.',
    );
  }

  static bool _sameFilePath(String first, String second) =>
      _normalizedReservationPath(first) == _normalizedReservationPath(second);

  static String _normalizedReservationPath(String value) =>
      path.normalize(path.absolute(value)).toLowerCase();

  static String? _preferredContentType(String? current, String? candidate) {
    if (candidate == null || candidate.trim().isEmpty) return current;
    if (current == null || current.trim().isEmpty) return candidate;
    if (FileTypeDetector.isGenericMimeType(current) &&
        !FileTypeDetector.isGenericMimeType(candidate)) {
      return candidate;
    }
    return current;
  }

  static Future<String> _uniqueFileName(
    Directory destination,
    String desired,
  ) async {
    final extension = path.extension(desired);
    final stem = extension.isEmpty
        ? desired
        : desired.substring(0, desired.length - extension.length);
    for (var index = 1; index < 10000; index++) {
      final candidate = '$stem ($index)$extension';
      final finalFile = File(path.join(destination.path, candidate));
      final partialFile = File('${finalFile.path}.part');
      if (!await finalFile.exists() && !await partialFile.exists()) {
        return candidate;
      }
    }
    throw const DownloadFailure(
      'Für den Dateinamen konnte kein freier Zielname gefunden werden.',
    );
  }

  static Uri _gatewayUri(String gateway, DownloadTask task) {
    final base = Uri.parse(gateway.trim());
    if ((base.scheme != 'http' && base.scheme != 'https') ||
        base.host.isEmpty) {
      throw DownloadFailure('Ungültiges HTTP-Gateway: $gateway');
    }

    final sourceSegments = _sourceSegments(task);
    final baseSegments = base.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList(growable: true);
    if (baseSegments.isNotEmpty &&
        baseSegments.last == 'ipfs' &&
        sourceSegments.isNotEmpty &&
        sourceSegments.first == 'ipfs') {
      sourceSegments.removeAt(0);
    }

    final query = <String, String>{
      ...base.queryParameters,
      if (task.isDirectoryArchive) 'format': 'tar',
    };
    return base.replace(
      pathSegments: <String>[...baseSegments, ...sourceSegments],
      queryParameters: query.isEmpty ? null : query,
      fragment: '',
    );
  }

  static List<String> _sourceSegments(DownloadTask task) {
    // ParsedIpfsInput already stores decoded path components. Uri.replace
    // below performs the one required encoding pass for the gateway request.
    final rawSegments = task.ipfsPath
        .trim()
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);
    final decoded = <String>[];
    for (final segment in rawSegments) {
      final value = segment;
      if (value == '.' ||
          value == '..' ||
          value.contains('/') ||
          value.contains(r'\') ||
          value.contains('\u0000')) {
        throw const DownloadFailure('Der IPFS-Pfad ist ungültig.');
      }
      decoded.add(value);
    }

    if (decoded.isNotEmpty && decoded.first == 'ipfs') {
      return decoded.toList(growable: true);
    }
    if (decoded.isNotEmpty && decoded.first == task.cid) {
      return <String>['ipfs', ...decoded];
    }
    return <String>['ipfs', task.cid, ...decoded];
  }

  static List<String> _orderedGateways(
    List<String> gateways, {
    String? preferred,
  }) {
    final result = <String>[];
    void add(String value) {
      final normalized = AppSettings.normalizeGateway(value);
      if (normalized.isEmpty) return;
      final uri = Uri.tryParse(normalized);
      if (uri == null ||
          (uri.scheme != 'http' && uri.scheme != 'https') ||
          uri.host.isEmpty) {
        return;
      }
      if (!result.any((entry) => _sameGateway(entry, normalized))) {
        result.add(normalized);
      }
    }

    if (preferred != null &&
        gateways.any((gateway) => _sameGateway(gateway, preferred))) {
      add(preferred);
    }
    for (final gateway in gateways) {
      add(gateway);
    }
    return result;
  }

  static bool _sameGateway(String first, String second) =>
      AppSettings.normalizeGateway(first).toLowerCase() ==
      AppSettings.normalizeGateway(second).toLowerCase();

  static Future<int> _fileLength(File file) async =>
      await file.exists() ? file.length() : 0;

  static Future<void> _truncate(File file) async {
    final handle = await file.open(mode: FileMode.write);
    await handle.close();
  }

  static int? _unsatisfiedRangeTotal(String? value) {
    if (value == null) return null;
    final match = RegExp(
      r'^bytes\s+\*/(\d+)$',
      caseSensitive: false,
    ).firstMatch(value.trim());
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  static String _errorMessage(Object error) => switch (error) {
    final DownloadFailure failure => failure.message,
    final _GatewayResponseException failure => failure.message,
    final TimeoutException _ => 'Zeitüberschreitung beim Gateway.',
    final SocketException failure =>
      failure.message.isEmpty
          ? 'Das Gateway ist nicht erreichbar.'
          : failure.message,
    final HttpException failure => failure.message,
    final FileSystemException failure =>
      failure.message.isEmpty
          ? 'Die Zieldatei konnte nicht geschrieben werden.'
          : failure.message,
    _ => error.toString().replaceFirst('Exception: ', ''),
  };
}

class DownloadPausedException implements Exception {
  const DownloadPausedException(this.task);

  final DownloadTask task;

  @override
  String toString() => 'DownloadPausedException(${task.id})';
}

class DownloadFailure implements Exception {
  const DownloadFailure(this.message, {this.task, this.cause});

  final String message;
  final DownloadTask? task;
  final Object? cause;

  @override
  String toString() => 'DownloadFailure: $message';
}

class _DownloadControl {
  bool paused = false;
  HttpClient? client;
  HttpClientRequest? request;
  final Completer<void> done = Completer<void>();

  void pause() {
    if (paused) return;
    paused = true;
    client?.close(force: true);
  }
}

class _FinalFileReservation {
  const _FinalFileReservation({
    required this.fileName,
    required this.file,
    required this.key,
  });

  final String fileName;
  final File file;
  final String key;
}

class _TransferPlan {
  const _TransferPlan({
    required this.writeMode,
    required this.startOffset,
    required this.totalBytes,
    required this.expectedBodyBytes,
  });

  final FileMode writeMode;
  final int startOffset;
  final int? totalBytes;
  final int? expectedBodyBytes;
}

class _ContentRange {
  const _ContentRange({
    required this.start,
    required this.end,
    required this.total,
  });

  final int start;
  final int end;
  final int? total;

  static _ContentRange? tryParse(String? value) {
    if (value == null) return null;
    final match = RegExp(
      r'^bytes\s+(\d+)-(\d+)/(\d+|\*)$',
      caseSensitive: false,
    ).firstMatch(value.trim());
    if (match == null) return null;

    final start = int.tryParse(match.group(1)!);
    final end = int.tryParse(match.group(2)!);
    final totalRaw = match.group(3)!;
    final total = totalRaw == '*' ? null : int.tryParse(totalRaw);
    if (start == null ||
        end == null ||
        end < start ||
        (total != null && (total <= end || total < 0))) {
      return null;
    }
    return _ContentRange(start: start, end: end, total: total);
  }
}

class _GatewayResponseException implements Exception {
  const _GatewayResponseException(this.statusCode, this.message);

  final int statusCode;
  final String message;
}

class _PauseSignal implements Exception {
  const _PauseSignal();
}
