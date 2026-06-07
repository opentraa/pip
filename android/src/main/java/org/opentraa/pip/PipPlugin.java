package org.opentraa.pip;

import android.graphics.Rect;
import android.util.Rational;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import java.util.HashMap;
import java.util.Map;

/** PipPlugin */
public class PipPlugin
    implements FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native
  /// Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine
  /// and unregister it when the Flutter Engine is detached from the Activity
  private MethodChannel channel;

  /// The controller for the PiP feature
  private PipController pipController;

  private String toStateCode(PipController.PipState state) {
    switch (state) {
    case Started:
      return "started";
    case Stopped:
      return "stopped";
    case Failed:
      return "failed";
    default:
      return "unknown";
    }
  }

  static Integer parsePositiveInt(Object value) {
    if (!(value instanceof Integer)) {
      return null;
    }
    Integer intValue = (Integer)value;
    return intValue > 0 ? intValue : null;
  }

  static Rect parseSourceRect(Object left, Object top, Object right,
                              Object bottom) {
    Integer parsedLeft = left instanceof Integer ? (Integer)left : null;
    Integer parsedTop = top instanceof Integer ? (Integer)top : null;
    Integer parsedRight = right instanceof Integer ? (Integer)right : null;
    Integer parsedBottom = bottom instanceof Integer ? (Integer)bottom : null;
    if (parsedLeft == null || parsedTop == null || parsedRight == null ||
        parsedBottom == null) {
      return null;
    }
    boolean isEmptyRect = parsedLeft == 0 && parsedTop == 0 &&
                          parsedRight == 0 && parsedBottom == 0;
    if (isEmptyRect) {
      return new Rect(parsedLeft, parsedTop, parsedRight, parsedBottom);
    }
    if (parsedRight <= parsedLeft || parsedBottom <= parsedTop) {
      return null;
    }
    return new Rect(parsedLeft, parsedTop, parsedRight, parsedBottom);
  }

  @Override
  public void
  onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel =
        new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "pip");
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (pipController != null) {
      switch (call.method) {
      case "isSupported":
        result.success(pipController.isSupported());
        break;
      case "isAutoEnterSupported":
        result.success(pipController.isAutoEnterSupported());
        break;
      case "isActived":
        result.success(pipController.isActived());
        break;
      case "setup":
        if (!(call.arguments instanceof Map)) {
          result.success(false);
          break;
        }
        final Map<?, ?> args = (Map<?, ?>)call.arguments;
        Rational aspectRatio = null;
        Integer aspectRatioX = parsePositiveInt(args.get("aspectRatioX"));
        Integer aspectRatioY = parsePositiveInt(args.get("aspectRatioY"));
        if (aspectRatioX != null && aspectRatioY != null) {
          aspectRatio = new Rational(aspectRatioX, aspectRatioY);
        }
        Boolean autoEnterEnabled =
            args.get("autoEnterEnabled") instanceof Boolean
                ? (Boolean)args.get("autoEnterEnabled")
                : null;
        Rect sourceRectHint =
            parseSourceRect(args.get("sourceRectHintLeft"),
                            args.get("sourceRectHintTop"),
                            args.get("sourceRectHintRight"),
                            args.get("sourceRectHintBottom"));
        Boolean seamlessResizeEnabled =
            args.get("seamlessResizeEnabled") instanceof Boolean
                ? (Boolean)args.get("seamlessResizeEnabled")
                : null;
        Boolean useExternalStateMonitor =
            args.get("useExternalStateMonitor") instanceof Boolean
                ? (Boolean)args.get("useExternalStateMonitor")
                : null;
        Integer externalStateMonitorInterval =
            parsePositiveInt(args.get("externalStateMonitorInterval"));
        result.success(
            pipController.setup(aspectRatio, autoEnterEnabled, sourceRectHint,
                                seamlessResizeEnabled, useExternalStateMonitor,
                                externalStateMonitorInterval));
        break;
      case "start":
        result.success(pipController.start());
        break;
      case "stop":
        pipController.stop();
        result.success(null);
        break;
      case "dispose":
        pipController.dispose();
        result.success(null);
        break;
      default:
        result.notImplemented();
      }
    } else {
      result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    if (channel != null) {
      channel.setMethodCallHandler(null);
      channel = null;
    }

    if (pipController != null) {
      pipController.dispose();
      pipController.detachFromActivity();
      pipController = null;
    }
  }

  private void initPipController(@NonNull ActivityPluginBinding binding) {
    if (pipController == null) {
      pipController = new PipController(
          binding.getActivity(), new PipController.PipStateChangedListener() {
            @Override
            public void onPipStateChangedListener(
                PipController.PipState state) {
              // put state into a json object
              channel.invokeMethod("stateChanged",
                                   new HashMap<String, Object>() {
                                     { put("state", toStateCode(state)); }
                                   });
            }
          });
    } else {
      pipController.attachToActivity(binding.getActivity());
    }
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    initPipController(binding);
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    if (pipController != null) {
      pipController.detachFromActivity();
    }
  }

  @Override
  public void onReattachedToActivityForConfigChanges(
      @NonNull ActivityPluginBinding binding) {
    initPipController(binding);
  }

  @Override
  public void onDetachedFromActivity() {
    if (pipController != null) {
      pipController.detachFromActivity();
    }
  }
}
