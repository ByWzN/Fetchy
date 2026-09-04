import 'dart:async';

import 'package:flutter/services.dart';

import '../../core/platform/platform_channels.dart';

class ShareIntentService {
  ShareIntentService._();

  static final ShareIntentService instance = ShareIntentService._();

  final StreamController<String> _sharedLinksController =
      StreamController<String>.broadcast();

  bool _isStarted = false;
  bool _initialLinkConsumed = false;

  Stream<String> get sharedLinks => _sharedLinksController.stream;

  void start() {
    if (_isStarted) {
      return;
    }
    _isStarted = true;
    PlatformChannels.shareChannel.setMethodCallHandler(_handleMethodCall);
  }

  Future<String?> consumeInitialSharedLink() async {
    if (_initialLinkConsumed) {
      return null;
    }
    _initialLinkConsumed = true;

    try {
      final String? text = await PlatformChannels.shareChannel
          .invokeMethod<String>(PlatformChannels.getInitialSharedText);
      return _normalize(text);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method != PlatformChannels.onSharedText) {
      return;
    }

    final Object? arguments = call.arguments;
    final String? text = arguments is String ? _normalize(arguments) : null;

    if (text != null && !_sharedLinksController.isClosed) {
      _sharedLinksController.add(text);
    }
  }

  String? _normalize(String? raw) {
    final String? trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  Future<void> dispose() async {
    PlatformChannels.shareChannel.setMethodCallHandler(null);
    _isStarted = false;
    await _sharedLinksController.close();
  }
}
