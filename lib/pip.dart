import 'pip_platform_interface.dart';

export 'pip_platform_interface.dart'
    show PipOptions, PipStateChangedObserver, PipState;

class Pip {
  Future<void> registerStateChangedObserver(
      PipStateChangedObserver observer) async {
    return PipPlatform.instance.registerStateChangedObserver(observer);
  }

  /// Unregisters a Picture in Picture state change observer.
  Future<void> unregisterStateChangedObserver() async {
    return PipPlatform.instance.unregisterStateChangedObserver();
  }

  /// Check if Picture in Picture is supported.
  ///
  /// Returns
  /// Whether Picture in Picture is supported.
  Future<bool> isSupported() async {
    return PipPlatform.instance.isSupported();
  }

  /// Check if Picture in Picture can auto enter.
  ///
  /// Returns
  /// Whether Picture in Picture can auto enter.
  Future<bool> isAutoEnterSupported() async {
    return PipPlatform.instance.isAutoEnterSupported();
  }

  /// Check if Picture in Picture is actived.
  ///
  /// Returns
  /// Whether Picture in Picture is actived.
  Future<bool> isActived() async {
    return PipPlatform.instance.isActived();
  }

  /// Setup or update Picture in Picture.
  ///
  /// [options] The options of the Picture in Picture.
  ///
  /// Returns
  /// Whether Picture in Picture is setup successfully.
  Future<bool> setup(PipOptions options) async {
    return PipPlatform.instance.setup(options);
  }

  /// Get the Picture in Picture view.
  /// Only available on iOS.
  ///
  /// Returns
  /// The Picture in Picture view.
  Future<int> getPipView() async {
    return PipPlatform.instance.getPipView();
  }

  /// Start Picture in Picture.
  ///
  /// Returns
  /// Whether Picture in Picture is started successfully.
  Future<bool> start() async {
    return PipPlatform.instance.start();
  }

  /// Stop Picture in Picture.
  Future<void> stop() async {
    return PipPlatform.instance.stop();
  }

  /// Dispose Picture in Picture.
  Future<void> dispose() async {
    return PipPlatform.instance.dispose();
  }
}
