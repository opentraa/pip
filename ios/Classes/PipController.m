#import "PipController.h"
#import "PipView.h"
#include <Foundation/Foundation.h>
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

#define USE_PIP_VIEW_CONTROLLER 0

@implementation PipOptions {
}
@end

@interface PipController () <AVPictureInPictureControllerDelegate,
                             AVPictureInPictureSampleBufferPlaybackDelegate>

// delegate
@property(nonatomic, weak) id<PipStateChangedDelegate> pipStateDelegate;

// is actived
@property(atomic, assign) BOOL isPipActived;

#pragma mark - content view
// content view
@property(nonatomic, assign) UIView *contentView;

// content view original index
@property(nonatomic, assign) NSUInteger contentViewOriginalIndex;

// content view original frame
@property(nonatomic, assign) CGRect contentViewOriginalFrame;

// content view original constraints
@property(nonatomic, strong) NSMutableArray *contentViewOriginalConstraints;

// content view original translatesAutoresizingMaskIntoConstraints
@property(nonatomic, assign)
    bool contentViewOriginalTranslatesAutoresizingMaskIntoConstraints;

// content view original parent view
@property(nonatomic, assign) UIView *contentViewOriginalParentView;

// content view original parent view constraints
@property(nonatomic, strong)
    NSMutableArray *contentViewOriginalParentViewConstraints;

#pragma mark - pip view
// pip view
@property(nonatomic, strong) PipView *pipView;

// pip controller
@property(nonatomic, strong) AVPictureInPictureController *pipController;

#if USE_PIP_VIEW_CONTROLLER
// Do not use this anymore, it is dangerous to use it and do not have the best
// user experience(we have to call bringToFront in didStart which make the
// truely pip view not visible for a while ).
// pip view controller, weak reference
@property(nonatomic) UIViewController *pipViewController;
#endif

@end

@implementation PipController

- (instancetype)initWith:(id<PipStateChangedDelegate>)delegate {
  self = [super init];
  if (self) {
    _pipStateDelegate = delegate;
    _contentViewOriginalConstraints = [[NSMutableArray alloc] init];
    _contentViewOriginalParentViewConstraints = [[NSMutableArray alloc] init];
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
    // view(which
    //    may caused by function dispose or call setup with different video
    //    source view)
    //    (_pipController.contentSource.activeVideoCallSourceView !=
    //    currentVideoSourceView)
    // This ensures the pip controller is properly configured with the current
    // video source with a good user experience.
    if (_pipController == nil || _pipController.contentSource == nil) {

      // create pip view
      _pipView = [[PipView alloc] init];

      [currentVideoSourceView insertSubview:_pipView atIndex:0];

      _pipView.translatesAutoresizingMaskIntoConstraints = NO;
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

#if USE_PIP_VIEW_CONTROLLER
      NSString *pipVCName =
          [NSString stringWithFormat:@"pictureInPictureViewController"];
      _pipViewController = [_pipController valueForKey:pipVCName];
#endif
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
          [self restoreContentViewIfNeeded];
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

// insert the content view to the new parent view
// you should call this method in the method of
// pictureInPictureControllerDidStartPictureInPicture or
// pictureInPictureControllerWillStartPictureInPicture, but bringSubViewToFront
// only take effect in the method of
// pictureInPictureControllerDidStartPictureInPicture, so if you call this
// method in the method of pictureInPictureControllerWillStartPictureInPicture,
// you should addtionaly call bringSubViewToFront in
// pictureInPictureControllerDidStartPictureInPicture.
- (void)insertContentViewIfNeeded:(UIView *)newParentView {
  // if the content view is not set or the new parent view is not set, just
  // return
  if (_contentView == nil || newParentView == nil) {
    PIP_LOG(@"insertContentViewIfNeeded: contentView or newParentView is nil");
    return;
  }

  // if the content view is already in the new parent view, just return
  if ([newParentView.subviews containsObject:_contentView]) {
    PIP_LOG(@"insertContentViewIfNeeded: contentView is already in the new "
            @"parent view");
    return;
  }

  // save the original content view properties
  _contentViewOriginalParentView = _contentView.superview;
  if (_contentViewOriginalParentView != nil) {
    _contentViewOriginalIndex =
        [_contentViewOriginalParentView.subviews indexOfObject:_contentView];
    _contentViewOriginalFrame = _contentView.frame;
    _contentViewOriginalTranslatesAutoresizingMaskIntoConstraints =
        _contentView.translatesAutoresizingMaskIntoConstraints;
    [_contentViewOriginalConstraints
        addObjectsFromArray:_contentView.constraints.mutableCopy];
    [_contentViewOriginalParentViewConstraints
        addObjectsFromArray:_contentViewOriginalParentView.constraints
                                .mutableCopy];

    // remove the content view from the original parent view
    [_contentView removeFromSuperview];

    PIP_LOG(
        @"insertContentViewIfNeeded: contentView is removed from the original "
        @"parent view");
  }

  // add the content view to the new parent view
  [newParentView insertSubview:_contentView
                       atIndex:newParentView.subviews.count];

  // no need to bring the content view to the front, because the content view
  // will be added to the front of the new parent view.
  // // bring the content view to the front
  // [newParentView bringSubviewToFront:_contentView];

  // update the content view constraints
  _contentView.translatesAutoresizingMaskIntoConstraints = YES;
  _contentView.autoresizingMask =
      UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  _contentView.frame = newParentView.frame;

  // It seems like no need to do so.
  // [newParentView addConstraints:@[
  //   [_contentView.leadingAnchor
  //       constraintEqualToAnchor:newParentView.leadingAnchor],
  //   [_contentView.trailingAnchor
  //       constraintEqualToAnchor:newParentView.trailingAnchor],
  //   [_contentView.topAnchor constraintEqualToAnchor:newParentView.topAnchor],
  //   [_contentView.bottomAnchor
  //       constraintEqualToAnchor:newParentView.bottomAnchor],
  // ]];

  PIP_LOG(@"insertContentViewIfNeeded: contentView is added to the new parent "
          @"view");
}

- (void)restoreContentViewIfNeeded {
  // only restore the content view if it is not nil and the original parent
  // view is not nil and the content view is already in the original parent view
  if (_contentView == nil || _contentViewOriginalParentView == nil ||
      [_contentViewOriginalParentView.subviews containsObject:_contentView]) {
    PIP_LOG(
        @"restoreContentViewIfNeeded: _contentViewOriginalParentView is nil or "
        @"contentView is already in the original parent view");
    return;
  }

  [_contentView removeFromSuperview];
  PIP_LOG(
      @"restoreContentViewIfNeeded: contentView is removed from the original "
      @"parent view");

  // in case that the subviews of _contentViewOriginalParentView has been
  // changed, we need to get the real index of the content view.
  NSUInteger trueIndex = MIN(_contentViewOriginalParentView.subviews.count,
                             _contentViewOriginalIndex);
  [_contentViewOriginalParentView insertSubview:_contentView atIndex:trueIndex];

  PIP_LOG(@"restoreContentViewIfNeeded: contentView is added to the original "
          @"parent view "
          @"at index: %lu",
          trueIndex);

  // restore the original frame
  _contentView.frame = _contentViewOriginalFrame;

  // restore the original constraints
  [_contentView removeConstraints:_contentView.constraints.copy];
  [_contentView addConstraints:_contentViewOriginalConstraints];

  // restore the original translatesAutoresizingMaskIntoConstraints
  _contentView.translatesAutoresizingMaskIntoConstraints =
      _contentViewOriginalTranslatesAutoresizingMaskIntoConstraints;

  // restore the original parent view
  [_contentViewOriginalParentView
      removeConstraints:_contentViewOriginalParentView.constraints.copy];
  [_contentViewOriginalParentView
      addConstraints:_contentViewOriginalParentViewConstraints];
}

- (void)dispose {
  PIP_LOG(@"PipController dispose");

  if (self->_pipController != nil) {
    // restore the content view if it is in the pip view controller
    [self restoreContentViewIfNeeded];

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

#if USE_PIP_VIEW_CONTROLLER
  if (_pipViewController) {
    [self insertContentViewIfNeeded:_pipViewController.view];
  }
#endif
}

- (void)pictureInPictureControllerDidStartPictureInPicture:
    (AVPictureInPictureController *)pictureInPictureController {
  PIP_LOG(@"pictureInPictureControllerDidStartPictureInPicture");

#if USE_PIP_VIEW_CONTROLLER
  // if you use the pipViewController, you must call this every time to bring
  // the content view to the front, otherwise the content view will not be
  // visible and covered by the pip host view.
  if (_pipViewController) {
    [_pipViewController.view bringSubviewToFront:_contentView];
  }
#else
  // TODO @sylar: check if this is the best way to do this, what will happen if
  // we have multiple windows? what if the root view controller is not a
  // UIViewController?
  UIWindow *window = [[UIApplication sharedApplication] windows].firstObject;
  if (window) {
    UIViewController *rootViewController = window.rootViewController;
    UIView *superview = rootViewController.view.superview;
    [self insertContentViewIfNeeded:superview];
  }
#endif

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

  // you can restore the content view in this method, but it will have a not so
  // good user experience. you will see the content view is not visible
  // immediately, but the pip window is still showing with a black background,
  // then animation to the settled contentSourceView. [self
  // restoreContentViewIfNeeded];
}

- (void)pictureInPictureControllerDidStopPictureInPicture:
    (AVPictureInPictureController *)pictureInPictureController {
  PIP_LOG(@"pictureInPictureControllerDidStopPictureInPicture");

  // restore the content view in
  // pictureInPictureControllerDidStopPictureInPicture will have the best user
  // experience.
  [self restoreContentViewIfNeeded];

  _isPipActived = NO;
  [_pipStateDelegate pipStateChanged:PipStateStopped error:nil];
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
