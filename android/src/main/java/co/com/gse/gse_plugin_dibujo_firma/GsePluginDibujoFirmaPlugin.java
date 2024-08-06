package co.com.gse.gse_plugin_dibujo_firma;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import android.content.Context;
import android.graphics.Bitmap;
import android.util.Base64;

import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.StandardMethodCodec;

import androidx.annotation.NonNull;


import com.shockwave.pdfium.PdfiumCore;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import com.shockwave.pdfium.PdfDocument;

/** GsePluginDibujoFirmaPlugin */
public class GsePluginDibujoFirmaPlugin implements FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;

  private static final String CHANNEL_NAME = "pdf/firmado";

  private PdfDocument doc = null;
  private PdfiumCore core = null;

  private Thread hilo = null;

  private Context ctx = null;
  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    ctx = flutterPluginBinding.getApplicationContext();
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "gse_plugin_dibujo_firma");
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    switch (call.method){
      case "loadDocument":
        try{
          byte[] docData = call.argument("data");
          loadDoc(docData);
          result.success(true);
        }catch(Exception e){
          result.success(false);
        }
        break;
      case "closeDocument":
        closeDoc();
        result.success(true);
        break;
      case "renderPage":
        Integer page = call.argument("page");
        PdfDocument docu = this.doc;
        hilo = new Thread(){
          public void run(){
            byte[] resultado = renderPage(page.intValue(),docu);
            result.success(resultado);
            //System.out.println("Pasa retornar bytes " + page);
          }
        };
        hilo.start();
        break;
      default:
        result.notImplemented();
        break;
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }

  public void loadDoc(byte[] dataDoc) throws IOException {
    if(this.core == null){
      this.core = new PdfiumCore(ctx);
    }
    //System.out.println("Antes de newDococument");
    this.doc = this.core.newDocument(dataDoc);
    //System.out.println("Después de newDococument");
  }

  public void closeDoc(){
    if(this.doc != null){
      if(hilo.isAlive()){
        hilo.interrupt();
      }
      //System.out.println("Antes de closeDococument");
      this.core.closeDocument(this.doc);
      //System.out.println("Después de closeDococument");
    }
  }

  public byte[] renderPage(int page, PdfDocument docu) {
    try{
      //System.out.println("aja ._." + page);
      this.core.openPage(docu, page);
      //System.out.println("Pasa abrir página " + page);
      int width = this.core.getPageWidthPoint(docu, page) * 3;
      int height = this.core.getPageHeightPoint(docu, page) * 3;
      //System.out.println("Pasa calcular tamaños " + page);

      // ARGB_8888 - best quality, high memory usage, higher possibility of OutOfMemoryError
      // RGB_565 - little worse quality, twice less memory usage
      Bitmap bitmap = Bitmap.createBitmap(width , height ,
              Bitmap.Config.RGB_565);
      //System.out.println("Pasa crear bitmap " + page);
      this.core.renderPageBitmap(docu, bitmap, page, 0, 0,
              width, height, true);
      //System.out.println("Pasa renderizar " + page);
      ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
      //System.out.println("Pasa crear bytes " + page);
      bitmap.compress(Bitmap.CompressFormat.PNG, 100, byteArrayOutputStream);
      //System.out.println("Pasa llenar bytes  " + page);
      byte[] byteArray = byteArrayOutputStream .toByteArray();
      //System.out.println("Pasa convertir a array " + page);
      return byteArray;
    }catch(Exception e){
      return new byte[]{};
    }
  }
}
