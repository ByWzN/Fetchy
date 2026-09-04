import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fetchy/core/update/app_version.dart';
import 'package:fetchy/core/update/github_release_client.dart';
import 'package:fetchy/core/update/release_notes.dart';
import 'package:fetchy/core/update/update_config.dart';
import 'package:fetchy/core/update/update_installer.dart';
import 'package:fetchy/core/update/update_models.dart';
import 'package:fetchy/core/update/update_service.dart';

/// A release client under full test control — no sockets are ever opened.
class _FakeReleaseClient implements GithubReleaseClient {
  _FakeReleaseClient({this.release, this.error});

  GithubRelease? release;
  UpdateCheckException? error;
  int callCount = 0;

  @override
  Future<GithubRelease?> fetchLatestRelease() async {
    callCount++;
    final UpdateCheckException? failure = error;
    if (failure != null) throw failure;
    return release;
  }
}

/// Reports a fixed installed version. Nothing here can install anything —
/// [verifyAndLaunchInstaller] only records that it was asked.
class _FakeInstaller implements UpdateInstaller {
  _FakeInstaller({
    this.versionName = '1.0.0',
    this.versionCode = 1,
    this.installPermissionGranted = true,
  });

  final String versionName;
  final int versionCode;
  bool installPermissionGranted;

  int launchInstallerCalls = 0;
  int openSettingsCalls = 0;

  @override
  Future<InstalledAppVersion?> installedVersion() async => InstalledAppVersion(
    versionName: versionName,
    versionCode: versionCode,
    packageName: 'com.example.fetchy',
  );

  @override
  Future<bool> canRequestPackageInstalls() async => installPermissionGranted;

  @override
  Future<bool> openInstallPermissionSettings() async {
    openSettingsCalls++;
    return true;
  }

  @override
  Future<String> downloadApk({
    required String url,
    required String fileName,
    int? expectedSizeBytes,
  }) async => '/cache/app_update/$fileName';

  @override
  Stream<UpdateDownloadProgress> get downloadProgress =>
      const Stream<UpdateDownloadProgress>.empty();

  @override
  Future<void> cancelDownload() async {}

  @override
  Future<void> verifyAndLaunchInstaller(String filePath) async {
    launchInstallerCalls++;
  }
}

GithubReleaseAsset _asset(String name, {int? size}) => GithubReleaseAsset(
  name: name,
  downloadUrl: 'https://github.com/o/r/releases/download/v1/$name',
  sizeBytes: size,
);

GithubRelease _release({
  required String tag,
  bool draft = false,
  bool prerelease = false,
  List<GithubReleaseAsset>? assets,
  String? body,
}) => GithubRelease(
  tagName: tag,
  name: 'Fetchy $tag',
  body: body,
  isDraft: draft,
  isPrerelease: prerelease,
  assets: assets ?? <GithubReleaseAsset>[_asset('fetchy-release.apk')],
);

/// The evaluation rules take a release and an installed version and return
/// an outcome, with no network and no platform channel involved.
UpdateCheckOutcome evaluateWith({
  required GithubRelease release,
  String installedName = '1.0.0',
  int installedCode = 1,
}) {
  final UpdateService service = UpdateService(
    client: _FakeReleaseClient(),
    installer: _FakeInstaller(),
  );
  return service.evaluate(
    release: release,
    installed: InstalledAppVersion(
      versionName: installedName,
      versionCode: installedCode,
      packageName: 'com.example.fetchy',
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('AppVersion', () {
    test('never compares versions as plain strings', () {
      final AppVersion older = AppVersion.tryParse('1.9.0')!;
      final AppVersion newer = AppVersion.tryParse('1.10.0')!;

      // Lexicographically "1.10.0" < "1.9.0", which would hide the update.
      expect('1.10.0'.compareTo('1.9.0') < 0, isTrue);
      expect(newer > older, isTrue);
    });

    test('accepts a v-prefixed tag and a missing patch segment', () {
      expect(AppVersion.tryParse('v2.3.4')!.displayName, '2.3.4');
      expect(AppVersion.tryParse('1.2')!.patch, 0);
    });

    test('ranks a pre-release below the matching stable version', () {
      final AppVersion beta = AppVersion.tryParse('1.2.0-beta.1')!;
      final AppVersion stable = AppVersion.tryParse('1.2.0')!;
      expect(beta < stable, isTrue);
      expect(AppVersion.tryParse('1.2.0-beta.2')! > beta, isTrue);
    });

    test('reads the build metadata as the Android versionCode', () {
      expect(AppVersion.tryParse('v1.2.3+7')!.buildNumber, 7);
      expect(AppVersion.tryParse('v1.2.3')!.buildNumber, isNull);
    });

    test('refuses to parse a tag that is not a version', () {
      expect(AppVersion.tryParse('nightly'), isNull);
      expect(AppVersion.tryParse(''), isNull);
      expect(AppVersion.tryParse(null), isNull);
    });
  });

  group('Update evaluation', () {
    test('1. the installed version equals the latest release', () {
      final UpdateCheckOutcome outcome = evaluateWith(
        release: _release(tag: 'v1.0.0'),
      );
      expect(outcome, isA<UpdateUpToDate>());
    });

    test('2. the latest release is newer than what is installed', () {
      final UpdateCheckOutcome outcome = evaluateWith(
        release: _release(tag: 'v1.1.0'),
      );

      expect(outcome, isA<UpdateAvailable>());
      final UpdateAvailable available = outcome as UpdateAvailable;
      expect(available.newVersion.displayName, '1.1.0');
      expect(available.apkAsset.name, 'fetchy-release.apk');
    });

    test('3. an older or equal release is never offered', () {
      expect(
        evaluateWith(
          release: _release(tag: 'v0.9.0'),
          installedName: '1.0.0',
        ),
        isA<UpdateUpToDate>(),
      );
      expect(
        evaluateWith(
          release: _release(tag: 'v1.0.0'),
          installedName: '1.0.0',
        ),
        isA<UpdateUpToDate>(),
      );
    });

    test('3b. a newer name with a versionCode that is not greater is refused', () {
      // The tag advertises 2.0.0 but carries versionCode 1, which is not
      // greater than the installed 1 — Android's monotonic rule wins.
      final UpdateCheckOutcome outcome = evaluateWith(
        release: _release(tag: 'v2.0.0+1'),
        installedName: '1.0.0',
        installedCode: 1,
      );
      expect(outcome, isA<UpdateUpToDate>());
    });

    test('3c. a newer versionCode in the tag is accepted', () {
      final UpdateCheckOutcome outcome = evaluateWith(
        release: _release(tag: 'v1.1.0+2'),
        installedName: '1.0.0',
        installedCode: 1,
      );
      expect(outcome, isA<UpdateAvailable>());
    });

    test('4. a prerelease is never offered as an update', () {
      final UpdateCheckOutcome outcome = evaluateWith(
        release: _release(tag: 'v2.0.0', prerelease: true),
      );
      expect(outcome, isA<UpdateUpToDate>());
    });

    test('5. a draft is never offered as an update', () {
      final UpdateCheckOutcome outcome = evaluateWith(
        release: _release(tag: 'v2.0.0', draft: true),
      );
      expect(outcome, isA<UpdateUpToDate>());
    });

    test('6. a newer release with no APK asset reports no compatible asset', () {
      final UpdateCheckOutcome outcome = evaluateWith(
        release: _release(
          tag: 'v1.1.0',
          assets: <GithubReleaseAsset>[
            _asset('fetchy-1.1.0-mapping.txt'),
            _asset('checksums.sha256'),
          ],
        ),
      );

      expect(outcome, isA<UpdateNoCompatibleAsset>());
    });

    test('7. the APK is selected from among several assets, never by position', () {
      final UpdateCheckOutcome outcome = evaluateWith(
        release: _release(
          tag: 'v1.1.0',
          assets: <GithubReleaseAsset>[
            _asset('Source code (zip)'),
            _asset('fetchy-1.1.0.aab'),
            _asset('checksums.sha256'),
            _asset('fetchy-1.1.0-release.apk', size: 42),
            _asset('fetchy-extra.apk'),
          ],
        ),
      );

      expect(outcome, isA<UpdateAvailable>());
      expect(
        (outcome as UpdateAvailable).apkAsset.name,
        'fetchy-1.1.0-release.apk',
      );
    });

    test('7b. a source archive is never selected as the update', () {
      final GithubReleaseAsset? selected = UpdateService.selectApkAsset(
        <GithubReleaseAsset>[
          _asset('fetchy-source.zip'),
          _asset('fetchy-source.tar.gz'),
        ],
      );
      expect(selected, isNull);
    });

    test('8. a release whose tag cannot be parsed is reported, not offered', () {
      final UpdateCheckOutcome outcome = evaluateWith(
        release: _release(tag: 'nightly-build'),
      );

      expect(outcome, isA<UpdateCheckFailed>());
      expect(
        (outcome as UpdateCheckFailed).reason,
        UpdateFailureReason.malformedResponse,
      );
    });
  });

  group('GithubRelease parsing', () {
    test('reads a realistic release payload', () {
      final GithubRelease? release = GithubRelease.fromJson(<String, Object?>{
        'tag_name': 'v1.4.0',
        'name': 'Fetchy 1.4.0',
        'body': '## Fixes\n- Snapchat links',
        'draft': false,
        'prerelease': false,
        'published_at': '2026-01-15T10:00:00Z',
        'html_url': 'https://github.com/o/r/releases/tag/v1.4.0',
        'assets': <Object?>[
          <String, Object?>{
            'name': 'fetchy-1.4.0-release.apk',
            'browser_download_url':
                'https://github.com/o/r/releases/download/v1.4.0/fetchy-1.4.0-release.apk',
            'size': 51200,
            'content_type': 'application/vnd.android.package-archive',
          },
        ],
      });

      expect(release, isNotNull);
      expect(release!.tagName, 'v1.4.0');
      expect(release.assets.single.sizeBytes, 51200);
      expect(release.publishedAt?.year, 2026);
      expect(release.isPublishedStable, isTrue);
    });

    test('8b. malformed payloads are rejected rather than half-read', () {
      expect(GithubRelease.fromJson(<String, Object?>{}), isNull);
      expect(GithubRelease.fromJson('not json at all'), isNull);
      expect(GithubRelease.fromJson(<String, Object?>{'tag_name': ''}), isNull);

      // An asset served over plain http is dropped: update payloads are
      // only ever fetched over TLS.
      final GithubRelease? release = GithubRelease.fromJson(<String, Object?>{
        'tag_name': 'v1.1.0',
        'assets': <Object?>[
          <String, Object?>{
            'name': 'fetchy.apk',
            'browser_download_url': 'http://insecure.example/fetchy.apk',
          },
        ],
      });
      expect(release!.assets, isEmpty);
    });
  });

  group('UpdateService.check', () {
    test('8c. a malformed response surfaces as a failure, not an update', () async {
      final _FakeReleaseClient client = _FakeReleaseClient(
        error: const UpdateCheckException(
          UpdateFailureReason.malformedResponse,
        ),
      );
      final UpdateService service = UpdateService(
        client: client,
        installer: _FakeInstaller(),
      );

      final UpdateCheckOutcome outcome = await service.check(manual: true);

      expect(outcome, isA<UpdateCheckFailed>());
      expect(
        (outcome as UpdateCheckFailed).reason,
        UpdateFailureReason.malformedResponse,
      );
      // The installed version is still known, so the UI can keep showing it.
      expect(outcome.installed?.versionName, '1.0.0');
    });

    test('9. network and timeout errors are reported gracefully', () async {
      for (final UpdateFailureReason reason in <UpdateFailureReason>[
        UpdateFailureReason.noNetwork,
        UpdateFailureReason.timeout,
        UpdateFailureReason.rateLimited,
        UpdateFailureReason.httpError,
        UpdateFailureReason.noRelease,
      ]) {
        final UpdateService service = UpdateService(
          client: _FakeReleaseClient(error: UpdateCheckException(reason)),
          installer: _FakeInstaller(),
        );

        final UpdateCheckOutcome outcome = await service.check(manual: true);
        expect(outcome, isA<UpdateCheckFailed>());
        expect((outcome as UpdateCheckFailed).reason, reason);
      }
    });

    test('a missing release is reported rather than treated as up to date', () async {
      final UpdateService service = UpdateService(
        client: _FakeReleaseClient(),
        installer: _FakeInstaller(),
      );

      final UpdateCheckOutcome outcome = await service.check(manual: true);
      expect(
        (outcome as UpdateCheckFailed).reason,
        UpdateFailureReason.noRelease,
      );
    });

    test('records the outcome so Settings can show it without re-checking', () async {
      final UpdateService service = UpdateService(
        client: _FakeReleaseClient(release: _release(tag: 'v1.2.0')),
        installer: _FakeInstaller(),
      );

      await service.check(manual: true);
      expect(service.latestOutcome.value, isA<UpdateAvailable>());
    });
  });

  group('Automatic-check cooldown', () {
    test('10. a manual check always bypasses the cooldown', () async {
      final _FakeReleaseClient client = _FakeReleaseClient(
        release: _release(tag: 'v1.1.0'),
      );
      final UpdateService service = UpdateService(
        client: client,
        installer: _FakeInstaller(),
      );

      await service.check(manual: true);
      expect(client.callCount, 1);

      // Immediately again: the cooldown has certainly not elapsed, and the
      // request is still made.
      await service.check(manual: true);
      expect(client.callCount, 2);
    });

    test('10b. an automatic check inside the cooldown makes no request', () async {
      final _FakeReleaseClient client = _FakeReleaseClient(
        release: _release(tag: 'v1.1.0'),
      );
      DateTime now = DateTime(2026, 1, 1, 12);
      final UpdateService service = UpdateService(
        client: client,
        installer: _FakeInstaller(),
        now: () => now,
      );

      await service.check(manual: true);
      expect(client.callCount, 1);

      now = now.add(const Duration(hours: 2));
      final UpdateCheckOutcome? skipped = await service.checkAutomatically();

      expect(skipped, isNull);
      expect(client.callCount, 1);
    });

    test('10c. an automatic check after the cooldown makes a request', () async {
      final _FakeReleaseClient client = _FakeReleaseClient(
        release: _release(tag: 'v1.1.0'),
      );
      DateTime now = DateTime(2026, 1, 1, 12);
      final UpdateService service = UpdateService(
        client: client,
        installer: _FakeInstaller(),
        now: () => now,
      );

      await service.check(manual: true);
      now = now.add(UpdateConfig.autoCheckCooldown + const Duration(minutes: 1));
      await service.checkAutomatically();

      expect(client.callCount, 2);
    });

    test('an unconfigured build never opens a connection', () async {
      // The real client is the single gate: while the repository
      // placeholders are in place it refuses before any socket is opened.
      const HttpGithubReleaseClient client = HttpGithubReleaseClient();

      await expectLater(
        client.fetchLatestRelease(),
        throwsA(
          isA<UpdateCheckException>().having(
            (UpdateCheckException e) => e.reason,
            'reason',
            UpdateFailureReason.notConfigured,
          ),
        ),
      );
    }, skip: UpdateConfig.isConfigured
        ? 'The repository is configured, so this guard no longer applies.'
        : null);
  });

  group('Release notes', () {
    test('renders headings and bullets as plain text', () {
      final List<ReleaseNoteLine> lines = parseReleaseNotes(
        '## What changed\n'
        '- Fixed **Snapchat** links\n'
        '* Faster `yt-dlp` startup\n',
      );

      expect(lines.length, 3);
      expect(lines[0].kind, ReleaseNoteLineKind.heading);
      expect(lines[0].text, 'What changed');
      expect(lines[1].kind, ReleaseNoteLineKind.bullet);
      expect(lines[1].text, 'Fixed Snapchat links');
      expect(lines[2].text, 'Faster yt-dlp startup');
    });

    test('strips links, images and any embedded HTML', () {
      final List<ReleaseNoteLine> lines = parseReleaseNotes(
        'See [the issue](https://example.com/evil) '
        '![shot](https://example.com/pixel.png)'
        '<script>alert(1)</script><b>bold</b>',
      );

      final String text = lines.single.text;
      expect(text, contains('the issue'));
      expect(text, isNot(contains('http')));
      expect(text, isNot(contains('<')));
      expect(text, isNot(contains('script')));
    });

    test('skips fenced code blocks and caps very long bodies', () {
      final List<ReleaseNoteLine> fenced = parseReleaseNotes(
        'Before\n```\nrm -rf /\n```\nAfter',
      );
      expect(fenced.map((ReleaseNoteLine l) => l.text), <String>[
        'Before',
        'After',
      ]);

      final List<ReleaseNoteLine> huge = parseReleaseNotes(
        List<String>.generate(500, (int i) => '- item $i').join('\n'),
      );
      expect(huge.length, kMaxReleaseNoteLines);
    });

    test('an empty body produces no lines rather than a blank block', () {
      expect(parseReleaseNotes(null), isEmpty);
      expect(parseReleaseNotes('   '), isEmpty);
    });
  });

  group('Installation safety', () {
    test('nothing is installed without an explicit request', () async {
      final _FakeInstaller installer = _FakeInstaller();
      final UpdateService service = UpdateService(
        client: _FakeReleaseClient(release: _release(tag: 'v1.1.0')),
        installer: installer,
      );

      await service.check(manual: true);

      // Finding an update must never, by itself, download or install.
      expect(installer.launchInstallerCalls, 0);
    });

    test('the installer is never reached without install permission', () async {
      final _FakeInstaller installer = _FakeInstaller(
        versionName: '1.0.0',
        versionCode: 1,
        installPermissionGranted: false,
      );

      // This is the gate the Updates screen applies before installing: no
      // permission means the user is sent to Android's settings, and the
      // installer is not launched.
      expect(await installer.canRequestPackageInstalls(), isFalse);
      await installer.openInstallPermissionSettings();

      expect(installer.openSettingsCalls, 1);
      expect(installer.launchInstallerCalls, 0);
    });

    test('install failures map to their own distinct outcomes', () {
      expect(
        const UpdateInstallException(
          UpdateInstallFailure.signatureMismatch,
        ).failure,
        UpdateInstallFailure.signatureMismatch,
      );
      expect(
        const UpdateInstallException(UpdateInstallFailure.notNewer).failure,
        UpdateInstallFailure.notNewer,
      );
    });
  });

  group('UpdateConfig', () {
    test('reports that the repository still needs configuring', () {
      // This intentionally fails once the placeholders are replaced,
      // as a reminder to re-read the release checklist.
      expect(
        UpdateConfig.isConfigured,
        isFalse,
        reason:
            'Replace githubOwner/githubRepository in update_config.dart, then '
            'update this expectation to isTrue.',
      );
    });

    test('builds the documented latest-release endpoint', () {
      expect(
        UpdateConfig.latestReleaseEndpoint.toString(),
        'https://api.github.com/repos/${UpdateConfig.githubOwner}/'
        '${UpdateConfig.githubRepository}/releases/latest',
      );
    });

    test('the APK pattern accepts real builds and rejects everything else', () {
      expect(UpdateConfig.apkAssetPattern.hasMatch('fetchy-1.2.3.apk'), isTrue);
      expect(
        UpdateConfig.apkAssetPattern.hasMatch('fetchy_1.2.3-release.apk'),
        isTrue,
      );
      expect(UpdateConfig.apkAssetPattern.hasMatch('fetchy-1.2.3.aab'), isFalse);
      expect(UpdateConfig.apkAssetPattern.hasMatch('source.zip'), isFalse);
      expect(UpdateConfig.apkAssetPattern.hasMatch('malware.apk'), isFalse);
    });
  });
}
