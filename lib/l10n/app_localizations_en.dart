// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'IPFSDownloader';

  @override
  String get library => 'LIBRARY';

  @override
  String get allDownloads => 'All downloads';

  @override
  String get all => 'All';

  @override
  String get active => 'Active';

  @override
  String get completed => 'Completed';

  @override
  String get errors => 'Errors';

  @override
  String get options => 'Options';

  @override
  String get settings => 'Settings';

  @override
  String get ipfsReady => 'IPFS ready';

  @override
  String fallbackRoutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fallback routes',
      one: '1 fallback route',
    );
    return '$_temp0';
  }

  @override
  String versionLabel(String version) {
    return 'IPFSDownloader $version';
  }

  @override
  String get activeDownloads => 'Active downloads';

  @override
  String get completedDownloads => 'Completed downloads';

  @override
  String get activeDownloadsSubtitle => 'Queued and running transfers';

  @override
  String get completedDownloadsSubtitle => 'Successfully saved on this device';

  @override
  String get failedDownloadsSubtitle => 'Transfers that need your attention';

  @override
  String get downloadsSubtitle => 'Save files directly from the IPFS network';

  @override
  String get pauseAll => 'Pause all';

  @override
  String get resume => 'Resume';

  @override
  String get addCid => 'Add CID';

  @override
  String get newIpfsFiles => 'New IPFS files';

  @override
  String get inputDescription =>
      'CID, ipfs:// link or gateway URL · one source per line';

  @override
  String get inputHint => 'bafybeig…\nipfs://bafybeig…/folder/file.zip';

  @override
  String get clearInput => 'Clear input';

  @override
  String get directoryArchiveTooltip =>
      'Download UnixFS directories as uncompressed TAR archives';

  @override
  String get folderAsTar => 'Folder as TAR';

  @override
  String get startDownload => 'Start download';

  @override
  String get saveHere => 'Save here';

  @override
  String addResult(int added, int duplicates) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added downloads were added',
      one: '1 download was added',
      zero: 'No downloads were added',
    );
    String _temp1 = intl.Intl.pluralLogic(
      duplicates,
      locale: localeName,
      other: ' · $duplicates duplicates were skipped.',
      one: ' · 1 duplicate was skipped.',
      zero: '.',
    );
    return '$_temp0$_temp1';
  }

  @override
  String downloadAddFailed(Object error) {
    return 'The download could not be added: $error';
  }

  @override
  String get chooseDestination => 'Choose destination folder';

  @override
  String get change => 'Change';

  @override
  String get metricActive => 'ACTIVE';

  @override
  String queuedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files in the queue',
      one: '1 file in the queue',
    );
    return '$_temp0';
  }

  @override
  String get noWaitingFiles => 'No files waiting';

  @override
  String get metricSpeed => 'SPEED';

  @override
  String get currentAggregateRate => 'Current aggregate rate';

  @override
  String get metricCompleted => 'COMPLETED';

  @override
  String get savedSuccessfully => 'Saved successfully';

  @override
  String get metricGateways => 'GATEWAYS';

  @override
  String get automaticFallback => 'Automatic fallback';

  @override
  String queueCount(int count) {
    return 'Queue · $count';
  }

  @override
  String get searchDownloads => 'Search downloads';

  @override
  String get clearCompleted => 'Remove completed entries from the list';

  @override
  String get removeEntryTitle => 'Remove entry?';

  @override
  String removeWithPartial(String fileName, String size) {
    return '“$fileName” will be removed from the list. Its partial file ($size) will also be deleted.';
  }

  @override
  String removeKeepFile(String fileName) {
    return '“$fileName” will only be removed from the list. A completed file will be kept.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get remove => 'Remove';

  @override
  String get statusQueued => 'Queued';

  @override
  String get statusResolving => 'Resolving';

  @override
  String get statusDownloading => 'Downloading';

  @override
  String get statusPaused => 'Paused';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusFailed => 'Failed';

  @override
  String get statusCanceled => 'Canceled';

  @override
  String bytesOfTotal(String received, String total) {
    return '$received of $total';
  }

  @override
  String timeRemaining(String duration) {
    return '$duration remaining';
  }

  @override
  String get savedLocally => 'Saved locally';

  @override
  String get ready => 'Ready';

  @override
  String get pause => 'Pause';

  @override
  String get showInFolder => 'Show in folder';

  @override
  String get start => 'Start';

  @override
  String get moreActions => 'More actions';

  @override
  String get openDestinationFolder => 'Open destination folder';

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String get removeFromList => 'Remove from list';

  @override
  String get nothingFound => 'Nothing found';

  @override
  String get nothingFoundMessage =>
      'Try a different file name or CID fragment.';

  @override
  String get noCompletedDownloads => 'No completed downloads yet';

  @override
  String get noCompletedDownloadsMessage =>
      'Successful transfers will appear here automatically.';

  @override
  String get noErrors => 'No errors';

  @override
  String get noErrorsMessage => 'All downloads are running as expected.';

  @override
  String get nothingActive => 'Nothing is active right now';

  @override
  String get nothingActiveMessage =>
      'Add a CID above or resume a paused download.';

  @override
  String get emptyQueue => 'Your queue is empty';

  @override
  String get emptyQueueMessage =>
      'Paste an IPFS CID above to download your first file.';

  @override
  String get chooseFolder => 'Choose folder';

  @override
  String folderOpenFailed(Object error) {
    return 'The folder could not be opened: $error';
  }

  @override
  String get gatewayRequired => 'Enter a gateway address.';

  @override
  String get gatewayInvalid => 'Enter a complete http:// or https:// address.';

  @override
  String get gatewayDuplicate => 'This gateway has already been added.';

  @override
  String get settingsSubtitle => 'Adapt IPFSDownloader to your workflow';

  @override
  String get downloadsSettings => 'Downloads';

  @override
  String get downloadsSettingsSubtitle => 'Location and queue behavior';

  @override
  String get defaultDestination => 'Default destination folder';

  @override
  String get defaultDestinationDescription =>
      'New downloads are saved here automatically.';

  @override
  String get noFolderSelected => 'No folder selected yet';

  @override
  String get choose => 'Choose';

  @override
  String get parallelDownloads => 'Parallel downloads';

  @override
  String get parallelDownloadsDescription =>
      'More parallel transfers can make better use of the available bandwidth.';

  @override
  String parallelDownloadsSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count parallel downloads',
      one: '1 parallel download',
    );
    return '$_temp0';
  }

  @override
  String get autoStartDownloads => 'Start downloads automatically';

  @override
  String get autoStartDownloadsDescription =>
      'New entries start as soon as a queue slot is available.';

  @override
  String get appearance => 'Appearance';

  @override
  String get appearanceSubtitle => 'User interface presentation';

  @override
  String get colorScheme => 'Color scheme';

  @override
  String get colorSchemeDescription =>
      'System follows your operating system appearance automatically.';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get languageDescription =>
      'Choose the language used throughout the application.';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get ipfsGateways => 'IPFS gateways';

  @override
  String get ipfsGatewaysSubtitle =>
      'Addresses are tried in order until a download succeeds.';

  @override
  String get minimumGatewayRequired => 'At least one gateway is required';

  @override
  String get removeGateway => 'Remove gateway';

  @override
  String get addGateway => 'Add gateway';

  @override
  String get add => 'Add';

  @override
  String get gatewayRules =>
      'Only HTTP and HTTPS addresses are allowed. At least one gateway must remain active.';

  @override
  String get network => 'Network';

  @override
  String get networkSubtitle => 'Timeouts for gateway connections';

  @override
  String get connectionTimeout => 'Connection timeout';

  @override
  String get connectionTimeoutDescription =>
      'After this time, the downloader automatically tries the next gateway.';

  @override
  String secondsShort(int count) {
    return '$count s';
  }

  @override
  String timeoutSecondsSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seconds timeout',
      one: '1 second timeout',
    );
    return '$_temp0';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours hr $minutes min';
  }

  @override
  String durationMinutesSeconds(int minutes, int seconds) {
    return '$minutes min $seconds sec';
  }

  @override
  String durationSeconds(int seconds) {
    return '$seconds sec';
  }

  @override
  String get downloadEngineClosed =>
      'The download engine has already been closed.';

  @override
  String get taskAlreadyActive =>
      'A download is already running for this task.';

  @override
  String get destinationNotSelected => 'No destination folder was selected.';

  @override
  String get noValidGateway => 'No valid HTTP gateway is configured.';

  @override
  String noGatewayCouldLoad(String details) {
    return 'No gateway could load the content. $details';
  }

  @override
  String get partialSizeMismatch =>
      'The saved partial file does not match the gateway file size.';

  @override
  String gatewayHttpError(int status) {
    return 'HTTP $status from the gateway.';
  }

  @override
  String responseEndedEarly(int actual, int expected) {
    return 'The response ended after $actual instead of $expected bytes.';
  }

  @override
  String get gatewayNoMoreData => 'The gateway returned no additional data.';

  @override
  String get partialLargerThanContent =>
      'The partial file is larger than the reported content.';

  @override
  String incompleteDownload(int received, int total) {
    return 'The download is incomplete ($received of $total bytes).';
  }

  @override
  String get invalidContentRange =>
      'The 206 response has no valid Content-Range header.';

  @override
  String contentRangeStartMismatch(int actual, int expected) {
    return 'Content-Range starts at $actual; $expected was expected.';
  }

  @override
  String get contentRangeLengthConflict =>
      'Content-Length and Content-Range conflict.';

  @override
  String get remoteFileSizeChanged =>
      'The file size has changed since this download started.';

  @override
  String get noFreeDetectedFilename =>
      'No free destination name could be found for the detected file name.';

  @override
  String get noFreeFilename =>
      'No free destination name could be found for the file.';

  @override
  String invalidHttpGateway(String gateway) {
    return 'Invalid HTTP gateway: $gateway';
  }

  @override
  String get invalidIpfsPath => 'The IPFS path is invalid.';

  @override
  String get gatewayTimeout => 'The gateway timed out.';

  @override
  String get gatewayUnreachable => 'The gateway is unreachable.';

  @override
  String get targetWriteFailed => 'The destination file could not be written.';

  @override
  String get selectDestinationFirst => 'Choose a destination folder first.';

  @override
  String get enterAtLeastOneCid => 'Enter at least one CID.';

  @override
  String get inputEmpty => 'The input is empty.';

  @override
  String get gatewayUrlMissingCid =>
      'The gateway URL does not contain an /ipfs/<CID> path.';

  @override
  String unsupportedCid(String cid) {
    return '“$cid” is not a supported CIDv0 or CIDv1 Base32 CID.';
  }

  @override
  String get relativePathNotAllowed =>
      'Relative path segments are not allowed.';

  @override
  String get encodedSeparatorNotAllowed =>
      'Encoded path separators are not allowed.';

  @override
  String get inputMissingCid => 'The input does not contain a CID.';

  @override
  String invalidUrlEncoding(String value) {
    return 'Invalid URL encoding in “$value”.';
  }

  @override
  String unexpectedError(Object error) {
    return 'Unexpected error: $error';
  }

  @override
  String stateSaveFailed(Object error) {
    return 'The application state could not be saved: $error';
  }
}
