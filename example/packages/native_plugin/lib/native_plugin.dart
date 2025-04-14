
import 'native_plugin_platform_interface.dart';

class NativePlugin {
  Future<String?> getPlatformVersion() {
    return NativePluginPlatform.instance.getPlatformVersion();
  }
}
