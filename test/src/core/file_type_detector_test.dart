import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ipfs_downloader/src/core/file_type_detector.dart';

void main() {
  group('binary signatures', () {
    final imageCases = <String, ({List<int> bytes, String extension})>{
      'JPEG': (bytes: <int>[0xFF, 0xD8, 0xFF, 0xE0], extension: 'jpg'),
      'PNG': (
        bytes: <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
        extension: 'png',
      ),
      'GIF87a': (bytes: ascii.encode('GIF87a'), extension: 'gif'),
      'GIF89a': (bytes: ascii.encode('GIF89a'), extension: 'gif'),
      'WebP': (
        bytes: <int>[
          ...ascii.encode('RIFF'),
          0,
          0,
          0,
          0,
          ...ascii.encode('WEBP'),
        ],
        extension: 'webp',
      ),
      'TIFF little endian': (
        bytes: <int>[0x49, 0x49, 0x2A, 0x00],
        extension: 'tiff',
      ),
      'TIFF big endian': (
        bytes: <int>[0x4D, 0x4D, 0x00, 0x2A],
        extension: 'tiff',
      ),
      'BMP': (bytes: ascii.encode('BM'), extension: 'bmp'),
      'ICO': (bytes: <int>[0, 0, 1, 0], extension: 'ico'),
    };

    for (final entry in imageCases.entries) {
      test('detects ${entry.key}', () {
        _expectType(entry.value.bytes, entry.value.extension);
      });
    }

    test('detects AVIF and HEIC ISO Base Media brands', () {
      _expectType(_ftyp('avif', compatibleBrands: <String>['mif1']), 'avif');
      _expectType(_ftyp('mif1', compatibleBrands: <String>['heic']), 'heic');
      _expectType(_ftyp('mif1'), 'heif');
    });

    test('finds a PDF signature after a permitted prefix', () {
      _expectType(<int>[0xEF, 0xBB, 0xBF, ...ascii.encode('%PDF-1.7')], 'pdf');
    });

    final archiveCases = <String, ({List<int> bytes, String extension})>{
      'empty ZIP': (bytes: <int>[0x50, 0x4B, 0x05, 0x06], extension: 'zip'),
      'RAR 4': (
        bytes: <int>[0x52, 0x61, 0x72, 0x21, 0x1A, 0x07, 0x00],
        extension: 'rar',
      ),
      'RAR 5': (
        bytes: <int>[0x52, 0x61, 0x72, 0x21, 0x1A, 0x07, 0x01, 0x00],
        extension: 'rar',
      ),
      '7-Zip': (
        bytes: <int>[0x37, 0x7A, 0xBC, 0xAF, 0x27, 0x1C],
        extension: '7z',
      ),
      'GZIP': (bytes: <int>[0x1F, 0x8B, 0x08, 0], extension: 'gz'),
      'BZIP2': (bytes: ascii.encode('BZh9'), extension: 'bz2'),
      'XZ': (bytes: <int>[0xFD, 0x37, 0x7A, 0x58, 0x5A, 0x00], extension: 'xz'),
    };

    for (final entry in archiveCases.entries) {
      test('detects ${entry.key}', () {
        _expectType(entry.value.bytes, entry.value.extension);
      });
    }

    test('detects TAR at its fixed magic offset', () {
      final bytes = List<int>.filled(512, 0);
      bytes.setRange(257, 262, ascii.encode('ustar'));
      _expectType(bytes, 'tar');
    });
  });

  group('audio and video signatures', () {
    final cases = <String, ({List<int> bytes, String extension})>{
      'ID3 MP3': (bytes: ascii.encode('ID3\u0004\u0000'), extension: 'mp3'),
      'headerless MP3 frame': (
        bytes: <int>[0xFF, 0xFB, 0x90, 0x64],
        extension: 'mp3',
      ),
      'FLAC': (bytes: ascii.encode('fLaC'), extension: 'flac'),
      'WAV': (
        bytes: <int>[
          ...ascii.encode('RIFF'),
          0,
          0,
          0,
          0,
          ...ascii.encode('WAVE'),
        ],
        extension: 'wav',
      ),
      'Ogg': (bytes: ascii.encode('OggS\u0000\u0002vorbis'), extension: 'ogg'),
      'Opus in Ogg': (
        bytes: ascii.encode('OggS\u0000\u0002........OpusHead'),
        extension: 'opus',
      ),
      'Matroska': (
        bytes: <int>[0x1A, 0x45, 0xDF, 0xA3, ...ascii.encode('matroska')],
        extension: 'mkv',
      ),
      'WebM': (
        bytes: <int>[0x1A, 0x45, 0xDF, 0xA3, ...ascii.encode('webm')],
        extension: 'webm',
      ),
      'AVI': (
        bytes: <int>[
          ...ascii.encode('RIFF'),
          0,
          0,
          0,
          0,
          ...ascii.encode('AVI '),
        ],
        extension: 'avi',
      ),
    };

    for (final entry in cases.entries) {
      test('detects ${entry.key}', () {
        _expectType(entry.value.bytes, entry.value.extension);
      });
    }

    test('distinguishes M4A, MP4 and QuickTime brands', () {
      _expectType(_ftyp('M4A '), 'm4a');
      _expectType(_ftyp('isom', compatibleBrands: <String>['mp42']), 'mp4');
      _expectType(_ftyp('qt  '), 'mov');
    });
  });

  group('program, database and font signatures', () {
    final cases = <String, ({List<int> bytes, String extension})>{
      'Windows executable': (bytes: _portableExecutable(), extension: 'exe'),
      'ELF': (bytes: <int>[0x7F, 0x45, 0x4C, 0x46], extension: 'elf'),
      'Mach-O 64 little endian': (
        bytes: <int>[0xCF, 0xFA, 0xED, 0xFE],
        extension: 'macho',
      ),
      'Mach-O universal': (
        bytes: <int>[0xCA, 0xFE, 0xBA, 0xBE, 0, 0, 0, 2],
        extension: 'macho',
      ),
      'Java class': (
        bytes: <int>[0xCA, 0xFE, 0xBA, 0xBE, 0, 0, 0, 61],
        extension: 'class',
      ),
      'SQLite': (
        bytes: ascii.encode('SQLite format 3\u0000'),
        extension: 'sqlite',
      ),
      'WOFF': (bytes: ascii.encode('wOFF'), extension: 'woff'),
      'WOFF2': (bytes: ascii.encode('wOF2'), extension: 'woff2'),
      'TrueType': (bytes: <int>[0, 1, 0, 0], extension: 'ttf'),
      'OpenType': (bytes: ascii.encode('OTTO'), extension: 'otf'),
    };

    for (final entry in cases.entries) {
      test('detects ${entry.key}', () {
        _expectType(entry.value.bytes, entry.value.extension);
      });
    }

    test('does not classify a short MZ prefix as executable', () {
      final result = FileTypeDetector.detect(ascii.encode('MZ ordinary text'));

      expect(result.extension, 'txt');
      expect(result.source, FileTypeDetectionSource.textHeuristic);
    });
  });

  group('ZIP container refinement', () {
    const zipBytes = <int>[0x50, 0x4B, 0x03, 0x04];

    test('uses supplied package entry names for OpenXML formats', () {
      final docx = FileTypeDetector.detect(
        zipBytes,
        zipEntryNames: const <String>[
          '[Content_Types].xml',
          'word/document.xml',
        ],
      );
      final xlsx = FileTypeDetector.detect(
        zipBytes,
        zipEntryNames: const <String>['[Content_Types].xml', 'xl/workbook.xml'],
      );
      final pptx = FileTypeDetector.detect(
        zipBytes,
        zipEntryNames: const <String>[
          '[Content_Types].xml',
          'ppt/slides/slide1.xml',
        ],
      );

      expect(docx.extension, 'docx');
      expect(xlsx.extension, 'xlsx');
      expect(pptx.extension, 'pptx');
      expect(docx.source, FileTypeDetectionSource.zipContents);
    });

    test('uses stored mimetype content for EPUB and OpenDocument', () {
      final epub = FileTypeDetector.detect(
        zipBytes,
        zipEntryContents: <String, List<int>>{
          'mimetype': ascii.encode('application/epub+zip'),
        },
      );
      final odt = FileTypeDetector.detect(
        zipBytes,
        zipEntryContents: <String, List<int>>{
          'mimetype': ascii.encode('application/vnd.oasis.opendocument.text'),
        },
      );

      expect(epub.extension, 'epub');
      expect(odt.extension, 'odt');
    });

    test('recognizes an EPUB mimetype directly from a stored local entry', () {
      final bytes = _storedZipEntry(
        'mimetype',
        ascii.encode('application/epub+zip'),
      );

      final result = FileTypeDetector.detect(bytes);

      expect(result.extension, 'epub');
      expect(result.source, FileTypeDetectionSource.zipContents);
    });

    test('allows only compatible metadata to refine a ZIP signature', () {
      final compatible = FileTypeDetector.detect(
        zipBytes,
        contentType:
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      );
      final conflicting = FileTypeDetector.detect(
        zipBytes,
        contentType: 'image/jpeg',
      );

      expect(compatible.extension, 'docx');
      expect(compatible.source, FileTypeDetectionSource.contentType);
      expect(conflicting.extension, 'zip');
      expect(conflicting.source, FileTypeDetectionSource.signature);
    });
  });

  group('text heuristics', () {
    final cases = <String, ({String value, String extension})>{
      'JSON object': (value: ' {"name":"IPFS","ok":true}', extension: 'json'),
      'truncated JSON header': (value: '{"items": [1, 2,', extension: 'json'),
      'XML': (value: '<?xml version="1.0"?><feed></feed>', extension: 'xml'),
      'HTML': (value: '<!doctype html><html></html>', extension: 'html'),
      'SVG with XML declaration': (
        value: '<?xml version="1.0"?>\n<svg viewBox="0 0 1 1"></svg>',
        extension: 'svg',
      ),
      'plain UTF-8': (
        value: 'Ein ganz normaler Text mit Umlauten: äöü',
        extension: 'txt',
      ),
    };

    for (final entry in cases.entries) {
      test('detects ${entry.key}', () {
        final result = FileTypeDetector.detect(utf8.encode(entry.value.value));

        expect(result.extension, entry.value.extension);
        expect(result.source, FileTypeDetectionSource.textHeuristic);
      });
    }

    test('recognizes UTF-16 text with a byte-order mark', () {
      final bytes = <int>[0xFF, 0xFE];
      for (final unit in 'Hallo Welt'.codeUnits) {
        bytes.add(unit & 0xFF);
        bytes.add(unit >> 8);
      }

      _expectType(bytes, 'txt');
    });

    test('does not call arbitrary invalid UTF-8 binary text', () {
      final result = FileTypeDetector.detect(<int>[0xFF, 0x00, 0x81, 0x02]);

      expect(result.extension, 'bin');
      expect(result.source, FileTypeDetectionSource.unknown);
      expect(result.isKnown, isFalse);
    });
  });

  group('HTTP metadata and precedence', () {
    test('magic bytes override a conflicting Content-Type', () {
      final result = FileTypeDetector.detect(<int>[
        0xFF,
        0xD8,
        0xFF,
        0xE0,
      ], contentType: 'application/pdf');

      expect(result.extension, 'jpg');
      expect(result.mimeType, 'image/jpeg');
      expect(result.source, FileTypeDetectionSource.signature);
    });

    test('uses a specific normalized Content-Type without bytes', () {
      final result = FileTypeDetector.detect(
        const <int>[],
        contentType: ' Image/JPEG; charset=binary ',
      );

      expect(result.extension, 'jpg');
      expect(result.source, FileTypeDetectionSource.contentType);
    });

    test('ignores gateway and generic binary MIME values', () {
      for (final mime in <String>[
        'application/octet-stream',
        'application/vnd.ipld.raw; version=1',
        'binary/octet-stream',
      ]) {
        final result = FileTypeDetector.detect(<int>[
          0xFF,
          0x00,
          0x81,
        ], contentType: mime);
        expect(result.extension, 'bin', reason: mime);
        expect(FileTypeDetector.isGenericMimeType(mime), isTrue);
      }
    });

    test('falls back to a recognized Content-Disposition extension', () {
      final result = FileTypeDetector.detect(
        const <int>[],
        contentDisposition: 'attachment; filename="manual.PDF"',
      );

      expect(result.extension, 'pdf');
      expect(result.suggestedFileName, 'manual.PDF');
      expect(result.source, FileTypeDetectionSource.contentDisposition);
    });

    test('understands structured vendor MIME suffixes', () {
      expect(
        FileTypeDetector.detect(
          const <int>[],
          contentType: 'application/problem+json',
        ).extension,
        'json',
      );
      expect(
        FileTypeDetector.detect(
          const <int>[],
          contentType: 'application/atom+xml',
        ).extension,
        'atom',
      );
    });

    test('uses the extended Dart MIME database for less common formats', () {
      const cases = <String, String>{
        'application/msword': 'doc',
        'application/vnd.ms-excel': 'xls',
        'application/vnd.ms-powerpoint': 'ppt',
        'text/calendar': 'ics',
      };

      for (final entry in cases.entries) {
        final result = FileTypeDetector.detect(
          const <int>[],
          contentType: entry.key,
        );
        expect(result.extension, entry.value, reason: entry.key);
        expect(result.source, FileTypeDetectionSource.contentType);
      }
    });

    test('uses the extended MIME database for disposition extensions', () {
      final result = FileTypeDetector.detect(
        const <int>[],
        contentDisposition: 'attachment; filename="meeting.ics"',
      );

      expect(result.extension, 'ics');
      expect(result.mimeType, 'text/calendar');
      expect(result.source, FileTypeDetectionSource.contentDisposition);
    });
  });

  group('Content-Disposition and safe names', () {
    test('prefers and decodes RFC 5987 filename-star', () {
      final name = FileTypeDetector.fileNameFromContentDisposition(
        "attachment; filename=plain.jpg; filename*=UTF-8''Urlaub%20K%C3%B6ln.jpg",
      );

      expect(name, 'Urlaub Köln.jpg');
    });

    test('removes path traversal, controls and reserved characters', () {
      expect(
        FileTypeDetector.fileNameFromContentDisposition(
          'attachment; filename="..\\folder\\bad<name>?.jpg"',
        ),
        'bad_name__.jpg',
      );
      expect(FileTypeDetector.sanitizeFileName('folder/CON.txt'), '_CON.txt');
      expect(
        FileTypeDetector.sanitizeFileName('bad\u0000name.txt'),
        'badname.txt',
      );
    });

    test('handles semicolons and escaped quotes inside quoted values', () {
      final name = FileTypeDetector.fileNameFromContentDisposition(
        'attachment; filename="my; special\\" file.txt"',
      );

      expect(name, 'my; special_ file.txt');
    });

    test('rejects invalid filename-star and falls back to filename', () {
      final name = FileTypeDetector.fileNameFromContentDisposition(
        "attachment; filename=fallback.png; filename*=UTF-8''bad%ZZname.png",
      );

      expect(name, 'fallback.png');
    });

    test('extracts only conservative extensions', () {
      expect(FileTypeDetector.extensionFromFileName('/tmp/photo.JPEG'), 'jpeg');
      expect(FileTypeDetector.extensionFromFileName('README'), isNull);
      expect(FileTypeDetector.extensionFromFileName('.profile'), isNull);
      expect(
        FileTypeDetector.extensionFromFileName('bad.long extension'),
        isNull,
      );
    });
  });

  group('file-name suggestion', () {
    test('replaces .bin with the canonical JPEG extension', () {
      final type = FileTypeDetector.detect(<int>[0xFF, 0xD8, 0xFF, 0xE0]);

      expect(
        type.suggestFileName(
          fallbackBaseName: 'bafkreihhx7pzvesno3x7',
          currentFileName: 'bafkreihhx7pzvesno3x7.bin',
        ),
        'bafkreihhx7pzvesno3x7.jpg',
      );
    });

    test(
      'prefers a sanitized disposition name and canonicalizes its suffix',
      () {
        final type = FileTypeDetector.detect(<int>[
          0xFF,
          0xD8,
          0xFF,
        ], contentDisposition: 'attachment; filename="folder\\holiday.jpeg"');

        expect(type.suggestFileName(fallbackBaseName: 'cid'), 'holiday.jpg');
      },
    );

    test('adds .bin only when unknown data has no extension', () {
      final unknown = FileTypeDetector.detect(<int>[0xFF, 0x00, 0x81]);

      expect(unknown.suggestFileName(fallbackBaseName: 'cid'), 'cid.bin');
      expect(
        unknown.suggestFileName(
          fallbackBaseName: 'cid',
          currentFileName: 'custom.data',
        ),
        'custom.data',
      );
    });
  });
}

void _expectType(List<int> bytes, String extension) {
  final result = FileTypeDetector.detect(bytes);
  expect(result.extension, extension);
  expect(result.source, isNot(FileTypeDetectionSource.unknown));
}

List<int> _ftyp(String majorBrand, {List<String> compatibleBrands = const []}) {
  final payload = <int>[
    ...ascii.encode('ftyp'),
    ...ascii.encode(majorBrand),
    0,
    0,
    0,
    0,
    for (final brand in compatibleBrands) ...ascii.encode(brand),
  ];
  final size = payload.length + 4;
  return <int>[
    (size >> 24) & 0xFF,
    (size >> 16) & 0xFF,
    (size >> 8) & 0xFF,
    size & 0xFF,
    ...payload,
  ];
}

List<int> _storedZipEntry(String name, List<int> content) {
  final nameBytes = utf8.encode(name);
  return <int>[
    0x50,
    0x4B,
    0x03,
    0x04,
    20,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    content.length & 0xFF,
    (content.length >> 8) & 0xFF,
    (content.length >> 16) & 0xFF,
    (content.length >> 24) & 0xFF,
    content.length & 0xFF,
    (content.length >> 8) & 0xFF,
    (content.length >> 16) & 0xFF,
    (content.length >> 24) & 0xFF,
    nameBytes.length & 0xFF,
    (nameBytes.length >> 8) & 0xFF,
    0,
    0,
    ...nameBytes,
    ...content,
  ];
}

List<int> _portableExecutable() {
  final bytes = List<int>.filled(132, 0);
  bytes[0] = 0x4D;
  bytes[1] = 0x5A;
  bytes[0x3C] = 128;
  bytes.setRange(128, 132, const <int>[0x50, 0x45, 0x00, 0x00]);
  return bytes;
}
