import 'package:flutter/material.dart';

import '../../../../app/theme/app_dimens.dart';
import '../../../../app/theme/fetchy_hook_icon.dart';
import '../../../../app/widgets/fetchy_rows.dart';
import '../../../../app/widgets/fetchy_selectors.dart';
import '../../../../app/widgets/fetchy_surface.dart';
import '../../../../core/settings/app_settings_service.dart';
import '../../../../core/settings/locale_controller.dart';
import '../../../../core/settings/theme_controller.dart';
import '../../../../core/storage/storage_settings.dart';
import '../../../../core/storage/storage_settings_service.dart';
import '../../../../core/update/app_version.dart';
import '../../../../core/update/update_models.dart';
import '../../../../core/update/update_service.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../diagnostics/presentation/pages/diagnostics_page.dart';
import '../../../history/history_service.dart';
import '../../../quick_fetch/presentation/pages/quick_fetch_settings_page.dart';
import '../../../quick_fetch/presentation/widgets/quick_fetch_enable_toggle.dart';
import '../../../quick_fetch/quick_fetch_models.dart';
import '../../../quick_fetch/quick_fetch_service.dart';
import '../../../root/presentation/pages/root_features_page.dart';
import '../../../sessions/presentation/pages/connected_accounts_page.dart';
import '../widgets/engine_info_tile.dart';
import 'download_location_page.dart';
import 'updates_page.dart';

/// Modern Settings: Appearance, Downloads (incl. Quick Fetch), History, and About.
class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.themeController,
    required this.localeController,
  });

  final ThemeController themeController;
  final LocaleController localeController;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AppSettingsService _settings = AppSettingsService.instance;
  final HistoryService _history = HistoryService.instance;
  final StorageSettingsService _storageSettings = StorageSettingsService.instance;

  QuickFetchCapabilities _quickFetchCapabilities =
      QuickFetchCapabilities.unavailable;
  bool _quickFetchBusy = false;
  bool _historyEnabled = true;
  StorageSettings _downloadLocation = StorageSettings.defaults;
  bool _loaded = false;

  /// The real installed versionName. Falls back to an em dash rather than
  /// a made-up number if Android could not be asked.
  String _appVersion = '—';

  /// Whether the silent startup check already found a newer release, so the
  /// Updates row can say so without repeating the request.
  bool _updateAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final QuickFetchCapabilities quickFetch = await QuickFetchService.instance
        .capabilities();
    final bool historyEnabled = await _settings.loadHistoryEnabled();
    final StorageSettings downloadLocation = await _storageSettings.load();
    final InstalledAppVersion? installed = await UpdateService.instance
        .installedVersion();

    if (!mounted) return;
    setState(() {
      _quickFetchCapabilities = quickFetch;
      _historyEnabled = historyEnabled;
      _downloadLocation = downloadLocation;
      _appVersion = installed?.versionName ?? '—';
      _updateAvailable =
          UpdateService.instance.latestOutcome.value is UpdateAvailable;
      _loaded = true;
    });
  }

  /// The single Quick Fetch enable/disable flow — shared with the full
  /// Quick Fetch screen so this master switch can never disagree with it.
  Future<void> _setQuickFetchEnabled(bool enabled) async {
    if (_quickFetchBusy) return;
    setState(() => _quickFetchBusy = true);

    final QuickFetchCapabilities result = await setQuickFetchEnabled(
      context,
      enabled: enabled,
      capabilities: _quickFetchCapabilities,
    );

    if (!mounted) return;
    setState(() {
      _quickFetchCapabilities = result;
      _quickFetchBusy = false;
    });
  }

  /// Opens Download Location, then re-reads it on return so the summary
  /// line here matches whatever the user actually left it set to.
  Future<void> _openDownloadLocationSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const DownloadLocationPage(),
      ),
    );

    final StorageSettings downloadLocation = await _storageSettings.load();
    if (!mounted) return;
    setState(() => _downloadLocation = downloadLocation);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return FetchyScaffold(
      title: strings.settingsTitle,
      body: !_loaded
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.sm,
                AppSpacing.page,
                100,
              ),
              children: <Widget>[
                _buildAppearanceSection(),
                const SizedBox(height: AppSpacing.xxl),
                _buildDownloadsSection(),
                const SizedBox(height: AppSpacing.xxl),
                _buildAccountsSection(),
                const SizedBox(height: AppSpacing.xxl),
                _buildHistorySection(),
                const SizedBox(height: AppSpacing.xxl),
                _buildAdvancedSection(),
                const SizedBox(height: AppSpacing.xxl),
                _buildDiagnosticsSection(),
                const SizedBox(height: AppSpacing.xxl),
                _buildAboutSection(),
              ],
            ),
    );
  }

  /// Appearance and Language, both on the same selector control.
  ///
  /// The two are the app's only "pick one of three" settings, and they now
  /// share one modern segmented track rather than each drawing its own
  /// outlined row of rectangles. Both live inside a single card so they
  /// read as one group of preferences about how the app presents itself.
  Widget _buildAppearanceSection() {
    final AppLocalizations strings = AppLocalizations.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        widget.themeController,
        widget.localeController,
      ]),
      builder: (BuildContext context, _) {
        final AppThemeMode currentTheme = widget.themeController.mode;
        final AppLanguageMode currentLanguage = widget.localeController.mode;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            FetchySectionHeader(title: strings.sectionAppearance),
            FetchyCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _SettingCaption(text: strings.themeLabel),
                  const SizedBox(height: AppSpacing.sm),
                  FetchySegmented<AppThemeMode>(
                    selected: currentTheme,
                    onChanged: widget.themeController.setMode,
                    segments: <FetchySegment<AppThemeMode>>[
                      FetchySegment<AppThemeMode>(
                        value: AppThemeMode.system,
                        label: strings.themeSystem,
                        icon: Icons.brightness_auto_rounded,
                      ),
                      FetchySegment<AppThemeMode>(
                        value: AppThemeMode.light,
                        label: strings.themeLight,
                        icon: Icons.light_mode_rounded,
                      ),
                      FetchySegment<AppThemeMode>(
                        value: AppThemeMode.dark,
                        label: strings.themeDark,
                        icon: Icons.dark_mode_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _SettingCaption(text: strings.languageLabel),
                  const SizedBox(height: AppSpacing.sm),
                  FetchySegmented<AppLanguageMode>(
                    selected: currentLanguage,
                    onChanged: widget.localeController.setMode,
                    segments: <FetchySegment<AppLanguageMode>>[
                      FetchySegment<AppLanguageMode>(
                        value: AppLanguageMode.system,
                        label: strings.themeSystem,
                        icon: Icons.translate_rounded,
                      ),
                      // Language autonyms are shown in their own language,
                      // not translated — the same convention every OS
                      // language picker uses.
                      const FetchySegment<AppLanguageMode>(
                        value: AppLanguageMode.english,
                        label: 'English',
                      ),
                      const FetchySegment<AppLanguageMode>(
                        value: AppLanguageMode.arabic,
                        label: 'العربية',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Opens the Quick Fetch screen, then re-reads capabilities on return so
  /// the master switch here matches whatever the user actually left it set
  /// to (action style, permissions, and the enabled state alike).
  Future<void> _openQuickFetchSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const QuickFetchSettingsPage(),
      ),
    );

    final QuickFetchCapabilities capabilities = await QuickFetchService
        .instance
        .capabilities();
    if (!mounted) return;
    setState(() => _quickFetchCapabilities = capabilities);
  }

  Widget _buildDownloadsSection() {
    final AppLocalizations strings = AppLocalizations.of(context);

    return FetchyGroup(
      title: strings.sectionDownloads,
      children: <Widget>[
        // Compact summary out here, full configuration inside: the row
        // says "Default" or "Custom" and nothing more, and the exact
        // folders, subfolder choice, and any access problem all live on the
        // Download Location screen itself.
        FetchyListRow(
          leading: const FetchyLeadingIcon(icon: Icons.folder_outlined),
          title: strings.downloadLocationTitle,
          subtitle: _downloadLocation.compactSummaryLabel(strings),
          showChevron: true,
          onTap: _openDownloadLocationSettings,
        ),
        // Quick Fetch has permissions, an action style, and background
        // behaviour to explain, so it gets its own screen rather than a bare
        // switch the user cannot reason about.
        FetchyListRow(
          leading: const FetchyLeadingIcon(
            icon: Icons.bolt_rounded,
            emphasis: true,
          ),
          title: strings.quickFetchTitle,
          subtitle: strings.quickFetchMasterDescription,
          trailing: Switch(
            value: _quickFetchCapabilities.enabled,
            onChanged: (_quickFetchCapabilities.available && !_quickFetchBusy)
                ? _setQuickFetchEnabled
                : null,
          ),
          onTap: _openQuickFetchSettings,
        ),
      ],
    );
  }

  Widget _buildAccountsSection() {
    final AppLocalizations strings = AppLocalizations.of(context);

    return FetchyGroup(
      title: strings.sectionAccounts,
      children: <Widget>[
        FetchyListRow(
          leading: const FetchyLeadingIcon(icon: Icons.verified_user_outlined),
          title: strings.connectedAccountsTitle,
          subtitle: strings.connectedAccountsSubtitle,
          showChevron: true,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext context) => const ConnectedAccountsPage(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAdvancedSection() {
    final AppLocalizations strings = AppLocalizations.of(context);

    return FetchyGroup(
      title: strings.sectionAdvanced,
      children: <Widget>[
        FetchyListRow(
          leading: const FetchyLeadingIcon(icon: Icons.terminal_rounded),
          title: strings.rootFeaturesTitle,
          subtitle: strings.rootFeaturesComingSoon,
          showChevron: true,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext context) => const RootFeaturesPage(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDiagnosticsSection() {
    final AppLocalizations strings = AppLocalizations.of(context);

    return FetchyGroup(
      title: strings.sectionDiagnostics,
      children: <Widget>[
        FetchyListRow(
          leading: const FetchyLeadingIcon(icon: Icons.troubleshoot_outlined),
          title: strings.technicalInformationTitle,
          subtitle: strings.technicalInformationSubtitle,
          showChevron: true,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext context) => const DiagnosticsPage(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHistorySection() {
    final AppLocalizations strings = AppLocalizations.of(context);

    return FetchyGroup(
      title: strings.sectionHistory,
      children: <Widget>[
        FetchyListRow(
          leading: const FetchyLeadingIcon(icon: Icons.history_rounded),
          title: strings.historySaveEnabled,
          subtitle: strings.historySaveDescription,
          trailing: Switch(
            value: _historyEnabled,
            onChanged: (bool value) async {
              setState(() => _historyEnabled = value);
              await _settings.saveHistoryEnabled(value);
            },
          ),
          onTap: () async {
            final bool value = !_historyEnabled;
            setState(() => _historyEnabled = value);
            await _settings.saveHistoryEnabled(value);
          },
        ),
        FetchyListRow(
          leading: const FetchyLeadingIcon(
            icon: Icons.delete_outline_rounded,
            destructive: true,
          ),
          title: strings.historyClearAction,
          destructive: true,
          onTap: _confirmClearHistory,
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    final AppLocalizations strings = AppLocalizations.of(context);

    return FetchyGroup(
      title: strings.sectionAbout,
      children: <Widget>[
        FetchyListRow(
          // The app's own row shows the app's own mark rather than a
          // generic info glyph.
          leading: const FetchyMarkTile(size: 38, radiusFactor: 0.32),
          title: strings.appVersionLabel,
          // The real installed versionName, read from Android itself.
          subtitle: _appVersion,
        ),
        // The app's own updater. Deliberately a separate row from the
        // yt-dlp Engine tile below: one updates Fetchy, the other updates
        // the extractor runtime, and conflating them would be confusing.
        FetchyListRow(
          leading: const FetchyLeadingIcon(icon: Icons.system_update_rounded),
          title: strings.updatesTitle,
          subtitle: _updateAvailable
              ? strings.updatesAvailableTitle
              : strings.updatesSettingsRowSubtitle,
          showChevron: true,
          onTap: _openUpdates,
        ),
        const EngineInfoTile(),
      ],
    );
  }

  Future<void> _openUpdates() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const UpdatesPage(),
      ),
    );

    if (!mounted) return;
    setState(
      () => _updateAvailable =
          UpdateService.instance.latestOutcome.value is UpdateAvailable,
    );
  }

  Future<void> _confirmClearHistory() async {
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
      await _history.clear();
    }
  }
}

/// A caption for one control inside a settings card — a level below
/// [FetchySectionHeader], which captions the card itself.
class _SettingCaption extends StatelessWidget {
  const _SettingCaption({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
