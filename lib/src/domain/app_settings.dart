enum AppThemePreference { system, light, dark }

enum AppLocalePreference { system, de, en, fr }

class AppSettings {
  const AppSettings({
    required this.defaultDownloadDirectory,
    this.gateways = defaultGateways,
    this.maxConcurrentDownloads = 3,
    this.autoStart = true,
    this.themePreference = AppThemePreference.system,
    this.localePreference = AppLocalePreference.system,
    this.connectionTimeoutSeconds = 20,
  });

  factory AppSettings.defaults({String downloadDirectory = ''}) =>
      AppSettings(defaultDownloadDirectory: downloadDirectory);

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final rawGateways = json['gateways'];
    final parsedGateways = rawGateways is List
        ? rawGateways
              .whereType<String>()
              .map(normalizeGateway)
              .where((gateway) => gateway.isNotEmpty)
              .toList(growable: false)
        : const <String>[];
    final themeName =
        json['themePreference'] as String? ??
        ((json['darkMode'] as bool? ?? false) ? 'dark' : 'system');
    final matchingTheme = AppThemePreference.values.where(
      (theme) => theme.name == themeName,
    );
    final localeName = json['localePreference'] as String? ?? 'system';
    final matchingLocale = AppLocalePreference.values.where(
      (locale) => locale.name == localeName,
    );

    return AppSettings(
      defaultDownloadDirectory:
          json['defaultDownloadDirectory'] as String? ?? '',
      gateways: parsedGateways.isEmpty ? defaultGateways : parsedGateways,
      maxConcurrentDownloads: _clampInt(
        json['maxConcurrentDownloads'],
        fallback: 3,
        min: 1,
        max: 8,
      ),
      autoStart: json['autoStart'] as bool? ?? true,
      themePreference: matchingTheme.isEmpty
          ? AppThemePreference.system
          : matchingTheme.first,
      localePreference: matchingLocale.isEmpty
          ? AppLocalePreference.system
          : matchingLocale.first,
      connectionTimeoutSeconds: _clampInt(
        json['connectionTimeoutSeconds'],
        fallback: 20,
        min: 5,
        max: 120,
      ),
    );
  }

  static const List<String> defaultGateways = <String>[
    'http://127.0.0.1:8080',
    'https://dweb.link',
    'https://ipfs.io',
  ];

  final String defaultDownloadDirectory;
  final List<String> gateways;
  final int maxConcurrentDownloads;
  final bool autoStart;
  final AppThemePreference themePreference;
  final AppLocalePreference localePreference;
  final int connectionTimeoutSeconds;

  AppSettings copyWith({
    String? defaultDownloadDirectory,
    List<String>? gateways,
    int? maxConcurrentDownloads,
    bool? autoStart,
    AppThemePreference? themePreference,
    AppLocalePreference? localePreference,
    int? connectionTimeoutSeconds,
  }) {
    return AppSettings(
      defaultDownloadDirectory:
          defaultDownloadDirectory ?? this.defaultDownloadDirectory,
      gateways: gateways ?? this.gateways,
      maxConcurrentDownloads:
          maxConcurrentDownloads?.clamp(1, 8).toInt() ??
          this.maxConcurrentDownloads,
      autoStart: autoStart ?? this.autoStart,
      themePreference: themePreference ?? this.themePreference,
      localePreference: localePreference ?? this.localePreference,
      connectionTimeoutSeconds:
          connectionTimeoutSeconds?.clamp(5, 120).toInt() ??
          this.connectionTimeoutSeconds,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'defaultDownloadDirectory': defaultDownloadDirectory,
    'gateways': gateways,
    'maxConcurrentDownloads': maxConcurrentDownloads,
    'autoStart': autoStart,
    'themePreference': themePreference.name,
    'localePreference': localePreference.name,
    'connectionTimeoutSeconds': connectionTimeoutSeconds,
  };

  static String normalizeGateway(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.replaceFirst(RegExp(r'/+$'), '');
  }
}

int _clampInt(
  Object? value, {
  required int fallback,
  required int min,
  required int max,
}) {
  final parsed = switch (value) {
    final int number => number,
    final num number => number.toInt(),
    _ => fallback,
  };
  return parsed.clamp(min, max).toInt();
}
