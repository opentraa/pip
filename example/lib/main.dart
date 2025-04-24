import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

import 'native_view.dart';

import 'package:flutter/services.dart';
import 'package:pip/pip.dart';
import 'package:native_plugin/native_plugin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => const HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final _pip = Pip();
  final _formKey = GlobalKey<FormState>();

  bool _isPipSupported = false;
  bool _isPipAutoEnterSupported = false;
  bool _isPipActived = false;
  int _playerView = 0;
  int _pipContentView = 0;
  int _currentImageIndex = 0;
  Timer? _imageTimer;

  final List<String> _imagePaths = [
    'images/PIP1.png',
    'images/PIP2.png',
    'images/PIP3.png',
  ];

  // Add controllers for input fields
  late final TextEditingController _aspectRatioXController;
  late final TextEditingController _aspectRatioYController;
  bool _autoEnterEnabled = false;

  final _nativePlugin = NativePlugin();

  AppLifecycleState _lastAppLifecycleState = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // We highly recommend to set the aspect ratio or preferred width and height based on the screen size, 
    // which will make the PiP experience more seamless.
    
    // Initialize controllers with default values based on platform
    final size = WidgetsBinding.instance.window.physicalSize;
    final scale = WidgetsBinding.instance.window.devicePixelRatio;
    final width = size.width / scale;
    final height = size.height / scale;
    
    if (Platform.isIOS) {
      _aspectRatioXController = TextEditingController(text: width.toStringAsFixed(0));
      _aspectRatioYController = TextEditingController(text: height.toStringAsFixed(0));
    } else {
      // Find the simplest ratio that matches the aspect ratio
      int gcd(int a, int b) {
        while (b != 0) {
          final t = b;
          b = a % b;
          a = t;
        }
        return a;
      }
      
      final divisor = gcd(width.toInt(), height.toInt());
      final x = (width / divisor).round();
      final y = (height / divisor).round();
      
      _aspectRatioXController = TextEditingController(text: x.toString());
      _aspectRatioYController = TextEditingController(text: y.toString());
    }
    
    initPlatformState();
    if (Platform.isAndroid) {
      _startImageTimer();
    }
  }

  void _startImageTimer() {
    _imageTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _currentImageIndex = (_currentImageIndex + 1) % _imagePaths.length;
      });
    });
  }

  @override
  void dispose() {
    if (Platform.isIOS && _pipContentView != 0) {
      _nativePlugin.disposePipContentView(_pipContentView);
    }

    _imageTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _aspectRatioXController.dispose();
    _aspectRatioYController.dispose();
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    print("[didChangeAppLifecycleState]: $state");

    if (state == AppLifecycleState.inactive) {
      // We recommend to set the autoEnterEnabled to true if the pip is auto enter supported not to call pipStart on inactive state.
      // https://developer.apple.com/documentation/avkit/adopting-picture-in-picture-in-a-custom-player?language=objc#Handle-User-Initiated-Requests
      // Important:
      // Only begin PiP playback in response to user interaction and never programmatically.
      // The App Store review team rejects apps that fail to follow this requirement.
      if (_lastAppLifecycleState != AppLifecycleState.paused &&
          !_isPipAutoEnterSupported) {
        await _pip.start();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (!Platform.isAndroid) {
        // on Android, the pipStop is not supported, the pipStop operation is only bring the activity to background.
        await _pip.stop();
      }
    }

    // The AppLifecycleState.hidden state was introduced in Flutter 3.13.0 to handle when
    // the app is temporarily hidden but not paused (e.g. during app switching on iOS).
    // Since this code needs to support Flutter 3.7.0+ for compatibility, we use
    // a switch statement that only handles lifecycle states available in all supported versions.
    // This allows us to safely ignore the hidden state and avoid unintentionally entering PiP
    // mode when the app recovers from being paused.
    // See: https://docs.flutter.dev/release/breaking-changes/add-applifecyclestate-hidden
    switch (state) {
      case AppLifecycleState.resumed:
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        if (_lastAppLifecycleState != state) {
          setState(() {
            _lastAppLifecycleState = state;
          });
        }
        break;
      default:
        break;
    }
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    bool pipIsSupported = false;
    bool pipIsAutoEnterSupported = false;
    bool isPipActived = false;
    try {
      var platformVersion = await _nativePlugin.getPlatformVersion();
      print('[platformVersion]: $platformVersion');
      pipIsSupported = await _pip.isSupported();
      pipIsAutoEnterSupported = await _pip.isAutoEnterSupported();
      isPipActived = await _pip.isActived();
      await _pip.registerStateChangedObserver(PipStateChangedObserver(
        onPipStateChanged: (state, error) {
          print('[onPipStateChanged] state: $state, error: $error');
          setState(() {
            _isPipActived = state == PipState.pipStateStarted;
          });

          if (state == PipState.pipStateFailed) {
            print('[onPipStateChanged] state: $state, error: $error');
            // if you destroy the source view of pip controller, some error may happen,
            // so we need to dispose the pip controller here.
            _pip.dispose();
          }
        },
      ));
    } on PlatformException {
      pipIsSupported = false;
      pipIsAutoEnterSupported = false;
      isPipActived = false;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _isPipSupported = pipIsSupported;
      _isPipAutoEnterSupported = pipIsAutoEnterSupported;
      _isPipActived = isPipActived;

      // set the autoEnterEnabled to true if the pip is auto enter supported
      _autoEnterEnabled = pipIsAutoEnterSupported;
    });
  }

  Future<void> _setupPip() async {
    if (_formKey.currentState!.validate()) {
      if (Platform.isIOS && _pipContentView == 0) {
        _pipContentView = await _nativePlugin.createPipContentView();
        print('[createPipContentView]: $_pipContentView');

        setState(() {
          _pipContentView = _pipContentView;
        });
      }
      final options = PipOptions(
        // According to https://developer.android.com/develop/ui/views/picture-in-picture#setautoenterenabled and Apple documentation
        // Both platforms recommend setting autoEnterEnabled to true for the best user experience.
        autoEnterEnabled: _autoEnterEnabled,

        // android only
        // The aspect ratio of the source view, keep same as the aspect ratio of the player view.
        aspectRatioX: int.tryParse(_aspectRatioXController.text),
        aspectRatioY: int.tryParse(_aspectRatioYController.text),
        // According to https://developer.android.com/develop/ui/views/picture-in-picture#set-sourcerecthint
        // If your app doesn't provide a proper sourceRectHint, the system tries to apply a content overlay
        // during the PiP entering animation, which makes for a poor user experience.
        sourceRectHintLeft: 0,
        sourceRectHintTop: 0,
        sourceRectHintRight: 0,
        sourceRectHintBottom: 0,
        // According to https://developer.android.com/develop/ui/views/picture-in-picture#seamless-resizing
        // The setSeamlessResizeEnabled flag is set to true by default for backward compatibility.
        // Leave this set to true for video content, and change it to false for non-video content.
        seamlessResizeEnabled: true,
        // The external state monitor checks the PiP view state at the interval specified by externalStateMonitorInterval (100ms).
        // This is necessary because FlutterActivity does not forward PiP state change events to the Flutter side.
        // Even if your Activity is a subclass of PipActivity, you can still use the external state monitor to track PiP state changes.
        useExternalStateMonitor: true,
        externalStateMonitorInterval: 100,

        // ios only
        contentView: _pipContentView,
        sourceContentView: _playerView,
        preferredContentWidth: int.tryParse(_aspectRatioXController.text),
        preferredContentHeight: int.tryParse(_aspectRatioYController.text),
        controlStyle: 2,
      );

      try {
        final success = await _pip.setup(options);
        print('PiP Setup ${success ? 'successful' : 'failed'}');
      } catch (e) {
        print('PiP Setup error: $e');
      }
    }
  }

  Widget _buildPipView() {
    if (!Platform.isAndroid) {
      return SizedBox(
        height: 200,
        child: NativeWidget(
          onPlatformViewCreated: (id, internalViewId) {
            print(
                'Platform view created: $id, internalViewId: $internalViewId');
            setState(() {
              _playerView = internalViewId;
            });
          },
        ),
      );
    }

    return Center(
      child: Builder(
        builder: (context) {
          try {
            return LayoutBuilder(
              builder: (context, constraints) {
                final size = MediaQuery.of(context).size;
                final imageWidth = size.width;
                final imageHeight = size.height;
                
                return Image.asset(
                  _imagePaths[_currentImageIndex],
                  width: imageWidth,
                  height: imageHeight,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    print('Error loading image: $error');
                    print('Stack trace: $stackTrace');
                    return const Text('Error loading image');
                  },
                );
              },
            );
          } catch (e) {
            print('Exception while loading image: $e');
            return Text('Exception: $e');
          }
        },
      ),
    );
  }

  Widget _buildPipFunctions() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.start,
      children: [
        if (_isPipAutoEnterSupported)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Auto Enter Enabled',
              style: TextStyle(color: Colors.white),
            ),
            value: _autoEnterEnabled,
            onChanged: (value) =>
                setState(() => _autoEnterEnabled = value ?? false),
            activeColor: Colors.blue,
            checkColor: Colors.white,
          ),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _aspectRatioXController,
                decoration: InputDecoration(
                  labelText: (Platform.isAndroid
                      ? 'Aspect Ratio X'
                      : 'Preferred Width'),
                  labelStyle: const TextStyle(color: Colors.white),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _aspectRatioYController,
                decoration: InputDecoration(
                  labelText: (Platform.isAndroid
                      ? 'Aspect Ratio Y'
                      : 'Preferred Height'),
                  labelStyle: const TextStyle(color: Colors.white),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        ElevatedButton(
          onPressed: _setupPip,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Setup'),
        ),
        if (!_isPipActived)
          ElevatedButton(
            onPressed: () async {
              try {
                final success = await _pip.start();
                print('PiP Start ${success ? 'successful' : 'failed'}');
              } catch (e) {
                print('PiP Start error: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start'),
          ),
        if (_isPipActived && !Platform.isAndroid)
          ElevatedButton(
            onPressed: () async {
              try {
                await _pip.stop();
                print('PiP Stopped');
              } catch (e) {
                print('PiP Stop error: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Stop'),
          ),
        ElevatedButton(
          onPressed: () async {
            try {
              await _pip.dispose();
              print('PiP Disposed');
            } catch (e) {
              print('PiP Dispose error: $e');
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Dispose'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isPipSupported
          ? Stack(
              children: [
                // Bottom layer: PIP View
                Positioned.fill(
                  child: _buildPipView(),
                ),
                // Overlay layer: Controls
                if (!(Platform.isAndroid && _isPipActived))
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      child: SingleChildScrollView(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPipFunctions(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            )
          : const Center(
              child: Text(
                'Pip is not supported',
                style: TextStyle(color: Colors.white),
              ),
            ),
    );
  }
}
