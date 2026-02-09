//
//  BMWDoIPModule.m
//  Objective-C Bridge for React Native
//

#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(BMWDoIPModule, NSObject)

RCT_EXTERN_METHOD(configureStaticIP:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(connect:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(readVIN:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(readParameter:(nonnull NSNumber *)ecuAddress
                  did:(nonnull NSNumber *)did
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(writeParameter:(nonnull NSNumber *)ecuAddress
                  did:(nonnull NSNumber *)did
                  value:(NSString *)value
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(unlockECU:(nonnull NSNumber *)ecuAddress
                  level:(nonnull NSNumber *)level
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(disconnect:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

@end
