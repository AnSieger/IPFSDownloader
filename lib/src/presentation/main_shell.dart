import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ipfs_downloader/l10n/app_localizations.dart';

import '../application/download_controller.dart';
import '../core/formatters.dart';
import '../core/ipfs_input_parser.dart';
import '../core/platform_actions.dart';
import '../domain/download_task.dart';
import '../theme/app_theme.dart';
import 'error_localizations.dart';
import 'settings_view.dart';

enum AppSection { all, active, completed, failed, settings }

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.controller});

  final DownloadController controller;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  AppSection _section = AppSection.all;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 920;
            final content = _section == AppSection.settings
                ? SettingsView(controller: widget.controller)
                : DownloadsPage(
                    controller: widget.controller,
                    section: _section,
                  );

            if (compact) {
              return Scaffold(
                body: SafeArea(bottom: false, child: content),
                bottomNavigationBar: _CompactNavigation(
                  section: _section,
                  onSelected: (section) => setState(() => _section = section),
                ),
              );
            }

            return Scaffold(
              body: Row(
                children: [
                  _Sidebar(
                    section: _section,
                    controller: widget.controller,
                    onSelected: (section) => setState(() => _section = section),
                  ),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: Theme.of(context).dividerColor,
                  ),
                  Expanded(child: content),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.section,
    required this.controller,
    required this.onSelected,
  });

  final AppSection section;
  final DownloadController controller;
  final ValueChanged<AppSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    return ColoredBox(
      color: dark ? AppColors.darkSidebar : AppColors.lightSidebar,
      child: SizedBox(
        width: 238,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 20, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: _Brand(),
                ),
                const SizedBox(height: 30),
                _SidebarLabel(l10n.library),
                const SizedBox(height: 7),
                _NavigationTile(
                  label: l10n.allDownloads,
                  icon: CupertinoIcons.square_stack_3d_up,
                  selected: section == AppSection.all,
                  count: controller.tasks.length,
                  onTap: () => onSelected(AppSection.all),
                ),
                _NavigationTile(
                  label: l10n.active,
                  icon: CupertinoIcons.arrow_down_circle,
                  selected: section == AppSection.active,
                  count:
                      controller.activeCount +
                      controller.queuedCount +
                      controller.pausedCount,
                  onTap: () => onSelected(AppSection.active),
                ),
                _NavigationTile(
                  label: l10n.completed,
                  icon: CupertinoIcons.check_mark_circled,
                  selected: section == AppSection.completed,
                  count: controller.completedCount,
                  onTap: () => onSelected(AppSection.completed),
                ),
                _NavigationTile(
                  label: l10n.errors,
                  icon: CupertinoIcons.exclamationmark_triangle,
                  selected: section == AppSection.failed,
                  count: controller.failedCount,
                  countColor: AppColors.red,
                  onTap: () => onSelected(AppSection.failed),
                ),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.fromLTRB(6, 0, 6, 14),
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: dark ? 0.54 : 0.68),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.mint,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Color(0x6630D158), blurRadius: 7),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.ipfsReady,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            Text(
                              l10n.fallbackRoutes(
                                controller.settings.gateways.length,
                              ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _NavigationTile(
                  label: l10n.settings,
                  icon: CupertinoIcons.slider_horizontal_3,
                  selected: section == AppSection.settings,
                  onTap: () => onSelected(AppSection.settings),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Text(
                    l10n.versionLabel('1.0'),
                    style: const TextStyle(
                      color: AppColors.lightSecondaryText,
                      fontSize: 10,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            boxShadow: const [
              BoxShadow(
                color: Color(0x35007AFF),
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.asset(
              'assets/app_icon_source.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            'IPFSDownloader',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _SidebarLabel extends StatelessWidget {
  const _SidebarLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontSize: 10, letterSpacing: 0.75),
      ),
    );
  }
}

class _NavigationTile extends StatelessWidget {
  const _NavigationTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.count,
    this.countColor,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final int? count;
  final Color? countColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected
            ? scheme.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected
                      ? scheme.primary
                      : Theme.of(context).textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? scheme.primary : null,
                    ),
                  ),
                ),
                if (count != null && count! > 0)
                  Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: (countColor ?? scheme.primary).withValues(
                        alpha: selected ? 0.14 : 0.09,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$count',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: countColor ?? (selected ? scheme.primary : null),
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactNavigation extends StatelessWidget {
  const _CompactNavigation({required this.section, required this.onSelected});

  final AppSection section;
  final ValueChanged<AppSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return NavigationBar(
      selectedIndex: AppSection.values.indexOf(section),
      onDestinationSelected: (index) => onSelected(AppSection.values[index]),
      destinations: [
        NavigationDestination(
          icon: const Icon(CupertinoIcons.square_stack_3d_up),
          label: l10n.all,
        ),
        NavigationDestination(
          icon: const Icon(CupertinoIcons.arrow_down_circle),
          label: l10n.active,
        ),
        NavigationDestination(
          icon: const Icon(CupertinoIcons.check_mark_circled),
          label: l10n.completed,
        ),
        NavigationDestination(
          icon: const Icon(CupertinoIcons.exclamationmark_triangle),
          label: l10n.errors,
        ),
        NavigationDestination(
          icon: const Icon(CupertinoIcons.slider_horizontal_3),
          label: l10n.options,
        ),
      ],
    );
  }
}

class DownloadsPage extends StatefulWidget {
  const DownloadsPage({
    super.key,
    required this.controller,
    required this.section,
  });

  final DownloadController controller;
  final AppSection section;

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  final _searchController = TextEditingController();
  final _quickAddKey = GlobalKey<_QuickAddCardState>();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = _filteredTasks();
    final l10n = AppLocalizations.of(context);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(32, 30, 32, 40),
          sliver: SliverList.list(
            children: [
              _PageHeader(
                section: widget.section,
                controller: widget.controller,
                onAdd: () => _quickAddKey.currentState?.focusInput(),
              ),
              const SizedBox(height: 24),
              _QuickAddCard(key: _quickAddKey, controller: widget.controller),
              const SizedBox(height: 20),
              _Metrics(controller: widget.controller),
              const SizedBox(height: 26),
              _ListHeader(
                count: tasks.length,
                queryController: _searchController,
                onQueryChanged: (value) => setState(() => _query = value),
                onClearCompleted: widget.controller.completedCount > 0
                    ? widget.controller.clearCompleted
                    : null,
              ),
              const SizedBox(height: 11),
              if (widget.controller.storageError case final String error)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _InlineNotice(
                    icon: CupertinoIcons.exclamationmark_triangle_fill,
                    color: AppColors.orange,
                    message: localizeAppError(l10n, error),
                  ),
                ),
              if (tasks.isEmpty)
                _EmptyState(
                  section: widget.section,
                  hasQuery: _query.isNotEmpty,
                )
              else
                _DownloadList(tasks: tasks, controller: widget.controller),
            ],
          ),
        ),
      ],
    );
  }

  List<DownloadTask> _filteredTasks() {
    Iterable<DownloadTask> result = widget.controller.tasks;
    result = switch (widget.section) {
      AppSection.active => result.where(
        (task) =>
            task.status.isActive ||
            task.status == DownloadStatus.queued ||
            task.status == DownloadStatus.paused,
      ),
      AppSection.completed => result.where(
        (task) => task.status == DownloadStatus.completed,
      ),
      AppSection.failed => result.where(
        (task) =>
            task.status == DownloadStatus.failed ||
            task.status == DownloadStatus.canceled,
      ),
      _ => result,
    };
    final normalizedQuery = _query.trim().toLowerCase();
    if (normalizedQuery.isNotEmpty) {
      result = result.where(
        (task) =>
            task.fileName.toLowerCase().contains(normalizedQuery) ||
            task.cid.toLowerCase().contains(normalizedQuery) ||
            task.ipfsPath.toLowerCase().contains(normalizedQuery),
      );
    }
    return result.toList(growable: false);
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.section,
    required this.controller,
    required this.onAdd,
  });

  final AppSection section;
  final DownloadController controller;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = switch (section) {
      AppSection.active => l10n.activeDownloads,
      AppSection.completed => l10n.completedDownloads,
      AppSection.failed => l10n.errors,
      _ => l10n.downloadsSettings,
    };
    final subtitle = switch (section) {
      AppSection.active => l10n.activeDownloadsSubtitle,
      AppSection.completed => l10n.completedDownloadsSubtitle,
      AppSection.failed => l10n.failedDownloadsSubtitle,
      _ => l10n.downloadsSubtitle,
    };
    final canPause = controller.activeCount + controller.queuedCount > 0;
    final canResume = controller.pausedCount + controller.failedCount > 0;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 20,
      runSpacing: 14,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canPause)
              OutlinedButton.icon(
                onPressed: controller.pauseAll,
                icon: const Icon(CupertinoIcons.pause_fill, size: 15),
                label: Text(l10n.pauseAll),
              )
            else if (canResume)
              OutlinedButton.icon(
                onPressed: controller.resumeAll,
                icon: const Icon(CupertinoIcons.play_fill, size: 15),
                label: Text(l10n.resume),
              ),
            const SizedBox(width: 9),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(CupertinoIcons.add, size: 17),
              label: Text(l10n.addCid),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickAddCard extends StatefulWidget {
  const _QuickAddCard({super.key, required this.controller});

  final DownloadController controller;

  @override
  State<_QuickAddCard> createState() => _QuickAddCardState();
}

class _QuickAddCardState extends State<_QuickAddCard> {
  final _inputController = TextEditingController();
  final _inputFocus = FocusNode();
  late String _destination;
  bool _directoryArchive = false;

  @override
  void initState() {
    super.initState();
    _destination = widget.controller.settings.defaultDownloadDirectory;
  }

  @override
  void didUpdateWidget(covariant _QuickAddCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldDefault = oldWidget.controller.settings.defaultDownloadDirectory;
    final newDefault = widget.controller.settings.defaultDownloadDirectory;
    if (_destination == oldDefault && oldDefault != newDefault) {
      _destination = newDefault;
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void focusInput() {
    _inputFocus.requestFocus();
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Card(
      key: const Key('quick-add-card'),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primary.withValues(alpha: 0.075),
              scheme.surface,
              scheme.surface,
            ],
            stops: const [0, 0.48, 1],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      CupertinoIcons.link,
                      size: 20,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.newIpfsFiles,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.inputDescription,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 17),
              TextField(
                key: const Key('cid-input'),
                controller: _inputController,
                focusNode: _inputFocus,
                minLines: 2,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                autocorrect: false,
                enableSuggestions: false,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: l10n.inputHint,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 35),
                    child: Icon(CupertinoIcons.number, size: 18),
                  ),
                  suffixIcon: IconButton(
                    tooltip: l10n.clearInput,
                    onPressed: _inputController.clear,
                    icon: const Icon(
                      CupertinoIcons.xmark_circle_fill,
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 720;
                  final destination = _DestinationField(
                    destination: _destination,
                    onChoose: _chooseDestination,
                  );
                  final controls = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message: l10n.directoryArchiveTooltip,
                        child: FilterChip(
                          selected: _directoryArchive,
                          onSelected: (value) =>
                              setState(() => _directoryArchive = value),
                          avatar: Icon(
                            CupertinoIcons.archivebox,
                            size: 15,
                            color: _directoryArchive
                                ? scheme.onSecondaryContainer
                                : null,
                          ),
                          label: Text(l10n.folderAsTar),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        key: const Key('start-download-button'),
                        onPressed: _add,
                        icon: const Icon(CupertinoIcons.arrow_down, size: 16),
                        label: Text(l10n.startDownload),
                      ),
                    ],
                  );

                  if (narrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        destination,
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: controls,
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: destination),
                      const SizedBox(width: 12),
                      controls,
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _chooseDestination() async {
    final l10n = AppLocalizations.of(context);
    final selected = await getDirectoryPath(
      initialDirectory: _destination.isEmpty ? null : _destination,
      confirmButtonText: l10n.saveHere,
    );
    if (selected != null && mounted) {
      setState(() => _destination = selected);
    }
  }

  void _add() {
    final l10n = AppLocalizations.of(context);
    try {
      final result = widget.controller.addDownloads(
        _inputController.text,
        destinationDirectory: _destination,
        directoryArchive: _directoryArchive,
      );
      if (result.added > 0) _inputController.clear();
      _showMessage(l10n.addResult(result.added, result.duplicates));
    } on IpfsInputException catch (error) {
      _showMessage(_localizedInputError(l10n, error), isError: true);
    } on FileSystemException catch (error) {
      _showMessage(
        error.message == 'Bitte zuerst einen Zielordner auswählen.'
            ? l10n.selectDestinationFirst
            : error.message,
        isError: true,
      );
    } on Object catch (error) {
      _showMessage(l10n.downloadAddFailed(error), isError: true);
    }
  }

  void _showMessage(String text, {bool isError = false}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? CupertinoIcons.exclamationmark_circle_fill
                  : CupertinoIcons.check_mark_circled_solid,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}

class _DestinationField extends StatelessWidget {
  const _DestinationField({required this.destination, required this.onChoose});

  final String destination;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: onChoose,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.folder,
              size: 17,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                destination.isEmpty ? l10n.chooseDestination : destination,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.change,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.controller});

  final DownloadController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 480
            ? 2
            : 1;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            _MetricCard(
              width: width,
              label: l10n.metricActive,
              value: '${controller.activeCount}',
              detail: controller.queuedCount > 0
                  ? l10n.queuedFiles(controller.queuedCount)
                  : l10n.noWaitingFiles,
              icon: CupertinoIcons.arrow_down,
              color: AppColors.blue,
            ),
            _MetricCard(
              width: width,
              label: l10n.metricSpeed,
              value: formatSpeed(controller.totalSpeed),
              detail: l10n.currentAggregateRate,
              icon: CupertinoIcons.speedometer,
              color: AppColors.purple,
            ),
            _MetricCard(
              width: width,
              label: l10n.metricCompleted,
              value: '${controller.completedCount}',
              detail: l10n.savedSuccessfully,
              icon: CupertinoIcons.check_mark,
              color: AppColors.mint,
            ),
            _MetricCard(
              width: width,
              label: l10n.metricGateways,
              value: '${controller.settings.gateways.length}',
              detail: l10n.automaticFallback,
              icon: CupertinoIcons.globe,
              color: AppColors.orange,
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.width,
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
  });

  final double width;
  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontSize: 9,
                        letterSpacing: 0.65,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({
    required this.count,
    required this.queryController,
    required this.onQueryChanged,
    required this.onClearCompleted,
  });

  final int count;
  final TextEditingController queryController;
  final ValueChanged<String> onQueryChanged;
  final Future<void> Function()? onClearCompleted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.queueCount(count),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        SizedBox(
          width: 230,
          height: 38,
          child: TextField(
            controller: queryController,
            onChanged: onQueryChanged,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: l10n.searchDownloads,
              prefixIcon: const Icon(CupertinoIcons.search, size: 16),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 9,
              ),
            ),
          ),
        ),
        if (onClearCompleted != null) ...[
          const SizedBox(width: 7),
          IconButton(
            tooltip: l10n.clearCompleted,
            onPressed: onClearCompleted,
            icon: const Icon(CupertinoIcons.clear, size: 18),
          ),
        ],
      ],
    );
  }
}

class _DownloadList extends StatelessWidget {
  const _DownloadList({required this.tasks, required this.controller});

  final List<DownloadTask> tasks;
  final DownloadController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < tasks.length; index++) ...[
            _DownloadRow(task: tasks[index], controller: controller),
            if (index < tasks.length - 1)
              Divider(
                height: 1,
                indent: 77,
                color: Theme.of(context).dividerColor,
              ),
          ],
        ],
      ),
    );
  }
}

class _DownloadRow extends StatefulWidget {
  const _DownloadRow({required this.task, required this.controller});

  final DownloadTask task;
  final DownloadController controller;

  @override
  State<_DownloadRow> createState() => _DownloadRowState();
}

class _DownloadRowState extends State<_DownloadRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        color: _hovered
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.025)
            : Colors.transparent,
        padding: const EdgeInsets.fromLTRB(17, 15, 12, 15),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 720) {
              return _buildCompact(context, task);
            }
            return _buildWide(context, task);
          },
        ),
      ),
    );
  }

  Widget _buildWide(BuildContext context, DownloadTask task) {
    return Row(
      children: [
        _FileIcon(fileName: task.fileName, status: task.status),
        const SizedBox(width: 14),
        Expanded(flex: 5, child: _TaskIdentity(task: task)),
        const SizedBox(width: 18),
        SizedBox(width: 185, child: _TaskProgress(task: task)),
        const SizedBox(width: 18),
        SizedBox(width: 105, child: _TaskTransfer(task: task)),
        const SizedBox(width: 8),
        _TaskActions(
          task: task,
          controller: widget.controller,
          confirmRemove: _confirmRemove,
        ),
      ],
    );
  }

  Widget _buildCompact(BuildContext context, DownloadTask task) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FileIcon(fileName: task.fileName, status: task.status),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TaskIdentity(task: task),
              const SizedBox(height: 12),
              _TaskProgress(task: task),
              const SizedBox(height: 8),
              _TaskTransfer(task: task),
            ],
          ),
        ),
        const SizedBox(width: 4),
        _TaskActions(
          task: task,
          controller: widget.controller,
          confirmRemove: _confirmRemove,
        ),
      ],
    );
  }

  Future<void> _confirmRemove(DownloadTask task) async {
    final l10n = AppLocalizations.of(context);
    final deletePartial =
        task.status != DownloadStatus.completed && task.receivedBytes > 0;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removeEntryTitle),
        content: Text(
          deletePartial
              ? l10n.removeWithPartial(
                  task.fileName,
                  formatBytes(task.receivedBytes),
                )
              : l10n.removeKeepFile(task.fileName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.controller.removeTask(task.id, deletePartial: deletePartial);
    }
  }
}

class _FileIcon extends StatelessWidget {
  const _FileIcon({required this.fileName, required this.status});

  final String fileName;
  final DownloadStatus status;

  @override
  Widget build(BuildContext context) {
    final extension = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';
    final (icon, color) = switch (extension) {
      'zip' ||
      'rar' ||
      '7z' ||
      'tar' ||
      'gz' => (CupertinoIcons.archivebox_fill, AppColors.orange),
      'jpg' ||
      'jpeg' ||
      'png' ||
      'gif' ||
      'webp' => (CupertinoIcons.photo_fill, AppColors.purple),
      'mp4' ||
      'mkv' ||
      'mov' ||
      'webm' => (CupertinoIcons.play_rectangle_fill, AppColors.indigo),
      'mp3' ||
      'flac' ||
      'wav' ||
      'm4a' => (CupertinoIcons.music_note_2, AppColors.red),
      'pdf' => (CupertinoIcons.doc_text_fill, AppColors.red),
      _ => (CupertinoIcons.doc_fill, AppColors.blue),
    };
    final effectiveColor = status == DownloadStatus.completed
        ? AppColors.mint
        : color;
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.105),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, size: 22, color: effectiveColor),
    );
  }
}

class _TaskIdentity extends StatelessWidget {
  const _TaskIdentity({required this.task});

  final DownloadTask task;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Tooltip(
          message: task.canonicalSource,
          child: Row(
            children: [
              Icon(
                CupertinoIcons.link,
                size: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  compactCid(task.cid),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
              ),
              if (task.isDirectoryArchive) ...[
                const SizedBox(width: 7),
                const _MiniTag(label: 'TAR'),
              ],
            ],
          ),
        ),
        if (task.error case final String error) ...[
          const SizedBox(height: 4),
          Text(
            localizeAppError(AppLocalizations.of(context), error),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.red),
          ),
        ],
      ],
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(fontSize: 8),
      ),
    );
  }
}

class _TaskProgress extends StatelessWidget {
  const _TaskProgress({required this.task});

  final DownloadTask task;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final statusColor = _statusColor(task.status);
    final statusLabel = switch (task.status) {
      DownloadStatus.queued => l10n.statusQueued,
      DownloadStatus.resolving => l10n.statusResolving,
      DownloadStatus.downloading => l10n.statusDownloading,
      DownloadStatus.paused => l10n.statusPaused,
      DownloadStatus.completed => l10n.statusCompleted,
      DownloadStatus.failed => l10n.statusFailed,
      DownloadStatus.canceled => l10n.statusCanceled,
    };
    final progress = task.progress;
    final indicatorProgress = switch (task.status) {
      DownloadStatus.resolving => null,
      DownloadStatus.downloading when progress == null => null,
      DownloadStatus.completed => 1.0,
      _ => progress ?? 0,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                statusLabel,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: statusColor),
              ),
            ),
            if (progress != null)
              Text(
                '${(progress * 100).round()} %',
                style: Theme.of(context).textTheme.labelMedium,
              ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: indicatorProgress,
            minHeight: 5,
            color: statusColor,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          task.totalBytes == null
              ? formatBytes(task.receivedBytes)
              : l10n.bytesOfTotal(
                  formatBytes(task.receivedBytes),
                  formatBytes(task.totalBytes),
                ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
        ),
      ],
    );
  }
}

class _TaskTransfer extends StatelessWidget {
  const _TaskTransfer({required this.task});

  final DownloadTask task;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final downloading = task.status == DownloadStatus.downloading;
    final mainText = downloading
        ? formatSpeed(task.speedBytesPerSecond)
        : task.gateway != null
        ? Uri.tryParse(task.gateway!)?.host ?? task.gateway!
        : '–';
    final detail = downloading
        ? l10n.timeRemaining(
            _formatLocalizedDuration(l10n, task.estimatedTimeRemaining),
          )
        : task.status == DownloadStatus.completed
        ? l10n.savedLocally
        : l10n.ready;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          mainText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 3),
        Text(
          detail,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
        ),
      ],
    );
  }
}

class _TaskActions extends StatelessWidget {
  const _TaskActions({
    required this.task,
    required this.controller,
    required this.confirmRemove,
  });

  final DownloadTask task;
  final DownloadController controller;
  final Future<void> Function(DownloadTask) confirmRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final running =
        task.status.isActive || task.status == DownloadStatus.queued;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: Key('primary-action-${task.id}'),
          tooltip: running
              ? l10n.pause
              : task.status == DownloadStatus.completed
              ? l10n.showInFolder
              : l10n.start,
          onPressed: () {
            if (running) {
              controller.pauseTask(task.id);
            } else if (task.status == DownloadStatus.completed) {
              unawaited(PlatformActions.revealFile(task.finalPath));
            } else {
              controller.startTask(task.id);
            }
          },
          icon: Icon(
            running
                ? CupertinoIcons.pause_fill
                : task.status == DownloadStatus.completed
                ? CupertinoIcons.folder
                : CupertinoIcons.play_fill,
            size: 17,
          ),
        ),
        PopupMenuButton<_TaskMenuAction>(
          tooltip: l10n.moreActions,
          icon: const Icon(CupertinoIcons.ellipsis, size: 19),
          position: PopupMenuPosition.under,
          onSelected: (action) => _perform(action),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _TaskMenuAction.showFolder,
              child: _MenuItem(
                icon: CupertinoIcons.folder,
                label: l10n.openDestinationFolder,
              ),
            ),
            if (task.status != DownloadStatus.completed)
              PopupMenuItem(
                value: _TaskMenuAction.cancel,
                child: _MenuItem(
                  icon: CupertinoIcons.stop_fill,
                  label: l10n.cancel,
                ),
              ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: _TaskMenuAction.moveUp,
              child: _MenuItem(
                icon: CupertinoIcons.arrow_up,
                label: l10n.moveUp,
              ),
            ),
            PopupMenuItem(
              value: _TaskMenuAction.moveDown,
              child: _MenuItem(
                icon: CupertinoIcons.arrow_down,
                label: l10n.moveDown,
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: _TaskMenuAction.remove,
              child: _MenuItem(
                icon: CupertinoIcons.trash,
                label: l10n.removeFromList,
                destructive: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _perform(_TaskMenuAction action) {
    switch (action) {
      case _TaskMenuAction.showFolder:
        unawaited(PlatformActions.openDirectory(task.destinationDirectory));
      case _TaskMenuAction.cancel:
        unawaited(controller.cancelTask(task.id));
      case _TaskMenuAction.moveUp:
        controller.moveTask(task.id, -1);
      case _TaskMenuAction.moveDown:
        controller.moveTask(task.id, 1);
      case _TaskMenuAction.remove:
        unawaited(confirmRemove(task));
    }
  }
}

enum _TaskMenuAction { showFolder, cancel, moveUp, moveDown, remove }

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Theme.of(context).colorScheme.error : null;
    return Row(
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.section, required this.hasQuery});

  final AppSection section;
  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (icon, title, message) = hasQuery
        ? (CupertinoIcons.search, l10n.nothingFound, l10n.nothingFoundMessage)
        : switch (section) {
            AppSection.completed => (
              CupertinoIcons.check_mark_circled,
              l10n.noCompletedDownloads,
              l10n.noCompletedDownloadsMessage,
            ),
            AppSection.failed => (
              CupertinoIcons.exclamationmark_triangle,
              l10n.noErrors,
              l10n.noErrorsMessage,
            ),
            AppSection.active => (
              CupertinoIcons.pause_circle,
              l10n.nothingActive,
              l10n.nothingActiveMessage,
            ),
            _ => (
              CupertinoIcons.arrow_down_doc,
              l10n.emptyQueue,
              l10n.emptyQueueMessage,
            ),
          };
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 52),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 26,
              ),
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 5),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 9),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

String _formatLocalizedDuration(AppLocalizations l10n, Duration? duration) {
  if (duration == null) return '–';
  if (duration <= Duration.zero) return l10n.durationSeconds(0);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  if (hours > 0) return l10n.durationHoursMinutes(hours, minutes);
  if (minutes > 0) return l10n.durationMinutesSeconds(minutes, seconds);
  return l10n.durationSeconds(seconds);
}

Color _statusColor(DownloadStatus status) => switch (status) {
  DownloadStatus.completed => AppColors.mint,
  DownloadStatus.failed || DownloadStatus.canceled => AppColors.red,
  DownloadStatus.paused => AppColors.orange,
  DownloadStatus.queued => AppColors.lightSecondaryText,
  DownloadStatus.resolving => AppColors.purple,
  DownloadStatus.downloading => AppColors.blue,
};

String _localizedInputError(AppLocalizations l10n, IpfsInputException error) =>
    switch (error.code) {
      IpfsInputError.noCid => l10n.enterAtLeastOneCid,
      IpfsInputError.emptyInput => l10n.inputEmpty,
      IpfsInputError.gatewayUrlMissingCid => l10n.gatewayUrlMissingCid,
      IpfsInputError.unsupportedCid => l10n.unsupportedCid(
        error.invalidValue ?? error.input ?? '',
      ),
      IpfsInputError.relativePathSegment => l10n.relativePathNotAllowed,
      IpfsInputError.encodedPathSeparator => l10n.encodedSeparatorNotAllowed,
      IpfsInputError.missingCid => l10n.inputMissingCid,
      IpfsInputError.invalidUrlEncoding => l10n.invalidUrlEncoding(
        error.invalidValue ?? '',
      ),
    };
