import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'IPFSDownloader'**
  String get appTitle;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'LIBRARY'**
  String get library;

  /// No description provided for @allDownloads.
  ///
  /// In en, this message translates to:
  /// **'All downloads'**
  String get allDownloads;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @errors.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get errors;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @ipfsReady.
  ///
  /// In en, this message translates to:
  /// **'IPFS ready'**
  String get ipfsReady;

  /// No description provided for @fallbackRoutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 fallback route} other{{count} fallback routes}}'**
  String fallbackRoutes(int count);

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'IPFSDownloader {version}'**
  String versionLabel(String version);

  /// No description provided for @activeDownloads.
  ///
  /// In en, this message translates to:
  /// **'Active downloads'**
  String get activeDownloads;

  /// No description provided for @completedDownloads.
  ///
  /// In en, this message translates to:
  /// **'Completed downloads'**
  String get completedDownloads;

  /// No description provided for @activeDownloadsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Queued and running transfers'**
  String get activeDownloadsSubtitle;

  /// No description provided for @completedDownloadsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Successfully saved on this device'**
  String get completedDownloadsSubtitle;

  /// No description provided for @failedDownloadsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Transfers that need your attention'**
  String get failedDownloadsSubtitle;

  /// No description provided for @downloadsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save files directly from the IPFS network'**
  String get downloadsSubtitle;

  /// No description provided for @pauseAll.
  ///
  /// In en, this message translates to:
  /// **'Pause all'**
  String get pauseAll;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @addCid.
  ///
  /// In en, this message translates to:
  /// **'Add CID'**
  String get addCid;

  /// No description provided for @newIpfsFiles.
  ///
  /// In en, this message translates to:
  /// **'New IPFS files'**
  String get newIpfsFiles;

  /// No description provided for @inputDescription.
  ///
  /// In en, this message translates to:
  /// **'CID, ipfs:// link or gateway URL · one source per line'**
  String get inputDescription;

  /// No description provided for @inputHint.
  ///
  /// In en, this message translates to:
  /// **'bafybeig…\nipfs://bafybeig…/folder/file.zip'**
  String get inputHint;

  /// No description provided for @clearInput.
  ///
  /// In en, this message translates to:
  /// **'Clear input'**
  String get clearInput;

  /// No description provided for @directoryArchiveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Download UnixFS directories as uncompressed TAR archives'**
  String get directoryArchiveTooltip;

  /// No description provided for @folderAsTar.
  ///
  /// In en, this message translates to:
  /// **'Folder as TAR'**
  String get folderAsTar;

  /// No description provided for @startDownload.
  ///
  /// In en, this message translates to:
  /// **'Start download'**
  String get startDownload;

  /// No description provided for @saveHere.
  ///
  /// In en, this message translates to:
  /// **'Save here'**
  String get saveHere;

  /// No description provided for @addResult.
  ///
  /// In en, this message translates to:
  /// **'{added, plural, =0{No downloads were added} =1{1 download was added} other{{added} downloads were added}}{duplicates, plural, =0{.} =1{ · 1 duplicate was skipped.} other{ · {duplicates} duplicates were skipped.}}'**
  String addResult(int added, int duplicates);

  /// No description provided for @downloadAddFailed.
  ///
  /// In en, this message translates to:
  /// **'The download could not be added: {error}'**
  String downloadAddFailed(Object error);

  /// No description provided for @chooseDestination.
  ///
  /// In en, this message translates to:
  /// **'Choose destination folder'**
  String get chooseDestination;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @metricActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get metricActive;

  /// No description provided for @queuedFiles.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file in the queue} other{{count} files in the queue}}'**
  String queuedFiles(int count);

  /// No description provided for @noWaitingFiles.
  ///
  /// In en, this message translates to:
  /// **'No files waiting'**
  String get noWaitingFiles;

  /// No description provided for @metricSpeed.
  ///
  /// In en, this message translates to:
  /// **'SPEED'**
  String get metricSpeed;

  /// No description provided for @currentAggregateRate.
  ///
  /// In en, this message translates to:
  /// **'Current aggregate rate'**
  String get currentAggregateRate;

  /// No description provided for @metricCompleted.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED'**
  String get metricCompleted;

  /// No description provided for @savedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get savedSuccessfully;

  /// No description provided for @metricGateways.
  ///
  /// In en, this message translates to:
  /// **'GATEWAYS'**
  String get metricGateways;

  /// No description provided for @automaticFallback.
  ///
  /// In en, this message translates to:
  /// **'Automatic fallback'**
  String get automaticFallback;

  /// No description provided for @queueCount.
  ///
  /// In en, this message translates to:
  /// **'Queue · {count}'**
  String queueCount(int count);

  /// No description provided for @searchDownloads.
  ///
  /// In en, this message translates to:
  /// **'Search downloads'**
  String get searchDownloads;

  /// No description provided for @clearCompleted.
  ///
  /// In en, this message translates to:
  /// **'Remove completed entries from the list'**
  String get clearCompleted;

  /// No description provided for @removeEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove entry?'**
  String get removeEntryTitle;

  /// No description provided for @removeWithPartial.
  ///
  /// In en, this message translates to:
  /// **'“{fileName}” will be removed from the list. Its partial file ({size}) will also be deleted.'**
  String removeWithPartial(String fileName, String size);

  /// No description provided for @removeKeepFile.
  ///
  /// In en, this message translates to:
  /// **'“{fileName}” will only be removed from the list. A completed file will be kept.'**
  String removeKeepFile(String fileName);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @statusQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get statusQueued;

  /// No description provided for @statusResolving.
  ///
  /// In en, this message translates to:
  /// **'Resolving'**
  String get statusResolving;

  /// No description provided for @statusDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get statusDownloading;

  /// No description provided for @statusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get statusPaused;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get statusFailed;

  /// No description provided for @statusCanceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get statusCanceled;

  /// No description provided for @bytesOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{received} of {total}'**
  String bytesOfTotal(String received, String total);

  /// No description provided for @timeRemaining.
  ///
  /// In en, this message translates to:
  /// **'{duration} remaining'**
  String timeRemaining(String duration);

  /// No description provided for @savedLocally.
  ///
  /// In en, this message translates to:
  /// **'Saved locally'**
  String get savedLocally;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @showInFolder.
  ///
  /// In en, this message translates to:
  /// **'Show in folder'**
  String get showInFolder;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get moreActions;

  /// No description provided for @openDestinationFolder.
  ///
  /// In en, this message translates to:
  /// **'Open destination folder'**
  String get openDestinationFolder;

  /// No description provided for @moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get moveDown;

  /// No description provided for @removeFromList.
  ///
  /// In en, this message translates to:
  /// **'Remove from list'**
  String get removeFromList;

  /// No description provided for @nothingFound.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get nothingFound;

  /// No description provided for @nothingFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'Try a different file name or CID fragment.'**
  String get nothingFoundMessage;

  /// No description provided for @noCompletedDownloads.
  ///
  /// In en, this message translates to:
  /// **'No completed downloads yet'**
  String get noCompletedDownloads;

  /// No description provided for @noCompletedDownloadsMessage.
  ///
  /// In en, this message translates to:
  /// **'Successful transfers will appear here automatically.'**
  String get noCompletedDownloadsMessage;

  /// No description provided for @noErrors.
  ///
  /// In en, this message translates to:
  /// **'No errors'**
  String get noErrors;

  /// No description provided for @noErrorsMessage.
  ///
  /// In en, this message translates to:
  /// **'All downloads are running as expected.'**
  String get noErrorsMessage;

  /// No description provided for @nothingActive.
  ///
  /// In en, this message translates to:
  /// **'Nothing is active right now'**
  String get nothingActive;

  /// No description provided for @nothingActiveMessage.
  ///
  /// In en, this message translates to:
  /// **'Add a CID above or resume a paused download.'**
  String get nothingActiveMessage;

  /// No description provided for @emptyQueue.
  ///
  /// In en, this message translates to:
  /// **'Your queue is empty'**
  String get emptyQueue;

  /// No description provided for @emptyQueueMessage.
  ///
  /// In en, this message translates to:
  /// **'Paste an IPFS CID above to download your first file.'**
  String get emptyQueueMessage;

  /// No description provided for @chooseFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose folder'**
  String get chooseFolder;

  /// No description provided for @folderOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'The folder could not be opened: {error}'**
  String folderOpenFailed(Object error);

  /// No description provided for @gatewayRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a gateway address.'**
  String get gatewayRequired;

  /// No description provided for @gatewayInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a complete http:// or https:// address.'**
  String get gatewayInvalid;

  /// No description provided for @gatewayDuplicate.
  ///
  /// In en, this message translates to:
  /// **'This gateway has already been added.'**
  String get gatewayDuplicate;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adapt IPFSDownloader to your workflow'**
  String get settingsSubtitle;

  /// No description provided for @downloadsSettings.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloadsSettings;

  /// No description provided for @downloadsSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Location and queue behavior'**
  String get downloadsSettingsSubtitle;

  /// No description provided for @defaultDestination.
  ///
  /// In en, this message translates to:
  /// **'Default destination folder'**
  String get defaultDestination;

  /// No description provided for @defaultDestinationDescription.
  ///
  /// In en, this message translates to:
  /// **'New downloads are saved here automatically.'**
  String get defaultDestinationDescription;

  /// No description provided for @noFolderSelected.
  ///
  /// In en, this message translates to:
  /// **'No folder selected yet'**
  String get noFolderSelected;

  /// No description provided for @choose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get choose;

  /// No description provided for @parallelDownloads.
  ///
  /// In en, this message translates to:
  /// **'Parallel downloads'**
  String get parallelDownloads;

  /// No description provided for @parallelDownloadsDescription.
  ///
  /// In en, this message translates to:
  /// **'More parallel transfers can make better use of the available bandwidth.'**
  String get parallelDownloadsDescription;

  /// No description provided for @parallelDownloadsSemantics.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 parallel download} other{{count} parallel downloads}}'**
  String parallelDownloadsSemantics(int count);

  /// No description provided for @autoStartDownloads.
  ///
  /// In en, this message translates to:
  /// **'Start downloads automatically'**
  String get autoStartDownloads;

  /// No description provided for @autoStartDownloadsDescription.
  ///
  /// In en, this message translates to:
  /// **'New entries start as soon as a queue slot is available.'**
  String get autoStartDownloadsDescription;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @appearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'User interface presentation'**
  String get appearanceSubtitle;

  /// No description provided for @colorScheme.
  ///
  /// In en, this message translates to:
  /// **'Color scheme'**
  String get colorScheme;

  /// No description provided for @colorSchemeDescription.
  ///
  /// In en, this message translates to:
  /// **'System follows your operating system appearance automatically.'**
  String get colorSchemeDescription;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose the language used throughout the application.'**
  String get languageDescription;

  /// No description provided for @languageGerman.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get languageGerman;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @ipfsGateways.
  ///
  /// In en, this message translates to:
  /// **'IPFS gateways'**
  String get ipfsGateways;

  /// No description provided for @ipfsGatewaysSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Addresses are tried in order until a download succeeds.'**
  String get ipfsGatewaysSubtitle;

  /// No description provided for @minimumGatewayRequired.
  ///
  /// In en, this message translates to:
  /// **'At least one gateway is required'**
  String get minimumGatewayRequired;

  /// No description provided for @removeGateway.
  ///
  /// In en, this message translates to:
  /// **'Remove gateway'**
  String get removeGateway;

  /// No description provided for @addGateway.
  ///
  /// In en, this message translates to:
  /// **'Add gateway'**
  String get addGateway;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @gatewayRules.
  ///
  /// In en, this message translates to:
  /// **'Only HTTP and HTTPS addresses are allowed. At least one gateway must remain active.'**
  String get gatewayRules;

  /// No description provided for @network.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get network;

  /// No description provided for @networkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Timeouts for gateway connections'**
  String get networkSubtitle;

  /// No description provided for @connectionTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timeout'**
  String get connectionTimeout;

  /// No description provided for @connectionTimeoutDescription.
  ///
  /// In en, this message translates to:
  /// **'After this time, the downloader automatically tries the next gateway.'**
  String get connectionTimeoutDescription;

  /// No description provided for @secondsShort.
  ///
  /// In en, this message translates to:
  /// **'{count} s'**
  String secondsShort(int count);

  /// No description provided for @timeoutSecondsSemantics.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 second timeout} other{{count} seconds timeout}}'**
  String timeoutSecondsSemantics(int count);

  /// No description provided for @durationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} hr {minutes} min'**
  String durationHoursMinutes(int hours, int minutes);

  /// No description provided for @durationMinutesSeconds.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min {seconds} sec'**
  String durationMinutesSeconds(int minutes, int seconds);

  /// No description provided for @durationSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} sec'**
  String durationSeconds(int seconds);

  /// No description provided for @downloadEngineClosed.
  ///
  /// In en, this message translates to:
  /// **'The download engine has already been closed.'**
  String get downloadEngineClosed;

  /// No description provided for @taskAlreadyActive.
  ///
  /// In en, this message translates to:
  /// **'A download is already running for this task.'**
  String get taskAlreadyActive;

  /// No description provided for @destinationNotSelected.
  ///
  /// In en, this message translates to:
  /// **'No destination folder was selected.'**
  String get destinationNotSelected;

  /// No description provided for @noValidGateway.
  ///
  /// In en, this message translates to:
  /// **'No valid HTTP gateway is configured.'**
  String get noValidGateway;

  /// No description provided for @noGatewayCouldLoad.
  ///
  /// In en, this message translates to:
  /// **'No gateway could load the content. {details}'**
  String noGatewayCouldLoad(String details);

  /// No description provided for @partialSizeMismatch.
  ///
  /// In en, this message translates to:
  /// **'The saved partial file does not match the gateway file size.'**
  String get partialSizeMismatch;

  /// No description provided for @gatewayHttpError.
  ///
  /// In en, this message translates to:
  /// **'HTTP {status} from the gateway.'**
  String gatewayHttpError(int status);

  /// No description provided for @responseEndedEarly.
  ///
  /// In en, this message translates to:
  /// **'The response ended after {actual} instead of {expected} bytes.'**
  String responseEndedEarly(int actual, int expected);

  /// No description provided for @gatewayNoMoreData.
  ///
  /// In en, this message translates to:
  /// **'The gateway returned no additional data.'**
  String get gatewayNoMoreData;

  /// No description provided for @partialLargerThanContent.
  ///
  /// In en, this message translates to:
  /// **'The partial file is larger than the reported content.'**
  String get partialLargerThanContent;

  /// No description provided for @incompleteDownload.
  ///
  /// In en, this message translates to:
  /// **'The download is incomplete ({received} of {total} bytes).'**
  String incompleteDownload(int received, int total);

  /// No description provided for @invalidContentRange.
  ///
  /// In en, this message translates to:
  /// **'The 206 response has no valid Content-Range header.'**
  String get invalidContentRange;

  /// No description provided for @contentRangeStartMismatch.
  ///
  /// In en, this message translates to:
  /// **'Content-Range starts at {actual}; {expected} was expected.'**
  String contentRangeStartMismatch(int actual, int expected);

  /// No description provided for @contentRangeLengthConflict.
  ///
  /// In en, this message translates to:
  /// **'Content-Length and Content-Range conflict.'**
  String get contentRangeLengthConflict;

  /// No description provided for @remoteFileSizeChanged.
  ///
  /// In en, this message translates to:
  /// **'The file size has changed since this download started.'**
  String get remoteFileSizeChanged;

  /// No description provided for @noFreeDetectedFilename.
  ///
  /// In en, this message translates to:
  /// **'No free destination name could be found for the detected file name.'**
  String get noFreeDetectedFilename;

  /// No description provided for @noFreeFilename.
  ///
  /// In en, this message translates to:
  /// **'No free destination name could be found for the file.'**
  String get noFreeFilename;

  /// No description provided for @invalidHttpGateway.
  ///
  /// In en, this message translates to:
  /// **'Invalid HTTP gateway: {gateway}'**
  String invalidHttpGateway(String gateway);

  /// No description provided for @invalidIpfsPath.
  ///
  /// In en, this message translates to:
  /// **'The IPFS path is invalid.'**
  String get invalidIpfsPath;

  /// No description provided for @gatewayTimeout.
  ///
  /// In en, this message translates to:
  /// **'The gateway timed out.'**
  String get gatewayTimeout;

  /// No description provided for @gatewayUnreachable.
  ///
  /// In en, this message translates to:
  /// **'The gateway is unreachable.'**
  String get gatewayUnreachable;

  /// No description provided for @targetWriteFailed.
  ///
  /// In en, this message translates to:
  /// **'The destination file could not be written.'**
  String get targetWriteFailed;

  /// No description provided for @selectDestinationFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose a destination folder first.'**
  String get selectDestinationFirst;

  /// No description provided for @enterAtLeastOneCid.
  ///
  /// In en, this message translates to:
  /// **'Enter at least one CID.'**
  String get enterAtLeastOneCid;

  /// No description provided for @inputEmpty.
  ///
  /// In en, this message translates to:
  /// **'The input is empty.'**
  String get inputEmpty;

  /// No description provided for @gatewayUrlMissingCid.
  ///
  /// In en, this message translates to:
  /// **'The gateway URL does not contain an /ipfs/<CID> path.'**
  String get gatewayUrlMissingCid;

  /// No description provided for @unsupportedCid.
  ///
  /// In en, this message translates to:
  /// **'“{cid}” is not a supported CIDv0 or CIDv1 Base32 CID.'**
  String unsupportedCid(String cid);

  /// No description provided for @relativePathNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Relative path segments are not allowed.'**
  String get relativePathNotAllowed;

  /// No description provided for @encodedSeparatorNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Encoded path separators are not allowed.'**
  String get encodedSeparatorNotAllowed;

  /// No description provided for @inputMissingCid.
  ///
  /// In en, this message translates to:
  /// **'The input does not contain a CID.'**
  String get inputMissingCid;

  /// No description provided for @invalidUrlEncoding.
  ///
  /// In en, this message translates to:
  /// **'Invalid URL encoding in “{value}”.'**
  String invalidUrlEncoding(String value);

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error: {error}'**
  String unexpectedError(Object error);

  /// No description provided for @stateSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The application state could not be saved: {error}'**
  String stateSaveFailed(Object error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
