import 'package:flutter_test/flutter_test.dart';
import 'package:ipfs_downloader/l10n/app_localizations_en.dart';
import 'package:ipfs_downloader/l10n/app_localizations_fr.dart';
import 'package:ipfs_downloader/src/presentation/error_localizations.dart';

void main() {
  test('localizes stable download errors', () {
    final english = AppLocalizationsEn();
    final french = AppLocalizationsFr();

    expect(
      localizeAppError(english, 'Zeitüberschreitung beim Gateway.'),
      'The gateway timed out.',
    );
    expect(
      localizeAppError(
        french,
        'Der Download ist unvollständig (12 von 48 Bytes).',
      ),
      'Le téléchargement est incomplet (12 octets sur 48).',
    );
  });

  test('localizes nested gateway details and keeps technical context', () {
    final english = AppLocalizationsEn();

    expect(
      localizeAppError(
        english,
        'Kein Gateway konnte den Inhalt laden. '
        'https://ipfs.io: HTTP 502 vom Gateway. · '
        'https://dweb.link: Zeitüberschreitung beim Gateway.',
      ),
      'No gateway could load the content. '
      'https://ipfs.io: HTTP 502 from the gateway. · '
      'https://dweb.link: The gateway timed out.',
    );
  });

  test('returns unknown platform errors unchanged', () {
    final english = AppLocalizationsEn();

    expect(
      localizeAppError(english, 'Connection reset by peer'),
      'Connection reset by peer',
    );
  });
}
