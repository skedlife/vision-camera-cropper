package com.visioncameracropper;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.util.Base64;

import androidx.annotation.NonNull;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.module.annotations.ReactModule;

import java.io.File;
import java.util.HashMap;
import java.util.Map;


@ReactModule(name = VisionCameraCropperModule.NAME)
public class VisionCameraCropperModule extends ReactContextBaseJavaModule {
  public static final String NAME = "VisionCameraCropper";
  private static ReactApplicationContext mContext;
  public VisionCameraCropperModule(ReactApplicationContext reactContext) {
    super(reactContext);
    mContext = reactContext;
  }
  @Override
  @NonNull
  public String getName() {
    return NAME;
  }

  public static ReactApplicationContext getContext(){
    return mContext;
  }

  // Example method
  // See https://reactnative.dev/docs/native-modules-android
  @ReactMethod
  public void rotateImage(String base64, int degree, Promise promise) {
    Bitmap bitmap = BitmapUtils.base642Bitmap(base64);
    Bitmap rotated = BitmapUtils.rotateBitmap(bitmap, degree,false,false);
    promise.resolve(BitmapUtils.bitmap2Base64(rotated));
  }

  @ReactMethod
  public void cropImage(ReadableMap arguments, Promise promise) {
      Bitmap bm = null;

      try {
          File cacheDir = getReactApplicationContext().getCacheDir();

          if (arguments.hasKey("base64Image")) {
              String base64Image = arguments.getString("base64Image");
              byte[] decodedBytes = Base64.decode(base64Image, Base64.DEFAULT);
              bm = BitmapFactory.decodeByteArray(decodedBytes, 0, decodedBytes.length);
          } else if (arguments.hasKey("imageFilePath")) {
              String imageFilePath = (String) arguments.getString("imageFilePath");
              bm = BitmapFactory.decodeFile(imageFilePath);
          }

          if (bm == null) throw new RuntimeException("Could not decode image.");

          if (arguments.hasKey("cropRegion")) {
              ReadableMap cropRegion = arguments.getMap("cropRegion");
              double left = cropRegion.getDouble("left") / 100.0 * bm.getWidth();
              double top = cropRegion.getDouble("top") / 100.0 * bm.getHeight();
              double width = cropRegion.getDouble("width") / 100.0 * bm.getWidth();
              double height = cropRegion.getDouble("height") / 100.0 * bm.getHeight();
              bm = Bitmap.createBitmap(bm, (int) left, (int) top, (int) width, (int) height, null, false);
          }

          if (arguments.hasKey("includeImageBase64")) {
              boolean includeImageBase64 = arguments.getBoolean("includeImageBase64");
              if (includeImageBase64) {
                  java.io.ByteArrayOutputStream outputStream = new java.io.ByteArrayOutputStream();
                  bm.compress(Bitmap.CompressFormat.JPEG, 100, outputStream);
                  byte[] byteArray = outputStream.toByteArray();
                  promise.resolve(Base64.encodeToString(byteArray, Base64.DEFAULT));
              }
          }

          if (arguments.hasKey("saveAsFile")) {
              boolean saveAsFile = arguments.getBoolean("saveAsFile");
              if (saveAsFile) {
                  String fileName = System.currentTimeMillis() + ".jpg";
                  File file = new File(cacheDir, fileName);
                  java.io.FileOutputStream out = new java.io.FileOutputStream(file);
                  bm.compress(Bitmap.CompressFormat.JPEG, 100, out);
                  out.flush();
                  out.close();
                  promise.resolve(file.getAbsolutePath());
              }
          }
      } catch (Exception e) {
          promise.reject("CROP_ERROR", e);
      }
  }
}
