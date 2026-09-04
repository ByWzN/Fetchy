import 'format_helpers.dart';

/// One completed download recorded locally. Every field traces back to
/// real data the engine reported for that download — nothing here is
/// fabricated for display purposes.
class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.title,
    required this.sourceUrl,
    required this.downloadedAt,
    this.thumbnailUrl,
    this.fileName,
    this.outputPath,
    this.outputUri,
    this.mediaType,
    this.qualityLabel,
    this.fileSizeBytes,
  });

  final String id;
  final String title;
  final String sourceUrl;
  final DateTime downloadedAt;

  final String? thumbnailUrl;
  final String? fileName;
  final String? outputPath;
  final String? outputUri;

  /// "video" or "audio". Null when unknown.
  final String? mediaType;

  /// e.g. "1080p" or "High". Whatever label was shown to the user at
  /// download time.
  final String? qualityLabel;
  final int? fileSizeBytes;

  String get platform => detectPlatformName(sourceUrl);

  String? get extension {
    final String? name = fileName ?? outputPath;
    if (name == null || !name.contains('.')) return null;
    return name.split('.').last.toUpperCase();
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'title': title,
      'sourceUrl': sourceUrl,
      'downloadedAt': downloadedAt.toIso8601String(),
      'thumbnailUrl': thumbnailUrl,
      'fileName': fileName,
      'outputPath': outputPath,
      'outputUri': outputUri,
      'mediaType': mediaType,
      'qualityLabel': qualityLabel,
      'fileSizeBytes': fileSizeBytes,
    };
  }

  static HistoryEntry? tryFromJson(Map<String, Object?> json) {
    final String? id = json['id'] as String?;
    final String? title = json['title'] as String?;
    final String? sourceUrl = json['sourceUrl'] as String?;
    final String? downloadedAtRaw = json['downloadedAt'] as String?;
    if (id == null || title == null || sourceUrl == null) return null;

    final DateTime? downloadedAt = downloadedAtRaw == null
        ? null
        : DateTime.tryParse(downloadedAtRaw);
    if (downloadedAt == null) return null;

    return HistoryEntry(
      id: id,
      title: title,
      sourceUrl: sourceUrl,
      downloadedAt: downloadedAt,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      fileName: json['fileName'] as String?,
      outputPath: json['outputPath'] as String?,
      outputUri: json['outputUri'] as String?,
      mediaType: json['mediaType'] as String?,
      qualityLabel: json['qualityLabel'] as String?,
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt(),
    );
  }
}
