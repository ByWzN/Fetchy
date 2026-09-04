/// Semantic-version parsing and comparison for the in-app updater.
///
/// Version strings are never compared as plain strings: lexicographically
/// "1.10.0" sorts before "1.9.0", which would hide a real update. Every
/// comparison in the updater goes through [AppVersion.compareTo].
class AppVersion implements Comparable<AppVersion> {
  const AppVersion({
    required this.major,
    required this.minor,
    required this.patch,
    this.preRelease,
    this.buildNumber,
    required this.raw,
  });

  final int major;
  final int minor;
  final int patch;

  /// The `-beta.1` part, when present. A version carrying one ranks *below*
  /// the same version without it, per semver.
  final String? preRelease;

  /// The `+N` build-metadata suffix, which Fetchy uses for exactly one
  /// purpose: carrying the Android `versionCode` in a release tag (Flutter
  /// already writes versions this way — `1.2.3+4` in pubspec.yaml).
  ///
  /// Semver says build metadata is ignored for precedence, and it is
  /// ignored in [compareTo]. It is used only for the separate monotonic
  /// versionCode safety check — see `UpdateService`.
  final int? buildNumber;

  /// Exactly what was parsed, so the UI can show the release's own spelling
  /// (tag `v1.2.3`) rather than a normalized rewrite.
  final String raw;

  static final RegExp _pattern = RegExp(
    r'^(\d{1,9})\.(\d{1,9})(?:\.(\d{1,9}))?'
    r'(?:-([0-9A-Za-z.-]+))?'
    r'(?:\+(\d{1,9}))?$',
  );

  /// Parses a version, tolerating the two forms releases actually use: a
  /// bare `1.2.3` and a `v`-prefixed tag `v1.2.3`. Returns null for
  /// anything else rather than guessing — an unparseable tag must never be
  /// treated as newer than what is installed.
  static AppVersion? tryParse(String? input) {
    if (input == null) return null;
    String text = input.trim();
    if (text.isEmpty) return null;
    if (text.startsWith('v') || text.startsWith('V')) {
      text = text.substring(1).trim();
    }

    final RegExpMatch? match = _pattern.firstMatch(text);
    if (match == null) return null;

    return AppVersion(
      major: int.parse(match.group(1)!),
      minor: int.parse(match.group(2)!),
      patch: int.tryParse(match.group(3) ?? '0') ?? 0,
      preRelease: match.group(4),
      buildNumber: int.tryParse(match.group(5) ?? ''),
      raw: input.trim(),
    );
  }

  bool get isPreRelease => preRelease != null;

  @override
  int compareTo(AppVersion other) {
    final int core =
        _compareInts(major, other.major) != 0
        ? _compareInts(major, other.major)
        : _compareInts(minor, other.minor) != 0
        ? _compareInts(minor, other.minor)
        : _compareInts(patch, other.patch);
    if (core != 0) return core;

    return _comparePreRelease(preRelease, other.preRelease);
  }

  bool operator >(AppVersion other) => compareTo(other) > 0;
  bool operator <(AppVersion other) => compareTo(other) < 0;
  bool operator >=(AppVersion other) => compareTo(other) >= 0;
  bool operator <=(AppVersion other) => compareTo(other) <= 0;

  static int _compareInts(int a, int b) => a.compareTo(b);

  /// Semver §11: a version with a pre-release ranks lower than the same
  /// version without one, and pre-release identifiers are compared field by
  /// field, numerically when both are numeric.
  static int _comparePreRelease(String? a, String? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;

    final List<String> left = a.split('.');
    final List<String> right = b.split('.');
    final int shared = left.length < right.length ? left.length : right.length;

    for (int i = 0; i < shared; i++) {
      final int? leftNumber = int.tryParse(left[i]);
      final int? rightNumber = int.tryParse(right[i]);

      if (leftNumber != null && rightNumber != null) {
        final int result = leftNumber.compareTo(rightNumber);
        if (result != 0) return result;
      } else if (leftNumber != null) {
        // Numeric identifiers always rank lower than alphanumeric ones.
        return -1;
      } else if (rightNumber != null) {
        return 1;
      } else {
        final int result = left[i].compareTo(right[i]);
        if (result != 0) return result;
      }
    }

    return left.length.compareTo(right.length);
  }

  /// `1.2.3`, plus the pre-release suffix when there is one. Deliberately
  /// omits the build metadata, which is an implementation detail of how the
  /// tag encodes the Android versionCode.
  String get displayName {
    final String core = '$major.$minor.$patch';
    return preRelease == null ? core : '$core-$preRelease';
  }

  @override
  String toString() => displayName;

  @override
  bool operator ==(Object other) =>
      other is AppVersion &&
      other.major == major &&
      other.minor == minor &&
      other.patch == patch &&
      other.preRelease == preRelease;

  @override
  int get hashCode => Object.hash(major, minor, patch, preRelease);
}

/// What is actually installed on this device, as Android itself reports it.
///
/// [versionCode] is the value Android enforces monotonicity on, and is the
/// final safety check before an update is ever offered or installed —
/// [versionName] alone is only a human-facing label.
class InstalledAppVersion {
  const InstalledAppVersion({
    required this.versionName,
    required this.versionCode,
    required this.packageName,
  });

  final String versionName;
  final int versionCode;
  final String packageName;

  AppVersion? get semantic => AppVersion.tryParse(versionName);

  static InstalledAppVersion? fromMap(Map<Object?, Object?> map) {
    final String? versionName = (map['versionName'] as String?)?.trim();
    final int? versionCode = (map['versionCode'] as num?)?.toInt();
    final String? packageName = (map['packageName'] as String?)?.trim();

    if (versionName == null || versionName.isEmpty) return null;
    if (versionCode == null) return null;
    if (packageName == null || packageName.isEmpty) return null;

    return InstalledAppVersion(
      versionName: versionName,
      versionCode: versionCode,
      packageName: packageName,
    );
  }
}
