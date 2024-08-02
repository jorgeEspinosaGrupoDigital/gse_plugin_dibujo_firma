
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gse_plugin_dibujo_firma/gse_plugin_dibujo_firma_method_channel.dart';
import 'package:gse_plugin_dibujo_firma/widgets/pdf_image.dart';
import './entity/pdf_file_path.dart';
import 'dart:typed_data';
import 'package:pdf_render/pdf_render.dart';


enum StickerArea{
  inMovingArea,
  notInArea,
  inResizingArea
}

enum SignState{
  signing,
  resizing
}

class InfoSign {
  final int page;
  final double relativeX;
  static const String base64Image = '';
  final double relativeY;
  final double relativeW;
  final double relativeH;
  final double docWidth;
  final double docHeight;

  const InfoSign({
    required this.page,
    required this.relativeX,
    required this.relativeY,
    required this.relativeW,
    required this.relativeH,
    required this.docWidth,
    required this.docHeight
  });
}

class GsePluginDibujoFirma extends StatefulWidget{

  final String path;
  final int page;
  final void Function(Map<String, Object>?) onSignResult;
  late final Future<bool?> loadedDoc;
  late final PdfFilePath doc;
  late final Future<Uint8List?> imgData;
  late final Uint8List docData;

  GsePluginDibujoFirma({required this.path, required this.page, required this.onSignResult}) {
    doc = PdfFilePath(path: path);
    loadedDoc = MethodChannelGsePluginDibujoFirma.loadDocument(doc);
    imgData = MethodChannelGsePluginDibujoFirma.getPage(page: page, doc: loadedDoc);
    asignarBytes();
  }

  void asignarBytes() async {
    docData = await doc.getDocumentData();
  }

  @override
  State<StatefulWidget> createState() {
    return _pluginDibujoFirma();
  }

}

class _pluginDibujoFirma extends State<GsePluginDibujoFirma> {

  bool zoomIn = false;
  bool _drawingSign = false;
  SignState state = SignState.signing;
  late double? ratio;
  final GlobalKey _gestureKey = GlobalKey();
  final GlobalKey _containerKey = GlobalKey();
  bool _resizing = false;
  double _x = -1;
  double _y = -1;
  double _w = 0;
  double _h = 0;
  double realH = 0;
  double realW = 0;
  double desfase = 0;
  double _originMoveX = 0;
  double _originMoveY = 0;
  double _widthDoc = 0;
  double _heightDoc = 0;
  final double prctCorner = 0.33;

  @override
  void initState(){
    super.initState();
    initDoc();
    widget.imgData.then((value) async {
      final buffer = await ui.ImmutableBuffer.fromUint8List(value!);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);

      final imageW = descriptor.width;
      final imageH = descriptor.height;

      ratio = imageW / imageH;

      descriptor.dispose();
      buffer.dispose();
    });
  }

  void initDoc() async {
    PdfDocument pdfDocument = await PdfDocument.openData(await widget.doc.getDocumentData());
    PdfPage page = await pdfDocument.getPage(widget.page + 1);
    _widthDoc = page.width;
    _heightDoc = page.height;
    pdfDocument.dispose();
  }

  void iniciarFirmado() {
    final Size sizeContainer = getSizeContainer();
    realW = sizeContainer.width;
    realH = realW / ratio!;
    desfase = (sizeContainer.height - realH) / 2;
    setState(() {
      state = SignState.signing;
      _drawingSign = true;
    });
  }

  bool isInPage(double x, double y){
    if(y > desfase && y < (desfase + realH)){
      return true;
    }
    return false;
  }

  void retornarInfoFirma() {
    Size relativeOrigin = getRelativeSize(_x, _y);
    Size relativeSize = getRelativeSize(_w, _h + desfase);
    final result = {
      "page" : widget.page,
      "relativeX": (relativeOrigin.width),
      "relativeY": relativeOrigin.height,
      "relativeW": relativeSize.width,
      "relativeH": relativeSize.height,
      "docHeight": _heightDoc,
      "docWidth": _widthDoc,
      "docData": widget.docData
    };
    //InfoSign infoSign = InfoSign(page: widget.page, relativeX: (relativeOrigin.width), relativeY: relativeOrigin.height, relativeW: relativeSize.width, relativeH: relativeSize.height, docHeight: _heightDoc, docWidth: _widthDoc);
    widget.onSignResult(result);
  }

  void cancelarFirma() {
    setState(() {
      state = SignState.signing;
      _drawingSign = false;
      _x = -1;
      _y = -1;
      _w = 0;
      _h = 0;
    });
  }

  Size getRelativeSize(double x, double y) {
    final Size totalSize = getSizeContainer();
    final double relativeX = x / totalSize.width;
    final double relativeY = (y - desfase) / realH;
    Size resp = Size(relativeX, relativeY);
    return resp;
  }

  Size getSizeContainer(){
    final RenderBox renderBox = _gestureKey.currentContext!.findRenderObject() as RenderBox;
    return renderBox.size;
  }

  Size getSizeImage(){
    final RenderBox renderBox = _containerKey.currentContext!.findRenderObject() as RenderBox;
    return renderBox.size;
  }

  Size getOriginImage(){
    return Size(realW, realH);
  }


  void onTapActivateResize(BuildContext context, TapUpDetails details) {
    final imgSize = getSizeImage();
    final imgOrigin = getOriginImage();
    final gestureSize = getSizeContainer();
    final relativeSize = getRelativeSize(imgSize.width, imgSize.height + desfase);
    final relativePosition = getRelativeSize(_x, _y);
    print('container size: $gestureSize\nsign size: $imgSize \nimage size: $imgOrigin \nrelative pos: $relativePosition \nrelative size: $relativeSize');
    final x = details.localPosition.dx;
    final y = details.localPosition.dy;
    print('x: $_x\ny: $_y');
    final stickerArea = isInDrawnSign(x, y);
    if (stickerArea == StickerArea.notInArea) {
      return;
    }
    setState(() {
      _resizing = _resizing ? false : true;
    });
  }

  void onDragStartMove(BuildContext context, DragStartDetails details) {
    if (!_resizing) {
      return;
    }
    _originMoveX = details.localPosition.dx;
    _originMoveY = details.localPosition.dy;
  }

  void onDragUpdateMove(BuildContext context, DragUpdateDetails details) {
    if (!_resizing) {
      return;
    }
    final Offset offset = details.localPosition;
    final double displacementX = offset.dx - _originMoveX;
    final double displacementY = offset.dy - _originMoveY;
    print('$displacementX, $displacementY');
    print(
        'XY: $_x, $_y :: Origin: $_originMoveX, $_originMoveY :: Details: $offset');
    final Size rPosition =
    getRelativeSize((_x + displacementX + _w), (_y + displacementY + _h));
    final Size rOrigin = getRelativeSize(_x + displacementX, _y + displacementY);
    double newX = _x;
    double newY = _y;
    if ((_x + displacementX) >= 0 && rPosition.width < 1) {
      newX = _x + displacementX;
    }
    if (rOrigin.height >= 0 && rPosition.height < 1) {
      newY = _y + displacementY;
    }
    _originMoveX = offset.dx;
    _originMoveY = offset.dy;
    setState(() {
      _x = newX;
      _y = newY;
    });
  }

  void onDragStartResize(BuildContext context, DragStartDetails details) {
    if (!_resizing) {
      return;
    }
    _originMoveX = details.localPosition.dx;
    _originMoveY = details.localPosition.dy;
  }

  void onDragUpdateResize(BuildContext context, DragUpdateDetails details) {
    if (!_resizing) {
      return;
    }
    final double displacementW = details.localPosition.dx - _originMoveX;
    final double displacementH = details.localPosition.dy - _originMoveY;
    final Size rSize =
    getRelativeSize((_x + displacementW + _w), (_y + displacementH + _h));
    double newW = _w;
    double newH = _h;
    if ((_x + _w + displacementW) >= _x && rSize.width < 1) {
      newW = _w + displacementW;
    }
    if ((_y + _h + displacementH) >= _y && rSize.height < 1) {
      newH = _h + displacementH;
    }
    print('rSize: $rSize');
    print(
        'y: $_y, x: $_x, h: $_h, w: $_w, desplazaminetoH $displacementH, desplazamientoW: $displacementW, newH: $newH, newW: $newW');
    _originMoveX = details.localPosition.dx;
    _originMoveY = details.localPosition.dy;
    setState(() {
      _w = newW;
      _h = newH;
    });
  }

  StickerArea isInDrawnSign(double x, double y) {
    StickerArea retorno = StickerArea.inMovingArea;
    if (x <= _x + _w &&
        x >= (_x + (_w * (1 - prctCorner))) &&
        y <= _y + _h &&
        y >= (_y + (_h * (1 - prctCorner)))) {
      retorno = StickerArea.inResizingArea;
      print(retorno);
    } else if (x > (_x + _w) || x < _x || y > (_y + _h) || y < _y) {
      retorno = StickerArea.notInArea;
    }
    return retorno;
  }

  void onDragStartDetailing(BuildContext context, DragStartDetails details) {
    final stickerArea =
    isInDrawnSign(details.localPosition.dx, details.localPosition.dy);
    switch (stickerArea) {
      case StickerArea.inMovingArea:
        onDragStartMove(context, details);
        break;
      case StickerArea.inResizingArea:
        onDragStartResize(context, details);
        break;
      case StickerArea.notInArea:
        break;
    }
  }

  void onDragUpdateDetailing(BuildContext context, DragUpdateDetails details) {
    final stickerArea =
    isInDrawnSign(details.localPosition.dx, details.localPosition.dy);
    switch (stickerArea) {
      case StickerArea.inMovingArea:
        onDragUpdateMove(context, details);
        break;
      case StickerArea.inResizingArea:
        onDragUpdateResize(context, details);
        break;
      case StickerArea.notInArea:
        break;
    }
  }

  void onDragStart(BuildContext context, DragStartDetails details) {
    if( details.localPosition.dy <= desfase || details.localPosition.dy >= (realH + desfase)){
      return;
    }
    setState(() {
      _x = details.localPosition.dx;
      _y = details.localPosition.dy;
      _w = 0;
      _h = 0;
    });
  }

  void onDragUpdate(BuildContext context, DragUpdateDetails details) {
    if( details.localPosition.dy <= desfase || details.localPosition.dy >= (realH + desfase)){
      return;
    }
    final Size rPosition =
    getRelativeSize(details.localPosition.dx, details.localPosition.dy);
    if (_x == -1 || _y == -1) {
      return;
    }
    double X = details.localPosition.dx;
    double Y = details.localPosition.dy;
    double tW = _w;
    double tH = _h;
    if ((X - _x) > 0 && rPosition.width < 1) {
      tW = X - _x;
    }
    if ((Y - _y) > 0 && rPosition.height < 1) {
      tH = Y - _y;
    }
    setState(() {
      _w = tW;
      _h = tH;
    });
  }

  void onDragEnd(BuildContext context) {
    if (_w == 0 || _h == 0) {
      return;
    }
    setState(() {
      state = SignState.resizing;
    });
    //_buildDialogSign(context);
  }

  void Function(DragStartDetails)? getDragStart(BuildContext context) {
    void Function(DragStartDetails)? retornar;
    switch (state) {
      case SignState.signing:
        retornar = _drawingSign ?
            (DragStartDetails details) => {onDragStart(context, details)} : null;
        break;
      case SignState.resizing:
        retornar = _resizing
            ? (DragStartDetails details) =>
        {onDragStartDetailing(context, details)}
            : null;
        break;
    }
    return retornar;
  }

  void Function(DragUpdateDetails)? getDragUpdate(BuildContext context) {
    void Function(DragUpdateDetails)? retornar;
    switch (state) {
      case SignState.signing:
        retornar = _drawingSign ?
            (DragUpdateDetails details) => {onDragUpdate(context, details)} : null;
        break;
      case SignState.resizing:
        retornar = _resizing ? (DragUpdateDetails details) =>
        {onDragUpdateDetailing(context, details)} : null;
        break;
    }
    return retornar;
  }

  void Function(DragEndDetails)? getDragEnd(BuildContext context) {
    void Function(DragEndDetails)? retornar;
    switch (state) {
      case SignState.signing:
        retornar = _drawingSign ? (DragEndDetails details) => {onDragEnd(context)} : null;
        break;
      case SignState.resizing:
        break;
    }
    return retornar;
  }

  Widget? floatingButton(){

      return (state == SignState.signing)
          ? FloatingActionButton(
        backgroundColor: _drawingSign ? Colors.grey : null,
        onPressed: () => {iniciarFirmado()},
        child: const Icon(CupertinoIcons.signature),
      )
          : ButtonBar(
        alignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
              onPressed: () => {retornarInfoFirma()},
              child: const Icon(Icons.check)),
          ElevatedButton(
              onPressed: () => {cancelarFirma()},
              child: const Icon(Icons.clear))
        ],
      );

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: floatingButton(),
      body: FutureBuilder(
          future: widget.loadedDoc,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else {
              if (snapshot.requireData!) {
                return InteractiveViewer(
                    minScale: 1,
                    maxScale: 16,
                    onInteractionUpdate: (details){
                      if(details.scale > 1 && !zoomIn){
                        setState(() {
                          zoomIn = true;
                        });
                      }else if(details.scale <= 1 && zoomIn){
                        setState(() {
                          zoomIn = false;
                        });
                      }
                    },
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      key: _gestureKey,
                      onTapUp: (TapUpDetails details) =>
                      {onTapActivateResize(context, details)},
                      onVerticalDragStart: getDragStart(context),
                      onHorizontalDragStart: getDragStart(context),
                      onVerticalDragUpdate: getDragUpdate(context),
                      onHorizontalDragUpdate: getDragUpdate(context),
                      onVerticalDragEnd: getDragEnd(context),
                      onHorizontalDragEnd: getDragEnd(context),
                      child: Stack(
                        fit: StackFit.expand,
                        alignment: AlignmentDirectional.center,
                        children: [
                          PdfImageWidget(imgData: widget.imgData, imgKey: GlobalKey(),),
                          Positioned(
                            top: _y,
                            left: _x,
                            width: _w,
                            height: _h,
                            child: Container(
                              key: _containerKey,
                              decoration: BoxDecoration(
                                  border:
                                  Border.all(color: Colors.blue, width: 0.2),
                                  color: Colors.blue.shade100.withOpacity(0.5)),
                            ),
                          ),
                          !_resizing
                              ? Positioned(
                              top: 0,
                              left: 0,
                              width: 0,
                              height: 0,
                              child: Container())
                              : Positioned(
                              top: _y + (_h * (1 - prctCorner)),
                              left: _x + (_w * (1 - prctCorner)),
                              width: _w * prctCorner,
                              height: _h * prctCorner,
                              child: Container(
                                decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.grey, width: 0.5)),
                              )),
                        ],
                      ),
                    ));
              } else {
                return const Center(
                  child: Text('Error al abrir el archivo'),
                );
              }
            }
          }),
      bottomNavigationBar:  null,
    );
  }

}
