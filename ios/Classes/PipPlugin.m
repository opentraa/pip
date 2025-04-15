#import "PipPlugin.h"

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
    @autoreleasepool {
      // new options
      PipOptions *options = [[PipOptions alloc] init];

      // source content view
      if ([call.arguments objectForKey:@"sourceContentView"] &&
          [[call.arguments objectForKey:@"sourceContentView"]
              isKindOfClass:[NSNumber class]]) {
        options.sourceContentView = (__bridge UIView *)[[call.arguments
            objectForKey:@"sourceContentView"] pointerValue];
      }

      // content view
      if ([call.arguments objectForKey:@"contentView"] &&
          [[call.arguments objectForKey:@"contentView"]
              isKindOfClass:[NSNumber class]]) {
        options.contentView = (__bridge UIView *)[[call.arguments
            objectForKey:@"contentView"] pointerValue];
      }

      // auto enter
      if ([call.arguments objectForKey:@"autoEnterEnabled"]) {
        options.autoEnterEnabled =
            [[call.arguments objectForKey:@"autoEnterEnabled"] boolValue];
      }

      // preferred content size
      if ([call.arguments objectForKey:@"preferredContentWidth"] &&
          [call.arguments objectForKey:@"preferredContentHeight"]) {
        options.preferredContentSize = CGSizeMake(
            [[call.arguments objectForKey:@"preferredContentWidth"] floatValue],
            [[call.arguments objectForKey:@"preferredContentHeight"]
                floatValue]);
      }

      // control style
      if ([call.arguments objectForKey:@"controlStyle"]) {
        options.controlStyle =
            [[call.arguments objectForKey:@"controlStyle"] intValue];
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
  NSDictionary *arguments = [[NSDictionary alloc]
      initWithObjectsAndKeys:[NSNumber numberWithLong:(long)state], @"state",
                             error, @"error", nil];
  [self.channel invokeMethod:@"stateChanged" arguments:arguments];
}

@end
