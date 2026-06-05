import 'package:flutter_test/flutter_test.dart';
import 'package:pip/pip.dart';
import 'package:pip/pip_method_channel.dart';
import 'package:pip/pip_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPipPlatform with MockPlatformInterfaceMixin implements PipPlatform {
  PipOptions? lastOptions;
  PipStateChangedObserver? observer;
  bool stopCalled = false;
  bool disposeCalled = false;

  @override
  Future<void> registerStateChangedObserver(
      PipStateChangedObserver observer) async {
    this.observer = observer;
  }

  @override
  Future<void> unregisterStateChangedObserver() async {
    observer = null;
  }

  @override
  Future<bool> isSupported() async => true;

  @override
  Future<bool> isAutoEnterSupported() async => true;

  @override
  Future<bool> isActived() async => false;

  @override
  Future<bool> setup(PipOptions options) async {
    lastOptions = options;
    return true;
  }

  @override
  Future<int> getPipView() async => 42;

  @override
  Future<bool> start() async => true;

  @override
  Future<void> stop() async {
    stopCalled = true;
  }

  @override
  Future<void> dispose() async {
    disposeCalled = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final initialPlatform = PipPlatform.instance;

  tearDown(() {
    PipPlatform.instance = initialPlatform;
  });

  test('$MethodChannelPip is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPip>());
  });

  test('delegates public API calls to the platform implementation', () async {
    final fakePlatform = MockPipPlatform();
    PipPlatform.instance = fakePlatform;
    final pip = Pip();

    await pip.registerStateChangedObserver(
      PipStateChangedObserver(onPipStateChanged: (_, __) {}),
    );
    expect(fakePlatform.observer, isNotNull);

    expect(await pip.isSupported(), isTrue);
    expect(await pip.isAutoEnterSupported(), isTrue);
    expect(await pip.isActived(), isFalse);
    expect(await pip.setup(const PipOptions(autoEnterEnabled: true)), isTrue);
    expect(fakePlatform.lastOptions?.autoEnterEnabled, isTrue);
    expect(await pip.getPipView(), 42);
    expect(await pip.start(), isTrue);

    await pip.stop();
    expect(fakePlatform.stopCalled, isTrue);

    await pip.dispose();
    expect(fakePlatform.disposeCalled, isTrue);

    await pip.unregisterStateChangedObserver();
    expect(fakePlatform.observer, isNull);
  });
}
