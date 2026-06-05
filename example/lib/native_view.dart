import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef PlatformViewCreatedCallback = void Function(
  int viewId,
  int internalViewId,
);

/// A widget representing an underlying platform view.
class NativeWidget extends StatelessWidget {
  /// Constructor
  const NativeWidget({super.key, required this.onPlatformViewCreated});

  final PlatformViewCreatedCallback onPlatformViewCreated;

  @override
  Widget build(BuildContext context) {
    const String viewType = 'native_view';
    final Map<String, dynamic> creationParams = <String, dynamic>{};

    return UiKitView(
      viewType: viewType,
      layoutDirection: TextDirection.ltr,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: (id) async {
        final methodChannel = MethodChannel('native_plugin/native_view_$id');
        final internalViewId =
            await methodChannel.invokeMethod<int>('getInternalView') ?? 0;
        onPlatformViewCreated(id, internalViewId);
      },
    );
  }
}
