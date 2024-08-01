import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gse_plugin_dibujo_firma/gse_plugin_dibujo_firma_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelGsePluginDibujoFirma platform = MethodChannelGsePluginDibujoFirma();
  const MethodChannel channel = MethodChannel('gse_plugin_dibujo_firma');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
  });
}
