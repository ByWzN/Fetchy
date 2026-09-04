import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_version.dart';
import 'github_release_client.dart';
import 'update_config.dart';
import 'update_installer.dart';
import 'update_models.dart';

/// Decides whether a newer Fetchy exists, and nothing else.
///
/// All the rules live here — draft/prerelease filtering, version
/// comparison, APK asset selection, and the automatic-check cooldown — so
/// they can be tested without a network, a device, or a widget. Fetching is
/// delegated to [GithubReleaseClient]; anything that only Android can do is
/// delegated to [UpdateInstaller].
///
/// This service is entirely self-contained: it shares no state with the
/// media downloader, the yt-dlp engine updater, sessions, or storage.
class UpdateService {
  UpdateService({
    GithubReleaseClient? client,
    UpdateInstaller? installer,
    DateTime Function()? now,
  }) : _client = client ?? const HttpGithubReleaseClient(),
       _installer = installer ?? PlatformUpdateInstaller.instance,
       _now = now ?? DateTime.now;

  static final UpdateService instance = UpdateService();

  final GithubReleaseClient _client;
  final UpdateInstaller _installer;
  final DateTime Function() _now;

  static const String _lastCheckKey = 'fetchy.update.lastCheckedAtMillis';

  UpdateInstaller get installer => _installer;

  /// The most recent outcome, so the Settings row can show "Update
  /// available" without repeating the network call. Null until the first
  /// check of this app run completes.
  final ValueNotifier<UpdateCheckOutcome?> latestOutcome =
      ValueNotifier<UpdateCheckOutcome?>(null);

  /// This build's real Android version. Cached for the app run — it cannot
  /// change while the process is alive.
  InstalledAppVersion? _installedCache;

  Future<InstalledAppVersion?> installedVersion() async {
    final InstalledAppVersion? cached = _installedCache;
    if (cached != null) return cached;

    final InstalledAppVersion? fresh = await _installer.installedVersion();
    _installedCache = fresh;
    return fresh;
  }

  /// The lightweight startup check.
  ///
  /// Returns null without touching the network when the cooldown has not
  /// elapsed, so navigating around the app — or restarting it repeatedly
  /// during a session — never produces a second request. It is deliberately
  /// silent: it only records the outcome for the Settings screen to show,
  /// and never raises a dialog.
  Future<UpdateCheckOutcome?> checkAutomatically() async {
    if (!await cooldownElapsed()) return null;
    return check(manual: false);
  }

  /// Runs a check. [manual] bypasses the cooldown entirely — the user
  /// pressing "Check for updates" always produces a real request.
  Future<UpdateCheckOutcome> check({required bool manual}) async {
    final InstalledAppVersion? installed = await installedVersion();

    // An unconfigured build is not special-cased here: the real client
    // refuses to send a request while the repository placeholders are in
    // place and reports UpdateFailureReason.notConfigured, which lands in
    // the catch below. Keeping the gate in one place means these rules stay
    // testable with a fake client.
    if (installed == null) {
      return _remember(
        const UpdateCheckFailed(UpdateFailureReason.unknown),
      );
    }

    try {
      final GithubRelease? release = await _client.fetchLatestRelease();
      // A successful round-trip restarts the cooldown even when the answer
      // is "you are up to date" — the point of the cooldown is to limit
      // requests, not to limit good news.
      await _recordCheckTime();

      if (release == null) {
        return _remember(
          UpdateCheckFailed(
            UpdateFailureReason.noRelease,
            installed: installed,
          ),
        );
      }

      return _remember(evaluate(release: release, installed: installed));
    } on UpdateCheckException catch (error) {
      return _remember(
        UpdateCheckFailed(error.reason, installed: installed),
      );
    }
  }

  /// The pure decision function: given a release and what is installed,
  /// what should the user be told? Exposed for testing.
  @visibleForTesting
  UpdateCheckOutcome evaluate({
    required GithubRelease release,
    required InstalledAppVersion installed,
  }) {
    // Drafts and prereleases are never offered. GitHub's "latest" endpoint
    // already excludes both, so this is a second, defensive gate rather
    // than the only one.
    if (!release.isPublishedStable) {
      return UpdateUpToDate(installed: installed);
    }

    final AppVersion? latest = release.version;
    if (latest == null) {
      // An unparseable tag is never assumed to be newer.
      return UpdateCheckFailed(
        UpdateFailureReason.malformedResponse,
        installed: installed,
      );
    }

    final AppVersion? current = installed.semantic;
    if (current == null) {
      return UpdateCheckFailed(
        UpdateFailureReason.unknown,
        installed: installed,
      );
    }

    // Semantic comparison, never a string comparison: "1.10.0" must win
    // over "1.9.0".
    if (latest <= current) {
      return UpdateUpToDate(installed: installed, latestVersion: latest);
    }

    // The monotonic Android safety check. A tag may carry the release's
    // versionCode as build metadata (`v1.2.3+4`, the same shape Flutter
    // already uses in pubspec.yaml). When it does, an update whose
    // versionCode is not strictly greater is refused here, before anything
    // is downloaded. When the tag does not carry one, this cannot be
    // decided yet and the identical check is enforced natively against the
    // downloaded APK's real versionCode before the installer is launched —
    // see AppUpdateChannelHandler.
    final int? declaredVersionCode = latest.buildNumber;
    if (declaredVersionCode != null &&
        declaredVersionCode <= installed.versionCode) {
      return UpdateUpToDate(installed: installed, latestVersion: latest);
    }

    final GithubReleaseAsset? apk = selectApkAsset(release.assets);
    if (apk == null) {
      return UpdateNoCompatibleAsset(
        installed: installed,
        newVersion: latest,
        release: release,
      );
    }

    return UpdateAvailable(
      installed: installed,
      newVersion: latest,
      release: release,
      apkAsset: apk,
    );
  }

  /// Picks the installable Android build out of everything attached to the
  /// release.
  ///
  /// Position is never trusted: GitHub appends two source archives to every
  /// release, and real releases also carry checksums and mapping files. An
  /// asset must both end in `.apk` and match
  /// [UpdateConfig.apkAssetPattern] to be considered, so a source archive
  /// can never be selected.
  @visibleForTesting
  static GithubReleaseAsset? selectApkAsset(List<GithubReleaseAsset> assets) {
    for (final GithubReleaseAsset asset in assets) {
      if (!asset.looksLikeApk) continue;
      if (!UpdateConfig.apkAssetPattern.hasMatch(asset.name)) continue;
      return asset;
    }
    return null;
  }

  UpdateCheckOutcome _remember(UpdateCheckOutcome outcome) {
    latestOutcome.value = outcome;
    return outcome;
  }

  /// Whether a full [UpdateConfig.autoCheckCooldown] has passed since the
  /// last successful check. Only the automatic check consults this — a
  /// manual check never does.
  @visibleForTesting
  Future<bool> cooldownElapsed() async {
    final int? last = await _readLastCheckMillis();
    if (last == null) return true;

    final DateTime lastChecked = DateTime.fromMillisecondsSinceEpoch(last);
    final Duration elapsed = _now().difference(lastChecked);

    // A negative elapsed time means the device clock moved backwards; treat
    // that as "stale" rather than blocking checks until the clock catches
    // up again.
    if (elapsed.isNegative) return true;
    return elapsed >= UpdateConfig.autoCheckCooldown;
  }

  /// The cooldown timestamp is a convenience, not state anything depends
  /// on, so a preferences failure degrades to "check again" rather than
  /// escaping from the fire-and-forget startup call.
  Future<int?> _readLastCheckMillis() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_lastCheckKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> _recordCheckTime() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastCheckKey, _now().millisecondsSinceEpoch);
    } catch (_) {
      // Not being able to remember the check time only means the next
      // automatic check runs sooner than it needed to.
    }
  }

  /// Test seam: forces the next automatic check to run.
  @visibleForTesting
  Future<void> clearCooldown() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastCheckKey);
    } catch (_) {
      // Already effectively cleared.
    }
  }
}
