// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'IPFSDownloader';

  @override
  String get library => 'MEDIATHEK';

  @override
  String get allDownloads => 'Alle Downloads';

  @override
  String get all => 'Alle';

  @override
  String get active => 'Aktiv';

  @override
  String get completed => 'Fertig';

  @override
  String get errors => 'Fehler';

  @override
  String get options => 'Optionen';

  @override
  String get settings => 'Einstellungen';

  @override
  String get ipfsReady => 'IPFS bereit';

  @override
  String fallbackRoutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ausweichrouten',
      one: '1 Ausweichroute',
    );
    return '$_temp0';
  }

  @override
  String versionLabel(String version) {
    return 'IPFSDownloader $version';
  }

  @override
  String get activeDownloads => 'Aktive Downloads';

  @override
  String get completedDownloads => 'Fertige Downloads';

  @override
  String get activeDownloadsSubtitle =>
      'Warteschlange und laufende Übertragungen';

  @override
  String get completedDownloadsSubtitle =>
      'Erfolgreich auf diesem Gerät gespeichert';

  @override
  String get failedDownloadsSubtitle =>
      'Übertragungen, die Aufmerksamkeit benötigen';

  @override
  String get downloadsSubtitle =>
      'Dateien direkt aus dem IPFS-Netzwerk sichern';

  @override
  String get pauseAll => 'Alle pausieren';

  @override
  String get resume => 'Fortsetzen';

  @override
  String get addCid => 'CID hinzufügen';

  @override
  String get newIpfsFiles => 'Neue IPFS-Dateien';

  @override
  String get inputDescription =>
      'CID, ipfs://-Link oder Gateway-URL · eine Quelle pro Zeile';

  @override
  String get inputHint => 'bafybeig…\nipfs://bafybeig…/ordner/datei.zip';

  @override
  String get clearInput => 'Eingabe leeren';

  @override
  String get directoryArchiveTooltip =>
      'UnixFS-Verzeichnisse als unkomprimierte TAR-Archive laden';

  @override
  String get folderAsTar => 'Ordner als TAR';

  @override
  String get startDownload => 'Download starten';

  @override
  String get saveHere => 'Hier speichern';

  @override
  String addResult(int added, int duplicates) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added Downloads wurden hinzugefügt',
      one: '1 Download wurde hinzugefügt',
      zero: 'Keine Downloads wurden hinzugefügt',
    );
    String _temp1 = intl.Intl.pluralLogic(
      duplicates,
      locale: localeName,
      other: ' · $duplicates Duplikate wurden übersprungen.',
      one: ' · 1 Duplikat wurde übersprungen.',
      zero: '.',
    );
    return '$_temp0$_temp1';
  }

  @override
  String downloadAddFailed(Object error) {
    return 'Download konnte nicht hinzugefügt werden: $error';
  }

  @override
  String get chooseDestination => 'Zielordner auswählen';

  @override
  String get change => 'Ändern';

  @override
  String get metricActive => 'AKTIV';

  @override
  String queuedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dateien in der Warteschlange',
      one: '1 Datei in der Warteschlange',
    );
    return '$_temp0';
  }

  @override
  String get noWaitingFiles => 'Keine wartenden Dateien';

  @override
  String get metricSpeed => 'GESCHWINDIGKEIT';

  @override
  String get currentAggregateRate => 'Aktuelle Gesamtrate';

  @override
  String get metricCompleted => 'FERTIG';

  @override
  String get savedSuccessfully => 'Erfolgreich gespeichert';

  @override
  String get metricGateways => 'GATEWAYS';

  @override
  String get automaticFallback => 'Automatischer Fallback';

  @override
  String queueCount(int count) {
    return 'Warteschlange · $count';
  }

  @override
  String get searchDownloads => 'Downloads durchsuchen';

  @override
  String get clearCompleted => 'Fertige Einträge aus der Liste entfernen';

  @override
  String get removeEntryTitle => 'Eintrag entfernen?';

  @override
  String removeWithPartial(String fileName, String size) {
    return '„$fileName“ wird aus der Liste entfernt. Die Teildatei ($size) wird ebenfalls gelöscht.';
  }

  @override
  String removeKeepFile(String fileName) {
    return '„$fileName“ wird nur aus der Liste entfernt. Eine fertige Datei bleibt erhalten.';
  }

  @override
  String get cancel => 'Abbrechen';

  @override
  String get remove => 'Entfernen';

  @override
  String get statusQueued => 'Wartend';

  @override
  String get statusResolving => 'Wird aufgelöst';

  @override
  String get statusDownloading => 'Wird geladen';

  @override
  String get statusPaused => 'Pausiert';

  @override
  String get statusCompleted => 'Fertig';

  @override
  String get statusFailed => 'Fehlgeschlagen';

  @override
  String get statusCanceled => 'Abgebrochen';

  @override
  String bytesOfTotal(String received, String total) {
    return '$received von $total';
  }

  @override
  String timeRemaining(String duration) {
    return '$duration verbleibend';
  }

  @override
  String get savedLocally => 'Lokal gespeichert';

  @override
  String get ready => 'Bereit';

  @override
  String get pause => 'Pausieren';

  @override
  String get showInFolder => 'Im Ordner zeigen';

  @override
  String get start => 'Starten';

  @override
  String get moreActions => 'Weitere Aktionen';

  @override
  String get openDestinationFolder => 'Zielordner öffnen';

  @override
  String get moveUp => 'Nach oben';

  @override
  String get moveDown => 'Nach unten';

  @override
  String get removeFromList => 'Aus Liste entfernen';

  @override
  String get nothingFound => 'Nichts gefunden';

  @override
  String get nothingFoundMessage =>
      'Versuche einen anderen Dateinamen oder CID-Ausschnitt.';

  @override
  String get noCompletedDownloads => 'Noch keine fertigen Downloads';

  @override
  String get noCompletedDownloadsMessage =>
      'Erfolgreiche Übertragungen erscheinen automatisch hier.';

  @override
  String get noErrors => 'Keine Fehler';

  @override
  String get noErrorsMessage => 'Alle Downloads laufen wie erwartet.';

  @override
  String get nothingActive => 'Gerade ist nichts aktiv';

  @override
  String get nothingActiveMessage =>
      'Füge oben eine CID hinzu oder setze einen pausierten Download fort.';

  @override
  String get emptyQueue => 'Deine Warteschlange ist leer';

  @override
  String get emptyQueueMessage =>
      'Füge oben eine IPFS-CID ein, um die erste Datei zu laden.';

  @override
  String get chooseFolder => 'Ordner auswählen';

  @override
  String folderOpenFailed(Object error) {
    return 'Der Ordner konnte nicht geöffnet werden: $error';
  }

  @override
  String get gatewayRequired => 'Bitte eine Gateway-Adresse eingeben.';

  @override
  String get gatewayInvalid =>
      'Erlaubt sind vollständige http://- oder https://-Adressen.';

  @override
  String get gatewayDuplicate => 'Dieses Gateway ist bereits eingetragen.';

  @override
  String get settingsSubtitle => 'IPFSDownloader an deinen Workflow anpassen';

  @override
  String get downloadsSettings => 'Downloads';

  @override
  String get downloadsSettingsSubtitle =>
      'Speicherort und Verhalten der Warteschlange';

  @override
  String get defaultDestination => 'Standard-Zielordner';

  @override
  String get defaultDestinationDescription =>
      'Neue Downloads werden automatisch hier gespeichert.';

  @override
  String get noFolderSelected => 'Noch kein Ordner ausgewählt';

  @override
  String get choose => 'Auswählen';

  @override
  String get parallelDownloads => 'Parallele Downloads';

  @override
  String get parallelDownloadsDescription =>
      'Mehr parallele Vorgänge können die verfügbare Bandbreite besser nutzen.';

  @override
  String parallelDownloadsSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count parallele Downloads',
      one: '1 paralleler Download',
    );
    return '$_temp0';
  }

  @override
  String get autoStartDownloads => 'Downloads automatisch starten';

  @override
  String get autoStartDownloadsDescription =>
      'Neue Einträge beginnen, sobald ein Platz in der Warteschlange frei ist.';

  @override
  String get appearance => 'Erscheinungsbild';

  @override
  String get appearanceSubtitle => 'Darstellung der Benutzeroberfläche';

  @override
  String get colorScheme => 'Farbschema';

  @override
  String get colorSchemeDescription =>
      'Mit „System“ folgt die App automatisch der Betriebssystem-Einstellung.';

  @override
  String get system => 'System';

  @override
  String get light => 'Hell';

  @override
  String get dark => 'Dunkel';

  @override
  String get language => 'Sprache';

  @override
  String get languageDescription =>
      'Wähle die Sprache für die gesamte Anwendung.';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get ipfsGateways => 'IPFS-Gateways';

  @override
  String get ipfsGatewaysSubtitle =>
      'Die Adressen werden der Reihe nach versucht, bis ein Download gelingt.';

  @override
  String get minimumGatewayRequired =>
      'Mindestens ein Gateway ist erforderlich';

  @override
  String get removeGateway => 'Gateway entfernen';

  @override
  String get addGateway => 'Gateway hinzufügen';

  @override
  String get add => 'Hinzufügen';

  @override
  String get gatewayRules =>
      'Nur HTTP- und HTTPS-Adressen sind zulässig. Mindestens ein Gateway muss aktiv bleiben.';

  @override
  String get network => 'Netzwerk';

  @override
  String get networkSubtitle => 'Zeitlimits für Gateway-Verbindungen';

  @override
  String get connectionTimeout => 'Verbindungs-Timeout';

  @override
  String get connectionTimeoutDescription =>
      'Danach wechselt der Downloader automatisch zum nächsten Gateway.';

  @override
  String secondsShort(int count) {
    return '$count s';
  }

  @override
  String timeoutSecondsSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sekunden Timeout',
      one: '1 Sekunde Timeout',
    );
    return '$_temp0';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours Std. $minutes Min.';
  }

  @override
  String durationMinutesSeconds(int minutes, int seconds) {
    return '$minutes Min. $seconds Sek.';
  }

  @override
  String durationSeconds(int seconds) {
    return '$seconds Sek.';
  }

  @override
  String get downloadEngineClosed =>
      'Die Download-Engine wurde bereits geschlossen.';

  @override
  String get taskAlreadyActive =>
      'Für diese Aufgabe läuft bereits ein Download.';

  @override
  String get destinationNotSelected => 'Es wurde kein Zielordner ausgewählt.';

  @override
  String get noValidGateway =>
      'Es ist kein gültiges HTTP-Gateway konfiguriert.';

  @override
  String noGatewayCouldLoad(String details) {
    return 'Kein Gateway konnte den Inhalt laden. $details';
  }

  @override
  String get partialSizeMismatch =>
      'Der gespeicherte Teil passt nicht zur Dateigröße des Gateways.';

  @override
  String gatewayHttpError(int status) {
    return 'HTTP $status vom Gateway.';
  }

  @override
  String responseEndedEarly(int actual, int expected) {
    return 'Die Antwort endete nach $actual statt nach $expected Bytes.';
  }

  @override
  String get gatewayNoMoreData => 'Das Gateway lieferte keine weiteren Daten.';

  @override
  String get partialLargerThanContent =>
      'Die Teildatei ist größer als der gemeldete Inhalt.';

  @override
  String incompleteDownload(int received, int total) {
    return 'Der Download ist unvollständig ($received von $total Bytes).';
  }

  @override
  String get invalidContentRange =>
      'Die 206-Antwort enthält keinen gültigen Content-Range-Header.';

  @override
  String contentRangeStartMismatch(int actual, int expected) {
    return 'Content-Range beginnt bei $actual, erwartet wurde $expected.';
  }

  @override
  String get contentRangeLengthConflict =>
      'Content-Length und Content-Range widersprechen sich.';

  @override
  String get remoteFileSizeChanged =>
      'Die Dateigröße hat sich gegenüber dem begonnenen Download geändert.';

  @override
  String get noFreeDetectedFilename =>
      'Für den erkannten Dateinamen konnte kein freier Zielname gefunden werden.';

  @override
  String get noFreeFilename =>
      'Für den Dateinamen konnte kein freier Zielname gefunden werden.';

  @override
  String invalidHttpGateway(String gateway) {
    return 'Ungültiges HTTP-Gateway: $gateway';
  }

  @override
  String get invalidIpfsPath => 'Der IPFS-Pfad ist ungültig.';

  @override
  String get gatewayTimeout => 'Zeitüberschreitung beim Gateway.';

  @override
  String get gatewayUnreachable => 'Das Gateway ist nicht erreichbar.';

  @override
  String get targetWriteFailed =>
      'Die Zieldatei konnte nicht geschrieben werden.';

  @override
  String get selectDestinationFirst =>
      'Bitte zuerst einen Zielordner auswählen.';

  @override
  String get enterAtLeastOneCid => 'Bitte mindestens eine CID eingeben.';

  @override
  String get inputEmpty => 'Die Eingabe ist leer.';

  @override
  String get gatewayUrlMissingCid =>
      'Die Gateway-URL enthält keinen /ipfs/<CID>-Pfad.';

  @override
  String unsupportedCid(String cid) {
    return '„$cid“ ist keine unterstützte CIDv0- oder CIDv1-Base32-CID.';
  }

  @override
  String get relativePathNotAllowed =>
      'Relative Pfadbestandteile sind nicht erlaubt.';

  @override
  String get encodedSeparatorNotAllowed =>
      'Kodierte Pfadtrenner sind nicht erlaubt.';

  @override
  String get inputMissingCid => 'In der Eingabe fehlt eine CID.';

  @override
  String invalidUrlEncoding(String value) {
    return 'Ungültige URL-Kodierung in „$value“.';
  }

  @override
  String unexpectedError(Object error) {
    return 'Unerwarteter Fehler: $error';
  }

  @override
  String stateSaveFailed(Object error) {
    return 'Status konnte nicht gespeichert werden: $error';
  }
}
