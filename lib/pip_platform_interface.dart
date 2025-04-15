import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/widgets.dart' show TargetPlatform;

import 'pip_method_channel.dart';

/// @nodoc
class PipOptions {
  /// @nodoc
  const PipOptions({
    this.autoEnterEnabled,

    // android only
    this.aspectRatioX,
    this.aspectRatioY,
    this.sourceRectHintLeft,
    this.sourceRectHintTop,
    this.sourceRectHintRight,
    this.sourceRectHintBottom,

    // ios only
    this.sourceContentView,
    this.contentView,
    this.preferredContentWidth,
    this.preferredContentHeight,
    this.controlStyle,
  });

  /// @nodoc
  final bool? autoEnterEnabled;

  /// android only
  /// @nodoc
  final int? aspectRatioX;

  /// @nodoc
  final int? aspectRatioY;

  /// @nodoc
  final int? sourceRectHintLeft;

  /// @nodoc
  final int? sourceRectHintTop;

  /// @nodoc
  final int? sourceRectHintRight;

  /// @nodoc
  final int? sourceRectHintBottom;

  /// ios only
  /// @nodoc
  final int? sourceContentView;

  /// after setup, the content view will be added to the pip view
  /// user should be responsible for the rendering of the content view.
  /// @nodoc
  final int? contentView;

  /// @nodoc
  final int? preferredContentWidth;

  /// @nodoc
  final int? preferredContentHeight;

  /// @nodoc
  /// 0: default show all system controls
  /// 1: hide forward and backward button
  /// 2: hide play pause button and the progress bar including forward and backward button (recommended)
  /// 3: hide all system controls including the close and restore button
  final int? controlStyle;

  /// @nodoc
  Map<String, dynamic> toDictionary() {
    final val = <String, dynamic>{};

    void writeNotNull(String key, dynamic value) {
      if (value != null) {
        val[key] = value;
      }
    }

    writeNotNull('autoEnterEnabled', autoEnterEnabled);

    // only for android
    if (defaultTargetPlatform == TargetPlatform.android) {
      writeNotNull('aspectRatioX', aspectRatioX);
      writeNotNull('aspectRatioY', aspectRatioY);
      writeNotNull('sourceRectHintLeft', sourceRectHintLeft);
      writeNotNull('sourceRectHintTop', sourceRectHintTop);
      writeNotNull('sourceRectHintRight', sourceRectHintRight);
      writeNotNull('sourceRectHintBottom', sourceRectHintBottom);
    }

    // only for ios
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      writeNotNull('sourceContentView', sourceContentView);
      writeNotNull('contentView', contentView);
      writeNotNull('preferredContentWidth', preferredContentWidth);
      writeNotNull('preferredContentHeight', preferredContentHeight);
      writeNotNull('controlStyle', controlStyle);
    }
    return val;
  }
}

/// @nodoc
enum PipState {
  /// @nodoc
  pipStateStarted,

  /// @nodoc
  pipStateStopped,

  /// @nodoc
  pipStateFailed,
}

class PipStateChangedObserver {
  /// @nodoc
  const PipStateChangedObserver({
    required this.onPipStateChanged,
  });

  /// @nodoc
  final void Function(PipState state, String? error) onPipStateChanged;
}

abstract class PipPlatform extends PlatformInterface {
  /// Constructs a PipPlatform.
  PipPlatform() : super(token: _token);

  static final Object _token = Object();

  static PipPlatform _instance = MethodChannelPip();

  /// The default instance of [PipPlatform] to use.
  ///
  /// Defaults to [MethodChannelPip].
  static PipPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PipPlatform] when
  /// they register themselves.
  static set instance(PipPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Registers a Picture in Picture state change observer.
  ///
  /// [observer] The Picture in Picture state change observer.
  Future<void> registerStateChangedObserver(
      PipStateChangedObserver observer) async {
    throw UnimplementedError(
        'registerStateChangedObserver() has not been implemented.');
  }

  /// Unregisters a Picture in Picture state change observer.
  Future<void> unregisterStateChangedObserver() async {
    throw UnimplementedError(
        'unregisterStateChangedObserver() has not been implemented.');
  }

  /// Check if Picture in Picture is supported.
  ///
  /// Returns
  /// Whether Picture in Picture is supported.
  Future<bool> isSupported() async {
    throw UnimplementedError('isSupported() has not been implemented.');
  }

  /// Check if Picture in Picture can auto enter.
  ///
  /// Returns
  /// Whether Picture in Picture can auto enter.
  Future<bool> isAutoEnterSupported() async {
    throw UnimplementedError(
        'isAutoEnterSupported() has not been implemented.');
  }

  /// Check if Picture in Picture is actived.
  ///
  /// Returns
  /// Whether Picture in Picture is actived.
  Future<bool> isActived() async {
    throw UnimplementedError('isActived() has not been implemented.');
  }

  /// Setup or update Picture in Picture.
  ///
  /// [options] The options of the Picture in Picture.
  ///
  /// Returns
  /// Whether Picture in Picture is setup successfully.
  Future<bool> setup(PipOptions options) async {
    throw UnimplementedError('setup() has not been implemented.');
  }

  /// Get the Picture in Picture view.
  /// Only available on iOS.
  ///
  /// Returns
  /// The Picture in Picture view.
  Future<int> getPipView() async {
    throw UnimplementedError('getPipView() has not been implemented.');
  }

  /// Start Picture in Picture.
  ///
  /// Returns
  /// Whether Picture in Picture is started successfully.
  Future<bool> start() async {
    throw UnimplementedError('start() has not been implemented.');
  }

  /// Stop Picture in Picture.
  Future<void> stop() async {
    throw UnimplementedError('stop() has not been implemented.');
  }

  /// Dispose Picture in Picture.
  Future<void> dispose() async {
    throw UnimplementedError('dispose() has not been implemented.');
  }
}
