import 'package:flutter/services.dart';

import 'platform_channels.dart';

/// The outcome of one pick/download attempt — either a local file path
/// ready to preview and embed, or a short user-presentable reason it
/// failed. Never a content:// Uri or remote URL: by the time this returns,
/// native has already materialized/downloaded the bytes into a private
/// temp file, so nothing above this layer ever needs SAF or network access
/// of its own.
class ArtworkPickResult {
  const ArtworkPickResult.success(this.path) : error = null;
  const ArtworkPickResult.failure(this.error) : path = null;

  final String? path;
  final String? error;

  bool get isSuccess => path != null;

  /// True specifically when the user closed the picker without choosing a
  /// file — distinct from an actual failure, so the caller can silently do
  /// nothing rather than show an error for a plain cancel.
  bool get isCancelled => path == null && error == null;
}

/// Thumbnail/Artwork support: picks a local image via Storage Access
/// Framework, or downloads the source thumbnail URL the extraction already
/// returned. Both converge on [ArtworkPickResult] so the Download Options
/// sheet never needs to know which path produced the local file.
class ArtworkService {
  ArtworkService._();

  static final ArtworkService instance = ArtworkService._();

  /// Opens the system image picker (SAF, `ACTION_OPEN_DOCUMENT`) and, once
  /// the user chooses a file, copies and validates it into a private temp
  /// file. Returns [ArtworkPickResult.isCancelled] when the user closes the
  /// picker without choosing anything.
  Future<ArtworkPickResult> pickCustomImage() async {
    try {
      final Map<Object?, Object?>? result = await PlatformChannels.artworkChannel
          .invokeMapMethod<Object?, Object?>(PlatformChannels.artworkPickCustomImage);
      final String? path = result?['path'] as String?;
      if (path == null || path.isEmpty) return const ArtworkPickResult.failure(null);
      return ArtworkPickResult.success(path);
    } on PlatformException catch (e) {
      return ArtworkPickResult.failure(e.message ?? 'Could not use that image.');
    } on MissingPluginException {
      return const ArtworkPickResult.failure('Image picking is not available on this build.');
    }
  }

  /// Downloads [url] — the thumbnail URL the extraction already returned
  /// in `MediaInfo.thumbnailUrl` — into a private temp file. Never triggers
  /// a new extraction and never re-downloads the media itself.
  Future<ArtworkPickResult> downloadSourceThumbnail(String url) async {
    try {
      final Map<Object?, Object?>? result = await PlatformChannels.artworkChannel
          .invokeMapMethod<Object?, Object?>(
            PlatformChannels.artworkDownloadSourceThumbnail,
            <String, Object?>{'url': url},
          );
      final String? path = result?['path'] as String?;
      if (path == null || path.isEmpty) {
        return const ArtworkPickResult.failure('The source thumbnail could not be downloaded.');
      }
      return ArtworkPickResult.success(path);
    } on PlatformException catch (e) {
      return ArtworkPickResult.failure(
        e.message ?? 'The source thumbnail could not be downloaded.',
      );
    } on MissingPluginException {
      return const ArtworkPickResult.failure('Thumbnail download is not available on this build.');
    }
  }

  /// Best-effort cleanup for a temp file this service produced but that
  /// ended up unused — the user canceled the sheet, or switched to a
  /// different artwork choice before Save. Never call this on a path that
  /// has already been handed to a running/started download.
  Future<void> deleteArtwork(String path) async {
    try {
      await PlatformChannels.artworkChannel.invokeMethod<void>(
        PlatformChannels.artworkDeleteArtwork,
        <String, Object?>{'path': path},
      );
    } catch (_) {
      // Best-effort only; a leftover temp file here is harmless.
    }
  }
}
