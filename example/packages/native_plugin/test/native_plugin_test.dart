import 'package:flutter_test/flutter_test.dart';
import 'package:native_plugin/native_plugin.dart';
import 'package:native_plugin/native_plugin_platform_interface.dart';
import 'package:native_plugin/native_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNativePluginPlatform
    with MockPlatformInterfaceMixin
    implements NativePluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final NativePluginPlatform initialPlatform = NativePluginPlatform.instance;

  test('$MethodChannelNativePlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNativePlugin>());
  });

  test('getPlatformVersion', () async {
    NativePlugin nativePlugin = NativePlugin();
    MockNativePluginPlatform fakePlatform = MockNativePluginPlatform();
    NativePluginPlatform.instance = fakePlatform;

    expect(await nativePlugin.getPlatformVersion(), '42');
  });
}
