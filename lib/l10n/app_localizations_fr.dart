// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'IPFSDownloader';

  @override
  String get library => 'BIBLIOTHÈQUE';

  @override
  String get allDownloads => 'Tous les téléchargements';

  @override
  String get all => 'Tous';

  @override
  String get active => 'Actifs';

  @override
  String get completed => 'Terminés';

  @override
  String get errors => 'Erreurs';

  @override
  String get options => 'Options';

  @override
  String get settings => 'Paramètres';

  @override
  String get ipfsReady => 'IPFS prêt';

  @override
  String fallbackRoutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count routes de secours',
      one: '1 route de secours',
    );
    return '$_temp0';
  }

  @override
  String versionLabel(String version) {
    return 'IPFSDownloader $version';
  }

  @override
  String get activeDownloads => 'Téléchargements actifs';

  @override
  String get completedDownloads => 'Téléchargements terminés';

  @override
  String get activeDownloadsSubtitle => 'Transferts en attente et en cours';

  @override
  String get completedDownloadsSubtitle =>
      'Enregistrés avec succès sur cet appareil';

  @override
  String get failedDownloadsSubtitle =>
      'Transferts nécessitant votre attention';

  @override
  String get downloadsSubtitle =>
      'Téléchargez des fichiers directement depuis le réseau IPFS';

  @override
  String get pauseAll => 'Tout suspendre';

  @override
  String get resume => 'Reprendre';

  @override
  String get addCid => 'Ajouter un CID';

  @override
  String get newIpfsFiles => 'Nouveaux fichiers IPFS';

  @override
  String get inputDescription =>
      'CID, lien ipfs:// ou URL de passerelle · une source par ligne';

  @override
  String get inputHint => 'bafybeig…\nipfs://bafybeig…/dossier/fichier.zip';

  @override
  String get clearInput => 'Effacer la saisie';

  @override
  String get directoryArchiveTooltip =>
      'Télécharger les répertoires UnixFS sous forme d’archives TAR non compressées';

  @override
  String get folderAsTar => 'Dossier en TAR';

  @override
  String get startDownload => 'Démarrer le téléchargement';

  @override
  String get saveHere => 'Enregistrer ici';

  @override
  String addResult(int added, int duplicates) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added téléchargements ont été ajoutés',
      one: '1 téléchargement a été ajouté',
      zero: 'Aucun téléchargement n’a été ajouté',
    );
    String _temp1 = intl.Intl.pluralLogic(
      duplicates,
      locale: localeName,
      other: ' · $duplicates doublons ont été ignorés.',
      one: ' · 1 doublon a été ignoré.',
      zero: '.',
    );
    return '$_temp0$_temp1';
  }

  @override
  String downloadAddFailed(Object error) {
    return 'Impossible d’ajouter le téléchargement : $error';
  }

  @override
  String get chooseDestination => 'Choisir le dossier de destination';

  @override
  String get change => 'Modifier';

  @override
  String get metricActive => 'ACTIFS';

  @override
  String queuedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers dans la file d’attente',
      one: '1 fichier dans la file d’attente',
    );
    return '$_temp0';
  }

  @override
  String get noWaitingFiles => 'Aucun fichier en attente';

  @override
  String get metricSpeed => 'VITESSE';

  @override
  String get currentAggregateRate => 'Débit total actuel';

  @override
  String get metricCompleted => 'TERMINÉS';

  @override
  String get savedSuccessfully => 'Enregistrés avec succès';

  @override
  String get metricGateways => 'PASSERELLES';

  @override
  String get automaticFallback => 'Basculement automatique';

  @override
  String queueCount(int count) {
    return 'File d’attente · $count';
  }

  @override
  String get searchDownloads => 'Rechercher des téléchargements';

  @override
  String get clearCompleted => 'Retirer les éléments terminés de la liste';

  @override
  String get removeEntryTitle => 'Supprimer l’élément ?';

  @override
  String removeWithPartial(String fileName, String size) {
    return '« $fileName » sera retiré de la liste. Le fichier partiel correspondant ($size) sera également supprimé.';
  }

  @override
  String removeKeepFile(String fileName) {
    return '« $fileName » sera uniquement retiré de la liste. Le fichier terminé sera conservé.';
  }

  @override
  String get cancel => 'Annuler';

  @override
  String get remove => 'Supprimer';

  @override
  String get statusQueued => 'En attente';

  @override
  String get statusResolving => 'Résolution';

  @override
  String get statusDownloading => 'Téléchargement';

  @override
  String get statusPaused => 'En pause';

  @override
  String get statusCompleted => 'Terminé';

  @override
  String get statusFailed => 'Échec';

  @override
  String get statusCanceled => 'Annulé';

  @override
  String bytesOfTotal(String received, String total) {
    return '$received sur $total';
  }

  @override
  String timeRemaining(String duration) {
    return 'Temps restant : $duration';
  }

  @override
  String get savedLocally => 'Enregistré localement';

  @override
  String get ready => 'Prêt';

  @override
  String get pause => 'Suspendre';

  @override
  String get showInFolder => 'Afficher dans le dossier';

  @override
  String get start => 'Démarrer';

  @override
  String get moreActions => 'Plus d’actions';

  @override
  String get openDestinationFolder => 'Ouvrir le dossier de destination';

  @override
  String get moveUp => 'Monter';

  @override
  String get moveDown => 'Descendre';

  @override
  String get removeFromList => 'Retirer de la liste';

  @override
  String get nothingFound => 'Aucun résultat';

  @override
  String get nothingFoundMessage =>
      'Essayez un autre nom de fichier ou fragment de CID.';

  @override
  String get noCompletedDownloads => 'Aucun téléchargement terminé';

  @override
  String get noCompletedDownloadsMessage =>
      'Les transferts réussis apparaîtront automatiquement ici.';

  @override
  String get noErrors => 'Aucune erreur';

  @override
  String get noErrorsMessage =>
      'Tous les téléchargements se déroulent comme prévu.';

  @override
  String get nothingActive => 'Aucun téléchargement actif';

  @override
  String get nothingActiveMessage =>
      'Ajoutez un CID ci-dessus ou reprenez un téléchargement en pause.';

  @override
  String get emptyQueue => 'Votre file d’attente est vide';

  @override
  String get emptyQueueMessage =>
      'Collez un CID IPFS ci-dessus pour télécharger votre premier fichier.';

  @override
  String get chooseFolder => 'Choisir un dossier';

  @override
  String folderOpenFailed(Object error) {
    return 'Impossible d’ouvrir le dossier : $error';
  }

  @override
  String get gatewayRequired => 'Saisissez l’adresse d’une passerelle.';

  @override
  String get gatewayInvalid =>
      'Saisissez une adresse http:// ou https:// complète.';

  @override
  String get gatewayDuplicate => 'Cette passerelle a déjà été ajoutée.';

  @override
  String get settingsSubtitle =>
      'Adaptez IPFSDownloader à votre façon de travailler';

  @override
  String get downloadsSettings => 'Téléchargements';

  @override
  String get downloadsSettingsSubtitle =>
      'Emplacement et comportement de la file d’attente';

  @override
  String get defaultDestination => 'Dossier de destination par défaut';

  @override
  String get defaultDestinationDescription =>
      'Les nouveaux téléchargements y sont enregistrés automatiquement.';

  @override
  String get noFolderSelected => 'Aucun dossier sélectionné';

  @override
  String get choose => 'Choisir';

  @override
  String get parallelDownloads => 'Téléchargements simultanés';

  @override
  String get parallelDownloadsDescription =>
      'Augmenter le nombre de transferts simultanés peut mieux exploiter la bande passante disponible.';

  @override
  String parallelDownloadsSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count téléchargements simultanés',
      one: '1 téléchargement simultané',
    );
    return '$_temp0';
  }

  @override
  String get autoStartDownloads =>
      'Démarrer automatiquement les téléchargements';

  @override
  String get autoStartDownloadsDescription =>
      'Les nouveaux éléments démarrent dès qu’une place se libère dans la file d’attente.';

  @override
  String get appearance => 'Apparence';

  @override
  String get appearanceSubtitle => 'Présentation de l’interface utilisateur';

  @override
  String get colorScheme => 'Thème de couleurs';

  @override
  String get colorSchemeDescription =>
      'Le mode Système s’adapte automatiquement à l’apparence de votre système d’exploitation.';

  @override
  String get system => 'Système';

  @override
  String get light => 'Clair';

  @override
  String get dark => 'Sombre';

  @override
  String get language => 'Langue';

  @override
  String get languageDescription =>
      'Choisissez la langue utilisée dans toute l’application.';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get ipfsGateways => 'Passerelles IPFS';

  @override
  String get ipfsGatewaysSubtitle =>
      'Les adresses sont essayées dans l’ordre jusqu’à ce qu’un téléchargement réussisse.';

  @override
  String get minimumGatewayRequired => 'Au moins une passerelle est requise';

  @override
  String get removeGateway => 'Supprimer la passerelle';

  @override
  String get addGateway => 'Ajouter une passerelle';

  @override
  String get add => 'Ajouter';

  @override
  String get gatewayRules =>
      'Seules les adresses HTTP et HTTPS sont autorisées. Au moins une passerelle doit rester active.';

  @override
  String get network => 'Réseau';

  @override
  String get networkSubtitle =>
      'Délais d’attente des connexions aux passerelles';

  @override
  String get connectionTimeout => 'Délai de connexion';

  @override
  String get connectionTimeoutDescription =>
      'Une fois ce délai écoulé, le téléchargeur essaie automatiquement la passerelle suivante.';

  @override
  String secondsShort(int count) {
    return '$count s';
  }

  @override
  String timeoutSecondsSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Délai d’attente de $count secondes',
      one: 'Délai d’attente de 1 seconde',
    );
    return '$_temp0';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String durationMinutesSeconds(int minutes, int seconds) {
    return '$minutes min $seconds s';
  }

  @override
  String durationSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get downloadEngineClosed =>
      'Le moteur de téléchargement est déjà fermé.';

  @override
  String get taskAlreadyActive =>
      'Un téléchargement est déjà en cours pour cette tâche.';

  @override
  String get destinationNotSelected =>
      'Aucun dossier de destination n’a été sélectionné.';

  @override
  String get noValidGateway =>
      'Aucune passerelle HTTP valide n’est configurée.';

  @override
  String noGatewayCouldLoad(String details) {
    return 'Aucune passerelle n’a pu charger le contenu. $details';
  }

  @override
  String get partialSizeMismatch =>
      'Le fichier partiel enregistré ne correspond pas à la taille indiquée par la passerelle.';

  @override
  String gatewayHttpError(int status) {
    return 'HTTP $status renvoyé par la passerelle.';
  }

  @override
  String responseEndedEarly(int actual, int expected) {
    return 'La réponse s’est terminée après $actual octets au lieu de $expected.';
  }

  @override
  String get gatewayNoMoreData =>
      'La passerelle n’a renvoyé aucune donnée supplémentaire.';

  @override
  String get partialLargerThanContent =>
      'Le fichier partiel est plus volumineux que le contenu annoncé.';

  @override
  String incompleteDownload(int received, int total) {
    return 'Le téléchargement est incomplet ($received octets sur $total).';
  }

  @override
  String get invalidContentRange =>
      'La réponse 206 ne contient aucun en-tête Content-Range valide.';

  @override
  String contentRangeStartMismatch(int actual, int expected) {
    return 'Content-Range commence à $actual, alors que $expected était attendu.';
  }

  @override
  String get contentRangeLengthConflict =>
      'Content-Length et Content-Range sont contradictoires.';

  @override
  String get remoteFileSizeChanged =>
      'La taille du fichier a changé depuis le début du téléchargement.';

  @override
  String get noFreeDetectedFilename =>
      'Aucun nom de destination libre n’a été trouvé pour le nom de fichier détecté.';

  @override
  String get noFreeFilename =>
      'Aucun nom de destination libre n’a été trouvé pour le fichier.';

  @override
  String invalidHttpGateway(String gateway) {
    return 'Passerelle HTTP non valide : $gateway';
  }

  @override
  String get invalidIpfsPath => 'Le chemin IPFS n’est pas valide.';

  @override
  String get gatewayTimeout => 'La passerelle a dépassé le délai d’attente.';

  @override
  String get gatewayUnreachable => 'La passerelle est inaccessible.';

  @override
  String get targetWriteFailed =>
      'Impossible d’écrire le fichier de destination.';

  @override
  String get selectDestinationFirst =>
      'Choisissez d’abord un dossier de destination.';

  @override
  String get enterAtLeastOneCid => 'Saisissez au moins un CID.';

  @override
  String get inputEmpty => 'La saisie est vide.';

  @override
  String get gatewayUrlMissingCid =>
      'L’URL de la passerelle ne contient pas de chemin /ipfs/<CID>.';

  @override
  String unsupportedCid(String cid) {
    return '« $cid » n’est pas un CIDv0 ou CIDv1 Base32 pris en charge.';
  }

  @override
  String get relativePathNotAllowed =>
      'Les segments de chemin relatifs ne sont pas autorisés.';

  @override
  String get encodedSeparatorNotAllowed =>
      'Les séparateurs de chemin encodés ne sont pas autorisés.';

  @override
  String get inputMissingCid => 'La saisie ne contient aucun CID.';

  @override
  String invalidUrlEncoding(String value) {
    return 'Encodage d’URL non valide dans « $value ».';
  }

  @override
  String unexpectedError(Object error) {
    return 'Erreur inattendue : $error';
  }

  @override
  String stateSaveFailed(Object error) {
    return 'Impossible d’enregistrer l’état de l’application : $error';
  }
}
