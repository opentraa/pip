#import "PipController.h"
#import "PipView.h"
#include <objc/objc.h>

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

@implementation PipOptions {
}
@end

@interface PipController () <AVPictureInPictureControllerDelegate,
                             AVPictureInPictureSampleBufferPlaybackDelegate>

// delegate
@property(nonatomic, weak) id<PipStateChangedDelegate> pipStateDelegate;

// is actived
@property(atomic, assign) BOOL isPipActived;

// content view
@property(nonatomic, assign) UIView *contentView;

// pip view
@property(nonatomic, strong) PipView *pipView;

// pip controller
@property(nonatomic, strong) AVPictureInPictureController *pipController;

// pip view controller, weak reference
@property(nonatomic) UIViewController *pipViewController;

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

    _contentView = (UIView *)options.contentView;

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
      _pipView.translatesAutoresizingMaskIntoConstraints = NO;

      [currentVideoSourceView insertSubview:_pipView atIndex:0];
      [NSLayoutConstraint activateConstraints:@[
        [_pipView.leadingAnchor
            constraintEqualToAnchor:currentVideoSourceView.leadingAnchor],
        [_pipView.trailingAnchor
            constraintEqualToAnchor:currentVideoSourceView.trailingAnchor],
        [_pipView.topAnchor
            constraintEqualToAnchor:currentVideoSourceView.topAnchor],
        [_pipView.bottomAnchor
            constraintEqualToAnchor:currentVideoSourceView.bottomAnchor],
      ]];

      [_pipView updateFrameSize:CGSizeMake(
                                    options.preferredContentSize.width <= 0
                                        ? 100
                                        : options.preferredContentSize.width,
                                    options.preferredContentSize.height <= 0
                                        ? 100
                                        : options.preferredContentSize.height)];

      AVPictureInPictureControllerContentSource *contentSource =
          [[AVPictureInPictureControllerContentSource alloc]
              initWithSampleBufferDisplayLayer:_pipView.sampleBufferDisplayLayer
                              playbackDelegate:self];

      _pipController = [[AVPictureInPictureController alloc]
          initWithContentSource:contentSource];
      _pipController.delegate = self;
      _pipController.canStartPictureInPictureAutomaticallyFromInline =
          options.autoEnterEnabled;

      // hide forward and backward button
      if (options.controlStyle >= 1) {
        _pipController.requiresLinearPlayback = YES;
      }

      if (options.controlStyle == 2) {
        // hide play pause button and the progress bar including forward and
        // backward button
        [_pipController setValue:[NSNumber numberWithInt:1]
                          forKey:@"controlsStyle"];
      } else if (options.controlStyle == 3) {
        // hide all system controls including the close and restore button
        [_pipController setValue:[NSNumber numberWithInt:2]
                          forKey:@"controlsStyle"];
      }

      NSString *pipVCName =
          [NSString stringWithFormat:@"pictureInPictureViewController"];
      _pipViewController = [_pipController valueForKey:pipVCName];
    } else {
      // pip controller is already initialized, so we need to update the options

      // if the content view is set, will add it to the pip view controller in
      // the method of pictureInPictureControllerDidStartPictureInPicture.
      //
      // if _contentView is not equal to options.contentView, it means the
      // content view has been changed, so we need to remove the old content
      // view and add the new one.
      if (_contentView != options.contentView) {
        if (_contentView != nil) {
          [_contentView removeFromSuperview];
        }

        _contentView = (UIView *)options.contentView;
      }

      if (options.preferredContentSize.width > 0 &&
          options.preferredContentSize.height > 0) {
        [_pipView
            updateFrameSize:CGSizeMake(options.preferredContentSize.width,
                                       options.preferredContentSize.height)];
      }

      if (options.autoEnterEnabled !=
          _pipController.canStartPictureInPictureAutomaticallyFromInline) {
        _pipController.canStartPictureInPictureAutomaticallyFromInline =
            options.autoEnterEnabled;
      }
    }

    return YES;
  }

  return NO;
}

- (UIView *_Nullable __weak)getPipView {
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

#pragma mark - AVPictureInPictureControllerDelegate

- (void)pictureInPictureControllerWillStartPictureInPicture:
    (AVPictureInPictureController *)pictureInPictureController {
  PIP_LOG(@"pictureInPictureControllerWillStartPictureInPicture");
}

- (void)pictureInPictureControllerDidStartPictureInPicture:
    (AVPictureInPictureController *)pictureInPictureController {
  PIP_LOG(@"pictureInPictureControllerDidStartPictureInPicture");

  if (_contentView != nil) {
    [_pipViewController.view insertSubview:_contentView atIndex:0];
    [_pipViewController.view bringSubviewToFront:_contentView];

    _contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [_pipViewController.view addConstraints:@[
      [_contentView.leadingAnchor
          constraintEqualToAnchor:_pipViewController.view.leadingAnchor],
      [_contentView.trailingAnchor
          constraintEqualToAnchor:_pipViewController.view.trailingAnchor],
      [_contentView.topAnchor
          constraintEqualToAnchor:_pipViewController.view.topAnchor],
      [_contentView.bottomAnchor
          constraintEqualToAnchor:_pipViewController.view.bottomAnchor],
    ]];
  }

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

  if (_contentView != nil) {
    [_contentView removeFromSuperview];
  }
}

#pragma mark - AVPictureInPictureSampleBufferPlaybackDelegate

- (void)pictureInPictureController:
            (nonnull AVPictureInPictureController *)pictureInPictureController
         didTransitionToRenderSize:(CMVideoDimensions)newRenderSize {
  PIP_LOG(@"didTransitionToRenderSize: %dx%d", newRenderSize.width,
          newRenderSize.height);
}

- (void)pictureInPictureController:
            (nonnull AVPictureInPictureController *)pictureInPictureController
                        setPlaying:(BOOL)playing {
  PIP_LOG(@"setPlaying: %@", playing ? @"YES" : @"NO");
}

- (void)pictureInPictureController:
            (nonnull AVPictureInPictureController *)pictureInPictureController
                    skipByInterval:(CMTime)skipInterval
                 completionHandler:(nonnull void (^)(void))completionHandler {
  completionHandler();
}

- (BOOL)pictureInPictureControllerIsPlaybackPaused:
    (nonnull AVPictureInPictureController *)pictureInPictureController {
  return NO;
}

- (CMTimeRange)pictureInPictureControllerTimeRangeForPlayback:
    (nonnull AVPictureInPictureController *)pictureInPictureController {
  // do not use kCMTimeIndefinite, otherwise the system will add a loading
  // indicator to the pip view.
  // https://stackoverflow.com/questions/69799535/picture-in-picture-from-avsamplebufferdisplaylayer-not-loading
  return CMTimeRangeMake(kCMTimeZero, kCMTimePositiveInfinity);
}

//- (CMTime)pictureInPictureControllerCurrentTime:(nonnull
// AVPictureInPictureController *)pictureInPictureController {
////    return CMTimeMake(self.loopTimer ? 2 * self.loopTimer.timeInterval : 0,
/// 1);
//}

@end
