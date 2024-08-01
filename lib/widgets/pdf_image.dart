import 'dart:typed_data';

import 'package:flutter/material.dart';

class PdfImageWidget extends StatelessWidget{


  final Future<Uint8List?> imgData;
  final GlobalKey imgKey;
  PdfImageWidget({super.key, required this.imgData, required this.imgKey});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: imgData,
        builder: (context, snapshot){
          if(snapshot.connectionState == ConnectionState.waiting){
            return const Center(
              child: CircularProgressIndicator(),
            );
          }else{

            return Image.memory(snapshot.requireData!,key: imgKey,);
          }
        }
    );
  }

}