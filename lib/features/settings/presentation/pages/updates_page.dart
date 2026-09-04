import 'dart:async';

import 'package:flutter/material.dart';
// Prefixed: package:intl exports its own TextDirection, which would
// otherwise shadow Flutter's and break the LTR version labels below.
import 'package:intl/intl.dart' as intl;

import '../../../../app/theme/app_dimens.dart';
import '../../../../app/widgets/fetchy_buttons.dart';
import '../../../../app/widgets/fetchy_progress.dart';
import '../../../../app/widgets/fetchy_rows.dart';
import '../../../../app/widgets/fetchy_surface.dart';
import '../../../../core/platform/file_action_service.dart';
import '../../../../core/update/app_version.dart';
import '../../../../core/update/release_notes.dart';
import '../../../../core/update/update_installer.dart';
import '../../../../core/update/update_models.dart';
import '../../../../core/update/update_service.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../history/format_helpers.dart';

/// Settings → About → Updates: the only screen that checks GitHub for a
/// newer Fetchy, downloads it, and hands it to Android's installer.
///
/// Every state the flow can be in is rendered here and nowhere else, and
/// the installation itself is always the user's explicit decision — this
/// screen can only ever open the system installer, never install anything.
class UpdatesPage extends StatefulWidget {
  const UpdatesPage({super.key, this.service});

  /// Injectable so the screen can be driven with a fake service in tests.
  final UpdateService? service;

  @override
  State<UpdatesPage> createState() => _UpdatesPageState();
}

enum _Phase {
  idle,
  checking,
  upToDate,
  available,
  noApk,
  downloading,
  readyToInstall,
  permissionRequired,
  failed,
}

class _UpdatesPageState extends State<UpdatesPage> {
  late final UpdateService _service = widget.service ?? UpdateService.instance;

  _Phase _phase = _Phase.idle;
  InstalledAppVersion? _installed;
  UpdateAvailable? _update;
  UpdateNoCompatibleAsset? _noApk;
  AppVersion? _latestSeen;
  UpdateFailureReason? _checkFailure;
  UpdateInstallFailure? _installFailure;

  UpdateDownloadProgress? _progress;
  StreamSubscription<UpdateDownloadProgress>? _progressSubscription;
  String? _downloadedApkPath;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    super.dispose();
  }

  /// Adopts whatever the silent startup check already found, so opening
  /// this screen right after launch shows the answer immediately instead
  /// of asking GitHub a second time.
  Future<void> _restore() async {
    final InstalledAppVersion? installed = await _service.installedVersion();
    if (!mounted) return;

    setState(() => _installed = installed);

    final UpdateCheckOutcome? cached = _service.latestOutcome.value;
    if (cached != null) _applyOutcome(cached);
  }

  Future<void> _check() async {
    setState(() {
      _phase = _Phase.checking;
      _checkFailure = null;
      _installFailure = null;
      _update = null;
      _noApk = null;
      _downloadedApkPath = null;
      _progress = null;
    });

    // A manual check always bypasses the automatic-check cooldown.
    final UpdateCheckOutcome outcome = await _service.check(manual: true);
    if (!mounted) return;
    _applyOutcome(outcome);
  }

  void _applyOutcome(UpdateCheckOutcome outcome) {
    setState(() {
      switch (outcome) {
        case UpdateUpToDate(:final InstalledAppVersion installed, :final AppVersion? latestVersion):
          _phase = _Phase.upToDate;
          _installed = installed;
          _latestSeen = latestVersion;
        case UpdateAvailable():
          _phase = _Phase.available;
          _installed = outcome.installed;
          _update = outcome;
          _latestSeen = outcome.newVersion;
        case UpdateNoCompatibleAsset():
          _phase = _Phase.noApk;
          _installed = outcome.installed;
          _noApk = outcome;
          _latestSeen = outcome.newVersion;
        case UpdateCheckFailed(:final UpdateFailureReason reason, :final InstalledAppVersion? installed):
          _phase = _Phase.failed;
          _checkFailure = reason;
          if (installed != null) _installed = installed;
      }
    });
  }

  Future<void> _download() async {
    final UpdateAvailable? update = _update;
    if (update == null) return;

    setState(() {
      _phase = _Phase.downloading;
      _progress = null;
      _installFailure = null;
    });

    _progressSubscription?.cancel();
    _progressSubscription = _service.installer.downloadProgress.listen((
      UpdateDownloadProgress progress,
    ) {
      if (!mounted) return;
      setState(() => _progress = progress);
    });

    try {
      final String path = await _service.installer.downloadApk(
        url: update.apkAsset.downloadUrl,
        fileName: update.apkAsset.name,
        expectedSizeBytes: update.apkAsset.sizeBytes,
      );
      if (!mounted) return;
      setState(() {
        _downloadedApkPath = path;
        _phase = _Phase.readyToInstall;
      });
    } on UpdateInstallException catch (error) {
      if (!mounted) return;
      setState(() {
        _installFailure = error.failure;
        // A canceled download returns the user to the offer, not to an
        // error screen — they chose to stop.
        _phase = error.failure == UpdateInstallFailure.canceled
            ? _Phase.available
            : _Phase.failed;
      });
    } finally {
      await _progressSubscription?.cancel();
      _progressSubscription = null;
    }
  }

  Future<void> _cancelDownload() async {
    await _service.installer.cancelDownload();
  }

  /// Never installs anything: it verifies the file natively and then opens
  /// Android's package installer, which the user must confirm.
  Future<void> _install() async {
    final String? path = _downloadedApkPath;
    if (path == null) return;

    final bool allowed = await _service.installer.canRequestPackageInstalls();
    if (!mounted) return;

    if (!allowed) {
      setState(() => _phase = _Phase.permissionRequired);
      return;
    }

    try {
      await _service.installer.verifyAndLaunchInstaller(path);
    } on UpdateInstallException catch (error) {
      if (!mounted) return;
      setState(() {
        _installFailure = error.failure;
        _phase = error.failure == UpdateInstallFailure.permissionRequired
            ? _Phase.permissionRequired
            : _Phase.failed;
      });
    }
  }

  Future<void> _openPermissionSettings() async {
    await _service.installer.openInstallPermissionSettings();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);

    return FetchyScaffold(
      title: strings.updatesTitle,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.sm,
          AppSpacing.page,
          100,
        ),
        children: <Widget>[
          _buildVersionCard(strings),
          const SizedBox(height: AppSpacing.xxl),
          ..._buildStateSection(strings),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            strings.updatesPrivacyNote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionCard(AppLocalizations strings) {
    final InstalledAppVersion? installed = _installed;
    final bool busy = _phase == _Phase.checking;

    return FetchyGroup(
      children: <Widget>[
        FetchyListRow(
          leading: const FetchyLeadingIcon(icon: Icons.tag_rounded),
          title: strings.updatesCurrentVersionLabel,
          // A version is a technical identifier and stays left-to-right
          // even when the interface is Arabic.
          trailing: Text(
            installed?.versionName ?? strings.updatesNeverChecked,
            textDirection: TextDirection.ltr,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (_latestSeen != null && _phase != _Phase.checking)
          FetchyListRow(
            leading: const FetchyLeadingIcon(icon: Icons.new_releases_outlined),
            title: strings.updatesNewVersionLabel,
            trailing: Text(
              _latestSeen!.displayName,
              textDirection: TextDirection.ltr,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FetchyTonalButton(
              label: strings.updatesCheckAction,
              icon: Icons.sync_rounded,
              expand: false,
              height: 44,
              busy: busy,
              onPressed: (busy || _phase == _Phase.downloading) ? null : _check,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildStateSection(AppLocalizations strings) {
    switch (_phase) {
      case _Phase.idle:
        return <Widget>[
          FetchyBanner(
            message: strings.updatesLastCheckedNever,
            icon: Icons.schedule_rounded,
          ),
        ];

      case _Phase.checking:
        return <Widget>[
          FetchyBanner(
            message: strings.updatesCheckingStatus,
            icon: Icons.sync_rounded,
          ),
        ];

      case _Phase.upToDate:
        return <Widget>[
          FetchyBanner(
            title: strings.updatesUpToDateTitle,
            message: strings.updatesUpToDateBody(
              _installed?.versionName ?? '',
            ),
            icon: Icons.check_circle_outline_rounded,
            tone: FetchyBannerTone.success,
          ),
        ];

      case _Phase.available:
        return _buildUpdateOffer(strings);

      case _Phase.noApk:
        return <Widget>[
          FetchyBanner(
            title: strings.updatesNoApkTitle,
            message: strings.updatesNoApkBody(
              _noApk?.newVersion.displayName ?? '',
            ),
            icon: Icons.inventory_2_outlined,
            tone: FetchyBannerTone.warning,
            action: _buildGithubLinkButton(strings, _noApk?.release.htmlUrl),
          ),
        ];

      case _Phase.downloading:
        return _buildDownloading(strings);

      case _Phase.readyToInstall:
        return <Widget>[
          FetchyBanner(
            title: strings.updatesReadyTitle,
            message: strings.updatesReadyBody(
              _update?.newVersion.displayName ?? '',
            ),
            icon: Icons.download_done_rounded,
            tone: FetchyBannerTone.success,
          ),
          const SizedBox(height: AppSpacing.lg),
          FetchyPrimaryButton(
            label: strings.updatesInstallAction,
            icon: Icons.install_mobile_rounded,
            onPressed: _install,
          ),
        ];

      case _Phase.permissionRequired:
        return <Widget>[
          FetchyBanner(
            title: strings.updatesPermissionTitle,
            message: strings.updatesPermissionBody,
            icon: Icons.shield_outlined,
            tone: FetchyBannerTone.warning,
          ),
          const SizedBox(height: AppSpacing.lg),
          FetchyTonalButton(
            label: strings.updatesOpenAndroidSettingsAction,
            icon: Icons.settings_outlined,
            emphasis: true,
            onPressed: _openPermissionSettings,
          ),
          const SizedBox(height: AppSpacing.sm),
          FetchyTonalButton(
            label: strings.updatesContinueInstallAction,
            icon: Icons.arrow_forward_rounded,
            onPressed: _install,
          ),
        ];

      case _Phase.failed:
        return _buildFailure(strings);
    }
  }

  List<Widget> _buildUpdateOffer(AppLocalizations strings) {
    final UpdateAvailable? update = _update;
    if (update == null) return const <Widget>[];

    final ThemeData theme = Theme.of(context);
    final List<ReleaseNoteLine> notes = parseReleaseNotes(update.releaseNotes);
    final int? size = update.apkAsset.sizeBytes;
    final DateTime? published = update.release.publishedAt;

    return <Widget>[
      FetchyBanner(
        title: strings.updatesAvailableTitle,
        message: strings.updatesAvailableBody(update.newVersion.displayName),
        icon: Icons.system_update_rounded,
        tone: FetchyBannerTone.info,
      ),
      const SizedBox(height: AppSpacing.lg),
      FetchyCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              update.releaseTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (published != null) ...<Widget>[
              const SizedBox(height: 2),
              Text(
                strings.updatesPublishedOn(
                  intl.DateFormat.yMMMd(
                    Localizations.localeOf(context).toLanguageTag(),
                  ).format(published.toLocal()),
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (size != null) ...<Widget>[
              const SizedBox(height: 2),
              Text(
                strings.updatesDownloadSize(formatFileSize(size)),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text(
              strings.updatesReleaseNotesTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (notes.isEmpty)
              Text(
                strings.updatesNoReleaseNotes,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              _ReleaseNotesBody(lines: notes),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      FetchyPrimaryButton(
        label: strings.updatesDownloadAction,
        icon: Icons.download_rounded,
        onPressed: _download,
      ),
    ];
  }

  List<Widget> _buildDownloading(AppLocalizations strings) {
    final ThemeData theme = Theme.of(context);
    final UpdateDownloadProgress? progress = _progress;
    final int? total = progress?.totalBytes;

    return <Widget>[
      FetchyCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              strings.updatesDownloadingStatus,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FetchyProgressBar(value: progress?.fraction),
            if (progress != null && total != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(
                strings.updatesDownloadedAmount(
                  formatFileSize(progress.receivedBytes),
                  formatFileSize(total),
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      FetchyTonalButton(
        label: strings.updatesDownloadCancelAction,
        icon: Icons.close_rounded,
        onPressed: _cancelDownload,
      ),
    ];
  }

  List<Widget> _buildFailure(AppLocalizations strings) {
    final UpdateInstallFailure? installFailure = _installFailure;
    final UpdateFailureReason? checkFailure = _checkFailure;

    final bool githubProblem =
        checkFailure == UpdateFailureReason.noNetwork ||
        checkFailure == UpdateFailureReason.timeout ||
        checkFailure == UpdateFailureReason.rateLimited ||
        checkFailure == UpdateFailureReason.httpError ||
        checkFailure == UpdateFailureReason.malformedResponse;

    final String title = githubProblem
        ? strings.updatesGithubUnavailableTitle
        : strings.updatesFailedTitle;

    final String message = installFailure != null
        ? _installFailureMessage(installFailure, strings)
        : _checkFailureMessage(checkFailure, strings);

    return <Widget>[
      FetchyBanner(
        title: title,
        message: message,
        icon: Icons.error_outline_rounded,
        tone: FetchyBannerTone.error,
      ),
      const SizedBox(height: AppSpacing.lg),
      FetchyTonalButton(
        label: strings.commonRetry,
        icon: Icons.refresh_rounded,
        expand: false,
        onPressed: _check,
      ),
    ];
  }

  Widget? _buildGithubLinkButton(AppLocalizations strings, String? url) {
    if (url == null || url.isEmpty) return null;
    return FetchyTonalButton(
      label: strings.updatesViewOnGithubAction,
      icon: Icons.open_in_new_rounded,
      expand: false,
      height: 40,
      onPressed: () => _openReleasePage(url),
    );
  }

  /// Reuses the existing "open an upstream https link in the browser"
  /// path — the same one Technical information already uses.
  Future<void> _openReleasePage(String url) async {
    await FileActionService.instance.openExternalUrl(url);
  }

  String _checkFailureMessage(
    UpdateFailureReason? reason,
    AppLocalizations strings,
  ) {
    switch (reason) {
      case UpdateFailureReason.notConfigured:
        return strings.updatesErrorNotConfigured;
      case UpdateFailureReason.noNetwork:
        return strings.updatesErrorNoNetwork;
      case UpdateFailureReason.timeout:
        return strings.updatesErrorTimeout;
      case UpdateFailureReason.rateLimited:
        return strings.updatesErrorRateLimited;
      case UpdateFailureReason.httpError:
        return strings.updatesErrorHttp;
      case UpdateFailureReason.malformedResponse:
        return strings.updatesErrorMalformed;
      case UpdateFailureReason.noRelease:
        return strings.updatesErrorNoRelease;
      case UpdateFailureReason.unknown:
      case null:
        return strings.updatesErrorUnknown;
    }
  }

  String _installFailureMessage(
    UpdateInstallFailure failure,
    AppLocalizations strings,
  ) {
    switch (failure) {
      case UpdateInstallFailure.packageMismatch:
        return strings.updatesInstallErrorPackageMismatch;
      case UpdateInstallFailure.notNewer:
        return strings.updatesInstallErrorNotNewer;
      case UpdateInstallFailure.signatureMismatch:
        return strings.updatesInstallErrorSignature;
      case UpdateInstallFailure.corruptDownload:
        return strings.updatesInstallErrorCorrupt;
      case UpdateInstallFailure.permissionRequired:
        return strings.updatesPermissionBody;
      case UpdateInstallFailure.downloadFailed:
        return strings.updatesInstallErrorDownloadFailed;
      case UpdateInstallFailure.canceled:
        return strings.updatesInstallErrorCanceled;
      case UpdateInstallFailure.unknown:
        return strings.updatesInstallErrorUnknown;
    }
  }
}

/// Sanitized release notes: plain text lines only, no links, no images, no
/// embedded HTML — see `parseReleaseNotes`.
class _ReleaseNotesBody extends StatelessWidget {
  const _ReleaseNotesBody({required this.lines});

  final List<ReleaseNoteLine> lines;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final ReleaseNoteLine line in lines)
          Padding(
            padding: EdgeInsetsDirectional.only(
              bottom: AppSpacing.xs,
              top: line.kind == ReleaseNoteLineKind.heading ? AppSpacing.sm : 0,
            ),
            child: switch (line.kind) {
              ReleaseNoteLineKind.heading => Text(
                line.text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              // The marker is a leading widget rather than part of the
              // string, so it sits on the correct side in Arabic.
              ReleaseNoteLineKind.bullet => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: AppSpacing.sm,
                    ),
                    child: Text(
                      '•',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(line.text, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
              ReleaseNoteLineKind.paragraph => Text(
                line.text,
                style: theme.textTheme.bodyMedium,
              ),
            },
          ),
      ],
    );
  }
}
