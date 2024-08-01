import Flutter
import UIKit
import PDFKit

public class GsePluginDibujoFirmaPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "gse_plugin_dibujo_firma", binaryMessenger: registrar.messenger())
    let instance = GsePluginDibujoFirmaPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method{
              case "loadDocument":
                  let arguments = call.arguments as? [String:FlutterStandardTypedData]
                  let data =  arguments!["data"]!.data
                  self.cargarDocumento(dataDoc: data)
                  result(true)
                  break
              case "renderPage":
                  DispatchQueue.global(qos: .background).async {
                      let arguments = call.arguments as? [String:NSNumber]
                      let pagina = arguments!["page"]!.intValue
                      let img = self.renderizarImagen(pagina: pagina)!
                      let dataImg = img.pngData()!
                      let uint8list = FlutterStandardTypedData(bytes: dataImg)
                      result(uint8list)
                  }
                  break
              case "closeDocument":
                  self.eliminarDocumento()
                  result(true)
                  break
              default:
                  result(FlutterMethodNotImplemented)
              }
  }

  private func cargarDocumento(dataDoc: Data){
          self.doc = PDFDocument(data: dataDoc)
      }
      private func eliminarDocumento(){
          self.doc = nil
      }
      private func renderizarImagen(pagina: Int) -> UIImage?{
          if let pdfPage = self.doc!.page(at: pagina) {
              let pdfPageSize = pdfPage.bounds(for: .mediaBox)
              let renderer = UIGraphicsImageRenderer(size: pdfPageSize.size)

              let image = renderer.image { ctx in
                  UIColor.white.set()
                  ctx.fill(pdfPageSize)
                  ctx.cgContext.translateBy(x: 0.0, y: pdfPageSize.size.height)
                  ctx.cgContext.scaleBy(x: 1.0, y: -1.0)

                  pdfPage.draw(with: .mediaBox, to: ctx.cgContext)
              }
              return image
          }else {
              return nil
          }
      }
}
