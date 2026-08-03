import 'package:flutter_test/flutter_test.dart';
import 'package:ipfs_downloader/src/theme/app_theme.dart';

void main() {
  test('fallback text roles stay legible in light and dark themes', () {
    final lightHeadline = buildLightTheme().textTheme.headlineSmall?.color;
    final darkHeadline = buildDarkTheme().textTheme.headlineSmall?.color;

    expect(lightHeadline, isNotNull);
    expect(darkHeadline, isNotNull);
    expect(lightHeadline!.computeLuminance(), lessThan(0.5));
    expect(darkHeadline!.computeLuminance(), greaterThan(0.5));
  });
}
