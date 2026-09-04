import '../downloader/extraction_error_mapper.dart';

/// The most recent Fetch/download failure, kept purely in memory so the
/// Developer information page can show real, current context instead of a
/// static snapshot. Holds nothing beyond what [MappedExtractionError]
/// already carries — no second error-classification system, no persistence,
/// and it is overwritten by the next failure or cleared on a cold start.
class LastExtractionError {
  LastExtractionError._();

  static final LastExtractionError instance = LastExtractionError._();

  MappedExtractionError? error;
  String? platform;

  void record(MappedExtractionError error, {String? platform}) {
    this.error = error;
    this.platform = platform;
  }
}
