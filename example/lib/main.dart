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
  final _aspectRatioXController = TextEditingController(text: '16');
  final _aspectRatioYController = TextEditingController(text: '9');
  bool _autoEnterEnabled = false;

  final _nativePlugin = NativePlugin();

  AppLifecycleState _lastAppLifecycleState = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
      // if you set the root view as the source view, you can call pipStart to enter pip mode on iOS.
      // however, if you call pipSetup after PlatformView is created, it may not work very well, coz
      // the source view need some time to be ready. So the best practice is set the autoEnterEnabled to true if
      // it is supported and call pipStart only in the resumed state.
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
        autoEnterEnabled: _autoEnterEnabled,

        // android only
        aspectRatioX: int.tryParse(_aspectRatioXController.text),
        aspectRatioY: int.tryParse(_aspectRatioYController.text),

        // ios only
        contentView: _pipContentView,
        sourceContentView: _playerView,
        preferredContentWidth: 900,
        preferredContentHeight: 1600,
        controlStyle: 2,
      );

      try {
        final success = await _pip.setup(options);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'PiP Setup ${success ? 'successful' : 'failed'}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PiP Setup error: $e')),
        );
      }
    }
  }

  Widget _buildPipView() {
    if (!Platform.isAndroid) {
      return SizedBox(
        height: 200,
        child: NativeWidget(
          onPlatformViewCreated: (id, internalViewId) {
            print('Platform view created: $id, internalViewId: $internalViewId');
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
                return Image.asset(
                  _imagePaths[_currentImageIndex],
                  width: _isPipActived ? constraints.maxWidth : null,
                  height: _isPipActived ? constraints.maxHeight : 200,
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
        Text(
          'Supported: $_isPipSupported\n'
          'Auto Enter Supported: $_isPipAutoEnterSupported\n'
          'Actived: $_isPipActived',
          style: const TextStyle(fontSize: 16),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Auto Enter Enabled'),
          value: _autoEnterEnabled,
          onChanged: (value) =>
              setState(() => _autoEnterEnabled = value ?? false),
        ),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _aspectRatioXController,
                decoration: const InputDecoration(labelText: 'Aspect Ratio X'),
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
                decoration: const InputDecoration(labelText: 'Aspect Ratio Y'),
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
          child: const Text('Setup PiP'),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              final success = await _pip.start();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text('PiP Start ${success ? 'successful' : 'failed'}')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('PiP Start error: $e')),
              );
            }
          },
          child: const Text('Start PiP'),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              await _pip.stop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PiP Stopped')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('PiP Stop error: $e')),
              );
            }
          },
          child: const Text('Stop PiP'),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              await _pip.dispose();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PiP Disposed')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('PiP Dispose error: $e')),
              );
            }
          },
          child: const Text('Dispose PiP'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isPipSupported
          ? (Platform.isAndroid && _isPipActived)
              ? _buildPipView()
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPipView(),
                          if (!(Platform.isAndroid && _isPipActived)) ...[
                            _buildPipFunctions(),
                          ],
                        ],
                      ),
                    ),
                  ),
                )
          : const Center(
              child: Text('Pip is not supported'),
            ),
    );
  }
}
