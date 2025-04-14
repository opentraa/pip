import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'native_plugin_platform_interface.dart';

/// An implementation of [NativePluginPlatform] that uses method channels.
class MethodChannelNativePlugin extends NativePluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('native_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
