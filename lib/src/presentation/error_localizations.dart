import 'package:ipfs_downloader/l10n/app_localizations.dart';

/// Localizes errors produced by the download and persistence layers.
///
/// Persisted tasks from earlier releases contain German fallback text. Keeping
/// the translation at the presentation boundary lets those errors follow a
/// runtime language change without invalidating the stored queue format.
String localizeAppError(AppLocalizations l10n, String error) {
  final message = error.trim();

  final exact = switch (message) {
    'Die Download-Engine wurde bereits geschlossen.' =>
      l10n.downloadEngineClosed,
    'Für diese Aufgabe läuft bereits ein Download.' => l10n.taskAlreadyActive,
    'Es wurde kein Zielordner ausgewählt.' => l10n.destinationNotSelected,
    'Es ist kein gültiges HTTP-Gateway konfiguriert.' => l10n.noValidGateway,
    'Der gespeicherte Teil passt nicht zur Dateigröße des Gateways.' =>
      l10n.partialSizeMismatch,
    'Das Gateway lieferte keine weiteren Daten.' => l10n.gatewayNoMoreData,
    'Die Teildatei ist größer als der gemeldete Inhalt.' =>
      l10n.partialLargerThanContent,
    '206-Antwort ohne gültigen Content-Range-Header.' =>
      l10n.invalidContentRange,
    'Content-Length und Content-Range widersprechen sich.' =>
      l10n.contentRangeLengthConflict,
    'Die Dateigröße hat sich gegenüber dem begonnenen Download geändert.' =>
      l10n.remoteFileSizeChanged,
    'Für den erkannten Dateinamen konnte kein freier Zielname gefunden werden.' =>
      l10n.noFreeDetectedFilename,
    'Für den Dateinamen konnte kein freier Zielname gefunden werden.' =>
      l10n.noFreeFilename,
    'Der IPFS-Pfad ist ungültig.' => l10n.invalidIpfsPath,
    'Zeitüberschreitung beim Gateway.' => l10n.gatewayTimeout,
    'Das Gateway ist nicht erreichbar.' => l10n.gatewayUnreachable,
    'Die Zieldatei konnte nicht geschrieben werden.' => l10n.targetWriteFailed,
    _ => null,
  };
  if (exact != null) return exact;

  final httpStatus = RegExp(r'^HTTP (\d+) vom Gateway\.$').firstMatch(message);
  if (httpStatus != null) {
    return l10n.gatewayHttpError(int.parse(httpStatus.group(1)!));
  }

  final responseEnded = RegExp(
    r'^Die Antwort endete nach (\d+) statt nach (\d+) Bytes\.$',
  ).firstMatch(message);
  if (responseEnded != null) {
    return l10n.responseEndedEarly(
      int.parse(responseEnded.group(1)!),
      int.parse(responseEnded.group(2)!),
    );
  }

  final incomplete = RegExp(
    r'^Der Download ist unvollständig \((\d+) von (\d+) Bytes\)\.$',
  ).firstMatch(message);
  if (incomplete != null) {
    return l10n.incompleteDownload(
      int.parse(incomplete.group(1)!),
      int.parse(incomplete.group(2)!),
    );
  }

  final rangeStart = RegExp(
    r'^Content-Range beginnt bei (\d+), erwartet wurde (\d+)\.$',
  ).firstMatch(message);
  if (rangeStart != null) {
    return l10n.contentRangeStartMismatch(
      int.parse(rangeStart.group(1)!),
      int.parse(rangeStart.group(2)!),
    );
  }

  const invalidGatewayPrefix = 'Ungültiges HTTP-Gateway: ';
  if (message.startsWith(invalidGatewayPrefix)) {
    return l10n.invalidHttpGateway(
      message.substring(invalidGatewayPrefix.length),
    );
  }

  const allGatewaysPrefix = 'Kein Gateway konnte den Inhalt laden. ';
  if (message.startsWith(allGatewaysPrefix)) {
    final details = message.substring(allGatewaysPrefix.length);
    final localizedDetails = details
        .split(' · ')
        .map((failure) {
          final separator = failure.indexOf(': ');
          if (separator < 0) return localizeAppError(l10n, failure);
          final gateway = failure.substring(0, separator);
          final reason = failure.substring(separator + 2);
          return '$gateway: ${localizeAppError(l10n, reason)}';
        })
        .join(' · ');
    return l10n.noGatewayCouldLoad(localizedDetails);
  }

  const unexpectedPrefix = 'Unerwarteter Fehler: ';
  if (message.startsWith(unexpectedPrefix)) {
    return l10n.unexpectedError(message.substring(unexpectedPrefix.length));
  }

  const stateSavePrefix = 'Status konnte nicht gespeichert werden: ';
  if (message.startsWith(stateSavePrefix)) {
    return l10n.stateSaveFailed(message.substring(stateSavePrefix.length));
  }

  return error;
}
