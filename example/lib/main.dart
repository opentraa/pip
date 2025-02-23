import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:pip/pip.dart';

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
  int _pipView = 0;

  // Add controllers for input fields
  final _aspectRatioXController = TextEditingController(text: '16');
  final _aspectRatioYController = TextEditingController(text: '9');
  bool _autoEnterEnabled = false;

  AppLifecycleState _lastAppLifecycleState = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initPlatformState();
  }

  @override
  void dispose() {
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
    });
  }

  Future<void> _setupPip() async {
    if (_formKey.currentState!.validate()) {
      final options = PipOptions(
        autoEnterEnabled: _autoEnterEnabled,
        aspectRatioX: int.tryParse(_aspectRatioXController.text),
        aspectRatioY: int.tryParse(_aspectRatioYController.text),
      );

      try {
        final success = await _pip.setup(options);
        final pipView = await _pip.getPipView();
        setState(() {
          _pipView = pipView;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'PiP Setup ${success ? 'successful, pipView: $pipView' : 'failed'}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PiP Setup error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter PiP Demo'),
      ),
      body: _isPipSupported
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PiP Status:\n'
                      'Supported: $_isPipSupported\n'
                      'Auto Enter Supported: $_isPipAutoEnterSupported\n'
                      'Actived: $_isPipActived',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    CheckboxListTile(
                      title: const Text('Auto Enter Enabled'),
                      value: _autoEnterEnabled,
                      onChanged: (value) =>
                          setState(() => _autoEnterEnabled = value ?? false),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _aspectRatioXController,
                      decoration:
                          const InputDecoration(labelText: 'Aspect Ratio X'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _aspectRatioYController,
                      decoration:
                          const InputDecoration(labelText: 'Aspect Ratio Y'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8.0, // 水平间距
                      runSpacing: 8.0, // 垂直间距
                      alignment: WrapAlignment.start,
                      children: [
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
                                    content: Text(
                                        'PiP Start ${success ? 'successful' : 'failed'}')),
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
                                SnackBar(
                                    content: Text('PiP Dispose error: $e')),
                              );
                            }
                          },
                          child: const Text('Dispose PiP'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : const Center(
              child: Text('Pip is not supported'),
            ),
    );
  }
}
