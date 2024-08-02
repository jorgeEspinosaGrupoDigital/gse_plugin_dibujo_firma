import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gse_plugin_dibujo_firma/entity/pdf_file_path.dart';



/// An implementation of [GsePluginDibujoFirmaPlatform] that uses method channels.
class MethodChannelGsePluginDibujoFirma {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  static const methodChannel = MethodChannel('gse_plugin_dibujo_firma');

  static Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  static Future<Uint8List?> getPage({required int page, required Future<bool?> doc}) async {
    await doc;
    final arguments = {"page":page};
    final imgData = await methodChannel.invokeMethod<Uint8List>('renderPage',arguments);
    return imgData;
  }

  static Future<bool?> loadDocument(PdfFilePath doc) async {
    final Uint8List bytes = await doc.getDocumentData();
    final arguments = {"data":bytes};
    return await methodChannel.invokeMethod<bool>("loadDocument",arguments);
  }

  static void closeDocument(){
    methodChannel.invokeMethod("closeDocument");
  }
}
