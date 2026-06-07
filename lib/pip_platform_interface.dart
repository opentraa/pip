import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/widgets.dart' show TargetPlatform;

import 'pip_method_channel.dart';

/// Picture in Picture options.
class PipOptions {
  const PipOptions({
    this.autoEnterEnabled,

    // android only
    this.aspectRatioX,
    this.aspectRatioY,
    this.sourceRectHintLeft,
    this.sourceRectHintTop,
    this.sourceRectHintRight,
    this.sourceRectHintBottom,
    this.seamlessResizeEnabled,
    this.useExternalStateMonitor,
    this.externalStateMonitorInterval,

    // ios only
    this.sourceContentView,
    this.contentView,
    this.preferredContentWidth,
    this.preferredContentHeight,
    this.controlStyle,
  });

  /// Whether Picture in Picture can auto enter.
  ///
  /// Default is false.
  final bool? autoEnterEnabled;

  /// android only
  /// The width of the aspect ratio.
  final int? aspectRatioX;

  /// The height of the aspect ratio.
  final int? aspectRatioY;

  /// The left of the source rect hint.
  final int? sourceRectHintLeft;

  /// The top of the source rect hint.
  final int? sourceRectHintTop;

  /// The right of the source rect hint.
  final int? sourceRectHintRight;

  /// The bottom of the source rect hint.
  final int? sourceRectHintBottom;

  /// Whether to enable seamless resize.
  ///
  /// Default is false.
  final bool? seamlessResizeEnabled;

  /// Whether to use external state monitor to detect the Picture in Picture state.
  ///
  /// Default is false. If true, the Picture in Picture state will be detected by the external state monitor thread.
  final bool? useExternalStateMonitor;

  /// The interval of the external state monitor.
  ///
  /// Default is 100 milliseconds.
  final int? externalStateMonitorInterval;

  /// ios only
  /// The source content view.
  final int? sourceContentView;

  /// after setup, the content view will be added to the pip view
  /// user should be responsible for the rendering of the content view.
  final int? contentView;

  /// The preferred width of the content view.
  final int? preferredContentWidth;

  /// The preferred height of the content view.
  final int? preferredContentHeight;

  /// The control style of the content view.
  ///
  /// 0: default show all system controls
  /// 1: hide forward and backward button
  /// 2: hide play pause button and the progress bar including forward and backward button (recommended)
  /// 3: hide all system controls including the close and restore button
  final int? controlStyle;

  /// Convert the options to a dictionary.
  Map<String, dynamic> toDictionary() {
    final targetPlatform = defaultTargetPlatform;
    _validate(targetPlatform);

    final val = <String, dynamic>{};

    void writePropertyIfNotNull(String key, dynamic value) {
      if (value != null) {
        val[key] = value;
      }
    }

    writePropertyIfNotNull('autoEnterEnabled', autoEnterEnabled);

    // only for android
    if (targetPlatform == TargetPlatform.android) {
      writePropertyIfNotNull('aspectRatioX', aspectRatioX);
      writePropertyIfNotNull('aspectRatioY', aspectRatioY);
      writePropertyIfNotNull('sourceRectHintLeft', sourceRectHintLeft);
      writePropertyIfNotNull('sourceRectHintTop', sourceRectHintTop);
      writePropertyIfNotNull('sourceRectHintRight', sourceRectHintRight);
      writePropertyIfNotNull('sourceRectHintBottom', sourceRectHintBottom);
      writePropertyIfNotNull('seamlessResizeEnabled', seamlessResizeEnabled);
      writePropertyIfNotNull(
        'useExternalStateMonitor',
        useExternalStateMonitor,
      );
      writePropertyIfNotNull(
        'externalStateMonitorInterval',
        externalStateMonitorInterval,
      );
    }

    // only for ios
    if (targetPlatform == TargetPlatform.iOS) {
      writePropertyIfNotNull('sourceContentView', sourceContentView);
      writePropertyIfNotNull('contentView', contentView);
      writePropertyIfNotNull('preferredContentWidth', preferredContentWidth);
      writePropertyIfNotNull('preferredContentHeight', preferredContentHeight);
      writePropertyIfNotNull('controlStyle', controlStyle);
    }
    return val;
  }

  void _validate(TargetPlatform targetPlatform) {
    if (targetPlatform == TargetPlatform.android) {
      _validateAndroidOptions();
    }
    if (targetPlatform == TargetPlatform.iOS) {
      _validateIosOptions();
    }
  }

  void _validateAndroidOptions() {
    final hasAspectRatioX = aspectRatioX != null;
    final hasAspectRatioY = aspectRatioY != null;
    if (hasAspectRatioX != hasAspectRatioY) {
      throw ArgumentError(
        'aspectRatioX and aspectRatioY must be provided together.',
      );
    }
    if (aspectRatioX != null && aspectRatioX! <= 0) {
      throw ArgumentError.value(aspectRatioX, 'aspectRatioX');
    }
    if (aspectRatioY != null && aspectRatioY! <= 0) {
      throw ArgumentError.value(aspectRatioY, 'aspectRatioY');
    }

    final rectValues = <int?>[
      sourceRectHintLeft,
      sourceRectHintTop,
      sourceRectHintRight,
      sourceRectHintBottom,
    ];
    final rectValueCount = rectValues.where((value) => value != null).length;
    if (rectValueCount != 0 && rectValueCount != rectValues.length) {
      throw ArgumentError(
        'All sourceRectHint values must be provided together.',
      );
    }
    final isEmptySourceRectHint =
        sourceRectHintLeft == 0 &&
        sourceRectHintTop == 0 &&
        sourceRectHintRight == 0 &&
        sourceRectHintBottom == 0;
    if (sourceRectHintLeft != null &&
        !isEmptySourceRectHint &&
        sourceRectHintRight! <= sourceRectHintLeft!) {
      throw ArgumentError('sourceRectHintRight must be greater than left.');
    }
    if (sourceRectHintTop != null &&
        !isEmptySourceRectHint &&
        sourceRectHintBottom! <= sourceRectHintTop!) {
      throw ArgumentError('sourceRectHintBottom must be greater than top.');
    }

    if (externalStateMonitorInterval != null &&
        externalStateMonitorInterval! <= 0) {
      throw ArgumentError.value(
        externalStateMonitorInterval,
        'externalStateMonitorInterval',
      );
    }
  }

  void _validateIosOptions() {
    final hasPreferredContentWidth = preferredContentWidth != null;
    final hasPreferredContentHeight = preferredContentHeight != null;
    if (hasPreferredContentWidth != hasPreferredContentHeight) {
      throw ArgumentError(
        'preferredContentWidth and preferredContentHeight must be provided together.',
      );
    }
    if (preferredContentWidth != null && preferredContentWidth! <= 0) {
      throw ArgumentError.value(preferredContentWidth, 'preferredContentWidth');
    }
    if (preferredContentHeight != null && preferredContentHeight! <= 0) {
      throw ArgumentError.value(
        preferredContentHeight,
        'preferredContentHeight',
      );
    }

    if (controlStyle != null && (controlStyle! < 0 || controlStyle! > 3)) {
      throw ArgumentError.value(controlStyle, 'controlStyle');
    }
  }
}

/// The state of the Picture in Picture.
enum PipState {
  /// The Picture in Picture is started.
  pipStateStarted,

  /// The Picture in Picture is stopped.
  pipStateStopped,

  /// The Picture in Picture is failed.
  pipStateFailed;

  /// Stable native wire protocol code for this state.
  String get code {
    switch (this) {
      case PipState.pipStateStarted:
        return 'started';
      case PipState.pipStateStopped:
        return 'stopped';
      case PipState.pipStateFailed:
        return 'failed';
    }
  }

  /// Parses native wire protocol values into [PipState].
  ///
  /// String values are the stable protocol. Integer values are accepted for
  /// backward compatibility with older native implementations.
  static PipState? fromNative(Object? value) {
    if (value is String) {
      switch (value) {
        case 'started':
          return PipState.pipStateStarted;
        case 'stopped':
          return PipState.pipStateStopped;
        case 'failed':
          return PipState.pipStateFailed;
      }
      return null;
    }

    if (value is int && value >= 0 && value < PipState.values.length) {
      return PipState.values[value];
    }

    return null;
  }
}

class PipStateChangedObserver {
  /// The observer of the Picture in Picture state changed.
  const PipStateChangedObserver({required this.onPipStateChanged});

  /// The callback of the Picture in Picture state changed.
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
    PipStateChangedObserver observer,
  ) async {
    throw UnimplementedError(
      'registerStateChangedObserver() has not been implemented.',
    );
  }

  /// Unregisters a Picture in Picture state change observer.
  Future<void> unregisterStateChangedObserver() async {
    throw UnimplementedError(
      'unregisterStateChangedObserver() has not been implemented.',
    );
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
      'isAutoEnterSupported() has not been implemented.',
    );
  }

  /// Check if Picture in Picture is active.
  ///
  /// Returns
  /// Whether Picture in Picture is active.
  Future<bool> isActive() async {
    // ignore: deprecated_member_use_from_same_package
    return isActived();
  }

  /// Check if Picture in Picture is active.
  ///
  /// Returns
  /// Whether Picture in Picture is active.
  @Deprecated('Use isActive instead.')
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
