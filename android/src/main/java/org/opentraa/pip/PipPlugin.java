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
        final Map<?, ?> args = (Map<?, ?>)call.arguments;
        Rational aspectRatio = null;
        if (args.get("aspectRatioX") != null &&
            args.get("aspectRatioY") != null) {
          aspectRatio = new Rational((int)args.get("aspectRatioX"),
                                     (int)args.get("aspectRatioY"));
        }
        Boolean autoEnterEnabled = null;
        if (args.get("autoEnterEnabled") != null) {
          autoEnterEnabled = (boolean)args.get("autoEnterEnabled");
        }
        Rect sourceRectHint = null;
        if (args.get("sourceRectHintLeft") != null &&
            args.get("sourceRectHintTop") != null &&
            args.get("sourceRectHintRight") != null &&
            args.get("sourceRectHintBottom") != null) {
          sourceRectHint = new Rect((int)args.get("sourceRectHintLeft"),
                                    (int)args.get("sourceRectHintTop"),
                                    (int)args.get("sourceRectHintRight"),
                                    (int)args.get("sourceRectHintBottom"));
        }
        Boolean seamlessResizeEnabled = null;
        if (args.get("seamlessResizeEnabled") != null) {
          seamlessResizeEnabled = (boolean)args.get("seamlessResizeEnabled");
        }
        Boolean useExternalStateMonitor = null;
        if (args.get("useExternalStateMonitor") != null) {
          useExternalStateMonitor =
              (boolean)args.get("useExternalStateMonitor");
        }
        Integer externalStateMonitorInterval = null;
        if (args.get("externalStateMonitorInterval") != null) {
          externalStateMonitorInterval =
              (int)args.get("externalStateMonitorInterval");
        }
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
    channel.setMethodCallHandler(null);
    if(pipController!=null){
      pipController.dispose();
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
                                     { put("state", state.getValue()); }
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
  public void onDetachedFromActivityForConfigChanges() {}

  @Override
  public void onReattachedToActivityForConfigChanges(
      @NonNull ActivityPluginBinding binding) {
    initPipController(binding);
  }

  @Override
  public void onDetachedFromActivity() {}
}
