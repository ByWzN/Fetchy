/// ============================================================================
/// THE ONE PLACE TO CONFIGURE FETCHY'S UPDATE SOURCE.
///
/// Everything the in-app updater needs to find a release lives here and
/// nowhere else. Before the first public release, change [githubOwner] and
/// [githubRepository] to the real repository and make sure the release
/// workflow attaches an APK whose filename matches [apkAssetPattern].
///
/// Nothing else in the app hard-codes a GitHub URL.
/// ============================================================================
library;

class UpdateConfig {
  const UpdateConfig._();

  // --------------------------------------------------------------------------
  // CONFIGURE BEFORE FIRST PUBLIC RELEASE
  // --------------------------------------------------------------------------

  /// The GitHub account or organization that owns the Fetchy repository.
  ///
  /// While this holds a placeholder value, [isConfigured] is false and the
  /// updater refuses to make any network request at all.
  static const String githubOwner = 'ByWzN';

  /// The repository name, e.g. `fetchy`.
  static const String githubRepository = 'Fetchy';

  /// Which release asset is the installable Android build.
  ///
  /// Release pages routinely carry several files (mapping files, checksums,
  /// the two source archives GitHub adds automatically), so the APK is
  /// chosen by matching this pattern rather than by position. Keep it
  /// narrow enough that it can only ever match a real Fetchy APK.
  static final RegExp apkAssetPattern = RegExp(
    r'^fetchy[-_].*\.apk$',
    caseSensitive: false,
  );

  // --------------------------------------------------------------------------
  // Derived — no need to change these.
  // --------------------------------------------------------------------------

  /// True once the two placeholders above have been replaced with a real
  /// repository. Until then the updater reports "not configured" instead of
  /// sending a request to a URL that cannot exist.
  static bool get isConfigured =>
      !githubOwner.contains('PLACEHOLDER') &&
      !githubRepository.contains('PLACEHOLDER') &&
      githubOwner.isNotEmpty &&
      githubRepository.isNotEmpty;

  /// GitHub's public "latest release" endpoint. Documented to return the
  /// most recent **published, non-prerelease** release, which is exactly
  /// the concept Fetchy wants — no tag guessing, no client-side sorting.
  static Uri get latestReleaseEndpoint => Uri.https(
    'api.github.com',
    '/repos/$githubOwner/$githubRepository/releases/latest',
  );

  /// The human-facing releases page, used only as a fallback link.
  static Uri get releasesPage =>
      Uri.https('github.com', '/$githubOwner/$githubRepository/releases');

  /// How long a successful automatic check is considered fresh. A manual
  /// "Check for updates" always ignores this.
  static const Duration autoCheckCooldown = Duration(hours: 24);

  /// Caps on the network calls, so a hung connection can never leave the
  /// UI stuck in "Checking…".
  static const Duration apiTimeout = Duration(seconds: 15);

  /// A release payload is a few kilobytes of JSON; anything vastly larger
  /// is not a release payload and is rejected rather than parsed.
  static const int maxApiResponseBytes = 1024 * 1024;
}
