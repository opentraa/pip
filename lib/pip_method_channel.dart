import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'pip_platform_interface.dart';

/// An implementation of [PipPlatform] that uses method channels.
class MethodChannelPip extends PipPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('pip');

  PipStateChangedObserver? _stateChangedObserver;

  MethodChannelPip() {
    methodChannel.setMethodCallHandler(_handleMethod);
  }

  Future<void> _handleMethod(MethodCall call) async {
    try {
      if (call.method == 'stateChanged') {
        final jsonMap = Map<String, dynamic>.from(call.arguments as Map);
        final state = jsonMap['state'] as int;
        final error = jsonMap['error'] as String?;
        _stateChangedObserver?.onPipStateChanged(PipState.values[state], error);
      }
    } catch (e) {
      assert(false, 'stateChanged error: $e');
    }
  }

  @override
  Future<void> registerStateChangedObserver(
      PipStateChangedObserver observer) async {
    _stateChangedObserver = observer;
  }

  @override
  Future<void> unregisterStateChangedObserver() async {
    _stateChangedObserver = null;
  }

  @override
  Future<bool> isSupported() async {
    final result = await methodChannel.invokeMethod<bool>('isSupported', null);
    return result ?? false;
  }

  @override
  Future<bool> isAutoEnterSupported() async {
    final result =
        await methodChannel.invokeMethod<bool>('isAutoEnterSupported', null);
    return result ?? false;
  }

  @override
  Future<bool> isActived() async {
    final result = await methodChannel.invokeMethod<bool>('isActived', null);
    return result ?? false;
  }

  @override
  Future<bool> setup(PipOptions options) async {
    final dicOptions = options.toDictionary();

    final result = await methodChannel.invokeMethod<bool>('setup', dicOptions);
    return result ?? false;
  }

  @override
  Future<int> getPipView() async {
    if (Platform.isIOS) {
      final result = await methodChannel.invokeMethod<int>('getPipView', null);
      return result ?? 0;
    }

    return Future.value(0);
  }

  @override
  Future<bool> start() async {
    final result = await methodChannel.invokeMethod<bool>('start', null);
    return result ?? false;
  }

  @override
  Future<void> stop() async {
    await methodChannel.invokeMethod<bool>('stop', null);
  }

  @override
  Future<void> dispose() async {
    await methodChannel.invokeMethod<bool>('dispose', null);
  }
}
