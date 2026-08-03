import 'dart:convert';

class ParsedIpfsInput {
  const ParsedIpfsInput({
    required this.cid,
    this.ipfsPath = '',
    this.originalInput = '',
  });

  final String cid;
  final String ipfsPath;
  final String originalInput;

  String suggestedFileName({bool directoryArchive = false}) {
    if (directoryArchive) {
      return sanitizeFileName(
        ipfsPath.isEmpty ? '$cid.tar' : '${ipfsPath.split('/').last}.tar',
      );
    }
    if (ipfsPath.isNotEmpty) {
      return sanitizeFileName(ipfsPath.split('/').last);
    }
    final shortCid = cid.length > 18 ? cid.substring(0, 18) : cid;
    return '$shortCid.bin';
  }
}

enum IpfsInputError {
  noCid,
  emptyInput,
  gatewayUrlMissingCid,
  unsupportedCid,
  relativePathSegment,
  encodedPathSeparator,
  missingCid,
  invalidUrlEncoding,
}

class IpfsInputException implements Exception {
  const IpfsInputException(
    this.message, {
    required this.code,
    this.input,
    this.invalidValue,
  });

  final String message;
  final IpfsInputError code;
  final String? input;
  final String? invalidValue;

  @override
  String toString() => message;
}

abstract final class IpfsInputParser {
  static final RegExp _cidV0 = RegExp(r'^Qm[1-9A-HJ-NP-Za-km-z]{44}$');
  static final RegExp _cidV1Base32 = RegExp(r'^[bB][A-Za-z2-7]{20,255}$');

  static List<ParsedIpfsInput> parseMany(String value) {
    final lines = const LineSplitter()
        .convert(value)
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    if (lines.isEmpty) {
      throw const IpfsInputException(
        'Bitte mindestens eine CID eingeben.',
        code: IpfsInputError.noCid,
      );
    }
    return lines.map(parse).toList(growable: false);
  }

  static ParsedIpfsInput parse(String value) {
    var input = value.trim();
    if (input.length >= 2 &&
        ((input.startsWith('"') && input.endsWith('"')) ||
            (input.startsWith("'") && input.endsWith("'")))) {
      input = input.substring(1, input.length - 1).trim();
    }
    if (input.isEmpty) {
      throw const IpfsInputException(
        'Die Eingabe ist leer.',
        code: IpfsInputError.emptyInput,
      );
    }

    String cid;
    List<String> pathSegments;
    var pathSegmentsAreDecoded = false;

    if (input.toLowerCase().startsWith('ipfs://')) {
      final remainder = input.substring(7);
      final parts = _splitPath(remainder);
      cid = parts.first;
      pathSegments = parts.skip(1).toList(growable: false);
    } else if (input.startsWith('/ipfs/')) {
      final parts = _splitPath(input.substring('/ipfs/'.length));
      cid = parts.first;
      pathSegments = parts.skip(1).toList(growable: false);
    } else {
      final uri = Uri.tryParse(input);
      if (uri != null &&
          (uri.scheme.toLowerCase() == 'http' ||
              uri.scheme.toLowerCase() == 'https')) {
        final ipfsIndex = uri.pathSegments.indexOf('ipfs');
        if (ipfsIndex >= 0 && uri.pathSegments.length > ipfsIndex + 1) {
          cid = uri.pathSegments[ipfsIndex + 1];
          pathSegments = uri.pathSegments
              .skip(ipfsIndex + 2)
              .toList(growable: false);
          pathSegmentsAreDecoded = true;
        } else {
          final marker = '.ipfs.';
          final markerIndex = uri.host.toLowerCase().indexOf(marker);
          if (markerIndex <= 0) {
            throw IpfsInputException(
              'Die Gateway-URL enthält keinen /ipfs/<CID>-Pfad.',
              code: IpfsInputError.gatewayUrlMissingCid,
              input: value,
            );
          }
          cid = uri.host.substring(0, markerIndex);
          pathSegments = uri.pathSegments;
          pathSegmentsAreDecoded = true;
        }
      } else {
        final parts = _splitPath(input);
        cid = parts.first;
        pathSegments = parts.skip(1).toList(growable: false);
      }
    }

    cid = cid.split('?').first.split('#').first;
    if (!isSupportedCid(cid)) {
      throw IpfsInputException(
        '„$cid“ ist keine unterstützte CIDv0- oder CIDv1-Base32-CID.',
        code: IpfsInputError.unsupportedCid,
        input: value,
        invalidValue: cid,
      );
    }
    if (cid.startsWith('B')) {
      cid = 'b${cid.substring(1).toLowerCase()}';
    }

    final decodedSegments = <String>[];
    for (final segment in pathSegments) {
      if (segment.isEmpty) continue;
      final decoded = pathSegmentsAreDecoded
          ? segment
          : _decodeSegment(segment);
      if (decoded == '.' || decoded == '..') {
        throw IpfsInputException(
          'Relative Pfadbestandteile sind nicht erlaubt.',
          code: IpfsInputError.relativePathSegment,
          input: value,
        );
      }
      if (decoded.contains('/') || decoded.contains('\\')) {
        throw IpfsInputException(
          'Kodierte Pfadtrenner sind nicht erlaubt.',
          code: IpfsInputError.encodedPathSeparator,
          input: value,
        );
      }
      decodedSegments.add(decoded);
    }

    return ParsedIpfsInput(
      cid: cid,
      ipfsPath: decodedSegments.join('/'),
      originalInput: value,
    );
  }

  static bool isSupportedCid(String value) =>
      _cidV0.hasMatch(value) || _cidV1Base32.hasMatch(value);

  static List<String> _splitPath(String value) {
    final withoutQuery = value.split('?').first.split('#').first;
    final parts = withoutQuery.split('/').where((part) => part.isNotEmpty);
    final result = parts.toList(growable: false);
    if (result.isEmpty) {
      throw const IpfsInputException(
        'In der Eingabe fehlt eine CID.',
        code: IpfsInputError.missingCid,
      );
    }
    return result;
  }

  static String _decodeSegment(String value) {
    try {
      return Uri.decodeComponent(value);
    } on FormatException {
      throw IpfsInputException(
        'Ungültige URL-Kodierung in „$value“.',
        code: IpfsInputError.invalidUrlEncoding,
        invalidValue: value,
      );
    } on ArgumentError {
      throw IpfsInputException(
        'Ungültige URL-Kodierung in „$value“.',
        code: IpfsInputError.invalidUrlEncoding,
        invalidValue: value,
      );
    }
  }
}

String sanitizeFileName(String value, {String fallback = 'download.bin'}) {
  var result = value
      .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
      .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
      .trim();
  result = result.replaceFirst(RegExp(r'[. ]+$'), '');
  if (result.isEmpty || result == '.' || result == '..') {
    result = fallback;
  }

  final baseName = result.split('.').first.toUpperCase();
  if (RegExp(r'^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$').hasMatch(baseName)) {
    result = '_$result';
  }
  if (result.length > 180) {
    final lastDot = result.lastIndexOf('.');
    final extension = lastDot > 0 && result.length - lastDot <= 16
        ? result.substring(lastDot)
        : '';
    result = '${result.substring(0, 180 - extension.length)}$extension';
  }
  return result;
}
