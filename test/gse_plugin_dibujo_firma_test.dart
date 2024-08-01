import 'package:flutter_test/flutter_test.dart';
import 'package:gse_plugin_dibujo_firma/gse_plugin_dibujo_firma.dart';
import 'package:gse_plugin_dibujo_firma/gse_plugin_dibujo_firma_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockGsePluginDibujoFirmaPlatform
    with MockPlatformInterfaceMixin{

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {

}
