import 'package:flutter_test/flutter_test.dart';
import 'package:ipfs_downloader/src/core/ipfs_input_parser.dart';

const String _cidV0 = 'QmYwAPJzv5CZsnAzt8auVZRnGiVvWjF34VQ9F4sY5k2zKx';
const String _cidV1 =
    'bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi';

void main() {
  group('IpfsInputParser.parse', () {
    test('accepts a bare CIDv0', () {
      final ParsedIpfsInput parsed = IpfsInputParser.parse(_cidV0);

      expect(parsed.cid, _cidV0);
      expect(parsed.ipfsPath, isEmpty);
      expect(parsed.originalInput, _cidV0);
    });

    test('accepts and canonicalizes an uppercase CIDv1', () {
      final ParsedIpfsInput parsed = IpfsInputParser.parse(
        _cidV1.toUpperCase(),
      );

      expect(parsed.cid, _cidV1);
      expect(parsed.ipfsPath, isEmpty);
    });

    test('parses an ipfs URI and decodes safe path segments', () {
      final ParsedIpfsInput parsed = IpfsInputParser.parse(
        'ipfs://$_cidV1/folder/My%20File.txt',
      );

      expect(parsed.cid, _cidV1);
      expect(parsed.ipfsPath, 'folder/My File.txt');
      expect(parsed.suggestedFileName(), 'My File.txt');
    });

    test('parses a canonical /ipfs/ path', () {
      final ParsedIpfsInput parsed = IpfsInputParser.parse(
        '/ipfs/$_cidV0/releases/file.tar',
      );

      expect(parsed.cid, _cidV0);
      expect(parsed.ipfsPath, 'releases/file.tar');
    });

    test('parses a path-style gateway URL without query or fragment', () {
      final ParsedIpfsInput parsed = IpfsInputParser.parse(
        'https://dweb.link/ipfs/$_cidV1/docs/manual.pdf'
        '?download=true#page-2',
      );

      expect(parsed.cid, _cidV1);
      expect(parsed.ipfsPath, 'docs/manual.pdf');
    });

    test('parses a subdomain-style gateway URL', () {
      final ParsedIpfsInput parsed = IpfsInputParser.parse(
        'https://$_cidV1.ipfs.dweb.link/assets/logo.svg',
      );

      expect(parsed.cid, _cidV1);
      expect(parsed.ipfsPath, 'assets/logo.svg');
    });

    test('trims whitespace and matching quotes', () {
      final ParsedIpfsInput parsed = IpfsInputParser.parse(
        '  "ipfs://$_cidV0/folder/file.txt"  ',
      );

      expect(parsed.cid, _cidV0);
      expect(parsed.ipfsPath, 'folder/file.txt');
      expect(parsed.originalInput, '  "ipfs://$_cidV0/folder/file.txt"  ');
    });

    test('strips a query from a bare CID', () {
      final ParsedIpfsInput parsed = IpfsInputParser.parse(
        '$_cidV1?download=true',
      );

      expect(parsed.cid, _cidV1);
      expect(parsed.ipfsPath, isEmpty);
    });
  });

  group('IpfsInputParser.parseMany', () {
    test('parses non-empty lines and preserves their order', () {
      final List<ParsedIpfsInput> parsed = IpfsInputParser.parseMany(
        '\n$_cidV0\r\n  ipfs://$_cidV1/folder/file.bin  \n\n',
      );

      expect(parsed, hasLength(2));
      expect(parsed.map((item) => item.cid), <String>[_cidV0, _cidV1]);
      expect(parsed.last.ipfsPath, 'folder/file.bin');
    });

    test('rejects input containing only whitespace', () {
      expect(
        () => IpfsInputParser.parseMany(' \n\t\r\n '),
        throwsA(
          isA<IpfsInputException>().having(
            (error) => error.message,
            'message',
            contains('mindestens eine CID'),
          ),
        ),
      );
    });
  });

  group('CID validation', () {
    test('recognizes supported CIDv0 and CIDv1 forms', () {
      expect(IpfsInputParser.isSupportedCid(_cidV0), isTrue);
      expect(IpfsInputParser.isSupportedCid(_cidV1), isTrue);
      expect(IpfsInputParser.isSupportedCid(_cidV1.toUpperCase()), isTrue);
    });

    test('rejects malformed and unsupported identifiers', () {
      expect(IpfsInputParser.isSupportedCid(''), isFalse);
      expect(IpfsInputParser.isSupportedCid('QmTooShort'), isFalse);
      expect(IpfsInputParser.isSupportedCid('bafy0invalidbase32'), isFalse);
      expect(
        () => IpfsInputParser.parse('not-a-cid'),
        throwsA(isA<IpfsInputException>()),
      );
    });

    test('rejects HTTP URLs that are not IPFS gateways', () {
      expect(
        () => IpfsInputParser.parse('https://example.com/file.bin'),
        throwsA(
          isA<IpfsInputException>().having(
            (error) => error.message,
            'message',
            contains('keinen /ipfs/<CID>-Pfad'),
          ),
        ),
      );
    });
  });

  group('path security', () {
    final Map<String, String> invalidInputs = <String, String>{
      'plain parent traversal': '$_cidV1/../secret.txt',
      'encoded parent traversal': 'ipfs://$_cidV1/%2E%2E/secret.txt',
      'current-directory segment': '$_cidV1/./secret.txt',
      'encoded forward slash': '$_cidV1/folder%2Fsecret.txt',
      'encoded backslash': '$_cidV1/folder%5Csecret.txt',
      'invalid percent encoding': '$_cidV1/folder/%ZZ.txt',
    };

    for (final MapEntry<String, String> entry in invalidInputs.entries) {
      test('rejects ${entry.key}', () {
        expect(
          () => IpfsInputParser.parse(entry.value),
          throwsA(isA<IpfsInputException>()),
        );
      });
    }
  });

  group('sanitizeFileName', () {
    test('replaces reserved characters and removes controls', () {
      expect(sanitizeFileName('  report<final>?.txt.  '), 'report_final__.txt');
      expect(sanitizeFileName('safe\u0000name.txt'), 'safename.txt');
    });

    test('uses the fallback for empty and relative names', () {
      expect(sanitizeFileName(''), 'download.bin');
      expect(sanitizeFileName(' . '), 'download.bin');
      expect(sanitizeFileName('..', fallback: 'file.bin'), 'file.bin');
    });

    test('protects Windows device names case-insensitively', () {
      expect(sanitizeFileName('CON'), '_CON');
      expect(sanitizeFileName('con.txt'), '_con.txt');
      expect(sanitizeFileName('Lpt9.log'), '_Lpt9.log');
      expect(sanitizeFileName('COM10.txt'), 'COM10.txt');
    });

    test('limits long names while preserving a short extension', () {
      final String sanitized = sanitizeFileName(
        '${List<String>.filled(200, 'a').join()}.zip',
      );

      expect(sanitized, hasLength(180));
      expect(sanitized, endsWith('.zip'));
    });

    test('retains valid unicode names', () {
      expect(sanitizeFileName('Überblick 你好.txt'), 'Überblick 你好.txt');
    });
  });

  group('ParsedIpfsInput.suggestedFileName', () {
    test('uses a compact CID fallback for a root file', () {
      const ParsedIpfsInput parsed = ParsedIpfsInput(cid: _cidV1);

      expect(parsed.suggestedFileName(), '${_cidV1.substring(0, 18)}.bin');
    });

    test('sanitizes the final path segment', () {
      const ParsedIpfsInput parsed = ParsedIpfsInput(
        cid: _cidV1,
        ipfsPath: 'reports/final?.pdf',
      );

      expect(parsed.suggestedFileName(), 'final_.pdf');
    });

    test('suggests tar names for directory archives', () {
      const ParsedIpfsInput root = ParsedIpfsInput(cid: _cidV1);
      const ParsedIpfsInput nested = ParsedIpfsInput(
        cid: _cidV1,
        ipfsPath: 'photos/holiday',
      );

      expect(root.suggestedFileName(directoryArchive: true), '$_cidV1.tar');
      expect(nested.suggestedFileName(directoryArchive: true), 'holiday.tar');
    });
  });
}
