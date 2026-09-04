import 'package:flutter/material.dart';

import '../../../../app/theme/app_dimens.dart';
import '../../../../app/widgets/fetchy_buttons.dart';
import '../../../../app/widgets/fetchy_rows.dart';
import '../../../../app/widgets/fetchy_selectors.dart';
import '../../../../app/widgets/fetchy_sheet.dart';
import '../../../../app/widgets/fetchy_surface.dart';
import '../../../../core/settings/app_settings_service.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../settings/presentation/widgets/settings_section.dart';
import '../../custom_cookie_service.dart';
import '../../custom_cookie_site.dart';
import '../../platform_session.dart';
import '../../session_service.dart';
import '../widgets/session_warning_dialog.dart';

/// Settings → Connected Accounts/Sessions. Phase 1: a generic, local,
/// encrypted session store with cookies.txt import (Advanced). In-app
/// sign-in (Easy) and browser/device import (Expert) are shown as
/// capability-detected, not implemented — see [SessionConnectCapabilities].
class ConnectedAccountsPage extends StatefulWidget {
  const ConnectedAccountsPage({super.key});

  @override
  State<ConnectedAccountsPage> createState() => _ConnectedAccountsPageState();
}

class _ConnectedAccountsPageState extends State<ConnectedAccountsPage> {
  final SessionService _service = SessionService.instance;
  final CustomCookieService _customCookies = CustomCookieService.instance;
  final AppSettingsService _settings = AppSettingsService.instance;

  SessionConnectCapabilities? _capabilities;
  Map<SessionPlatform, PlatformSession> _sessions =
      <SessionPlatform, PlatformSession>{};
  List<CustomCookieSite> _customSites = const <CustomCookieSite>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final SessionConnectCapabilities capabilities = await _service
        .getCapabilities();
    final List<PlatformSession> sessions = await _service.listSessions();
    final List<CustomCookieSite> customSites = await _customCookies.listSites();

    if (!mounted) return;
    setState(() {
      _capabilities = capabilities;
      _sessions = <SessionPlatform, PlatformSession>{
        for (final PlatformSession session in sessions)
          session.platform: session,
      };
      _customSites = customSites;
      _loading = false;
    });
  }

  PlatformSession _sessionFor(SessionPlatform platform) {
    return _sessions[platform] ??
        PlatformSession(platform: platform, status: SessionStatus.notConnected);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return FetchyScaffold(
      title: strings.sessionsPageTitle,
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.sm,
                AppSpacing.page,
                AppSpacing.hero,
              ),
              children: <Widget>[
                _buildPrivacyNotice(context, strings),
                const SizedBox(height: AppSpacing.xxl),
                SettingsSection(
                  title: strings.sessionsPlatformsSection,
                  children: SessionPlatform.values
                      .map((SessionPlatform p) => _buildPlatformTile(p, strings))
                      .toList(growable: false),
                ),
                const SizedBox(height: AppSpacing.xxl),
                _buildCustomSitesSection(strings),
              ],
            ),
    );
  }

  /// General Cookie Manager: cookies for arbitrary websites beyond the
  /// four built-in platforms above. Same encrypted local store, same
  /// Netscape cookie parser, same "on-device only" model — an extension of
  /// Connected Accounts, not a separate system.
  Widget _buildCustomSitesSection(AppLocalizations strings) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return SettingsSection(
      title: strings.sessionsOtherSitesSection,
      children: <Widget>[
        if (_customSites.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Text(
              strings.sessionsNoCustomSites,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (final CustomCookieSite site in _customSites)
            FetchyListRow(
              leading: const FetchyLeadingIcon(
                icon: Icons.public_rounded,
                emphasis: true,
              ),
              // A domain is a technical identifier and stays
              // left-to-right in every locale.
              titleTextDirection: TextDirection.ltr,
              title: site.domain,
              subtitle: site.metadata ?? strings.sessionsConnected,
              trailing: FetchyIconButton(
                icon: Icons.delete_outline_rounded,
                tooltip: strings.commonRemove,
                size: 36,
                iconSize: 18,
                onPressed: () => _removeCustomSite(site.domain),
              ),
            ),
        FetchyListRow(
          leading: FetchyLeadingIcon(
            icon: Icons.add_rounded,
            emphasis: true,
          ),
          title: strings.sessionsAddCookiesForOtherSites,
          onTap: _addCustomSite,
          showChevron: true,
        ),
      ],
    );
  }

  Future<void> _removeCustomSite(String domain) async {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(strings.sessionsRemoveSiteConfirmTitle(domain)),
        content: Text(strings.sessionsRemoveSiteConfirmBody),
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
            child: Text(strings.commonRemove),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _customCookies.removeSite(domain);
    await _load();
  }

  /// Website -> cookie source flow: asks for the site first, then which
  /// way to bring cookies in. Kept as two short steps rather than one
  /// dense form, matching the rest of this page's per-action sheets.
  Future<void> _addCustomSite() async {
    if (!await _ensureWarningAcknowledged()) return;

    final String? website = await _promptForWebsite();
    if (website == null || website.trim().isEmpty) return;

    if (!mounted) return;
    final _CookieSourceChoice? choice = await showFetchySheet<_CookieSourceChoice>(
      context,
      builder: (BuildContext context) => _CookieSourceSheet(website: website.trim()),
    );
    if (choice == null) return;

    switch (choice) {
      case _CookieSourceChoice.file:
        await _importCustomCookiesFile(website.trim());
      case _CookieSourceChoice.paste:
        await _importCustomCookiesPasted(website.trim());
    }
  }

  Future<String?> _promptForWebsite() {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(strings.sessionsAddCookiesDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(strings.sessionsEnterWebsite),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: strings.sessionsWebsiteLabel,
                hintText: strings.sessionsWebsiteHint,
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(strings.commonNext),
          ),
        ],
      ),
    );
  }

  Future<void> _importCustomCookiesFile(String website) async {
    final AppLocalizations strings = AppLocalizations.of(context);
    try {
      final CustomCookieSite? site = await _customCookies
          .pickAndImportCookiesFile(website, strings);
      if (site == null) return; // user canceled the picker

      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${strings.sessionsCookiesImportedMessage(site.domain)}'
            '${site.metadata != null ? ' ${site.metadata}' : ''}',
          ),
        ),
      );
    } on InvalidCookieFileError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.sessionsCouldNotImportCookies)),
      );
    }
  }

  Future<void> _importCustomCookiesPasted(String website) async {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextEditingController controller = TextEditingController();
    final String? pasted = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(strings.sessionsPasteCookiesForWebsite(website)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(strings.sessionsPasteCookiesHelp),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 8,
              minLines: 4,
              decoration: InputDecoration(
                hintText: strings.sessionsCookieFileHint,
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(strings.commonImport),
          ),
        ],
      ),
    );
    if (pasted == null || pasted.trim().isEmpty) return;

    try {
      final CustomCookieSite site = await _customCookies.importCookiesText(
        domain: website,
        cookiesText: pasted,
        strings: strings,
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${strings.sessionsCookiesImportedMessage(site.domain)}'
            '${site.metadata != null ? ' ${site.metadata}' : ''}',
          ),
        ),
      );
    } on InvalidCookieFileError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.sessionsCouldNotImportCookies)),
      );
    }
  }

  Widget _buildPrivacyNotice(BuildContext context, AppLocalizations strings) {
    return FetchyBanner(
      message: strings.sessionsPrivacyNotice,
      icon: Icons.shield_outlined,
    );
  }

  Widget _buildPlatformTile(SessionPlatform platform, AppLocalizations strings) {
    final PlatformSession session = _sessionFor(platform);

    return FetchyListRow(
      leading: FetchyLeadingIcon(
        icon: _iconFor(platform),
        // The tint is the connection state: a connected platform is
        // brand-coloured, an unconnected one stays neutral.
        emphasis: session.isConnected,
      ),
      title: platform.displayName,
      subtitle: _statusLabel(platform, session.status, strings),
      showChevron: true,
      onTap: () => _openPlatformSheet(platform),
    );
  }

  IconData _iconFor(SessionPlatform platform) {
    switch (platform) {
      case SessionPlatform.youtube:
        return Icons.smart_display_outlined;
      case SessionPlatform.tiktok:
        return Icons.music_note_outlined;
      case SessionPlatform.x:
        return Icons.alternate_email_rounded;
      case SessionPlatform.instagram:
        return Icons.camera_alt_outlined;
    }
  }

  /// X's browser login never produces a usable session (see
  /// `SessionsChannelHandler.openCustomTabLogin`) — cookies.txt import is
  /// the only real path there, so an unconnected X session is framed as
  /// "Session import required" rather than the generic "Not connected"
  /// used by the other platforms.
  String _statusLabel(SessionPlatform platform, SessionStatus status, AppLocalizations strings) {
    if (status == SessionStatus.notConnected && platform == SessionPlatform.x) {
      return strings.sessionsStatusImportRequired;
    }
    switch (status) {
      case SessionStatus.sessionImported:
        return strings.sessionsStatusConnected;
      case SessionStatus.sessionUsable:
        return strings.sessionsStatusConnectedWorks;
      case SessionStatus.unknown:
        return strings.sessionsStatusConnectedUnverified;
      case SessionStatus.sessionExpired:
        return strings.sessionsStatusExpired;
      case SessionStatus.sessionInvalid:
        return strings.sessionsStatusInvalid;
      case SessionStatus.notConnected:
        return strings.sessionsStatusNotConnected;
    }
  }

  Future<void> _openPlatformSheet(SessionPlatform platform) async {
    await showFetchySheet<void>(
      context,
      builder: (BuildContext sheetContext) {
        return _PlatformSessionSheet(
          platform: platform,
          session: _sessionFor(platform),
          capabilities: _capabilities,
          onEasyConnect: () async {
            Navigator.of(sheetContext).pop();
            await _easyConnect(platform);
          },
          onImportCookies: () async {
            Navigator.of(sheetContext).pop();
            await _importCookies(platform);
          },
          onTestConnection: () async {
            Navigator.of(sheetContext).pop();
            await _testConnection(platform);
          },
          onExport: () async {
            Navigator.of(sheetContext).pop();
            await _exportSession(platform);
          },
          onRemove: () async {
            Navigator.of(sheetContext).pop();
            await _removeSession(platform);
          },
        );
      },
    );
  }

  /// Ensures the user has seen the session warning at least once before
  /// any connection method (Easy or Advanced) proceeds. Returns false if
  /// they canceled.
  Future<bool> _ensureWarningAcknowledged() async {
    final bool acknowledged = await _settings.loadSessionWarningAcknowledged();
    if (acknowledged) return true;
    if (!mounted) return false;
    final bool continueImport = await showSessionWarningDialog(context);
    if (!continueImport) return false;
    await _settings.saveSessionWarningAcknowledged(true);
    return true;
  }

  /// Starts Easy Connect for [platform]. The mechanism is chosen natively
  /// per platform (see `SessionService.openBrowserLogin`): a WebView that
  /// genuinely captures a session for YouTube/Instagram/TikTok, or a
  /// Custom Tab for X that never can. Either way, this only ever reports
  /// what actually happened — a non-null [PlatformSession] means a real
  /// session now exists; null means it doesn't, regardless of what the
  /// user did in the browser, and the honest next step (Advanced) is
  /// offered instead of a claim Fetchy can't back up.
  Future<void> _easyConnect(SessionPlatform platform) async {
    if (!await _ensureWarningAcknowledged()) return;
    if (!mounted) return;
    final AppLocalizations strings = AppLocalizations.of(context);

    PlatformSession? session;
    try {
      session = await _service.openBrowserLogin(platform);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.sessionsCouldNotOpenBrowser)),
      );
      return;
    }

    if (!mounted) return;

    if (session != null) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${strings.sessionsSessionConnectedMessage(platform.displayName)}'
            '${session.metadata != null ? ' ${session.metadata}' : ''}',
          ),
        ),
      );
      return;
    }

    final bool? importNow = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(strings.sessionsBrowserUnconfirmedTitle),
        content: Text(strings.sessionsBrowserUnconfirmedBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.sessionsNotNow),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.sessionsImportCookiesNow),
          ),
        ],
      ),
    );

    if (importNow == true) {
      await _importCookies(platform);
    }
  }

  Future<void> _importCookies(SessionPlatform platform) async {
    if (!await _ensureWarningAcknowledged()) return;
    if (!mounted) return;
    final AppLocalizations strings = AppLocalizations.of(context);

    try {
      final PlatformSession? session = await _service.pickAndImportCookiesFile(
        platform,
        strings,
      );
      if (session == null) return; // user canceled the picker

      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${strings.sessionsSessionImportedMessage(platform.displayName)}'
            '${session.metadata != null ? ' ${session.metadata}' : ''}',
          ),
        ),
      );
    } on InvalidCookieFileError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.sessionsCouldNotImportSession)),
      );
    }
  }

  /// Runs the real extraction pipeline against a link the user supplies,
  /// with this platform's stored cookies attached — see
  /// `SessionService.testConnection` for why this never invents a "Valid"
  /// result.
  Future<void> _testConnection(SessionPlatform platform) async {
    final AppLocalizations strings = AppLocalizations.of(context);
    final String? url = await _promptForTestUrl(platform);
    if (url == null || url.trim().isEmpty) return;

    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final TestConnectionResult result = await _service.testConnection(
        platform,
        url.trim(),
        strings,
      );
      if (!mounted) return;
      Navigator.of(context).pop(); // close the progress dialog
      await _load();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text(strings.sessionsTestConnectionResultTitle(platform.displayName)),
          content: Text(result.message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings.commonOk),
            ),
          ],
        ),
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.sessionsCouldNotCompleteTest)),
      );
    }
  }

  Future<String?> _promptForTestUrl(SessionPlatform platform) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(strings.sessionsTestConnectionTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(strings.sessionsTestUrlPrompt(platform.displayName)),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: strings.sessionsUrlHint,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(strings.commonTest),
          ),
        ],
      ),
    );
  }

  Future<void> _exportSession(SessionPlatform platform) async {
    final AppLocalizations strings = AppLocalizations.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(strings.sessionsExportSessionTitle),
        content: Text(strings.sessionsExportSessionBody),
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

    try {
      final bool exported = await _service.exportSession(platform);
      if (!mounted || !exported) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.sessionsSessionExported)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.sessionsCouldNotExportSession)),
      );
    }
  }

  Future<void> _removeSession(SessionPlatform platform) async {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(strings.sessionsRemoveSessionConfirmTitle(platform.displayName)),
        content: Text(strings.sessionsRemoveSessionConfirmBody),
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
            child: Text(strings.commonRemove),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _service.removeSession(platform);
    await _load();
  }
}

class _PlatformSessionSheet extends StatelessWidget {
  const _PlatformSessionSheet({
    required this.platform,
    required this.session,
    required this.capabilities,
    required this.onEasyConnect,
    required this.onImportCookies,
    required this.onTestConnection,
    required this.onExport,
    required this.onRemove,
  });

  final SessionPlatform platform;
  final PlatformSession session;
  final SessionConnectCapabilities? capabilities;
  final VoidCallback onEasyConnect;
  final VoidCallback onImportCookies;
  final VoidCallback onTestConnection;
  final VoidCallback onExport;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final SessionConnectCapabilities caps =
        capabilities ??
        const SessionConnectCapabilities(
          easy: false,
          advanced: false,
          expert: false,
        );

    return FetchySheet(
      title: platform.displayName,
      titleTrailing: Wrap(
        spacing: AppSpacing.sm,
        children: <Widget>[
          if (platform == SessionPlatform.tiktok)
            FetchyTag(
              label: strings.sessionsExperimentalTag,
              background: colorScheme.tertiaryContainer,
              foreground: colorScheme.onTertiaryContainer,
            ),
          if (platform == SessionPlatform.x && !session.isConnected)
            FetchyTag(
              label: strings.sessionsImportRequiredTag,
              background: colorScheme.secondaryContainer,
              foreground: colorScheme.onSecondaryContainer,
            ),
        ],
      ),
      subtitle: session.isConnected
          ? (session.metadata ?? strings.sessionsConnected)
          : (platform == SessionPlatform.x
                ? strings.sessionsXBlocksInAppBrowser
                : strings.sessionsNotConnected),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (platform == SessionPlatform.x) ...<Widget>[
            _LevelTile(
              title: strings.sessionsImportCookiesTxtTitle,
              subtitle: caps.advanced
                  ? strings.sessionsImportCookiesTxtSubtitleAvailable
                  : caps.advancedReason ?? strings.commonNotAvailableOnDevice,
              icon: Icons.upload_file_outlined,
              enabled: caps.advanced,
              emphasized: true,
              onTap: caps.advanced ? onImportCookies : null,
            ),
            _LevelTile(
              title: strings.sessionsOpenInBrowserTitle,
              subtitle: strings.sessionsOpenInBrowserSubtitle,
              icon: Icons.open_in_browser_rounded,
              enabled: caps.easy,
              onTap: caps.easy ? onEasyConnect : null,
            ),
          ] else ...<Widget>[
            _LevelTile(
              title: platform == SessionPlatform.tiktok
                  ? strings.sessionsSignInBrowserTitleExperimental
                  : strings.sessionsSignInBrowserTitle,
              subtitle: platform == SessionPlatform.tiktok
                  ? strings.sessionsSignInTikTokRedirectWarning
                  : caps.easyReason ??
                        strings.sessionsSignInGenericSubtitle(platform.displayName),
              icon: Icons.open_in_browser_rounded,
              enabled: caps.easy,
              onTap: caps.easy ? onEasyConnect : null,
            ),
            _LevelTile(
              title: strings.sessionsImportCookiesFileTitle,
              subtitle: caps.advanced
                  ? strings.sessionsImportCookiesFileSubtitle
                  : caps.advancedReason ?? strings.commonNotAvailableOnDevice,
              icon: Icons.upload_file_outlined,
              enabled: caps.advanced,
              onTap: caps.advanced ? onImportCookies : null,
            ),
          ],
          _LevelTile(
            title: strings.sessionsRootAssistedTitle,
            subtitle: strings.sessionsRootAssistedSubtitle(platform.displayName),
            icon: Icons.phonelink_lock_outlined,
            enabled: false,
            onTap: null,
          ),
          _LevelTile(
            title: strings.sessionsTestConnectionTileTitle,
            subtitle: session.isConnected
                ? strings.sessionsTestConnectionAvailableSubtitle
                : strings.sessionsTestConnectionUnavailableSubtitle,
            icon: Icons.wifi_tethering_rounded,
            enabled: session.isConnected,
            onTap: session.isConnected ? onTestConnection : null,
          ),
          if (session.isConnected) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
            _LevelTile(
              title: strings.sessionsExportSessionTileTitle,
              subtitle: strings.sessionsExportSessionTileSubtitle,
              icon: Icons.ios_share_rounded,
              enabled: true,
              onTap: onExport,
            ),
            _LevelTile(
              title: strings.sessionsRemoveSessionTileTitle,
              subtitle: strings.sessionsRemoveSessionTileSubtitle,
              icon: Icons.delete_outline_rounded,
              enabled: true,
              destructive: true,
              onTap: onRemove,
            ),
          ],
        ],
      ),
    );
  }
}

/// One connection method in a session sheet.
///
/// Rendered as a soft tonal card rather than a bare list row, so the
/// recommended path for a given platform can be tinted without the others
/// looking broken, and a genuinely unavailable method reads as dimmed
/// rather than as missing.
class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.destructive = false,
    this.emphasized = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;
  final bool destructive;
  final bool emphasized;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FetchyActionTile(
      title: title,
      subtitle: subtitle,
      icon: icon,
      enabled: enabled,
      emphasis: emphasized,
      destructive: destructive,
      onTap: onTap,
    );
  }
}

enum _CookieSourceChoice { file, paste }

/// The second step of adding a custom site: how to bring its cookies in.
/// Kept to exactly the two options the General Cookie Manager actually
/// supports — no additional cookie-source UI beyond these.
class _CookieSourceSheet extends StatelessWidget {
  const _CookieSourceSheet({required this.website});

  final String website;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);

    return FetchySheet(
      title: strings.sessionsCookieSourceTitle,
      subtitle: strings.sessionsCookieSourcePrompt(website),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _LevelTile(
            title: strings.sessionsImportCookieFileTitle,
            subtitle: strings.sessionsImportCookieFileSubtitle,
            icon: Icons.upload_file_outlined,
            enabled: true,
            onTap: () => Navigator.of(context).pop(_CookieSourceChoice.file),
          ),
          _LevelTile(
            title: strings.sessionsPasteCookiesTitle,
            subtitle: strings.sessionsPasteCookiesSubtitle,
            icon: Icons.content_paste_outlined,
            enabled: true,
            onTap: () => Navigator.of(context).pop(_CookieSourceChoice.paste),
          ),
        ],
      ),
    );
  }
}
