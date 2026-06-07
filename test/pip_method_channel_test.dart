import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pip/pip_platform_interface.dart';
import 'package:pip/pip_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('pip');
  late MethodChannelPip platform;
  late List<MethodCall> methodCalls;

  setUp(() {
    platform = MethodChannelPip();
    methodCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          switch (methodCall.method) {
            case 'isSupported':
            case 'isAutoEnterSupported':
            case 'setup':
            case 'start':
              return true;
            case 'isActived':
              return false;
            case 'getPipView':
              return 123;
            case 'stop':
            case 'dispose':
              return null;
            default:
              throw PlatformException(code: 'unimplemented');
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('forwards platform method calls to the native channel', () async {
    expect(await platform.isSupported(), isTrue);
    expect(await platform.isAutoEnterSupported(), isTrue);
    expect(await platform.isActived(), isFalse);
    expect(
      await platform.setup(const PipOptions(autoEnterEnabled: true)),
      isTrue,
    );
    expect(await platform.start(), isTrue);
    await platform.stop();
    await platform.dispose();

    expect(methodCalls.map((call) => call.method), <String>[
      'isSupported',
      'isAutoEnterSupported',
      'isActived',
      'setup',
      'start',
      'stop',
      'dispose',
    ]);
  });

  test('returns a native PiP view pointer on iOS only', () async {
    final pipView = await platform.getPipView();

    expect(pipView, Platform.isIOS ? 123 : 0);
    expect(
      methodCalls.map((call) => call.method),
      Platform.isIOS ? <String>['getPipView'] : isEmpty,
    );
  });

  test('serializes setup options for the active platform', () async {
    await platform.setup(
      const PipOptions(
        autoEnterEnabled: true,
        aspectRatioX: 16,
        aspectRatioY: 9,
        sourceRectHintLeft: 1,
        sourceRectHintTop: 2,
        sourceRectHintRight: 3,
        sourceRectHintBottom: 4,
        seamlessResizeEnabled: true,
        useExternalStateMonitor: true,
        externalStateMonitorInterval: 100,
        sourceContentView: 10,
        contentView: 11,
        preferredContentWidth: 200,
        preferredContentHeight: 100,
        controlStyle: 2,
      ),
    );

    final setupCall = methodCalls.singleWhere((call) => call.method == 'setup');
    final arguments = Map<String, Object?>.from(setupCall.arguments as Map);

    expect(arguments['autoEnterEnabled'], isTrue);
    if (Platform.isAndroid) {
      expect(arguments['aspectRatioX'], 16);
      expect(arguments['aspectRatioY'], 9);
      expect(arguments['sourceRectHintLeft'], 1);
      expect(arguments['sourceRectHintTop'], 2);
      expect(arguments['sourceRectHintRight'], 3);
      expect(arguments['sourceRectHintBottom'], 4);
      expect(arguments['seamlessResizeEnabled'], isTrue);
      expect(arguments['useExternalStateMonitor'], isTrue);
      expect(arguments['externalStateMonitorInterval'], 100);
      expect(arguments.containsKey('contentView'), isFalse);
    } else if (Platform.isIOS) {
      expect(arguments['sourceContentView'], 10);
      expect(arguments['contentView'], 11);
      expect(arguments['preferredContentWidth'], 200);
      expect(arguments['preferredContentHeight'], 100);
      expect(arguments['controlStyle'], 2);
      expect(arguments.containsKey('aspectRatioX'), isFalse);
    }
  });

  test('notifies registered observers when native state changes', () async {
    PipState? receivedState;
    String? receivedError;
    await platform.registerStateChangedObserver(
      PipStateChangedObserver(
        onPipStateChanged: (state, error) {
          receivedState = state;
          receivedError = error;
        },
      ),
    );

    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          'pip',
          channel.codec.encodeMethodCall(
            const MethodCall('stateChanged', <String, Object?>{
              'state': 2,
              'error': 'Pip is not possible',
            }),
          ),
          (_) {},
        );

    expect(receivedState, PipState.pipStateFailed);
    expect(receivedError, 'Pip is not possible');
  });

  test('accepts stable native state code strings', () async {
    final expectedStates = <String, PipState>{
      'started': PipState.pipStateStarted,
      'stopped': PipState.pipStateStopped,
      'failed': PipState.pipStateFailed,
    };

    for (final entry in expectedStates.entries) {
      PipState? receivedState;
      await platform.registerStateChangedObserver(
        PipStateChangedObserver(
          onPipStateChanged: (state, _) {
            receivedState = state;
          },
        ),
      );

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            'pip',
            channel.codec.encodeMethodCall(
              MethodCall('stateChanged', <String, Object?>{'state': entry.key}),
            ),
            (_) {},
          );

      expect(receivedState, entry.value);
    }
  });

  test(
    'ignores unknown native state code strings without notifying observers',
    () async {
      var callbackCount = 0;
      await platform.registerStateChangedObserver(
        PipStateChangedObserver(
          onPipStateChanged: (_, __) {
            callbackCount += 1;
          },
        ),
      );

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            'pip',
            channel.codec.encodeMethodCall(
              const MethodCall('stateChanged', <String, Object?>{
                'state': 'unknown',
              }),
            ),
            (_) {},
          );

      expect(callbackCount, 0);
    },
  );

  test(
    'ignores invalid native state payloads without notifying observers',
    () async {
      var callbackCount = 0;
      await platform.registerStateChangedObserver(
        PipStateChangedObserver(
          onPipStateChanged: (_, __) {
            callbackCount += 1;
          },
        ),
      );

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            'pip',
            channel.codec.encodeMethodCall(
              const MethodCall('stateChanged', <String, Object?>{
                'state': 'not-a-valid-state',
                'error': 123,
              }),
            ),
            (_) {},
          );

      expect(callbackCount, 0);
    },
  );

  test(
    'ignores non-map native state payloads without notifying observers',
    () async {
      var callbackCount = 0;
      await platform.registerStateChangedObserver(
        PipStateChangedObserver(
          onPipStateChanged: (_, __) {
            callbackCount += 1;
          },
        ),
      );

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            'pip',
            channel.codec.encodeMethodCall(
              const MethodCall('stateChanged', 'started'),
            ),
            (_) {},
          );

      expect(callbackCount, 0);
    },
  );

  test('ignores unknown native methods without notifying observers', () async {
    var callbackCount = 0;
    await platform.registerStateChangedObserver(
      PipStateChangedObserver(
        onPipStateChanged: (_, __) {
          callbackCount += 1;
        },
      ),
    );

    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          'pip',
          channel.codec.encodeMethodCall(
            const MethodCall('unknownMethod', <String, Object?>{
              'state': 'started',
            }),
          ),
          (_) {},
        );

    expect(callbackCount, 0);
  });

  test(
    'ignores non-string native state errors without notifying observers',
    () async {
      var callbackCount = 0;
      await platform.registerStateChangedObserver(
        PipStateChangedObserver(
          onPipStateChanged: (_, __) {
            callbackCount += 1;
          },
        ),
      );

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            'pip',
            channel.codec.encodeMethodCall(
              const MethodCall('stateChanged', <String, Object?>{
                'state': 'failed',
                'error': 123,
              }),
            ),
            (_) {},
          );

      expect(callbackCount, 0);
    },
  );

  test(
    'keeps backward compatibility with legacy native state indexes',
    () async {
      PipState? receivedState;
      await platform.registerStateChangedObserver(
        PipStateChangedObserver(
          onPipStateChanged: (state, _) {
            receivedState = state;
          },
        ),
      );

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            'pip',
            channel.codec.encodeMethodCall(
              const MethodCall('stateChanged', <String, Object?>{'state': 1}),
            ),
            (_) {},
          );

      expect(receivedState, PipState.pipStateStopped);
    },
  );
}
