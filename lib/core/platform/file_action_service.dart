import 'package:flutter/services.dart';

class FileActionResult {
  const FileActionResult({required this.success, this.error});

  final bool success;
  final String? error;
}

class FileStatusResult {
  const FileStatusResult({
    required this.exists,
    this.sizeBytes,
    this.displayPath,
  });

  final bool exists;
  final int? sizeBytes;
  final String? displayPath;
}

class FileActionService {
  FileActionService._();

  static final FileActionService instance = FileActionService._();

  static const MethodChannel _channel = MethodChannel(
    'app.fetchy/file_actions',
  );

  Future<FileActionResult> openFile({
    String? uri,
    String? path,
    String? mimeType,
  }) async {
    try {
      final Map<Object?, Object?>? result = await _channel
          .invokeMapMethod<Object?, Object?>('openFile', <String, Object?>{
            'uri': uri,
            'path': path,
            'mimeType': mimeType,
          });
      final bool success = (result?['success'] as bool?) ?? false;
      final String? error = result?['error'] as String?;
      return FileActionResult(success: success, error: error);
    } on PlatformException catch (e) {
      return FileActionResult(success: false, error: e.message);
    } catch (e) {
      return FileActionResult(success: false, error: e.toString());
    }
  }

  Future<FileActionResult> shareFile({
    String? uri,
    String? path,
    String? mimeType,
  }) async {
    try {
      final Map<Object?, Object?>? result = await _channel
          .invokeMapMethod<Object?, Object?>('shareFile', <String, Object?>{
            'uri': uri,
            'path': path,
            'mimeType': mimeType,
          });
      final bool success = (result?['success'] as bool?) ?? false;
      final String? error = result?['error'] as String?;
      return FileActionResult(success: success, error: error);
    } on PlatformException catch (e) {
      return FileActionResult(success: false, error: e.message);
    } catch (e) {
      return FileActionResult(success: false, error: e.toString());
    }
  }

  /// Opens an http(s) link in the user's browser — used for the upstream
  /// yt-dlp/youtubedl-android/FFmpeg resource links in Technical
  /// information. A plain system Intent, same pattern as [openFile]/
  /// [shareFile]; no url_launcher dependency needed for this.
  Future<bool> openExternalUrl(String url) async {
    try {
      return await _channel.invokeMethod<bool>('openExternalUrl', <String, Object?>{
            'url': url,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<FileStatusResult> checkFileExists({String? uri, String? path}) async {
    try {
      final Map<Object?, Object?>? result = await _channel
          .invokeMapMethod<Object?, Object?>(
            'checkFileExists',
            <String, Object?>{'uri': uri, 'path': path},
          );
      final bool exists = (result?['exists'] as bool?) ?? false;
      final int? sizeBytes = (result?['sizeBytes'] as num?)?.toInt();
      final String? displayPath = result?['displayPath'] as String?;
      return FileStatusResult(
        exists: exists,
        sizeBytes: (sizeBytes != null && sizeBytes > 0) ? sizeBytes : null,
        displayPath: displayPath,
      );
    } catch (_) {
      return const FileStatusResult(exists: false);
    }
  }
}
