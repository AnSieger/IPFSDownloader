import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ipfs_downloader/l10n/app_localizations.dart';

import 'application/download_controller.dart';
import 'domain/app_settings.dart';
import 'presentation/main_shell.dart';
import 'theme/app_theme.dart';

class IPFSDownloaderApp extends StatefulWidget {
  const IPFSDownloaderApp({super.key, required this.controller});

  final DownloadController controller;

  @override
  State<IPFSDownloaderApp> createState() => _IPFSDownloaderAppState();
}

class _IPFSDownloaderAppState extends State<IPFSDownloaderApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(widget.controller.flush());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          debugShowCheckedModeBanner: false,
          locale: _localeFor(widget.controller.settings.localePreference),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          localeListResolutionCallback: _resolveLocale,
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: switch (widget.controller.settings.themePreference) {
            AppThemePreference.system => ThemeMode.system,
            AppThemePreference.light => ThemeMode.light,
            AppThemePreference.dark => ThemeMode.dark,
          },
          home: MainShell(controller: widget.controller),
        );
      },
    );
  }
}

Locale? _localeFor(AppLocalePreference preference) => switch (preference) {
  AppLocalePreference.system => null,
  AppLocalePreference.de => const Locale('de'),
  AppLocalePreference.en => const Locale('en'),
  AppLocalePreference.fr => const Locale('fr'),
};

Locale _resolveLocale(
  List<Locale>? preferredLocales,
  Iterable<Locale> supportedLocales,
) {
  for (final preferred in preferredLocales ?? const <Locale>[]) {
    for (final supported in supportedLocales) {
      if (preferred.languageCode == supported.languageCode) return supported;
    }
  }
  return const Locale('en');
}
