import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'update_config.dart';
import 'update_models.dart';

/// Reads the latest published release. Split out from `UpdateService` so
/// the update rules can be tested with no network at all.
abstract class GithubReleaseClient {
  /// Returns the newest published release, or null when the repository has
  /// no releases yet. Throws [UpdateCheckException] for every other
  /// failure — never a raw [SocketException] or [FormatException].
  Future<GithubRelease?> fetchLatestRelease();
}

/// The real client, built on `dart:io`'s [HttpClient] so the updater adds no
/// package dependency for one GET request.
///
/// PRIVACY: this issues exactly one anonymous GET to GitHub's public API.
/// It sends no cookies (none are ever attached to this client), no
/// credentials, no Fetchy session, no clipboard content, no download
/// history, and no device identifier. The only headers are the two GitHub
/// documents as required plus a static User-Agent.
class HttpGithubReleaseClient implements GithubReleaseClient {
  const HttpGithubReleaseClient();

  static const String _userAgent = 'Fetchy-Update-Checker';

  @override
  Future<GithubRelease?> fetchLatestRelease() async {
    if (!UpdateConfig.isConfigured) {
      throw const UpdateCheckException(UpdateFailureReason.notConfigured);
    }

    final HttpClient client = HttpClient()
      ..connectionTimeout = UpdateConfig.apiTimeout
      ..userAgent = _userAgent;

    try {
      final String body = await _get(client, UpdateConfig.latestReleaseEndpoint)
          .timeout(
            UpdateConfig.apiTimeout,
            onTimeout: () =>
                throw const UpdateCheckException(UpdateFailureReason.timeout),
          );

      final Object? decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?>) {
        throw const UpdateCheckException(
          UpdateFailureReason.malformedResponse,
        );
      }

      final GithubRelease? release = GithubRelease.fromJson(decoded);
      if (release == null) {
        throw const UpdateCheckException(
          UpdateFailureReason.malformedResponse,
        );
      }
      return release;
    } on UpdateCheckException {
      rethrow;
    } on SocketException {
      throw const UpdateCheckException(UpdateFailureReason.noNetwork);
    } on HandshakeException {
      throw const UpdateCheckException(UpdateFailureReason.noNetwork);
    } on TimeoutException {
      throw const UpdateCheckException(UpdateFailureReason.timeout);
    } on FormatException {
      throw const UpdateCheckException(UpdateFailureReason.malformedResponse);
    } catch (_) {
      throw const UpdateCheckException(UpdateFailureReason.unknown);
    } finally {
      client.close(force: true);
    }
  }

  Future<String> _get(HttpClient client, Uri uri) async {
    final HttpClientRequest request = await client.getUrl(uri);
    request.headers
      ..set(HttpHeaders.acceptHeader, 'application/vnd.github+json')
      ..set('X-GitHub-Api-Version', '2022-11-28');
    // Belt and braces: nothing sets a cookie on this client, and nothing is
    // allowed to add one either.
    request.cookies.clear();
    request.followRedirects = true;

    final HttpClientResponse response = await request.close();
    final int status = response.statusCode;

    if (status == HttpStatus.notFound) {
      // The documented response when a repository has no published release.
      await response.drain<void>();
      throw const UpdateCheckException(UpdateFailureReason.noRelease);
    }

    if (status == HttpStatus.forbidden || status == 429) {
      final String? remaining = response.headers.value('x-ratelimit-remaining');
      await response.drain<void>();
      throw UpdateCheckException(
        remaining == '0' || status == 429
            ? UpdateFailureReason.rateLimited
            : UpdateFailureReason.httpError,
      );
    }

    if (status != HttpStatus.ok) {
      await response.drain<void>();
      throw const UpdateCheckException(UpdateFailureReason.httpError);
    }

    final int declaredLength = response.contentLength;
    if (declaredLength > UpdateConfig.maxApiResponseBytes) {
      await response.drain<void>();
      throw const UpdateCheckException(UpdateFailureReason.malformedResponse);
    }

    // Read with a hard cap rather than trusting Content-Length, so a
    // mislabelled or chunked response cannot make the app read unbounded
    // data into memory.
    final StringBuffer buffer = StringBuffer();
    int total = 0;
    await for (final String chunk in response.transform(utf8.decoder)) {
      total += chunk.length;
      if (total > UpdateConfig.maxApiResponseBytes) {
        throw const UpdateCheckException(
          UpdateFailureReason.malformedResponse,
        );
      }
      buffer.write(chunk);
    }

    return buffer.toString();
  }
}
