import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fetchy/core/platform/platform_channels.dart';
import 'package:fetchy/features/quick_fetch/quick_fetch_models.dart';
import 'package:fetchy/features/quick_fetch/quick_fetch_service.dart';
import 'package:fetchy/features/share/share_intent_service.dart';

/// Builds a capabilities payload shaped exactly like the native
/// QuickFetchChannelHandler.capabilities() map.
Map<Object?, Object?> capabilityPayload({
  bool enabled = true,
  bool accessibilityEnabled = false,
  bool accessibilityConnected = false,
  String installSource = 'unknown',
}) => <Object?, Object?>{
  'sdkInt': 33,
  'enabled': enabled,
  'actionStyle': 'notification',
  'accessibilityEnabled': accessibilityEnabled,
  'accessibilityConnected': accessibilityConnected,
  'canPostNotifications': true,
  'needsNotificationPermission': true,
  'canDrawOverlays': false,
  'hasPendingCandidate': false,
  'installSource': installSource,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Quick Fetch setup state', () {
    test('is READY only when the service is both enabled and bound', () {
      final QuickFetchCapabilities ready = QuickFetchCapabilities.fromMap(
        capabilityPayload(
          accessibilityEnabled: true,
          accessibilityConnected: true,
        ),
      );

      expect(ready.setupState, QuickFetchSetupState.ready);
      expect(ready.backgroundDetectionReady, isTrue);
    });

    test('is NOT_ENABLED when switched on but not yet bound', () {
      // Enabled in system settings but not connected is not "ready": the
      // platform has not actually bound the service, so detection is not
      // live and the UI must not claim it is.
      final QuickFetchCapabilities capabilities =
          QuickFetchCapabilities.fromMap(
            capabilityPayload(
              accessibilityEnabled: true,
              accessibilityConnected: false,
            ),
          );

      expect(capabilities.setupState, QuickFetchSetupState.notEnabled);
    });

    test('is NOT_ENABLED when the service is off', () {
      final QuickFetchCapabilities capabilities =
          QuickFetchCapabilities.fromMap(capabilityPayload());

      expect(capabilities.setupState, QuickFetchSetupState.notEnabled);
    });

    test('exposes exactly two states — no invented RESTRICTED state', () {
      // Android never tells an app *why* its accessibility service is off,
      // so the model must not offer a third state that implies it does.
      expect(QuickFetchSetupState.values, <QuickFetchSetupState>[
        QuickFetchSetupState.ready,
        QuickFetchSetupState.notEnabled,
      ]);
    });
  });

  group('Install source classification', () {
    test('maps each wire value to its bucket', () {
      expect(
        QuickFetchInstallSource.fromWireName('store'),
        QuickFetchInstallSource.store,
      );
      expect(
        QuickFetchInstallSource.fromWireName('sideload'),
        QuickFetchInstallSource.sideload,
      );
      expect(
        QuickFetchInstallSource.fromWireName('other'),
        QuickFetchInstallSource.other,
      );
    });

    test('anything unrecognized degrades to unknown', () {
      expect(
        QuickFetchInstallSource.fromWireName(null),
        QuickFetchInstallSource.unknown,
      );
      expect(
        QuickFetchInstallSource.fromWireName('com.some.installer'),
        QuickFetchInstallSource.unknown,
      );
    });

    test('restricted-settings guidance shows for sideload and unknown only', () {
      expect(
        QuickFetchInstallSource.sideload.mayNeedRestrictedSettingsStep,
        isTrue,
      );
      // Unknown gets the generic explanation rather than silence.
      expect(
        QuickFetchInstallSource.unknown.mayNeedRestrictedSettingsStep,
        isTrue,
      );
      // A store install is not subject to the restriction.
      expect(
        QuickFetchInstallSource.store.mayNeedRestrictedSettingsStep,
        isFalse,
      );
      expect(
        QuickFetchInstallSource.other.mayNeedRestrictedSettingsStep,
        isFalse,
      );
    });

    test('is carried through from the native capabilities payload', () {
      final QuickFetchCapabilities capabilities =
          QuickFetchCapabilities.fromMap(
            capabilityPayload(installSource: 'sideload'),
          );

      expect(capabilities.installSource, QuickFetchInstallSource.sideload);
    });
  });

  group('Quick Fetch settings intents', () {
    late List<MethodCall> calls;

    setUp(() {
      calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(PlatformChannels.quickFetchChannel, (
            MethodCall call,
          ) async {
            calls.add(call);
            return true;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(PlatformChannels.quickFetchChannel, null);
    });

    test('App Info uses its own official settings method', () async {
      await QuickFetchService.instance.openAppInfoSettings();

      expect(calls.single.method, PlatformChannels.quickFetchOpenAppInfoSettings);
      expect(calls.single.method, 'openAppInfoSettings');
    });

    test('Accessibility settings stay a separate action', () async {
      await QuickFetchService.instance.openAccessibilitySettings();

      expect(
        calls.single.method,
        PlatformChannels.quickFetchOpenAccessibilitySettings,
      );
    });
  });

  group('Share to Fetchy', () {
    late ShareIntentService service;

    setUp(() {
      service = ShareIntentService.instance;
      service.start();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(PlatformChannels.shareChannel, null);
    });

    /// Simulates native delivering a share while Fetchy is already running.
    Future<void> deliverWarmShare(String text) async {
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            PlatformChannels.shareChannelName,
            const StandardMethodCodec().encodeMethodCall(
              MethodCall(PlatformChannels.onSharedText, text),
            ),
            (_) {},
          );
    }

    test('a warm-start share reaches the shared-link stream', () async {
      final Future<String> received = service.sharedLinks.first;

      await deliverWarmShare('https://youtu.be/abc123');

      expect(await received, 'https://youtu.be/abc123');
    });

    test('repeated shares are each delivered, not collapsed', () async {
      final List<String> seen = <String>[];
      final sub = service.sharedLinks.listen(seen.add);

      await deliverWarmShare('https://youtu.be/first');
      await deliverWarmShare('https://youtu.be/second');
      // Deliberately the same link twice: sharing one link again is a real
      // user action and must not be swallowed.
      await deliverWarmShare('https://youtu.be/second');

      await sub.cancel();
      expect(seen, <String>[
        'https://youtu.be/first',
        'https://youtu.be/second',
        'https://youtu.be/second',
      ]);
    });

    test('blank shares are dropped rather than emitted', () async {
      final List<String> seen = <String>[];
      final sub = service.sharedLinks.listen(seen.add);

      await deliverWarmShare('   ');
      await deliverWarmShare('https://youtu.be/real');

      await sub.cancel();
      expect(seen, <String>['https://youtu.be/real']);
    });

    test('a cold-start share is consumed exactly once', () async {
      int initialCalls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(PlatformChannels.shareChannel, (
            MethodCall call,
          ) async {
            if (call.method == PlatformChannels.getInitialSharedText) {
              initialCalls++;
              return 'https://youtu.be/cold';
            }
            return null;
          });

      final String? first = await service.consumeInitialSharedLink();
      // A second read must not replay the same share — that is what would
      // make one shared link get fetched twice.
      final String? second = await service.consumeInitialSharedLink();

      expect(first, 'https://youtu.be/cold');
      expect(second, isNull);
      expect(initialCalls, 1);
    });
  });
}
