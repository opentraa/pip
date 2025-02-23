#import "PipController.h"

#import <AVKit/AVKit.h>
#import <UIKit/UIKit.h>

#ifdef DEBUG
#define ENABLE_LOG 1
#else
#define ENABLE_LOG 0
#endif

#if ENABLE_LOG
#define PIP_LOG(fmt, ...) NSLog((@"[PIP] " fmt), ##__VA_ARGS__)
#else
#define PIP_LOG(fmt, ...)
#endif

@interface PipView : UIView
@end

@implementation PipView

- (instancetype)init {
  self = [super init];
  return self;
}

+ (Class)layerClass {
  return [AVSampleBufferDisplayLayer class];
}

@end

@implementation PipOptions {
}
@end

@interface PipController ()

// delegate
@property(nonatomic, weak) id<PipStateChangedDelegate> pipStateDelegate;

// is actived
@property(atomic, assign) BOOL isPipActived;

// pip view
@property(nonatomic, strong) PipView *pipView;

// pip controller
@property(nonatomic, strong) AVPictureInPictureController *pipController;

@end

@implementation PipController

- (instancetype)initWith:(id<PipStateChangedDelegate>)delegate {
  self = [super init];
  if (self) {
    _pipStateDelegate = delegate;
  }
  return self;
}

- (BOOL)isSupported {
  // In iOS 15 and later, AVKit provides PiP support for video-calling apps,
  // which enables you to deliver a familiar video-calling experience that
  // behaves like FaceTime.
  // https://developer.apple.com/documentation/avkit/avpictureinpicturecontroller/ispictureinpicturesupported()?language=objc
  // https://developer.apple.com/documentation/avkit/adopting-picture-in-picture-for-video-calls?language=objc
  //
  if (__builtin_available(iOS 15.0, *)) {
    return [AVPictureInPictureController isPictureInPictureSupported];
  }

  return NO;
}

- (BOOL)isAutoEnterSupported {
  // canStartPictureInPictureAutomaticallyFromInline is only available on iOS
  // after 14.2, so we just need to check if pip is supported.
  // https://developer.apple.com/documentation/avkit/avpictureinpicturecontroller/canstartpictureinpictureautomaticallyfrominline?language=objc
  //
  return [self isSupported];
}

- (BOOL)isActived {
  return _isPipActived;
}

- (BOOL)setup:(PipOptions *)options {
  PIP_LOG(@"PipController setup with preferredContentSize: %@, "
                  @"autoEnterEnabled: %d",
                  NSStringFromCGSize(options.preferredContentSize),
                  options.autoEnterEnabled);
  if (![self isSupported]) {
    [_pipStateDelegate pipStateChanged:PipStateFailed
                                 error:@"Pip is not supported"];
    return NO;
  }

  if (__builtin_available(iOS 15.0, *)) {
    // we allow the videoCanvas to be nil, which means to use the root view
    // of the app as the source view and do not render the video for now.
    UIView *currentVideoSourceView =
        (options.sourceContentView != nil)
            ? options.sourceContentView
            : [UIApplication.sharedApplication.keyWindow rootViewController]
                  .view;

    // We need to setup or re-setup the pip controller if:
    // 1. The pip controller hasn't been initialized yet (_pipController == nil)
    // 2. The content source is missing (_pipController.contentSource == nil)
    // 3. The active video call source view has changed to a different
    // view(which
    //    may caused by function dispose or call setup with different video
    //    source view)
    //    (_pipController.contentSource.activeVideoCallSourceView !=
    //    currentVideoSourceView)
    // This ensures the pip controller is properly configured with the current
    // video source with a good user experience.
    if (_pipController == nil || _pipController.contentSource == nil ||
        _pipController.contentSource.activeVideoCallSourceView !=
            currentVideoSourceView) {

      // create pip view
      _pipView = [[PipView alloc] init];
      _pipView.autoresizingMask =
          UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

      // create pip view controller
      AVPictureInPictureVideoCallViewController *pipViewController =
          [[AVPictureInPictureVideoCallViewController alloc] init];
      // if the preferredContentSize is not set, use 100x100 as the default size
      // coz invalid size will cause the pip view to start failed with
      // Domain=PGPegasusErrorDomain Code=-1003.
      pipViewController.preferredContentSize =
          CGSizeMake(options.preferredContentSize.width <= 0
                         ? 100
                         : options.preferredContentSize.width,
                     options.preferredContentSize.height <= 0
                         ? 100
                         : options.preferredContentSize.height);
      pipViewController.view.backgroundColor = UIColor.clearColor;
      [pipViewController.view addSubview:_pipView];

      // create pip controller
      AVPictureInPictureControllerContentSource *contentSource =
          [[AVPictureInPictureControllerContentSource alloc]
              initWithActiveVideoCallSourceView:currentVideoSourceView
                          contentViewController:pipViewController];

      _pipController = [[AVPictureInPictureController alloc]
          initWithContentSource:contentSource];
      _pipController.delegate = self;
      _pipController.canStartPictureInPictureAutomaticallyFromInline =
          options.autoEnterEnabled;
    }

    return YES;
  }

  return NO;
}

- (UIView * _Nullable __weak)getPipView {
  return _pipView;
}

- (BOOL)start {
  PIP_LOG(@"PipController start");

  if (![self isSupported]) {
    [_pipStateDelegate pipStateChanged:PipStateFailed
                                 error:@"Pip is not supported"];
    return NO;
  }

  // call startPictureInPicture too fast will make no effect.
  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.1),
      dispatch_get_main_queue(), ^{
        if (self->_pipController == nil) {
          [self->_pipStateDelegate
              pipStateChanged:PipStateFailed
                        error:@"Pip controller is not initialized"];
          return;
        }

        if (![self->_pipController isPictureInPicturePossible]) {
          [self->_pipStateDelegate pipStateChanged:PipStateFailed
                                             error:@"Pip is not possible"];
        } else if (![self->_pipController isPictureInPictureActive]) {
          [self->_pipController startPictureInPicture];
        }
      });

  return YES;
}

- (void)stop {
  PIP_LOG(@"PipController stop");

  if (![self isSupported]) {
    [_pipStateDelegate pipStateChanged:PipStateFailed
                                 error:@"Pip is not supported"];
    return;
  }

  if (self->_pipController == nil ||
      ![self->_pipController isPictureInPictureActive]) {
    // no need to call pipStateChanged since the pip controller is not
    // initialized.
    return;
  }

  [self->_pipController stopPictureInPicture];
}

- (void)dispose {
  PIP_LOG(@"PipController dispose");

  if (self->_pipController != nil) {
    // if ([self->_pipController isPictureInPictureActive]) {
    //   [self->_pipController stopPictureInPicture];
    // }
    //
    // set contentSource to nil will make pip stop immediately without any
    // animation, which is more adaptive to the function of dispose, so we
    // use this method to stop pip not to call stopPictureInPicture.
    //
    // Below is the official document of contentSource property:
    // https://developer.apple.com/documentation/avkit/avpictureinpicturecontroller/contentsource-swift.property?language=objc

    if (__builtin_available(iOS 15.0, *)) {
      self->_pipController.contentSource = nil;
    }

    // Note: do not set self->_pipController and self->_pipView to nil,
    // coz this will make the pip view do not disappear immediately with
    // unknown reason, which is not expected.
    //
    // self->_pipController = nil;
    // self->_pipView = nil;
  }

  if (self->_isPipActived) {
    self->_isPipActived = NO;
    [self->_pipStateDelegate pipStateChanged:PipStateStopped error:nil];
  }
}

- (void)pictureInPictureControllerWillStartPictureInPicture:
    (AVPictureInPictureController *)pictureInPictureController {
  PIP_LOG(@"pictureInPictureControllerWillStartPictureInPicture");
}

- (void)pictureInPictureControllerDidStartPictureInPicture:
    (AVPictureInPictureController *)pictureInPictureController {
  PIP_LOG(@"pictureInPictureControllerDidStartPictureInPicture");

  _isPipActived = YES;
  [_pipStateDelegate pipStateChanged:PipStateStarted error:nil];
}

- (void)pictureInPictureController:
            (AVPictureInPictureController *)pictureInPictureController
    failedToStartPictureInPictureWithError:(NSError *)error {
  PIP_LOG(
      @"pictureInPictureController failedToStartPictureInPictureWithError: %@",
      error);
  [_pipStateDelegate pipStateChanged:PipStateFailed error:error.description];
}

- (void)pictureInPictureControllerWillStopPictureInPicture:
    (AVPictureInPictureController *)pictureInPictureController {
  PIP_LOG(@"pictureInPictureControllerWillStopPictureInPicture");
}

- (void)pictureInPictureControllerDidStopPictureInPicture:
    (AVPictureInPictureController *)pictureInPictureController {
  PIP_LOG(@"pictureInPictureControllerDidStopPictureInPicture");

  _isPipActived = NO;
  [_pipStateDelegate pipStateChanged:PipStateStopped error:nil];
}

@end
