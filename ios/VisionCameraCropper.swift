@objc(VisionCameraCropper)
class VisionCameraCropper: NSObject {

  @objc(rotateImage:degree:withResolver:withRejecter:)
  func rotateImage(base64: String, degree: Float, resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {

      guard let image = VisionCameraCropper.convertBase64ToImage(base64) else {
          reject("error","Invalid base64",nil);
          return;
      };
      print("image width %d", image.size.width)
      let rotated = VisionCameraCropper.rotate(image: image,degree: CGFloat(degree))
      print("rotated image width %d", rotated.size.width)
      resolve(VisionCameraCropper.getBase64FromImage(rotated))
  }

    public static func rotate(image: UIImage, degree: CGFloat) -> UIImage {
        let radians = degree / (180.0 / .pi)
        let width = image.size.width
        let height = image.size.height
        let newWidth = abs(width * cos(radians)) + abs(height * sin(radians))
        let newHeight = abs(width * sin(radians)) + abs(height * cos(radians))
        let rotatedSize = CGSize(width: newWidth, height: newHeight)

        UIGraphicsBeginImageContextWithOptions(rotatedSize, false, image.scale)
        if let context = UIGraphicsGetCurrentContext() {
            context.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
            context.rotate(by: radians)
            image.draw(in: CGRect(x: -width / 2, y: -height / 2, width: width, height: height))
            let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return rotatedImage ?? image
        }
        return image
    }

    public static func getBase64FromImage(_ image:UIImage) -> String {
      let dataTmp = image.jpegData(compressionQuality: 100)
      if let data = dataTmp {
          return data.base64EncodedString()
      }
      return ""
    }

    public static func convertBase64ToImage(_ imageStr:String) ->UIImage?{
        if let data: NSData = NSData(base64Encoded: imageStr, options:NSData.Base64DecodingOptions.ignoreUnknownCharacters)
        {
            if let image: UIImage = UIImage(data: data as Data)
            {
                return image
            }
        }
        return nil
    }

    @objc(cropImage:resolver:rejecter:)
    func cropImage(_ arguments:[String: Any], resolver:RCTPromiseResolveBlock, rejecter:RCTPromiseRejectBlock) -> Void {
      var image: UIImage? = nil

      do {
        if let base64Image = arguments["base64Image"] as? String,
           let imageData = Data(base64Encoded: base64Image, options: .ignoreUnknownCharacters) {
          image = UIImage(data: imageData)
        } else if let imageFilePath = arguments["imageFilePath"] as? String {
          image = UIImage(contentsOfFile: imageFilePath)
        }

        guard let originalImage = image else {
          throw NSError(domain: "VisionCameraCropper", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not decode image."])
        }
        let cgimage = image?.cgImage!
        var croppedImage = originalImage
          let cropRegion = arguments["cropRegion"] as? [String: Double]
          if cropRegion != nil {
            let imgWidth = Double((image?.cgImage!.width)!)
            let imgHeight = Double((image?.cgImage!.height)!)
            let left:Double = Double(cropRegion?["left"] ?? 0) / 100.0 * imgWidth
            let top:Double = Double(cropRegion?["top"] ?? 0) / 100.0 * imgHeight
            let width:Double = Double(cropRegion?["width"] ?? 100) / 100.0 * imgWidth
            let height:Double = Double(cropRegion?["height"] ?? 100) / 100.0 * imgHeight

            let cropRect = CGRect(
                x: left,
                y: top,
                width: width,
                height: height
            ).integral

              let cropped = cgimage!.cropping(
                to: cropRect
            )!
            croppedImage = UIImage(cgImage: cropped)
        }

        if let includeImageBase64 = arguments["includeImageBase64"] as? Bool, includeImageBase64 {
          if let jpegData = croppedImage.jpegData(compressionQuality: 1.0) {
            let base64 = jpegData.base64EncodedString()
            resolver(base64)
            return
          } else {
            throw NSError(domain: "VisionCameraCropper", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to encode cropped image to base64."])
          }
        }

        if let saveAsFile = arguments["saveAsFile"] as? Bool, saveAsFile {
          if let jpegData = croppedImage.jpegData(compressionQuality: 1.0) {
            let fileManager = FileManager.default
            let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
            let fileName = "\(Int(Date().timeIntervalSince1970 * 1000)).jpg"
            let fileURL = cacheDir.appendingPathComponent(fileName)
            try jpegData.write(to: fileURL)
            resolver(fileURL.path)
            return
          } else {
            throw NSError(domain: "VisionCameraCropper", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to save cropped image to file."])
          }
        }
      } catch let error as NSError {
        rejecter("CROP_ERROR", error.localizedDescription, error)
      }
    }

}
