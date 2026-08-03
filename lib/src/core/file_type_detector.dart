import 'dart:convert';

import 'package:mime/mime.dart' as mime;

/// Describes which piece of evidence determined a file type.
enum FileTypeDetectionSource {
  /// A binary magic number or another unambiguous byte signature.
  signature,

  /// File names or uncompressed metadata found inside a ZIP container.
  zipContents,

  /// A non-generic HTTP Content-Type value.
  contentType,

  /// The extension of a safe HTTP Content-Disposition file name.
  contentDisposition,

  /// A structured-text or plain-text byte heuristic.
  textHeuristic,

  /// No useful evidence was available.
  unknown,
}

/// The result of inspecting the beginning of a downloaded file.
final class DetectedFileType {
  const DetectedFileType({
    required this.extension,
    required this.mimeType,
    required this.source,
    this.suggestedFileName,
  });

  /// Canonical extension without a leading dot (for example `jpg`).
  final String extension;

  /// Canonical MIME type for the detected format.
  final String mimeType;

  final FileTypeDetectionSource source;

  /// A sanitized name supplied by Content-Disposition, when present.
  final String? suggestedFileName;

  bool get isKnown => source != FileTypeDetectionSource.unknown;

  String get dottedExtension => '.$extension';

  /// Builds a safe name and applies the canonical detected extension.
  ///
  /// A Content-Disposition name has priority, followed by [currentFileName]
  /// and [fallbackBaseName]. Known types replace an existing last extension;
  /// this intentionally turns a CID fallback such as `abc.bin` into
  /// `abc.jpg`. Unknown data retains meaningful user-provided extensions.
  String suggestFileName({
    required String fallbackBaseName,
    String? currentFileName,
  }) {
    final dispositionName = suggestedFileName?.trim();
    final currentName = currentFileName?.trim();
    final candidate = dispositionName != null && dispositionName.isNotEmpty
        ? dispositionName
        : currentName != null && currentName.isNotEmpty
        ? currentName
        : fallbackBaseName;
    var safeName = FileTypeDetector.sanitizeFileName(
      candidate,
      fallback: FileTypeDetector.sanitizeFileName(
        fallbackBaseName,
        fallback: 'download',
      ),
    );

    if (!isKnown) {
      if (FileTypeDetector.extensionFromFileName(safeName) == null) {
        safeName = '$safeName.bin';
      }
      return FileTypeDetector.sanitizeFileName(safeName);
    }

    final lastDot = safeName.lastIndexOf('.');
    final stem = lastDot > 0 ? safeName.substring(0, lastDot) : safeName;
    return FileTypeDetector.sanitizeFileName(
      '$stem.$extension',
      fallback: 'download.$extension',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DetectedFileType &&
      extension == other.extension &&
      mimeType == other.mimeType &&
      source == other.source &&
      suggestedFileName == other.suggestedFileName;

  @override
  int get hashCode =>
      Object.hash(extension, mimeType, source, suggestedFileName);

  @override
  String toString() =>
      'DetectedFileType($extension, $mimeType, ${source.name})';
}

/// Detects common formats without native code or third-party packages.
///
/// Callers normally only need the first 4-64 KiB. Passing more ZIP bytes can
/// improve container refinement. [zipEntryNames] and [zipEntryContents] allow
/// a future ZIP reader to provide its central-directory results without
/// coupling this detector to a ZIP implementation.
abstract final class FileTypeDetector {
  static const _TypeInfo _jpeg = _TypeInfo('jpg', 'image/jpeg');
  static const _TypeInfo _png = _TypeInfo('png', 'image/png');
  static const _TypeInfo _gif = _TypeInfo('gif', 'image/gif');
  static const _TypeInfo _webp = _TypeInfo('webp', 'image/webp');
  static const _TypeInfo _avif = _TypeInfo('avif', 'image/avif');
  static const _TypeInfo _heic = _TypeInfo('heic', 'image/heic');
  static const _TypeInfo _heif = _TypeInfo('heif', 'image/heif');
  static const _TypeInfo _tiff = _TypeInfo('tiff', 'image/tiff');
  static const _TypeInfo _bmp = _TypeInfo('bmp', 'image/bmp');
  static const _TypeInfo _ico = _TypeInfo('ico', 'image/x-icon');
  static const _TypeInfo _cur = _TypeInfo('cur', 'image/x-icon');
  static const _TypeInfo _svg = _TypeInfo('svg', 'image/svg+xml');
  static const _TypeInfo _pdf = _TypeInfo('pdf', 'application/pdf');
  static const _TypeInfo _zip = _TypeInfo('zip', 'application/zip');
  static const _TypeInfo _docx = _TypeInfo(
    'docx',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  );
  static const _TypeInfo _xlsx = _TypeInfo(
    'xlsx',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  );
  static const _TypeInfo _pptx = _TypeInfo(
    'pptx',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  );
  static const _TypeInfo _epub = _TypeInfo('epub', 'application/epub+zip');
  static const _TypeInfo _odt = _TypeInfo(
    'odt',
    'application/vnd.oasis.opendocument.text',
  );
  static const _TypeInfo _ods = _TypeInfo(
    'ods',
    'application/vnd.oasis.opendocument.spreadsheet',
  );
  static const _TypeInfo _odp = _TypeInfo(
    'odp',
    'application/vnd.oasis.opendocument.presentation',
  );
  static const _TypeInfo _jar = _TypeInfo('jar', 'application/java-archive');
  static const _TypeInfo _apk = _TypeInfo(
    'apk',
    'application/vnd.android.package-archive',
  );
  static const _TypeInfo _rar = _TypeInfo('rar', 'application/vnd.rar');
  static const _TypeInfo _sevenZip = _TypeInfo(
    '7z',
    'application/x-7z-compressed',
  );
  static const _TypeInfo _gzip = _TypeInfo('gz', 'application/gzip');
  static const _TypeInfo _bzip2 = _TypeInfo('bz2', 'application/x-bzip2');
  static const _TypeInfo _xz = _TypeInfo('xz', 'application/x-xz');
  static const _TypeInfo _tar = _TypeInfo('tar', 'application/x-tar');
  static const _TypeInfo _mp3 = _TypeInfo('mp3', 'audio/mpeg');
  static const _TypeInfo _aac = _TypeInfo('aac', 'audio/aac');
  static const _TypeInfo _flac = _TypeInfo('flac', 'audio/flac');
  static const _TypeInfo _wav = _TypeInfo('wav', 'audio/wav');
  static const _TypeInfo _ogg = _TypeInfo('ogg', 'audio/ogg');
  static const _TypeInfo _opus = _TypeInfo('opus', 'audio/opus');
  static const _TypeInfo _ogv = _TypeInfo('ogv', 'video/ogg');
  static const _TypeInfo _m4a = _TypeInfo('m4a', 'audio/mp4');
  static const _TypeInfo _mp4 = _TypeInfo('mp4', 'video/mp4');
  static const _TypeInfo _mov = _TypeInfo('mov', 'video/quicktime');
  static const _TypeInfo _threeGp = _TypeInfo('3gp', 'video/3gpp');
  static const _TypeInfo _mkv = _TypeInfo('mkv', 'video/x-matroska');
  static const _TypeInfo _webm = _TypeInfo('webm', 'video/webm');
  static const _TypeInfo _avi = _TypeInfo('avi', 'video/x-msvideo');
  static const _TypeInfo _exe = _TypeInfo(
    'exe',
    'application/vnd.microsoft.portable-executable',
  );
  static const _TypeInfo _elf = _TypeInfo('elf', 'application/x-elf');
  static const _TypeInfo _machO = _TypeInfo(
    'macho',
    'application/x-mach-binary',
  );
  static const _TypeInfo _javaClass = _TypeInfo('class', 'application/java-vm');
  static const _TypeInfo _sqlite = _TypeInfo(
    'sqlite',
    'application/vnd.sqlite3',
  );
  static const _TypeInfo _woff = _TypeInfo('woff', 'font/woff');
  static const _TypeInfo _woff2 = _TypeInfo('woff2', 'font/woff2');
  static const _TypeInfo _ttf = _TypeInfo('ttf', 'font/ttf');
  static const _TypeInfo _otf = _TypeInfo('otf', 'font/otf');
  static const _TypeInfo _ttc = _TypeInfo('ttc', 'font/collection');
  static const _TypeInfo _json = _TypeInfo('json', 'application/json');
  static const _TypeInfo _xml = _TypeInfo('xml', 'application/xml');
  static const _TypeInfo _html = _TypeInfo('html', 'text/html');
  static const _TypeInfo _text = _TypeInfo('txt', 'text/plain');
  static const _TypeInfo _css = _TypeInfo('css', 'text/css');
  static const _TypeInfo _csv = _TypeInfo('csv', 'text/csv');
  static const _TypeInfo _javascript = _TypeInfo('js', 'text/javascript');
  static const _TypeInfo _car = _TypeInfo('car', 'application/vnd.ipld.car');
  static const _TypeInfo _binary = _TypeInfo('bin', 'application/octet-stream');

  static const Set<String> _genericMimeTypes = <String>{
    '',
    'application/binary',
    'application/download',
    'application/force-download',
    'application/octet-stream',
    'application/unknown',
    'application/vnd.ipld.raw',
    'application/x-binary',
    'application/x-download',
    'application/x-ipfs',
    'binary/octet-stream',
    'unknown/unknown',
  };

  static const Map<String, _TypeInfo> _mimeTypes = <String, _TypeInfo>{
    'image/jpeg': _jpeg,
    'image/jpg': _jpeg,
    'image/pjpeg': _jpeg,
    'image/png': _png,
    'image/x-png': _png,
    'image/gif': _gif,
    'image/webp': _webp,
    'image/avif': _avif,
    'image/heic': _heic,
    'image/heic-sequence': _heic,
    'image/heif': _heif,
    'image/heif-sequence': _heif,
    'image/tiff': _tiff,
    'image/bmp': _bmp,
    'image/x-ms-bmp': _bmp,
    'image/x-icon': _ico,
    'image/vnd.microsoft.icon': _ico,
    'image/svg+xml': _svg,
    'application/pdf': _pdf,
    'application/zip': _zip,
    'application/x-zip': _zip,
    'application/x-zip-compressed': _zip,
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
        _docx,
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': _xlsx,
    'application/vnd.openxmlformats-officedocument.presentationml.presentation':
        _pptx,
    'application/epub+zip': _epub,
    'application/vnd.oasis.opendocument.text': _odt,
    'application/vnd.oasis.opendocument.spreadsheet': _ods,
    'application/vnd.oasis.opendocument.presentation': _odp,
    'application/java-archive': _jar,
    'application/vnd.android.package-archive': _apk,
    'application/vnd.rar': _rar,
    'application/x-rar': _rar,
    'application/x-rar-compressed': _rar,
    'application/x-7z-compressed': _sevenZip,
    'application/gzip': _gzip,
    'application/x-gzip': _gzip,
    'application/x-bzip2': _bzip2,
    'application/x-xz': _xz,
    'application/x-tar': _tar,
    'audio/mpeg': _mp3,
    'audio/mp3': _mp3,
    'audio/aac': _aac,
    'audio/flac': _flac,
    'audio/x-flac': _flac,
    'audio/wav': _wav,
    'audio/wave': _wav,
    'audio/x-wav': _wav,
    'audio/vnd.wave': _wav,
    'audio/ogg': _ogg,
    'application/ogg': _ogg,
    'audio/opus': _opus,
    'audio/mp4': _m4a,
    'audio/x-m4a': _m4a,
    'video/mp4': _mp4,
    'video/quicktime': _mov,
    'video/3gpp': _threeGp,
    'video/x-matroska': _mkv,
    'video/webm': _webm,
    'video/x-msvideo': _avi,
    'video/avi': _avi,
    'video/ogg': _ogv,
    'application/vnd.microsoft.portable-executable': _exe,
    'application/x-msdownload': _exe,
    'application/x-dosexec': _exe,
    'application/x-elf': _elf,
    'application/x-mach-binary': _machO,
    'application/java-vm': _javaClass,
    'application/vnd.sqlite3': _sqlite,
    'application/x-sqlite3': _sqlite,
    'font/woff': _woff,
    'application/font-woff': _woff,
    'font/woff2': _woff2,
    'font/ttf': _ttf,
    'application/x-font-ttf': _ttf,
    'font/otf': _otf,
    'application/x-font-opentype': _otf,
    'font/collection': _ttc,
    'application/json': _json,
    'text/json': _json,
    'application/xml': _xml,
    'text/xml': _xml,
    'text/html': _html,
    'application/xhtml+xml': _html,
    'text/plain': _text,
    'text/css': _css,
    'text/csv': _csv,
    'text/javascript': _javascript,
    'application/javascript': _javascript,
    'application/x-javascript': _javascript,
    'application/vnd.ipld.car': _car,
  };

  static const Map<String, _TypeInfo> _extensions = <String, _TypeInfo>{
    'jpg': _jpeg,
    'jpeg': _jpeg,
    'jpe': _jpeg,
    'png': _png,
    'gif': _gif,
    'webp': _webp,
    'avif': _avif,
    'heic': _heic,
    'heif': _heif,
    'tif': _tiff,
    'tiff': _tiff,
    'bmp': _bmp,
    'ico': _ico,
    'cur': _cur,
    'svg': _svg,
    'pdf': _pdf,
    'zip': _zip,
    'docx': _docx,
    'xlsx': _xlsx,
    'pptx': _pptx,
    'epub': _epub,
    'odt': _odt,
    'ods': _ods,
    'odp': _odp,
    'jar': _jar,
    'apk': _apk,
    'rar': _rar,
    '7z': _sevenZip,
    'gz': _gzip,
    'gzip': _gzip,
    'tgz': _gzip,
    'bz2': _bzip2,
    'xz': _xz,
    'tar': _tar,
    'mp3': _mp3,
    'aac': _aac,
    'flac': _flac,
    'wav': _wav,
    'ogg': _ogg,
    'oga': _ogg,
    'opus': _opus,
    'ogv': _ogv,
    'm4a': _m4a,
    'mp4': _mp4,
    'm4v': _mp4,
    'mov': _mov,
    '3gp': _threeGp,
    'mkv': _mkv,
    'webm': _webm,
    'avi': _avi,
    'exe': _exe,
    'elf': _elf,
    'macho': _machO,
    'class': _javaClass,
    'sqlite': _sqlite,
    'sqlite3': _sqlite,
    'db': _sqlite,
    'woff': _woff,
    'woff2': _woff2,
    'ttf': _ttf,
    'otf': _otf,
    'ttc': _ttc,
    'json': _json,
    'jsonld': _json,
    'xml': _xml,
    'html': _html,
    'htm': _html,
    'xhtml': _html,
    'txt': _text,
    'text': _text,
    'log': _text,
    'md': _text,
    'css': _css,
    'csv': _csv,
    'js': _javascript,
    'mjs': _javascript,
    'car': _car,
  };

  static const Set<_TypeInfo> _zipContainerTypes = <_TypeInfo>{
    _zip,
    _docx,
    _xlsx,
    _pptx,
    _epub,
    _odt,
    _ods,
    _odp,
    _jar,
    _apk,
  };

  /// Detects a type using bytes first and HTTP metadata only as a fallback.
  static DetectedFileType detect(
    List<int> headerBytes, {
    String? contentType,
    String? contentDisposition,
    Iterable<String>? zipEntryNames,
    Map<String, List<int>>? zipEntryContents,
  }) {
    final dispositionName = fileNameFromContentDisposition(contentDisposition);
    final signature = _detectSignature(
      headerBytes,
      zipEntryNames: zipEntryNames,
      zipEntryContents: zipEntryContents,
    );

    if (signature != null) {
      // A generic ZIP signature can safely be refined by ZIP-specific HTTP
      // metadata. Unrelated MIME claims never override magic bytes.
      if (signature.info == _zip) {
        final mimeInfo = _typeFromContentType(contentType);
        if (mimeInfo != null && _zipContainerTypes.contains(mimeInfo)) {
          return _result(
            mimeInfo,
            FileTypeDetectionSource.contentType,
            dispositionName,
          );
        }
        final nameInfo = _typeFromFileName(dispositionName);
        if (nameInfo != null && _zipContainerTypes.contains(nameInfo)) {
          return _result(
            nameInfo,
            FileTypeDetectionSource.contentDisposition,
            dispositionName,
          );
        }
      }
      return _result(signature.info, signature.source, dispositionName);
    }

    final structuredText = _detectStructuredText(headerBytes);
    if (structuredText != null) {
      return _result(
        structuredText,
        FileTypeDetectionSource.textHeuristic,
        dispositionName,
      );
    }

    final mimeInfo = _typeFromContentType(contentType);
    if (mimeInfo != null) {
      return _result(
        mimeInfo,
        FileTypeDetectionSource.contentType,
        dispositionName,
      );
    }

    final nameInfo = _typeFromFileName(dispositionName);
    if (nameInfo != null) {
      return _result(
        nameInfo,
        FileTypeDetectionSource.contentDisposition,
        dispositionName,
      );
    }

    if (_decodeText(headerBytes) != null) {
      return _result(
        _text,
        FileTypeDetectionSource.textHeuristic,
        dispositionName,
      );
    }

    return _result(_binary, FileTypeDetectionSource.unknown, dispositionName);
  }

  /// Returns whether a MIME value carries no useful file-format information.
  static bool isGenericMimeType(String? value) =>
      _genericMimeTypes.contains(_normalizedMimeType(value));

  /// Extracts and sanitizes an RFC 6266/RFC 5987 file name.
  ///
  /// `filename*` takes precedence over `filename`. Directory components,
  /// control characters and platform-reserved characters are removed.
  static String? fileNameFromContentDisposition(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parameters = _headerParameters(value);
    final extended = parameters['filename*'];
    final regular = parameters['filename'];
    final decoded = extended == null
        ? null
        : _decodeExtendedHeaderValue(extended);
    final candidate = decoded?.trim().isNotEmpty == true ? decoded : regular;
    if (candidate == null || candidate.trim().isEmpty) return null;
    return sanitizeFileName(candidate, fallback: 'download');
  }

  /// Returns a conservative lower-case extension from a safe or unsafe name.
  static String? extensionFromFileName(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.replaceAll('\\', '/');
    final name = normalized.substring(normalized.lastIndexOf('/') + 1).trim();
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) return null;
    final extension = name.substring(dot + 1).toLowerCase();
    if (!RegExp(r'^[a-z0-9][a-z0-9_+-]{0,15}$').hasMatch(extension)) {
      return null;
    }
    return extension;
  }

  /// Produces a cross-platform basename suitable for the download directory.
  static String sanitizeFileName(
    String value, {
    String fallback = 'download.bin',
  }) {
    String clean(String input) {
      final normalized = input.replaceAll('\\', '/');
      var result = normalized.substring(normalized.lastIndexOf('/') + 1);
      result = result
          .replaceAll(RegExp(r'[\x00-\x1F\x7F-\x9F]'), '')
          .replaceAll(RegExp(r'[\u202A-\u202E\u2066-\u2069]'), '')
          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
          .trim()
          .replaceFirst(RegExp(r'[. ]+$'), '');
      if (result == '.' || result == '..') return '';

      final firstDot = result.indexOf('.');
      final stem = (firstDot < 0 ? result : result.substring(0, firstDot))
          .replaceFirst(RegExp(r'[. ]+$'), '')
          .toUpperCase();
      if (RegExp(r'^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$').hasMatch(stem)) {
        result = '_$result';
      }
      return result;
    }

    var result = clean(value);
    if (result.isEmpty) result = clean(fallback);
    if (result.isEmpty) result = 'download.bin';

    const maximumRunes = 180;
    final runes = result.runes.toList(growable: false);
    if (runes.length > maximumRunes) {
      final lastDot = result.lastIndexOf('.');
      final extension = lastDot > 0 && result.length - lastDot <= 20
          ? result.substring(lastDot)
          : '';
      final extensionLength = extension.runes.length;
      result =
          '${String.fromCharCodes(runes.take(maximumRunes - extensionLength))}$extension';
    }
    return result;
  }

  static DetectedFileType _result(
    _TypeInfo info,
    FileTypeDetectionSource source,
    String? suggestedFileName,
  ) => DetectedFileType(
    extension: info.extension,
    mimeType: info.mimeType,
    source: source,
    suggestedFileName: suggestedFileName,
  );

  static _DetectionCandidate? _detectSignature(
    List<int> bytes, {
    Iterable<String>? zipEntryNames,
    Map<String, List<int>>? zipEntryContents,
  }) {
    if (_startsWith(bytes, const <int>[0xFF, 0xD8, 0xFF])) {
      return const _DetectionCandidate(_jpeg);
    }
    if (_startsWith(bytes, const <int>[
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
    ])) {
      return const _DetectionCandidate(_png);
    }
    if (_asciiAt(bytes, 0, 'GIF87a') || _asciiAt(bytes, 0, 'GIF89a')) {
      return const _DetectionCandidate(_gif);
    }
    if (_asciiAt(bytes, 0, 'RIFF') && _asciiAt(bytes, 8, 'WEBP')) {
      return const _DetectionCandidate(_webp);
    }

    final bmff = _detectIsoBaseMedia(bytes);
    if (bmff != null) return _DetectionCandidate(bmff);

    if (_startsWith(bytes, const <int>[0x49, 0x49, 0x2A, 0x00]) ||
        _startsWith(bytes, const <int>[0x4D, 0x4D, 0x00, 0x2A]) ||
        _startsWith(bytes, const <int>[0x49, 0x49, 0x2B, 0x00]) ||
        _startsWith(bytes, const <int>[0x4D, 0x4D, 0x00, 0x2B])) {
      return const _DetectionCandidate(_tiff);
    }
    if (_asciiAt(bytes, 0, 'BM')) {
      return const _DetectionCandidate(_bmp);
    }
    if (_startsWith(bytes, const <int>[0x00, 0x00, 0x01, 0x00])) {
      return const _DetectionCandidate(_ico);
    }
    if (_startsWith(bytes, const <int>[0x00, 0x00, 0x02, 0x00])) {
      return const _DetectionCandidate(_cur);
    }
    final pdfOffset = _indexOfAscii(bytes, '%PDF-', maximumOffset: 1024);
    if (pdfOffset >= 0) return const _DetectionCandidate(_pdf);

    if (_isZip(bytes)) {
      final zipType = _refineZip(
        bytes,
        suppliedEntryNames: zipEntryNames,
        suppliedEntryContents: zipEntryContents,
      );
      return _DetectionCandidate(
        zipType ?? _zip,
        zipType == null
            ? FileTypeDetectionSource.signature
            : FileTypeDetectionSource.zipContents,
      );
    }
    if (_startsWith(bytes, const <int>[
          0x52,
          0x61,
          0x72,
          0x21,
          0x1A,
          0x07,
          0x00,
        ]) ||
        _startsWith(bytes, const <int>[
          0x52,
          0x61,
          0x72,
          0x21,
          0x1A,
          0x07,
          0x01,
          0x00,
        ])) {
      return const _DetectionCandidate(_rar);
    }
    if (_startsWith(bytes, const <int>[0x37, 0x7A, 0xBC, 0xAF, 0x27, 0x1C])) {
      return const _DetectionCandidate(_sevenZip);
    }
    if (_startsWith(bytes, const <int>[0x1F, 0x8B])) {
      return const _DetectionCandidate(_gzip);
    }
    if (_asciiAt(bytes, 0, 'BZh') &&
        bytes.length >= 4 &&
        _byte(bytes, 3) >= 0x31 &&
        _byte(bytes, 3) <= 0x39) {
      return const _DetectionCandidate(_bzip2);
    }
    if (_startsWith(bytes, const <int>[0xFD, 0x37, 0x7A, 0x58, 0x5A, 0x00])) {
      return const _DetectionCandidate(_xz);
    }
    if (_asciiAt(bytes, 257, 'ustar')) {
      return const _DetectionCandidate(_tar);
    }

    final hasUtf16Bom =
        _startsWith(bytes, const <int>[0xFF, 0xFE]) ||
        _startsWith(bytes, const <int>[0xFE, 0xFF]);
    if (_asciiAt(bytes, 0, 'ID3') || (!hasUtf16Bom && _isMp3Frame(bytes))) {
      return const _DetectionCandidate(_mp3);
    }
    if (_isAdts(bytes)) return const _DetectionCandidate(_aac);
    if (_asciiAt(bytes, 0, 'fLaC')) {
      return const _DetectionCandidate(_flac);
    }
    if (_asciiAt(bytes, 0, 'RIFF') && _asciiAt(bytes, 8, 'WAVE')) {
      return const _DetectionCandidate(_wav);
    }
    if (_asciiAt(bytes, 0, 'OggS')) {
      if (_containsAscii(bytes, 'OpusHead', maximumOffset: 256)) {
        return const _DetectionCandidate(_opus);
      }
      if (_containsAscii(bytes, 'theora', maximumOffset: 256)) {
        return const _DetectionCandidate(_ogv);
      }
      return const _DetectionCandidate(_ogg);
    }
    if (_startsWith(bytes, const <int>[0x1A, 0x45, 0xDF, 0xA3])) {
      if (_containsAscii(bytes, 'webm', maximumOffset: 512)) {
        return const _DetectionCandidate(_webm);
      }
      return const _DetectionCandidate(_mkv);
    }
    if (_asciiAt(bytes, 0, 'RIFF') && _asciiAt(bytes, 8, 'AVI ')) {
      return const _DetectionCandidate(_avi);
    }

    if (_isPortableExecutable(bytes)) {
      return const _DetectionCandidate(_exe);
    }
    if (_startsWith(bytes, const <int>[0x7F, 0x45, 0x4C, 0x46])) {
      return const _DetectionCandidate(_elf);
    }
    if (_isJavaClass(bytes)) return const _DetectionCandidate(_javaClass);
    if (_isMachO(bytes)) return const _DetectionCandidate(_machO);
    if (_asciiAt(bytes, 0, 'SQLite format 3\u0000')) {
      return const _DetectionCandidate(_sqlite);
    }
    if (_asciiAt(bytes, 0, 'wOFF')) {
      return const _DetectionCandidate(_woff);
    }
    if (_asciiAt(bytes, 0, 'wOF2')) {
      return const _DetectionCandidate(_woff2);
    }
    if (_startsWith(bytes, const <int>[0x00, 0x01, 0x00, 0x00]) ||
        _asciiAt(bytes, 0, 'true')) {
      return const _DetectionCandidate(_ttf);
    }
    if (_asciiAt(bytes, 0, 'OTTO')) {
      return const _DetectionCandidate(_otf);
    }
    if (_asciiAt(bytes, 0, 'ttcf')) {
      return const _DetectionCandidate(_ttc);
    }
    return null;
  }

  static _TypeInfo? _detectIsoBaseMedia(List<int> bytes) {
    if (bytes.length < 12 || !_asciiAt(bytes, 4, 'ftyp')) return null;
    final boxSize = _uint32BigEndian(bytes, 0);
    final end = boxSize >= 12 && boxSize <= bytes.length
        ? boxSize
        : bytes.length.clamp(12, 256);
    final brands = <String>{};
    for (var offset = 8; offset + 4 <= end; offset += 4) {
      brands.add(_ascii(bytes, offset, 4));
    }

    if (brands.any(const <String>{'avif', 'avis'}.contains)) return _avif;
    if (brands.any(const <String>{'heic', 'heix', 'hevc', 'hevx'}.contains)) {
      return _heic;
    }
    if (brands.any(const <String>{'mif1', 'msf1', 'heif'}.contains)) {
      return _heif;
    }
    if (brands.any(const <String>{'M4A ', 'M4B ', 'M4P '}.contains)) {
      return _m4a;
    }
    if (brands.contains('qt  ')) return _mov;
    if (brands.any((brand) => brand.startsWith('3g'))) return _threeGp;
    return _mp4;
  }

  static _TypeInfo? _refineZip(
    List<int> bytes, {
    Iterable<String>? suppliedEntryNames,
    Map<String, List<int>>? suppliedEntryContents,
  }) {
    final metadata = _readZipMetadata(bytes);
    final names = <String>{
      ...metadata.names.map(_normalizedZipEntry),
      ...?suppliedEntryNames?.map(_normalizedZipEntry),
    }..removeWhere((name) => name.isEmpty);
    final contents = <String, List<int>>{
      for (final entry in metadata.storedContents.entries)
        _normalizedZipEntry(entry.key): entry.value,
      if (suppliedEntryContents != null)
        for (final entry in suppliedEntryContents.entries)
          _normalizedZipEntry(entry.key): entry.value,
    };

    bool hasPrefix(String prefix) =>
        names.any((name) => name.startsWith(prefix));
    final hasContentTypes = names.contains('[content_types].xml');
    if (hasContentTypes && hasPrefix('word/')) return _docx;
    if (hasContentTypes && hasPrefix('xl/')) return _xlsx;
    if (hasContentTypes && hasPrefix('ppt/')) return _pptx;

    final mimeBytes = contents['mimetype'];
    final mimeValue = mimeBytes == null
        ? null
        : _decodeAsciiLossy(mimeBytes).trim().toLowerCase();
    switch (mimeValue) {
      case 'application/epub+zip':
        return _epub;
      case 'application/vnd.oasis.opendocument.text':
        return _odt;
      case 'application/vnd.oasis.opendocument.spreadsheet':
        return _ods;
      case 'application/vnd.oasis.opendocument.presentation':
        return _odp;
    }
    if (names.contains('meta-inf/container.xml') &&
        (names.contains('mimetype') || hasPrefix('oebps/'))) {
      return _epub;
    }
    if (names.contains('androidmanifest.xml') &&
        names.contains('classes.dex')) {
      return _apk;
    }
    if (names.contains('meta-inf/manifest.mf')) return _jar;
    return null;
  }

  static _ZipMetadata _readZipMetadata(List<int> bytes) {
    final names = <String>{};
    final contents = <String, List<int>>{};

    var offset = 0;
    while (offset + 30 <= bytes.length &&
        _startsWith(bytes, const <int>[0x50, 0x4B, 0x03, 0x04], offset)) {
      final flags = _uint16LittleEndian(bytes, offset + 6);
      final compression = _uint16LittleEndian(bytes, offset + 8);
      final compressedSize = _uint32LittleEndian(bytes, offset + 18);
      final nameLength = _uint16LittleEndian(bytes, offset + 26);
      final extraLength = _uint16LittleEndian(bytes, offset + 28);
      final nameStart = offset + 30;
      final dataStart = nameStart + nameLength + extraLength;
      if (nameStart + nameLength > bytes.length || dataStart > bytes.length) {
        break;
      }
      final name = utf8.decode(
        bytes.sublist(nameStart, nameStart + nameLength),
        allowMalformed: true,
      );
      names.add(name);
      if (compression == 0 && dataStart + compressedSize <= bytes.length) {
        contents[name] = bytes.sublist(dataStart, dataStart + compressedSize);
      }
      if ((flags & 0x08) != 0 || dataStart + compressedSize <= offset) break;
      offset = dataStart + compressedSize;
    }

    // A full sample may include the central directory even when local entries
    // use data descriptors. Scan for its small, self-describing name records.
    for (var index = 0; index + 46 <= bytes.length; index++) {
      if (!_startsWith(bytes, const <int>[0x50, 0x4B, 0x01, 0x02], index)) {
        continue;
      }
      final nameLength = _uint16LittleEndian(bytes, index + 28);
      final extraLength = _uint16LittleEndian(bytes, index + 30);
      final commentLength = _uint16LittleEndian(bytes, index + 32);
      final end = index + 46 + nameLength + extraLength + commentLength;
      if (end > bytes.length) continue;
      names.add(
        utf8.decode(
          bytes.sublist(index + 46, index + 46 + nameLength),
          allowMalformed: true,
        ),
      );
      index = end - 1;
    }
    return _ZipMetadata(names, contents);
  }

  static _TypeInfo? _detectStructuredText(List<int> bytes) {
    final decoded = _decodeText(bytes);
    if (decoded == null) return null;
    final prefix = decoded.length > 8192 ? decoded.substring(0, 8192) : decoded;
    final withoutBom = prefix.replaceFirst('\uFEFF', '');
    final trimmed = withoutBom.trimLeft();
    if (trimmed.isEmpty) return null;

    final markupStart = trimmed.replaceFirst(
      RegExp(r'^(?:<\?xml[^>]*>\s*)?(?:<!--.*?-->\s*)*', dotAll: true),
      '',
    );
    if (RegExp(r'^<svg(?:\s|>)', caseSensitive: false).hasMatch(markupStart)) {
      return _svg;
    }
    if (RegExp(
      r'^(?:<!doctype\s+html(?:\s|>)|<html(?:\s|>)|<head(?:\s|>)|<body(?:\s|>))',
      caseSensitive: false,
    ).hasMatch(markupStart)) {
      return _html;
    }

    if (_looksLikeJson(trimmed)) return _json;
    if (trimmed.startsWith('<?xml') ||
        RegExp(
          r'^<[A-Za-z_][A-Za-z0-9_.:-]*(?:\s|/?>)',
        ).hasMatch(markupStart)) {
      return _xml;
    }
    return null;
  }

  static bool _looksLikeJson(String text) {
    if (!text.startsWith('{') && !text.startsWith('[')) return false;
    try {
      jsonDecode(text);
      return true;
    } on FormatException {
      // A header sample frequently ends halfway through an otherwise valid
      // document. Require JSON punctuation before accepting that case.
      if (text.startsWith('{')) {
        return RegExp(
          r'^\{\s*(?:"(?:[^"\\]|\\.)*"\s*:|\})',
          dotAll: true,
        ).hasMatch(text);
      }
      return RegExp(r'^\[\s*(?:\]|[\{"\-0-9tfn])', dotAll: true).hasMatch(text);
    }
  }

  static String? _decodeText(List<int> bytes) {
    if (bytes.isEmpty) return null;
    if (_startsWith(bytes, const <int>[0xFF, 0xFE])) {
      return _decodeUtf16(bytes, littleEndian: true);
    }
    if (_startsWith(bytes, const <int>[0xFE, 0xFF])) {
      return _decodeUtf16(bytes, littleEndian: false);
    }

    final sample = bytes.length > 65536 ? bytes.sublist(0, 65536) : bytes;
    var disallowedControls = 0;
    for (final rawByte in sample) {
      final byte = rawByte & 0xFF;
      if (byte == 0) return null;
      if ((byte < 0x20 && byte != 0x09 && byte != 0x0A && byte != 0x0D) ||
          byte == 0x7F) {
        disallowedControls++;
      }
    }
    if (disallowedControls > 0 && disallowedControls * 50 > sample.length) {
      return null;
    }

    final decoded = utf8.decode(sample, allowMalformed: true);
    final replacements = '\uFFFD'.allMatches(decoded).length;
    if (replacements == 0) return decoded;
    // Permit one replacement only at the very end: a bounded network sample
    // may split its final UTF-8 code point.
    if (replacements == 1 && decoded.length > 1 && decoded.endsWith('\uFFFD')) {
      return decoded.substring(0, decoded.length - 1);
    }
    return null;
  }

  static String? _decodeUtf16(List<int> bytes, {required bool littleEndian}) {
    if (bytes.length < 4) return null;
    final codeUnits = <int>[];
    for (var index = 2; index + 1 < bytes.length; index += 2) {
      final first = _byte(bytes, index);
      final second = _byte(bytes, index + 1);
      final unit = littleEndian ? first | (second << 8) : (first << 8) | second;
      if ((unit < 0x20 && unit != 0x09 && unit != 0x0A && unit != 0x0D) ||
          unit == 0x7F) {
        return null;
      }
      codeUnits.add(unit);
    }
    return String.fromCharCodes(codeUnits);
  }

  static _TypeInfo? _typeFromContentType(String? value) {
    final normalized = _normalizedMimeType(value);
    if (_genericMimeTypes.contains(normalized)) return null;
    final exact = _mimeTypes[normalized];
    if (exact != null) return exact;

    final packageExtension = mime.extensionFromMime(normalized);
    if (_isSafeExtension(packageExtension)) {
      return _TypeInfo(packageExtension!, normalized);
    }
    if (normalized.endsWith('+json')) return _json;
    if (normalized.endsWith('+xml')) return _xml;
    if (normalized.startsWith('text/')) return _text;
    return null;
  }

  static _TypeInfo? _typeFromFileName(String? value) {
    final extension = extensionFromFileName(value);
    if (extension == null) return null;
    final exact = _extensions[extension];
    if (exact != null) return exact;

    final packageMimeType = mime.lookupMimeType('file.$extension');
    if (packageMimeType == null || isGenericMimeType(packageMimeType)) {
      return null;
    }
    final packageExtension = mime.extensionFromMime(packageMimeType);
    return _TypeInfo(
      _isSafeExtension(packageExtension) ? packageExtension! : extension,
      packageMimeType,
    );
  }

  static bool _isSafeExtension(String? value) =>
      value != null && RegExp(r'^[a-z0-9][a-z0-9_+-]{0,15}$').hasMatch(value);

  static String _normalizedMimeType(String? value) {
    if (value == null) return '';
    var result = value.split(';').first.trim().toLowerCase();
    if (result.length >= 2 && result.startsWith('"') && result.endsWith('"')) {
      result = result.substring(1, result.length - 1).trim();
    }
    return result;
  }

  static Map<String, String> _headerParameters(String value) {
    final pieces = <String>[];
    final buffer = StringBuffer();
    var quoted = false;
    var escaped = false;
    for (final codePoint in value.runes) {
      final character = String.fromCharCode(codePoint);
      if (escaped) {
        buffer.write(character);
        escaped = false;
        continue;
      }
      if (quoted && character == '\\') {
        buffer.write(character);
        escaped = true;
        continue;
      }
      if (character == '"') quoted = !quoted;
      if (character == ';' && !quoted) {
        pieces.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(character);
      }
    }
    pieces.add(buffer.toString());

    final result = <String, String>{};
    for (final piece in pieces.skip(1)) {
      final equals = piece.indexOf('=');
      if (equals <= 0) continue;
      final key = piece.substring(0, equals).trim().toLowerCase();
      final rawValue = piece.substring(equals + 1).trim();
      if (key.isEmpty || result.containsKey(key)) continue;
      result[key] = _unquoteHeaderValue(rawValue);
    }
    return result;
  }

  static String _unquoteHeaderValue(String value) {
    if (value.length < 2 || !value.startsWith('"') || !value.endsWith('"')) {
      return value;
    }
    final inner = value.substring(1, value.length - 1);
    final result = StringBuffer();
    for (var index = 0; index < inner.length; index++) {
      final character = inner[index];
      if (character == '\\' && index + 1 < inner.length) {
        final next = inner[index + 1];
        if (next == '\\' || next == '"') {
          result.write(next);
          index++;
          continue;
        }
      }
      result.write(character);
    }
    return result.toString();
  }

  static String? _decodeExtendedHeaderValue(String value) {
    final firstQuote = value.indexOf("'");
    final secondQuote = firstQuote < 0
        ? -1
        : value.indexOf("'", firstQuote + 1);
    if (firstQuote <= 0 || secondQuote < 0) return null;
    final charset = value.substring(0, firstQuote).trim().toLowerCase();
    final encoded = value.substring(secondQuote + 1);
    final decodedBytes = <int>[];
    try {
      for (var index = 0; index < encoded.length; index++) {
        if (encoded[index] == '%') {
          if (index + 2 >= encoded.length) return null;
          final byte = int.parse(
            encoded.substring(index + 1, index + 3),
            radix: 16,
          );
          decodedBytes.add(byte);
          index += 2;
        } else {
          decodedBytes.addAll(utf8.encode(encoded[index]));
        }
      }
      if (charset == 'iso-8859-1' || charset == 'latin1') {
        return latin1.decode(decodedBytes);
      }
      if (charset.isEmpty || charset == 'utf-8' || charset == 'utf8') {
        return utf8.decode(decodedBytes, allowMalformed: false);
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  static bool _isZip(List<int> bytes) =>
      _startsWith(bytes, const <int>[0x50, 0x4B, 0x03, 0x04]) ||
      _startsWith(bytes, const <int>[0x50, 0x4B, 0x05, 0x06]) ||
      _startsWith(bytes, const <int>[0x50, 0x4B, 0x07, 0x08]);

  static bool _isMp3Frame(List<int> bytes) {
    if (bytes.length < 3 ||
        _byte(bytes, 0) != 0xFF ||
        (_byte(bytes, 1) & 0xE0) != 0xE0) {
      return false;
    }
    final version = (_byte(bytes, 1) >> 3) & 0x03;
    final layer = (_byte(bytes, 1) >> 1) & 0x03;
    final bitrate = (_byte(bytes, 2) >> 4) & 0x0F;
    final sampleRate = (_byte(bytes, 2) >> 2) & 0x03;
    return version != 1 &&
        layer != 0 &&
        bitrate != 0 &&
        bitrate != 15 &&
        sampleRate != 3;
  }

  static bool _isAdts(List<int> bytes) =>
      bytes.length >= 4 &&
      _byte(bytes, 0) == 0xFF &&
      (_byte(bytes, 1) & 0xF6) == 0xF0;

  static bool _isPortableExecutable(List<int> bytes) {
    if (bytes.length < 64 || !_asciiAt(bytes, 0, 'MZ')) return false;
    final peOffset = _uint32LittleEndian(bytes, 0x3C);
    return peOffset >= 64 &&
        peOffset + 4 <= bytes.length &&
        _startsWith(bytes, const <int>[0x50, 0x45, 0x00, 0x00], peOffset);
  }

  static bool _isJavaClass(List<int> bytes) {
    if (bytes.length < 8 ||
        !_startsWith(bytes, const <int>[0xCA, 0xFE, 0xBA, 0xBE])) {
      return false;
    }
    final minorVersion = _uint16BigEndian(bytes, 4);
    final majorVersion = _uint16BigEndian(bytes, 6);
    return (minorVersion == 0 || minorVersion == 0xFFFF) &&
        majorVersion >= 45 &&
        majorVersion <= 100;
  }

  static bool _isMachO(List<int> bytes) {
    const thinMagics = <List<int>>[
      <int>[0xFE, 0xED, 0xFA, 0xCE],
      <int>[0xCE, 0xFA, 0xED, 0xFE],
      <int>[0xFE, 0xED, 0xFA, 0xCF],
      <int>[0xCF, 0xFA, 0xED, 0xFE],
    ];
    if (thinMagics.any((magic) => _startsWith(bytes, magic))) return true;
    if (bytes.length < 8) return false;

    final isBigEndianFat =
        _startsWith(bytes, const <int>[0xCA, 0xFE, 0xBA, 0xBE]) ||
        _startsWith(bytes, const <int>[0xCA, 0xFE, 0xBA, 0xBF]);
    final isLittleEndianFat =
        _startsWith(bytes, const <int>[0xBE, 0xBA, 0xFE, 0xCA]) ||
        _startsWith(bytes, const <int>[0xBF, 0xBA, 0xFE, 0xCA]);
    if (!isBigEndianFat && !isLittleEndianFat) return false;

    final architectureCount = isBigEndianFat
        ? _uint32BigEndian(bytes, 4)
        : _uint32LittleEndian(bytes, 4);
    return architectureCount >= 1 && architectureCount <= 32;
  }

  static String _normalizedZipEntry(String value) => value
      .replaceAll('\\', '/')
      .replaceFirst(RegExp(r'^/+'), '')
      .toLowerCase();

  static bool _startsWith(
    List<int> bytes,
    List<int> signature, [
    int offset = 0,
  ]) {
    if (offset < 0 || offset + signature.length > bytes.length) return false;
    for (var index = 0; index < signature.length; index++) {
      if (_byte(bytes, offset + index) != signature[index]) return false;
    }
    return true;
  }

  static bool _asciiAt(List<int> bytes, int offset, String value) =>
      _startsWith(bytes, value.codeUnits, offset);

  static String _ascii(List<int> bytes, int offset, int length) =>
      String.fromCharCodes(
        bytes.skip(offset).take(length).map((value) => value & 0xFF),
      );

  static bool _containsAscii(
    List<int> bytes,
    String value, {
    required int maximumOffset,
  }) => _indexOfAscii(bytes, value, maximumOffset: maximumOffset) >= 0;

  static int _indexOfAscii(
    List<int> bytes,
    String value, {
    required int maximumOffset,
  }) {
    if (value.isEmpty || bytes.length < value.length || maximumOffset < 0) {
      return -1;
    }
    final availableOffset = bytes.length - value.length;
    final limit = maximumOffset < availableOffset
        ? maximumOffset
        : availableOffset;
    for (var offset = 0; offset <= limit; offset++) {
      if (_asciiAt(bytes, offset, value)) return offset;
    }
    return -1;
  }

  static int _byte(List<int> bytes, int offset) => bytes[offset] & 0xFF;

  static int _uint16LittleEndian(List<int> bytes, int offset) =>
      _byte(bytes, offset) | (_byte(bytes, offset + 1) << 8);

  static int _uint16BigEndian(List<int> bytes, int offset) =>
      (_byte(bytes, offset) << 8) | _byte(bytes, offset + 1);

  static int _uint32LittleEndian(List<int> bytes, int offset) =>
      _byte(bytes, offset) |
      (_byte(bytes, offset + 1) << 8) |
      (_byte(bytes, offset + 2) << 16) |
      (_byte(bytes, offset + 3) << 24);

  static int _uint32BigEndian(List<int> bytes, int offset) =>
      (_byte(bytes, offset) << 24) |
      (_byte(bytes, offset + 1) << 16) |
      (_byte(bytes, offset + 2) << 8) |
      _byte(bytes, offset + 3);

  static String _decodeAsciiLossy(List<int> bytes) =>
      String.fromCharCodes(bytes.map((value) => value & 0x7F));
}

final class _TypeInfo {
  const _TypeInfo(this.extension, this.mimeType);

  final String extension;
  final String mimeType;
}

final class _DetectionCandidate {
  const _DetectionCandidate(
    this.info, [
    this.source = FileTypeDetectionSource.signature,
  ]);

  final _TypeInfo info;
  final FileTypeDetectionSource source;
}

final class _ZipMetadata {
  const _ZipMetadata(this.names, this.storedContents);

  final Set<String> names;
  final Map<String, List<int>> storedContents;
}
