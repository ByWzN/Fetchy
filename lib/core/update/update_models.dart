import 'app_version.dart';

/// One downloadable file attached to a GitHub release.
class GithubReleaseAsset {
  const GithubReleaseAsset({
    required this.name,
    required this.downloadUrl,
    this.sizeBytes,
    this.contentType,
  });

  final String name;

  /// GitHub's `browser_download_url`. Always used as-is; the updater never
  /// constructs a download URL of its own.
  final String downloadUrl;

  final int? sizeBytes;
  final String? contentType;

  bool get looksLikeApk => name.toLowerCase().endsWith('.apk');

  static GithubReleaseAsset? fromJson(Object? raw) {
    if (raw is! Map<String, Object?>) return null;

    final String? name = (raw['name'] as String?)?.trim();
    final String? url = (raw['browser_download_url'] as String?)?.trim();
    if (name == null || name.isEmpty) return null;
    if (url == null || !url.startsWith('https://')) return null;

    return GithubReleaseAsset(
      name: name,
      downloadUrl: url,
      sizeBytes: (raw['size'] as num?)?.toInt(),
      contentType: raw['content_type'] as String?,
    );
  }
}

/// A GitHub release, reduced to the fields the updater actually reads.
class GithubRelease {
  const GithubRelease({
    required this.tagName,
    this.name,
    this.body,
    this.isDraft = false,
    this.isPrerelease = false,
    this.publishedAt,
    this.htmlUrl,
    this.assets = const <GithubReleaseAsset>[],
  });

  final String tagName;
  final String? name;

  /// The release notes, as Markdown, exactly as the author wrote them.
  final String? body;

  final bool isDraft;
  final bool isPrerelease;
  final DateTime? publishedAt;
  final String? htmlUrl;
  final List<GithubReleaseAsset> assets;

  /// A release is only ever offered as an update when this is true: it must
  /// be published, stable, and carry a usable tag.
  bool get isPublishedStable =>
      !isDraft && !isPrerelease && tagName.trim().isNotEmpty;

  AppVersion? get version => AppVersion.tryParse(tagName);

  static GithubRelease? fromJson(Object? raw) {
    if (raw is! Map<String, Object?>) return null;

    final String? tagName = (raw['tag_name'] as String?)?.trim();
    if (tagName == null || tagName.isEmpty) return null;

    final Object? rawAssets = raw['assets'];
    final List<GithubReleaseAsset> assets = rawAssets is List
        ? rawAssets
              .map(GithubReleaseAsset.fromJson)
              .whereType<GithubReleaseAsset>()
              .toList(growable: false)
        : const <GithubReleaseAsset>[];

    return GithubRelease(
      tagName: tagName,
      name: (raw['name'] as String?)?.trim(),
      body: raw['body'] as String?,
      isDraft: raw['draft'] == true,
      isPrerelease: raw['prerelease'] == true,
      publishedAt: DateTime.tryParse((raw['published_at'] as String?) ?? ''),
      htmlUrl: raw['html_url'] as String?,
      assets: assets,
    );
  }
}

/// Why a check could not produce an answer. Each maps to one plain-language
/// message in the UI — the user is never shown a raw exception.
enum UpdateFailureReason {
  /// The repository placeholders in `UpdateConfig` were never replaced, so
  /// no request was made at all.
  notConfigured,

  noNetwork,
  timeout,

  /// GitHub's unauthenticated hourly quota is used up. Genuinely temporary,
  /// so the UI says to try later rather than reporting a fault.
  rateLimited,

  /// Any other non-success HTTP status.
  httpError,

  /// The response was not the JSON shape a release is documented to have.
  malformedResponse,

  /// The repository has no published release yet (a 404 from the "latest"
  /// endpoint), which is the normal state before the very first release.
  noRelease,

  unknown,
}

/// The result of one update check.
sealed class UpdateCheckOutcome {
  const UpdateCheckOutcome();
}

/// The installed build is the newest published stable release.
final class UpdateUpToDate extends UpdateCheckOutcome {
  const UpdateUpToDate({required this.installed, this.latestVersion});

  final InstalledAppVersion installed;

  /// The newest release found, when there was one to compare against.
  final AppVersion? latestVersion;
}

/// A newer published stable release exists and carries an installable APK.
final class UpdateAvailable extends UpdateCheckOutcome {
  const UpdateAvailable({
    required this.installed,
    required this.newVersion,
    required this.release,
    required this.apkAsset,
  });

  final InstalledAppVersion installed;
  final AppVersion newVersion;
  final GithubRelease release;
  final GithubReleaseAsset apkAsset;

  String get releaseTitle {
    final String? name = release.name;
    if (name != null && name.isNotEmpty) return name;
    return release.tagName;
  }

  String? get releaseNotes {
    final String? body = release.body?.trim();
    return (body == null || body.isEmpty) ? null : body;
  }
}

/// A newer release exists but has no asset matching
/// `UpdateConfig.apkAssetPattern` — so there is nothing safe to install.
/// Source archives are never offered as a substitute.
final class UpdateNoCompatibleAsset extends UpdateCheckOutcome {
  const UpdateNoCompatibleAsset({
    required this.installed,
    required this.newVersion,
    required this.release,
  });

  final InstalledAppVersion installed;
  final AppVersion newVersion;
  final GithubRelease release;
}

/// The check itself could not complete.
final class UpdateCheckFailed extends UpdateCheckOutcome {
  const UpdateCheckFailed(this.reason, {this.installed});

  final UpdateFailureReason reason;

  /// Present whenever the installed version was known before the failure —
  /// the UI can still show "Current version" even when GitHub is down.
  final InstalledAppVersion? installed;
}

/// Thrown by a [GithubReleaseClient] and converted to an
/// [UpdateCheckFailed] by the service. Carries a reason, never a stack
/// trace or a raw socket error.
class UpdateCheckException implements Exception {
  const UpdateCheckException(this.reason);

  final UpdateFailureReason reason;

  @override
  String toString() => 'UpdateCheckException(${reason.name})';
}
