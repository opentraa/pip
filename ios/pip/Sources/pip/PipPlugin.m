#import "include/pip/PipPlugin.h"

@interface PipPlugin ()

@property(nonatomic) FlutterMethodChannel *channel;

@property(nonatomic, strong) PipController *pipController;

@end

@implementation PipPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:@"pip"
                                  binaryMessenger:[registrar messenger]];
  PipPlugin *instance = [[PipPlugin alloc] init];

  instance.channel = channel;
  instance.pipController =
      [[PipController alloc] initWith:(id<PipStateChangedDelegate>)instance];

  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall *)call
                  result:(FlutterResult)result {
  if ([@"isSupported" isEqualToString:call.method]) {
    result([NSNumber numberWithBool:[self.pipController isSupported]]);
  } else if ([@"isAutoEnterSupported" isEqualToString:call.method]) {
    result([NSNumber numberWithBool:[self.pipController isAutoEnterSupported]]);
  } else if ([@"isActived" isEqualToString:call.method]) {
    result([NSNumber numberWithBool:[self.pipController isActived]]);
  } else if ([@"setup" isEqualToString:call.method]) {
    if (![call.arguments isKindOfClass:[NSDictionary class]]) {
      result(@NO);
      return;
    }

    NSDictionary *arguments = (NSDictionary *)call.arguments;

    @autoreleasepool {
      // new options
      PipOptions *options = [[PipOptions alloc] init];

      // source content view
      if ([arguments objectForKey:@"sourceContentView"] &&
          [[arguments objectForKey:@"sourceContentView"]
              isKindOfClass:[NSNumber class]]) {
        options.sourceContentView = (__bridge UIView *)[[arguments
            objectForKey:@"sourceContentView"] pointerValue];
      }

      // content view
      if ([arguments objectForKey:@"contentView"] &&
          [[arguments objectForKey:@"contentView"]
              isKindOfClass:[NSNumber class]]) {
        options.contentView = (__bridge UIView *)[[arguments
            objectForKey:@"contentView"] pointerValue];
      }

      // auto enter
      if ([arguments objectForKey:@"autoEnterEnabled"]) {
        options.autoEnterEnabled =
            [[arguments objectForKey:@"autoEnterEnabled"] boolValue];
      }

      // preferred content size
      if ([arguments objectForKey:@"preferredContentWidth"] &&
          [arguments objectForKey:@"preferredContentHeight"]) {
        options.preferredContentSize = CGSizeMake(
            [[arguments objectForKey:@"preferredContentWidth"] floatValue],
            [[arguments objectForKey:@"preferredContentHeight"]
                floatValue]);
      }

      // control style
      if ([arguments objectForKey:@"controlStyle"]) {
        options.controlStyle =
            [[arguments objectForKey:@"controlStyle"] intValue];
      } else {
        // default to show all system controls
        options.controlStyle = 0;
      }

      result([NSNumber numberWithBool:[self.pipController setup:options]]);
    }
  } else if ([@"getPipView" isEqualToString:call.method]) {
    result([NSNumber
        numberWithUnsignedLongLong:(uint64_t)[self.pipController getPipView]]);
  } else if ([@"start" isEqualToString:call.method]) {
    result([NSNumber numberWithBool:[self.pipController start]]);
  } else if ([@"stop" isEqualToString:call.method]) {
    [self.pipController stop];
    result(nil);
  } else if ([@"dispose" isEqualToString:call.method]) {
    [self.pipController dispose];
    result(nil);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)pipStateChanged:(PipState)state error:(NSString *)error {
  NSMutableDictionary *arguments =
      [@{@"state" : [self stateCode:state]} mutableCopy];
  if (error != nil) {
    arguments[@"error"] = error;
  }
  [self.channel invokeMethod:@"stateChanged" arguments:arguments];
}

- (NSString *)stateCode:(PipState)state {
  switch (state) {
  case PipStateStarted:
    return @"started";
  case PipStateStopped:
    return @"stopped";
  case PipStateFailed:
    return @"failed";
  }
  return @"unknown";
}

@end
