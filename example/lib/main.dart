import 'package:flutter/material.dart';
import 'dart:async';

import 'dart:developer';
import 'package:gse_plugin_dibujo_firma/gse_plugin_dibujo_firma.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const MaterialApp(
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState(BuildContext ctx) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null) {
      return;
    }
    String path = result.files.first.path!;
    await Navigator.push(ctx, MaterialPageRoute(builder: (context) => GsePluginDibujoFirma(path: path, page: 0, onSignResult: (info){print(info!);},)));
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: [
            ElevatedButton(onPressed: () async {
              initPlatformState(context);
            }, child: const Text('Select')),
            Center(
              child: Text('Running on: $_platformVersion\n'),
            ),
          ],
        ),
      ),
    );
  }
}
