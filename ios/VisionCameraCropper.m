#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(VisionCameraCropper, NSObject)

RCT_EXTERN_METHOD(rotateImage:(NSString)base64 degree:(float)degree
                 withResolver:(RCTPromiseResolveBlock)resolve
                 withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(cropImage:(NSDictionary *)arguments
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

@end
