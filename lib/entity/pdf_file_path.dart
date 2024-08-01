import 'dart:typed_data';
import 'dart:io';

class PdfFilePath  {
  final String path;

  const PdfFilePath({required this.path});


  Future<Uint8List> getDocumentData(){
    final document = File(path);
    return document.readAsBytes();
  }
}