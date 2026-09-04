import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fetchy/core/engine/downloader_engine.dart';
import 'package:fetchy/core/platform/platform_channels.dart';
import 'package:fetchy/features/downloader/downloader_service.dart';
import 'package:fetchy/features/media/format_parser.dart';
import 'package:fetchy/features/media/format_selector.dart';
import 'package:fetchy/features/media/media_info.dart';

/// Records what the downloader layer actually hands to the engine, which is
/// the contract this fix is about: the previewed entry's index has to survive
/// all the way down, and must stay absent when there is no playlist.
class _RecordingEngine implements DownloaderEngine {
  int? lastPlaylistIndex;
  bool startDownloadCalled = false;

  @override
  Stream<DownloadEvent> get downloadEvents =>
      const Stream<DownloadEvent>.empty();

  @override
  Future<MediaInfo> extract(String url, {String? timingRunId}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> startDownload({
    required String downloadId,
    required String url,
    required String formatId,
    String? audioFormatId,
    Map<String, Object?>? storage,
    Map<String, Object?>? downloadOptions,
    int? playlistIndex,
  }) async {
    startDownloadCalled = true;
    lastPlaylistIndex = playlistIndex;
  }

  @override
  Future<bool> cancelDownload(String downloadId) async => true;
}

FormatCandidate _combinedCandidate() {
  return FormatCandidate.combined(
    const ParsedFormat(
      raw: MediaFormat(formatId: '0', extension: 'mp4', height: 720),
      kind: FormatKind.videoAndAudio,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('MediaInfo.playlistIndex', () {
    test('is read from a multi-entry extraction payload', () {
      final MediaInfo info = MediaInfo.fromMap(<Object?, Object?>{
        'sourceUrl': 'https://snapchat.com/t/IRZXSOY',
        'title': 'View',
        'playlistIndex': 4,
      });

      expect(info.playlistIndex, 4);
    });

    test('is null for an ordinary single-video extraction payload', () {
      final MediaInfo info = MediaInfo.fromMap(<Object?, Object?>{
        'sourceUrl': 'https://youtube.com/watch?v=abc',
        'title': 'Clip',
      });

      expect(info.playlistIndex, isNull);
    });
  });

  group('DownloaderService.startDownload', () {
    test('forwards the previewed entry index to the engine', () async {
      final _RecordingEngine engine = _RecordingEngine();
      final DownloaderService service = DownloaderService(engine: engine);

      final DownloadStartResult result = await service.startDownload(
        downloadId: 'dl_1',
        url: 'https://snapchat.com/t/IRZXSOY',
        candidate: _combinedCandidate(),
        playlistIndex: 4,
      );

      expect(result, isA<DownloadAccepted>());
      expect(engine.startDownloadCalled, isTrue);
      expect(engine.lastPlaylistIndex, 4);
    });

    test('passes no entry index when the media is not part of a playlist',
        () async {
      final _RecordingEngine engine = _RecordingEngine();
      final DownloaderService service = DownloaderService(engine: engine);

      await service.startDownload(
        downloadId: 'dl_2',
        url: 'https://youtube.com/watch?v=abc',
        candidate: _combinedCandidate(),
      );

      expect(engine.startDownloadCalled, isTrue);
      expect(engine.lastPlaylistIndex, isNull);
    });
  });

  group('PlatformDownloaderEngine channel payload', () {
    late List<MethodCall> calls;

    setUp(() {
      calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(PlatformChannels.engineChannel, (
        MethodCall call,
      ) async {
        calls.add(call);
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(PlatformChannels.engineChannel, null);
    });

    test('carries playlistIndex to native when one was previewed', () async {
      await PlatformDownloaderEngine.instance.startDownload(
        downloadId: 'dl_3',
        url: 'https://snapchat.com/t/IRZXSOY',
        formatId: '0',
        playlistIndex: 4,
      );

      final Map<Object?, Object?> arguments =
          calls.single.arguments as Map<Object?, Object?>;
      expect(arguments['playlistIndex'], 4);
    });

    test('sends a null playlistIndex for a single-video download', () async {
      await PlatformDownloaderEngine.instance.startDownload(
        downloadId: 'dl_4',
        url: 'https://youtube.com/watch?v=abc',
        formatId: '22',
      );

      final Map<Object?, Object?> arguments =
          calls.single.arguments as Map<Object?, Object?>;
      expect(arguments['playlistIndex'], isNull);
    });
  });
}
