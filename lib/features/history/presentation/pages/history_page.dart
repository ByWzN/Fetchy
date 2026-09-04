import 'package:flutter/material.dart';

import '../../../../app/theme/app_dimens.dart';
import '../../../../app/widgets/fetchy_buttons.dart';
import '../../../../app/widgets/fetchy_rows.dart';
import '../../../../app/widgets/fetchy_selectors.dart';
import '../../../../app/widgets/fetchy_sheet.dart';
import '../../../../app/widgets/fetchy_surface.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../history_entry.dart';
import '../../history_service.dart';
import '../widgets/history_list_tile.dart';
import 'history_detail_page.dart';

/// Full download history with local search, media type filters, platform
/// filters, and file inspection — backed by [HistoryService]'s local persistence.
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final HistoryService _historyService = HistoryService.instance;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedMediaType = 'all'; // 'all', 'video', 'audio'
  String _selectedPlatform =
      'all'; // 'all', 'YouTube', 'TikTok', 'Instagram', 'X', 'Other'

  @override
  void initState() {
    super.initState();
    _historyService.load();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final String query = _searchController.text.trim();
    if (query != _searchQuery) {
      setState(() => _searchQuery = query);
    }
  }

  /// How many filters are narrowing the list right now. Drives the badge on
  /// the Filter button so the user can see that a filter is active without
  /// the options themselves taking up the page.
  int get _activeFilterCount {
    int count = 0;
    if (_selectedMediaType != 'all') count++;
    if (_selectedPlatform != 'all') count++;
    return count;
  }

  Widget _buildSearchField(AppLocalizations strings) {
    final ThemeData theme = Theme.of(context);
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: strings.historySearchHint,
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => _searchController.clear(),
              )
            : null,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md + 2,
        ),
      ),
    );
  }

  /// Opens the filter options in a bottom sheet. Selections apply live, so
  /// the sheet only needs a Done button rather than an Apply/Cancel pair.
  Future<void> _openFilterSheet() async {
    final AppLocalizations strings = AppLocalizations.of(context);
    await showFetchySheet<void>(
      context,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            void update(VoidCallback change) {
              setSheetState(change);
              // Keep the underlying list in sync as choices are made.
              setState(() {});
            }

            return FetchySheet(
              title: strings.historyFilterTooltip,
              footer: Row(
                children: <Widget>[
                  if (_activeFilterCount > 0)
                    Expanded(
                      child: FetchyTonalButton(
                        label: strings.commonClear,
                        height: 52,
                        onPressed: () => update(() {
                          _selectedMediaType = 'all';
                          _selectedPlatform = 'all';
                        }),
                      ),
                    ),
                  if (_activeFilterCount > 0) const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FetchyPrimaryButton(
                      label: strings.commonDone,
                      icon: Icons.check_rounded,
                      height: 52,
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _SheetLabel(text: strings.historyMediaTypeLabel),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: <Widget>[
                      for (final MapEntry<String, String> option
                          in <String, String>{
                            'all': strings.commonAll,
                            'video': strings.historyMediaTypeVideo,
                            'audio': strings.historyMediaTypeAudio,
                          }.entries)
                        FetchyChoiceChip(
                          label: option.value,
                          isSelected: _selectedMediaType == option.key,
                          onTap: () =>
                              update(() => _selectedMediaType = option.key),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _SheetLabel(text: strings.historySourceLabel),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: <Widget>[
                      for (final MapEntry<String, String> option
                          in <String, String>{
                            'all': strings.commonAll,
                            'YouTube': 'YouTube',
                            'TikTok': 'TikTok',
                            'Instagram': 'Instagram',
                            'X': 'X',
                            'Other': strings.historySourceOther,
                          }.entries)
                        FetchyChoiceChip(
                          label: option.value,
                          isSelected: _selectedPlatform == option.key,
                          onTap: () =>
                              update(() => _selectedPlatform = option.key),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (mounted) setState(() {});
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedMediaType = 'all';
      _selectedPlatform = 'all';
    });
  }

  List<HistoryEntry> _filterEntries(List<HistoryEntry> entries) {
    final String query = _searchQuery.toLowerCase();

    return entries.where((HistoryEntry entry) {
      // 1. Media Type Filter
      if (_selectedMediaType == 'video' && entry.mediaType == 'audio') {
        return false;
      }
      if (_selectedMediaType == 'audio' && entry.mediaType != 'audio') {
        return false;
      }

      // 2. Platform Filter
      if (_selectedPlatform != 'all') {
        if (_selectedPlatform == 'Other') {
          if (<String>[
            'YouTube',
            'TikTok',
            'Instagram',
            'X',
          ].contains(entry.platform)) {
            return false;
          }
        } else if (entry.platform.toLowerCase() !=
            _selectedPlatform.toLowerCase()) {
          return false;
        }
      }

      // 3. Search Query Filter
      if (query.isNotEmpty) {
        final bool matchesTitle = entry.title.toLowerCase().contains(query);
        final bool matchesFileName =
            entry.fileName?.toLowerCase().contains(query) ?? false;
        final bool matchesUrl = entry.sourceUrl.toLowerCase().contains(query);
        final bool matchesPlatform = entry.platform.toLowerCase().contains(
          query,
        );
        if (!matchesTitle &&
            !matchesFileName &&
            !matchesUrl &&
            !matchesPlatform) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);

    return FetchyScaffold(
      title: strings.historyPageTitle,
      actions: <Widget>[
        ValueListenableBuilder<List<HistoryEntry>>(
          valueListenable: _historyService.entries,
          builder: (BuildContext context, List<HistoryEntry> entries, _) {
            if (entries.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.lg),
              child: FetchyIconButton(
                icon: Icons.delete_outline_rounded,
                tooltip: strings.historyClearHistoryTooltip,
                destructive: true,
                onPressed: () => _confirmClear(context),
              ),
            );
          },
        ),
      ],
      body: ValueListenableBuilder<List<HistoryEntry>>(
        valueListenable: _historyService.entries,
        builder: (BuildContext context, List<HistoryEntry> entries, _) {
          if (entries.isEmpty) {
            return const _EmptyHistory();
          }

          final List<HistoryEntry> filtered = _filterEntries(entries);
          final bool hasActiveFilters =
              _searchQuery.isNotEmpty ||
              _selectedMediaType != 'all' ||
              _selectedPlatform != 'all';

          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.sm,
                  AppSpacing.page,
                  0,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(child: _buildSearchField(strings)),
                    const SizedBox(width: AppSpacing.md),
                    _FilterButton(
                      activeCount: _activeFilterCount,
                      onPressed: _openFilterSheet,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: filtered.isEmpty
                    ? LayoutBuilder(
                        builder:
                            (
                              BuildContext context,
                              BoxConstraints constraints,
                            ) {
                              return SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.page,
                                  vertical: AppSpacing.sm,
                                ),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight,
                                  ),
                                  child: _NoSearchResults(
                                    hasFilters: hasActiveFilters,
                                    onReset: _resetFilters,
                                  ),
                                ),
                              );
                            },
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.page,
                          AppSpacing.sm,
                          AppSpacing.page,
                          100,
                        ),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (BuildContext context, int index) {
                          final HistoryEntry entry = filtered[index];
                          return HistoryListTile(
                            entry: entry,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    HistoryDetailPage(entry: entry),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final AppLocalizations strings = AppLocalizations.of(context);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(strings.historyClearHistoryTitle),
        content: Text(strings.historyClearHistoryBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.commonClear),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _historyService.clear();
    }
  }
}

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults({required this.hasFilters, required this.onReset});

  final bool hasFilters;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xl,
          horizontal: AppSpacing.md,
        ),
        child: FetchyEmptyState(
          icon: Icons.search_off_rounded,
          title: strings.historyNoMatchingDownloads,
          message: strings.historyTryChangingFilters,
          action: hasFilters
              ? FetchyTonalButton(
                  label: strings.historyResetFilters,
                  icon: Icons.clear_all_rounded,
                  expand: false,
                  onPressed: onReset,
                )
              : null,
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: FetchyCard(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xxxl,
                  horizontal: AppSpacing.xl,
                ),
                child: FetchyEmptyState(
                  icon: Icons.history_rounded,
                  title: strings.historyNoHistoryYet,
                  message: strings.historyDownloadsWillShowHere,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The Filter entry point, badged with the number of active filters.
class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.activeCount, required this.onPressed});

  final int activeCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final bool isActive = activeCount > 0;

    return Badge(
      isLabelVisible: isActive,
      label: Text('$activeCount'),
      child: FetchyIconButton(
        icon: Icons.tune_rounded,
        tooltip: AppLocalizations.of(context).historyFilterTooltip,
        // Tinted while any filter is narrowing the list, so the state is
        // legible from the button itself and not only from the badge.
        emphasis: isActive,
        size: 48,
        iconSize: 20,
        borderRadius: AppShape.control,
        onPressed: onPressed,
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  const _SheetLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}
