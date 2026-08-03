import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:ipfs_downloader/l10n/app_localizations.dart';

import '../application/download_controller.dart';
import '../domain/app_settings.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key, required this.controller});

  final DownloadController controller;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late AppSettings _settings;
  late final TextEditingController _directoryController;
  late final TextEditingController _newGatewayController;
  late final ScrollController _scrollController;
  late List<_GatewayDraft> _gatewayDrafts;

  String? _newGatewayError;
  bool _isChoosingDirectory = false;

  @override
  void initState() {
    super.initState();
    _settings = widget.controller.settings;
    _directoryController = TextEditingController(
      text: _settings.defaultDownloadDirectory,
    );
    _newGatewayController = TextEditingController();
    _scrollController = ScrollController();
    _gatewayDrafts = _settings.gateways
        .map(_GatewayDraft.new)
        .toList(growable: true);
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant SettingsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_handleControllerChanged);
    widget.controller.addListener(_handleControllerChanged);
    _synchronizeWithController(force: true);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    _directoryController.dispose();
    _newGatewayController.dispose();
    _scrollController.dispose();
    for (final draft in _gatewayDrafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void _handleControllerChanged() {
    _synchronizeWithController();
  }

  void _synchronizeWithController({bool force = false}) {
    final incoming = widget.controller.settings;
    if (!force && identical(incoming, _settings)) return;

    final gatewaysChanged =
        force || !_sameStrings(incoming.gateways, _settings.gateways);
    setState(() {
      _settings = incoming;
      if (_directoryController.text != incoming.defaultDownloadDirectory) {
        _directoryController.text = incoming.defaultDownloadDirectory;
      }
      if (gatewaysChanged) {
        for (final draft in _gatewayDrafts) {
          draft.dispose();
        }
        _gatewayDrafts = incoming.gateways
            .map(_GatewayDraft.new)
            .toList(growable: true);
      }
    });
  }

  void _publish(AppSettings settings) {
    setState(() => _settings = settings);
    widget.controller.updateSettings(settings);
  }

  Future<void> _chooseDirectory() async {
    if (_isChoosingDirectory) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _isChoosingDirectory = true);
    try {
      final initialDirectory = _settings.defaultDownloadDirectory.trim();
      final directory = await getDirectoryPath(
        initialDirectory: initialDirectory.isEmpty ? null : initialDirectory,
        confirmButtonText: l10n.chooseFolder,
      );
      if (!mounted || directory == null || directory.trim().isEmpty) return;
      _directoryController.text = directory;
      _publish(_settings.copyWith(defaultDownloadDirectory: directory));
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.folderOpenFailed(error))));
    } finally {
      if (mounted) setState(() => _isChoosingDirectory = false);
    }
  }

  void _addGateway() {
    final value = _newGatewayController.text;
    final error = _validateGateway(value);
    if (error != null) {
      setState(() => _newGatewayError = error);
      return;
    }

    final normalized = AppSettings.normalizeGateway(value);
    setState(() {
      _gatewayDrafts.add(_GatewayDraft(normalized));
      _newGatewayController.clear();
      _newGatewayError = null;
    });
    _validateAndPublishGateways();
  }

  void _removeGateway(int index) {
    if (_gatewayDrafts.length <= 1) return;
    final removed = _gatewayDrafts.removeAt(index);
    removed.dispose();
    _validateAndPublishGateways();
  }

  void _validateAndPublishGateways() {
    final values = _gatewayDrafts
        .map((draft) => draft.controller.text)
        .toList(growable: false);
    final errors = <String?>[];
    for (var index = 0; index < values.length; index++) {
      errors.add(_validateGateway(values[index], ownIndex: index));
    }

    AppSettings? updatedSettings;
    setState(() {
      for (var index = 0; index < _gatewayDrafts.length; index++) {
        _gatewayDrafts[index].error = errors[index];
      }
      if (errors.every((error) => error == null) && values.isNotEmpty) {
        final normalized = values
            .map(AppSettings.normalizeGateway)
            .toList(growable: false);
        updatedSettings = _settings.copyWith(gateways: normalized);
        _settings = updatedSettings!;
      }
    });
    if (updatedSettings != null) {
      widget.controller.updateSettings(updatedSettings!);
    }
  }

  String? _validateGateway(String value, {int? ownIndex}) {
    final l10n = AppLocalizations.of(context);
    final normalized = AppSettings.normalizeGateway(value);
    if (normalized.isEmpty) return l10n.gatewayRequired;

    final uri = Uri.tryParse(normalized);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return l10n.gatewayInvalid;
    }

    final normalizedLower = normalized.toLowerCase();
    for (var index = 0; index < _gatewayDrafts.length; index++) {
      if (index == ownIndex) continue;
      final candidate = AppSettings.normalizeGateway(
        _gatewayDrafts[index].controller.text,
      ).toLowerCase();
      if (candidate == normalizedLower) {
        return l10n.gatewayDuplicate;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final colors = theme.colorScheme;

    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 44),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PageHeader(colors: colors),
                  const SizedBox(height: 28),
                  _SettingsCard(
                    icon: Icons.folder_copy_outlined,
                    title: l10n.downloadsSettings,
                    subtitle: l10n.downloadsSettingsSubtitle,
                    children: [
                      _PreferenceRow(
                        title: l10n.defaultDestination,
                        description: l10n.defaultDestinationDescription,
                        trailing: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _directoryController,
                                readOnly: true,
                                maxLines: 1,
                                decoration: InputDecoration(
                                  hintText: l10n.noFolderSelected,
                                  prefixIcon: const Icon(Icons.folder_outlined),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            FilledButton.icon(
                              onPressed: _isChoosingDirectory
                                  ? null
                                  : _chooseDirectory,
                              icon: _isChoosingDirectory
                                  ? const SizedBox.square(
                                      dimension: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.more_horiz, size: 19),
                              label: Text(l10n.choose),
                            ),
                          ],
                        ),
                      ),
                      const _SectionDivider(),
                      _PreferenceRow(
                        title: l10n.parallelDownloads,
                        description: l10n.parallelDownloadsDescription,
                        trailing: Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: _settings.maxConcurrentDownloads
                                    .toDouble(),
                                min: 1,
                                max: 8,
                                divisions: 7,
                                label: '${_settings.maxConcurrentDownloads}',
                                onChanged: (value) {
                                  _publish(
                                    _settings.copyWith(
                                      maxConcurrentDownloads: value.round(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            _ValueBadge(
                              value: '${_settings.maxConcurrentDownloads}',
                              semanticsLabel: l10n.parallelDownloadsSemantics(
                                _settings.maxConcurrentDownloads,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const _SectionDivider(),
                      _PreferenceRow(
                        title: l10n.autoStartDownloads,
                        description: l10n.autoStartDownloadsDescription,
                        trailing: Align(
                          alignment: Alignment.centerRight,
                          child: Switch.adaptive(
                            value: _settings.autoStart,
                            onChanged: (value) {
                              _publish(_settings.copyWith(autoStart: value));
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SettingsCard(
                    icon: Icons.contrast_outlined,
                    title: l10n.appearance,
                    subtitle: l10n.appearanceSubtitle,
                    children: [
                      _PreferenceRow(
                        title: l10n.colorScheme,
                        description: l10n.colorSchemeDescription,
                        trailing: SegmentedButton<AppThemePreference>(
                          segments: [
                            ButtonSegment(
                              value: AppThemePreference.system,
                              icon: const Icon(Icons.laptop_outlined, size: 18),
                              label: Text(l10n.system),
                            ),
                            ButtonSegment(
                              value: AppThemePreference.light,
                              icon: const Icon(
                                Icons.light_mode_outlined,
                                size: 18,
                              ),
                              label: Text(l10n.light),
                            ),
                            ButtonSegment(
                              value: AppThemePreference.dark,
                              icon: const Icon(
                                Icons.dark_mode_outlined,
                                size: 18,
                              ),
                              label: Text(l10n.dark),
                            ),
                          ],
                          selected: {_settings.themePreference},
                          showSelectedIcon: false,
                          onSelectionChanged: (selection) {
                            _publish(
                              _settings.copyWith(
                                themePreference: selection.first,
                              ),
                            );
                          },
                          style: const ButtonStyle(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                      const _SectionDivider(),
                      _PreferenceRow(
                        title: l10n.language,
                        description: l10n.languageDescription,
                        trailing: DropdownButtonFormField<AppLocalePreference>(
                          key: ValueKey(_settings.localePreference),
                          initialValue: _settings.localePreference,
                          decoration: const InputDecoration(),
                          isExpanded: true,
                          items: [
                            DropdownMenuItem(
                              value: AppLocalePreference.system,
                              child: Text(l10n.system),
                            ),
                            const DropdownMenuItem(
                              value: AppLocalePreference.de,
                              child: Text('Deutsch'),
                            ),
                            const DropdownMenuItem(
                              value: AppLocalePreference.en,
                              child: Text('English'),
                            ),
                            const DropdownMenuItem(
                              value: AppLocalePreference.fr,
                              child: Text('Français'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              _publish(
                                _settings.copyWith(localePreference: value),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SettingsCard(
                    icon: Icons.hub_outlined,
                    title: l10n.ipfsGateways,
                    subtitle: l10n.ipfsGatewaysSubtitle,
                    children: [
                      ...List<Widget>.generate(_gatewayDrafts.length, (index) {
                        final draft = _gatewayDrafts[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == _gatewayDrafts.length - 1 ? 0 : 12,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 11),
                                child: _GatewayIndex(index: index + 1),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  key: ObjectKey(draft),
                                  controller: draft.controller,
                                  keyboardType: TextInputType.url,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  onChanged: (_) =>
                                      _validateAndPublishGateways(),
                                  onSubmitted: (_) {
                                    FocusScope.of(context).unfocus();
                                    _validateAndPublishGateways();
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'https://gateway.example',
                                    errorText: draft.error,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Tooltip(
                                  message: _gatewayDrafts.length <= 1
                                      ? l10n.minimumGatewayRequired
                                      : l10n.removeGateway,
                                  child: IconButton(
                                    onPressed: _gatewayDrafts.length <= 1
                                        ? null
                                        : () => _removeGateway(index),
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newGatewayController,
                              keyboardType: TextInputType.url,
                              autocorrect: false,
                              enableSuggestions: false,
                              onChanged: (_) {
                                if (_newGatewayError != null) {
                                  setState(() => _newGatewayError = null);
                                }
                              },
                              onSubmitted: (_) => _addGateway(),
                              decoration: InputDecoration(
                                labelText: l10n.addGateway,
                                hintText: 'https://gateway.example',
                                prefixIcon: const Icon(Icons.add_link),
                                errorText: _newGatewayError,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilledButton.icon(
                            onPressed: _addGateway,
                            icon: const Icon(Icons.add, size: 19),
                            label: Text(l10n.add),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              l10n.gatewayRules,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SettingsCard(
                    icon: Icons.network_check_outlined,
                    title: l10n.network,
                    subtitle: l10n.networkSubtitle,
                    children: [
                      _PreferenceRow(
                        title: l10n.connectionTimeout,
                        description: l10n.connectionTimeoutDescription,
                        trailing: Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: _settings.connectionTimeoutSeconds
                                    .toDouble(),
                                min: 5,
                                max: 120,
                                divisions: 115,
                                label: l10n.secondsShort(
                                  _settings.connectionTimeoutSeconds,
                                ),
                                onChanged: (value) {
                                  _publish(
                                    _settings.copyWith(
                                      connectionTimeoutSeconds: value.round(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            _ValueBadge(
                              value: l10n.secondsShort(
                                _settings.connectionTimeoutSeconds,
                              ),
                              semanticsLabel: l10n.timeoutSecondsSemantics(
                                _settings.connectionTimeoutSeconds,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(Icons.tune_rounded, color: colors.primary, size: 26),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.settings, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 3),
              Text(
                l10n.settingsSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: colors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 1),
                      Text(subtitle, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({
    required this.title,
    required this.description,
    required this.trailing,
  });

  final String title;
  final String description;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 680;
        final text = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 3),
            Text(description, style: theme.textTheme.bodySmall),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [text, const SizedBox(height: 14), trailing],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: text),
            const SizedBox(width: 32),
            SizedBox(width: 390, child: trailing),
          ],
        );
      },
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Divider(height: 1),
    );
  }
}

class _ValueBadge extends StatelessWidget {
  const _ValueBadge({required this.value, required this.semanticsLabel});

  final String value;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      label: semanticsLabel,
      child: Container(
        constraints: const BoxConstraints(minWidth: 52),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.outline),
        ),
        child: Text(
          value,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge,
        ),
      ),
    );
  }
}

class _GatewayIndex extends StatelessWidget {
  const _GatewayIndex({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text('$index', style: theme.textTheme.labelMedium),
    );
  }
}

class _GatewayDraft {
  _GatewayDraft(String value) : controller = TextEditingController(text: value);

  final TextEditingController controller;
  String? error;

  void dispose() => controller.dispose();
}

bool _sameStrings(List<String> left, List<String> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
