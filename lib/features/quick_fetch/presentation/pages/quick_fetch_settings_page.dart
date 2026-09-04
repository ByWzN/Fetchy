import 'package:flutter/material.dart';

import '../../../../app/theme/app_dimens.dart';
import '../../../../app/theme/fetchy_tokens.dart';
import '../../../../app/widgets/fetchy_buttons.dart';
import '../../../../app/widgets/fetchy_rows.dart';
import '../../../../app/widgets/fetchy_selectors.dart';
import '../../../../app/widgets/fetchy_surface.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../quick_fetch_availability.dart';
import '../../quick_fetch_models.dart';
import '../../quick_fetch_service.dart';
import '../widgets/quick_fetch_enable_toggle.dart';
import 'watched_domains_edit_page.dart';

/// The full Quick Fetch screen: the switch, the action style, live capability
/// status, and — deliberately prominent — a plain description of what the
/// background detector does and does not do.
class QuickFetchSettingsPage extends StatefulWidget {
  const QuickFetchSettingsPage({super.key});

  @override
  State<QuickFetchSettingsPage> createState() => _QuickFetchSettingsPageState();
}

class _QuickFetchSettingsPageState extends State<QuickFetchSettingsPage>
    with WidgetsBindingObserver {
  final QuickFetchService _quickFetch = QuickFetchService.instance;

  QuickFetchCapabilities _capabilities = QuickFetchCapabilities.unavailable;
  bool _loaded = false;
  bool _busy = false;

  /// True once the user has been sent to Android's Accessibility settings
  /// at least once this visit. Only changes the wording and which follow-up
  /// actions are offered — never what state is reported, which always comes
  /// from a fresh platform query.
  bool _enableAttempted = false;

  List<String> _watchedDomains = const <String>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // While the feature is held back there is no live state to query and
    // nothing to configure — the screen is a static "coming soon" card.
    if (!QuickFetchAvailability.isAvailable) {
      _loaded = true;
      return;
    }

    _refresh();
    _loadWatchedDomains();
  }

  Future<void> _loadWatchedDomains() async {
    final String text = await _quickFetch.getWatchedDomainsText();
    if (!mounted) return;
    setState(() {
      _watchedDomains = text
          .split('\n')
          .map((String l) => l.trim())
          .where((String l) => l.isNotEmpty)
          .toList();
    });
  }

  Future<void> _openWatchedDomainsEditor() async {
    await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => const WatchedDomainsEditPage(),
      ),
    );
    await _loadWatchedDomains();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!QuickFetchAvailability.isAvailable) return;

    // Accessibility, notification, and overlay access can all be changed from
    // the system screens this page links out to, so state is always re-read on
    // return rather than assumed from the request result.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final QuickFetchCapabilities capabilities = await _quickFetch
        .capabilities();
    if (!mounted) return;
    setState(() {
      _capabilities = capabilities;
      _loaded = true;
    });
  }

  /// Delegates to the shared enable/disable flow (consent dialog, the actual
  /// platform call, persisting the result) so this page and the Settings
  /// page's master switch can never drift into two different notions of
  /// "enabled".
  Future<void> _setEnabled(bool enabled) async {
    if (_busy) return;
    setState(() => _busy = true);

    final QuickFetchCapabilities result = await setQuickFetchEnabled(
      context,
      enabled: enabled,
      capabilities: _capabilities,
    );

    if (!mounted) return;
    setState(() {
      _capabilities = result;
      _busy = false;
    });

    // The shared flow already requested the notification permission if
    // needed; re-read live capabilities so Status reflects whatever the
    // user actually granted.
    if (result.enabled) await _refresh();
  }

  Future<void> _setActionStyle(QuickFetchActionStyle style) async {
    if (_busy || style == _capabilities.actionStyle) return;
    setState(() => _busy = true);

    final QuickFetchCapabilities result = await _quickFetch.setActionStyle(
      style,
    );

    if (!mounted) return;
    setState(() {
      _capabilities = result;
      _busy = false;
    });

    if (result.enabled) await _promptForRequiredPermission(result);
  }

  /// Requests only the permission the *selected* style needs, and only right
  /// after the user chose it — never on app startup, and never for a style
  /// that is not in use.
  Future<void> _promptForRequiredPermission(
    QuickFetchCapabilities capabilities,
  ) async {
    if (capabilities.actionStyle == QuickFetchActionStyle.notification) {
      if (capabilities.canPostNotifications) return;
      await _quickFetch.requestNotificationPermission();
      await _refresh();
    }
    // Overlay access cannot be granted by a dialog — the user must visit the
    // system screen — so it is offered as an explicit button in Status.
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    if (!QuickFetchAvailability.isAvailable) {
      return FetchyScaffold(
        title: strings.quickFetchTitle,
        body: _buildComingSoonBody(strings),
      );
    }

    return FetchyScaffold(
      title: strings.quickFetchTitle,
      body: !_loaded
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.md,
                AppSpacing.page,
                AppSpacing.xxxl,
              ),
              children: <Widget>[
                Text(
                  strings.quickFetchIntro,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _buildToggleSection(strings),
                if (_capabilities.enabled) ...<Widget>[
                  const SizedBox(height: AppSpacing.xxl),
                  _buildSetupSection(strings),
                  const SizedBox(height: AppSpacing.xxl),
                  _buildActionStyleSection(strings),
                  const SizedBox(height: AppSpacing.xxl),
                  _buildStatusSection(strings),
                ],
                const SizedBox(height: AppSpacing.xxl),
                _buildShareFallbackSection(strings),
                const SizedBox(height: AppSpacing.xxl),
                _buildHowItWorksSection(strings),
                const SizedBox(height: AppSpacing.xxl),
                _buildWatchedSitesSection(strings),
              ],
            ),
    );
  }

  /// The screen while Quick Fetch is held back from a release.
  ///
  /// Deliberately a finished-looking card rather than a disabled version of
  /// the real screen: no dead switches, no status rows that cannot resolve,
  /// and nothing asking for Accessibility access. The full screen returns
  /// unchanged the moment [QuickFetchAvailability.isAvailable] is true again.
  Widget _buildComingSoonBody(AppLocalizations strings) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final FetchyTokens tokens = FetchyTokens.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.md,
        AppSpacing.page,
        AppSpacing.xxxl,
      ),
      children: <Widget>[
        FetchyCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: tokens.surfaceSelected,
                      borderRadius: AppShape.control,
                    ),
                    child: Icon(
                      Icons.bolt_rounded,
                      size: 24,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          strings.quickFetchTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          strings.quickFetchComingSoonTag,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                strings.quickFetchComingSoonBody,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // States plainly that nothing about downloading depends on this, so
        // a "coming soon" feature never reads as a missing capability.
        FetchyBanner(
          message: strings.quickFetchComingSoonMeanwhile,
          icon: Icons.info_outline_rounded,
        ),
      ],
    );
  }

  Widget _buildToggleSection(AppLocalizations strings) {
    return FetchyGroup(
      title: strings.quickFetchTitle,
      dividerIndent: 0,
      children: <Widget>[
        FetchyListRow(
          leading: FetchyLeadingIcon(
            icon: Icons.bolt_rounded,
            emphasis: _capabilities.enabled,
          ),
          title: strings.quickFetchEnableTitle,
          subtitle: _capabilities.enabled
              ? strings.quickFetchOnDescription
              : strings.quickFetchOffDescription,
          trailing: Switch(
            value: _capabilities.enabled,
            onChanged: _capabilities.available && !_busy ? _setEnabled : null,
          ),
          // Tapping the row toggles, exactly as the SwitchListTile this
          // replaced did — and under the same availability gate.
          onTap: _capabilities.available && !_busy
              ? () => _setEnabled(!_capabilities.enabled)
              : null,
        ),
      ],
    );
  }

  /// Background detection setup: the one place that explains what state
  /// Quick Fetch's detector is in and what the user can do about it.
  ///
  /// Only two states are ever claimed — ready, or not enabled. Android does
  /// not tell an app *why* its accessibility service is off, so "the user
  /// hasn't turned it on" and "Restricted Settings blocked it" are never
  /// presented as distinguishable facts. The restricted-settings guidance is
  /// offered as help the user can open, not asserted as the diagnosis.
  Widget _buildSetupSection(AppLocalizations strings) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final FetchyTokens tokens = FetchyTokens.of(context);
    final bool ready = _capabilities.setupState == QuickFetchSetupState.ready;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FetchySectionHeader(title: strings.quickFetchAutoDetectLabel),
        FetchyCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    ready
                        ? Icons.check_circle_outline_rounded
                        : Icons.bolt_outlined,
                    size: 22,
                    color: ready ? tokens.successFg : colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          ready
                              ? strings.quickFetchSetupReadyTitle
                              : _enableAttempted
                              ? strings.quickFetchSetupNotYetEnabledTitle
                              : strings.quickFetchSetupNeededTitle,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          ready
                              ? strings.quickFetchSetupReadyMessage
                              : _enableAttempted
                              ? strings.quickFetchSetupNotYetEnabledMessage
                              : strings.quickFetchSetupNeededMessage,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!ready) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                FetchyPrimaryButton(
                  label: _enableAttempted
                      ? strings.quickFetchTryAgain
                      : strings.quickFetchEnableCta,
                  icon: Icons.bolt_rounded,
                  height: 48,
                  onPressed: _startEnableFlow,
                ),
                // The secondary routes only appear once the direct attempt
                // has not worked, so the first-run screen stays a single
                // clear action rather than a wall of buttons.
                if (_enableAttempted) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  FetchyTonalButton(
                    label: strings.quickFetchOpenAccessibilitySettings,
                    icon: Icons.accessibility_new_rounded,
                    height: 44,
                    onPressed: () async {
                      await _quickFetch.openAccessibilitySettings();
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FetchyTonalButton(
                    label: strings.quickFetchOpenAppInfo,
                    icon: Icons.info_outline_rounded,
                    height: 44,
                    onPressed: () async {
                      await _quickFetch.openAppInfoSettings();
                    },
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                // Technical detail stays folded away until asked for.
                _RestrictedSettingsHelp(
                  showRestrictedGuidance: _capabilities
                      .installSource
                      .mayNeedRestrictedSettingsStep,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  strings.quickFetchOptionalNote,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// The universal fallback, stated plainly so nobody concludes that
  /// Accessibility access is required to download with Fetchy at all.
  Widget _buildShareFallbackSection(AppLocalizations strings) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FetchySectionHeader(title: strings.quickFetchShareFallbackTitle),
        FetchyCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const FetchyLeadingIcon(icon: Icons.ios_share_rounded),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      strings.quickFetchShareFallbackSubtitle,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      strings.quickFetchShareFallbackMessage,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Explains what is about to happen, then opens Android's own
  /// Accessibility settings. Fetchy never attempts to switch the service on
  /// itself — there is no supported way to do that, and no unsupported one
  /// is used.
  Future<void> _startEnableFlow() async {
    final AppLocalizations strings = AppLocalizations.of(context);

    final bool? proceed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        icon: Icon(
          Icons.accessibility_new_rounded,
          size: 28,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(strings.quickFetchEnableExplainTitle),
        content: SingleChildScrollView(
          child: Text(strings.quickFetchEnableExplainBody),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.quickFetchEnableExplainContinue),
          ),
        ],
      ),
    );

    if (proceed != true) return;

    // Remembered so the follow-up state can offer the secondary routes and
    // the "isn't enabled yet" wording instead of repeating the first-run
    // pitch. State itself is always re-read from the platform on resume.
    setState(() => _enableAttempted = true);
    await _quickFetch.openAccessibilitySettings();
  }

  Widget _buildActionStyleSection(AppLocalizations strings) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FetchySectionHeader(title: strings.quickFetchActionStyleTitle),
        FetchyCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              FetchySegmented<QuickFetchActionStyle>(
                selected: _capabilities.actionStyle,
                onChanged: _busy ? null : _setActionStyle,
                segments: <FetchySegment<QuickFetchActionStyle>>[
                  FetchySegment<QuickFetchActionStyle>(
                    value: QuickFetchActionStyle.notification,
                    label: strings.quickFetchStyleNotification,
                    icon: Icons.notifications_outlined,
                  ),
                  FetchySegment<QuickFetchActionStyle>(
                    value: QuickFetchActionStyle.floatingDot,
                    label: strings.quickFetchStyleFloatingDot,
                    icon: Icons.blur_circular_rounded,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // The description sits inside the same card as the control it
              // describes, and swaps as the selection changes.
              AnimatedSwitcher(
                duration: AppMotion.medium,
                child: Text(
                  key: ValueKey<QuickFetchActionStyle>(_capabilities.actionStyle),
                  switch (_capabilities.actionStyle) {
                    QuickFetchActionStyle.notification =>
                      strings.quickFetchStyleNotificationDescription,
                    QuickFetchActionStyle.floatingDot =>
                      strings.quickFetchStyleOverlayDescription,
                  },
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Live status. Every row is derived from a platform query on this build —
  /// never inferred from a stored preference.
  Widget _buildStatusSection(AppLocalizations strings) {
    final List<Widget> rows = <Widget>[];

    // 1. Whichever permission the selected style needs. Background
    // detection has its own dedicated setup card above this section.
    if (_capabilities.actionStyle == QuickFetchActionStyle.notification) {
      rows.add(
        _capabilities.canPostNotifications
            ? _StatusTile(
                icon: Icons.check_circle_outline_rounded,
                severity: _Severity.ok,
                title: strings.quickFetchNotificationAllowedTitle,
                message: strings.quickFetchNotificationAllowedMessage,
              )
            : _StatusTile(
                icon: Icons.notifications_off_outlined,
                severity: _Severity.error,
                title: strings.quickFetchNotificationNotAllowedTitle,
                message: strings.quickFetchNotificationNotAllowedMessage,
                actionLabel: strings.quickFetchOpenNotificationSettings,
                onAction: () async {
                  await _quickFetch.openNotificationSettings();
                },
              ),
      );
    } else {
      rows.add(
        _capabilities.canDrawOverlays
            ? _StatusTile(
                icon: Icons.check_circle_outline_rounded,
                severity: _Severity.ok,
                title: strings.quickFetchOverlayAllowedTitle,
                message: strings.quickFetchOverlayAllowedMessage,
              )
            : _StatusTile(
                icon: Icons.layers_outlined,
                severity: _Severity.error,
                title: strings.quickFetchOverlayNotAllowedTitle,
                message: strings.quickFetchOverlayNotAllowedMessage,
                actionLabel: strings.quickFetchEnableOverlay,
                onAction: () async {
                  await _quickFetch.openOverlaySettings();
                },
              ),
      );
    }

    return FetchyGroup(
      title: strings.quickFetchStatusTitle,
      dividerIndent: 0,
      children: rows,
    );
  }

  Widget _buildHowItWorksSection(AppLocalizations strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FetchySectionHeader(title: strings.quickFetchHowItWorksTitle),
        FetchyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _Bullet(strings.quickFetchHowItWorks1),
              _Bullet(strings.quickFetchHowItWorks2),
              _Bullet(strings.quickFetchHowItWorks3),
              _Bullet(strings.quickFetchHowItWorks4),
              _Bullet(strings.quickFetchHowItWorks5),
              _Bullet(strings.quickFetchConsent4, last: true),
            ],
          ),
        ),
      ],
    );
  }

  /// A clean, read-only list — not an always-open text editor. Built-in
  /// defaults are just the starting content of the underlying text; once
  /// loaded there is no separate "built-in" vs. "custom" list left
  /// anywhere, but nothing here is directly tappable/editable — that only
  /// happens on the dedicated [WatchedDomainsEditPage], reached via Edit.
  Widget _buildWatchedSitesSection(AppLocalizations strings) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FetchySectionHeader(
          title: strings.quickFetchWatchedSitesTitle,
          trailing: TextButton(
            onPressed: _openWatchedDomainsEditor,
            child: Text(strings.commonEdit),
          ),
        ),
        FetchyCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _watchedDomains.isEmpty
              ? Text(
                  strings.quickFetchNoSitesWatched,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              // Domains are technical identifiers: shown as tonal tags in a
              // wrap rather than as a monospace column, which reads as data
              // the app is watching rather than as a config file.
              : Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: <Widget>[
                    for (final String domain in _watchedDomains)
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: FetchyTag(label: domain),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          strings.quickFetchWatchedSitesFooter,
          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// The Restricted Settings explanation, folded away behind a disclosure so
/// the main setup card stays a single clear action.
///
/// The wording never claims Restricted Settings *is* what happened — Android
/// does not tell an app that — and never claims every device words the menu
/// item identically.
class _RestrictedSettingsHelp extends StatefulWidget {
  const _RestrictedSettingsHelp({required this.showRestrictedGuidance});

  /// Whether to include the sideload-specific paragraph. False for a store
  /// install, where the restriction does not apply.
  final bool showRestrictedGuidance;

  @override
  State<_RestrictedSettingsHelp> createState() =>
      _RestrictedSettingsHelpState();
}

class _RestrictedSettingsHelpState extends State<_RestrictedSettingsHelp> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => setState(() => _expanded = !_expanded),
            icon: Icon(
              _expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 20,
            ),
            label: Text(strings.quickFetchHelpShow),
            style: TextButton.styleFrom(
              padding: const EdgeInsetsDirectional.only(
                start: AppSpacing.xs,
                end: AppSpacing.sm,
              ),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
        AnimatedSize(
          duration: AppMotion.medium,
          curve: Curves.easeOutCubic,
          alignment: AlignmentDirectional.topStart,
          child: !_expanded
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (widget.showRestrictedGuidance) ...<Widget>[
                        Text(
                          strings.quickFetchRestrictedHelpTitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          strings.quickFetchRestrictedHelpBody,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      Text(
                        strings.quickFetchRestrictedHelpNote,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

enum _Severity { ok, warning, error }

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.icon,
    required this.severity,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final _Severity severity;
  final String title;
  final String message;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final FetchyTokens tokens = FetchyTokens.of(context);

    // Severity reads from a coloured glyph on a neutral row rather than
    // from a fully tinted banner: these rows sit in a list where several
    // states can be visible at once, and three coloured blocks in a
    // column would be louder than the information warrants.
    final Color tint = switch (severity) {
      _Severity.ok => tokens.successFg,
      _Severity.warning => tokens.warningFg,
      _Severity.error => colorScheme.error,
    };

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 20, color: tint),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FetchyTonalButton(
                      label: actionLabel!,
                      expand: false,
                      height: 42,
                      emphasis: true,
                      onPressed: () => onAction!(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text, {this.last = false});

  final String text;

  /// The final bullet drops its trailing gap so the card's own padding is
  /// the only space below it.
  final bool last;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsetsDirectional.only(top: 7, end: AppSpacing.md),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary.withValues(alpha: 0.55),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
