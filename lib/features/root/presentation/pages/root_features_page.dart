import 'package:flutter/material.dart';

import '../../../../app/theme/app_dimens.dart';
import '../../../../app/widgets/fetchy_buttons.dart';
import '../../../../app/widgets/fetchy_rows.dart';
import '../../../../app/widgets/fetchy_surface.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../settings/presentation/widgets/settings_section.dart';
import '../../root_feature_flag.dart';
import '../../root_service.dart';
import '../../root_status.dart';

/// Settings → Advanced / Root Features.
///
/// Root is never required for normal Fetchy use, never checked at
/// startup, and never invoked silently — this page is the only place
/// [RootService.enable] is ever called, and only after the user explicitly
/// taps through the safety warning below.
///
/// The functional UI below is fully implemented but gated behind
/// [kRootFeaturesEnabled], currently `false` for the first release — see
/// that flag's doc for why. While disabled, [build] renders
/// [_RootComingSoonView] instead, and [initState] skips [_load] entirely so
/// no root status check ever runs.
///
/// No root-exclusive feature is implemented yet — see the four rows below,
/// each explicitly labeled with why it is deferred rather than half-built.
class RootFeaturesPage extends StatefulWidget {
  const RootFeaturesPage({super.key});

  @override
  State<RootFeaturesPage> createState() => _RootFeaturesPageState();
}

class _RootFeaturesPageState extends State<RootFeaturesPage> {
  final RootService _service = RootService.instance;

  RootStatus _status = RootStatus.unknown;
  bool _loading = true;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    if (kRootFeaturesEnabled) {
      _load();
    } else {
      _loading = false;
    }
  }

  Future<void> _load() async {
    // getStatus() only reads a cached value — it cannot trigger a root
    // grant prompt, so it is safe to call as soon as this page opens.
    final RootStatus status = await _service.getStatus();
    if (!mounted) return;
    setState(() {
      _status = status;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return FetchyScaffold(
      title: strings.rootFeaturesPageTitle,
      body: !kRootFeaturesEnabled
          ? const _RootComingSoonView()
          : _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.sm,
                AppSpacing.page,
                AppSpacing.hero,
              ),
              children: <Widget>[
                _buildStatusCard(context, strings),
                const SizedBox(height: AppSpacing.lg),
                _buildBypassNotice(context, strings),
                const SizedBox(height: AppSpacing.xxl),
                SettingsSection(
                  title: strings.rootFeaturesSectionTitle,
                  children: <Widget>[
                    _FeatureTile(
                      title: strings.rootFeaturesBrowserImportTitle,
                      reason: strings.rootFeaturesBrowserImportReason,
                    ),
                    _FeatureTile(
                      title: strings.rootFeaturesDiagnosticsTitle,
                      reason: strings.rootFeaturesDiagnosticsReason,
                    ),
                    _FeatureTile(
                      title: strings.rootFeaturesFileAccessTitle,
                      reason: strings.rootFeaturesFileAccessReason,
                    ),
                    _FeatureTile(
                      title: strings.rootFeaturesSessionImportTitle,
                      reason: strings.rootFeaturesSessionImportReason,
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildStatusCard(BuildContext context, AppLocalizations strings) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return FetchyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _statusLabel(_status, strings),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            strings.rootFeaturesAccessDescription,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          if (_status != RootStatus.available) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FetchyTonalButton(
                label: strings.rootFeaturesEnableButton,
                icon: Icons.lock_open_rounded,
                expand: false,
                emphasis: true,
                busy: _checking,
                onPressed: _checking ? null : _enableRootFeatures,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBypassNotice(BuildContext context, AppLocalizations strings) {
    return FetchyBanner(
      message: strings.rootFeaturesBypassNotice,
      tone: FetchyBannerTone.error,
      icon: Icons.gavel_rounded,
    );
  }

  String _statusLabel(RootStatus status, AppLocalizations strings) {
    switch (status) {
      case RootStatus.available:
        return strings.rootStatusAvailable;
      case RootStatus.unavailable:
        return strings.rootStatusUnavailable;
      case RootStatus.denied:
        return strings.rootStatusDenied;
      case RootStatus.unknown:
        return strings.rootStatusUnknown;
    }
  }

  Future<void> _enableRootFeatures() async {
    final AppLocalizations strings = AppLocalizations.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(strings.rootFeaturesEnableConfirmTitle),
        content: Text(strings.rootFeaturesAccessDescription),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.commonContinue),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _checking = true);
    final RootStatus status = await _service.enable();
    if (!mounted) return;
    setState(() {
      _status = status;
      _checking = false;
    });

    if (status != RootStatus.available && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_statusLabel(status, strings))),
      );
    }
  }
}

/// Shown instead of the functional Root Features UI while
/// [kRootFeaturesEnabled] is `false`. Deliberately non-actionable — no
/// "Enable", "Connect", or "Detect Root" control appears here, and nothing
/// on this screen touches [RootService].
class _RootComingSoonView extends StatelessWidget {
  const _RootComingSoonView();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: FetchyEmptyState(
          icon: Icons.terminal_rounded,
          title: strings.rootFeaturesTitle,
          message: strings.rootFeaturesDescription,
          action: FetchyTag(label: strings.rootFeaturesComingSoonTag),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.title, required this.reason});

  final String title;
  final String reason;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);

    return FetchyListRow(
      leading: const FetchyLeadingIcon(icon: Icons.block_rounded),
      title: title,
      subtitle: strings.rootFeaturesNotBuiltYet(reason),
      // Each of these is deliberately non-actionable: nothing here is
      // built yet, so nothing here is tappable.
      enabled: false,
    );
  }
}
