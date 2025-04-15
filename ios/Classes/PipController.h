#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVPictureInPictureController.h>
#import <UIKit/UIKit.h>

/**
 * PipState
 * @note PipStateStarted: pip is started
 * @note PipStateStopped: pip is stopped
 * @note PipStateFailed: pip is failed
 */
typedef NS_ENUM(NSInteger, PipState) {
  PipStateStarted = 0,
  PipStateStopped = 1,
  PipStateFailed = 2,
};

/**
 * @protocol PipStateChangedDelegate
 * @abstract A protocol that defines the methods for pip state changed.
 */
@protocol PipStateChangedDelegate

/**
 * @method pipStateChanged
 * @param state
 *        The state of pip.
 * @param error
 *        The error message.
 * @abstract Delegate can implement this method to handle the pip state changed.
 */
- (void)pipStateChanged:(PipState)state error:(NSString *_Nullable)error;

@end

/**
 * @class PipOptions
 * @abstract A class that defines the options for pip.
 */
@interface PipOptions : NSObject

/**
 * @property sourceContentView
 * @abstract The source content view for pip, set to nil will use the root
 * view of the application as the source content view.
 */
@property(nonatomic, assign) UIView *_Nullable sourceContentView;

/**
 * @property contentView
 * @abstract The content view for pip.
 */
@property(nonatomic, assign) UIView *_Nullable contentView;

/**
 * @property autoEnterEnabled
 * @abstract Whether to enable auto enter pip.
 */
@property(nonatomic, assign) BOOL autoEnterEnabled;

/**
 * @property preferredContentSize
 * @abstract The preferred content size for pip.
 */
@property(nonatomic, assign) CGSize preferredContentSize;

/**
 * @property controlStyle
 * @abstract The style of pip control.
 */
@property(nonatomic, assign) int controlStyle;

@end

/**
 * @class PipController
 * @abstract A class that controls the pip.
 */
@interface PipController : NSObject <AVPictureInPictureControllerDelegate>

/**
 * @method initWith
 * @param delegate
 *        The delegate of pip state changed.
 * @abstract Initialize the pip controller.
 */
- (instancetype _Nonnull)initWith:
    (id<PipStateChangedDelegate> _Nonnull)delegate;

/**
 * @method isSupported
 * @abstract Check if pip is supported.
 * @return Whether pip is supported.
 * @discussion This method is used to check if pip is supported, When No all
 * other methods will return NO or do nothing.
 */
- (BOOL)isSupported;

/**
 * @method isAutoEnterSupported
 * @abstract Check if pip is auto enter supported.
 * @return Whether pip is auto enter supported.
 */
- (BOOL)isAutoEnterSupported;

/**
 * @method isActived
 * @abstract Check if pip is actived.
 * @return Whether pip is actived.
 */
- (BOOL)isActived;

/**
 * @method setup
 * @param options
 *        The options for pip.
 * @abstract Setup pip or update pip options.
 * @return Whether pip is setup successfully.
 * @discussion This method is used to setup pip or update pip options, but only
 * the `videoCanvas` is allowed to update after the pip controller is
 * initialized, unless you call the `dispose` method and re-initialize the pip
 * controller.
 */
- (BOOL)setup:(PipOptions *_Nonnull)options;

/**
 * @method getPipView
 * @abstract Get the pip view.
 * @return The pip view.
 */
- (UIView * _Nullable __weak)getPipView;

/**
 * @method start
 * @abstract Start pip.
 * @return Whether start pip is successful or not.
 * @discussion This method is used to start pip, however, it will only works
 * when application is in the foreground. If you want to start pip when
 * application is changing to the background, you should set the
 * `autoEnterEnabled` to YES when calling the `setup` method.
 */
- (BOOL)start;

/**
 * @method stop
 * @abstract Stop pip.
 * @discussion This method is used to stop pip, however, it will only works when
 * application is in the foreground. If you want to stop pip in the background,
 * you can use the `dispose` method, which will destroy the internal pip
 * controller and release the pip view.
 * If `isPictureInPictureActive` is NO, this method will do nothing.
 */
- (void)stop;

/**
 * @method dispose
 * @abstract Dispose all resources that pip controller holds.
 * @discussion This method is used to dispose all resources that pip controller
 * holds, which will destroy the internal pip controller and release the pip
 * view. Accroding to the Apple's documentation, you should call this method
 * when you want to stop pip in the background. see:
 * https://developer.apple.com/documentation/avkit/adopting-picture-in-picture-for-video-calls?language=objc
 */
- (void)dispose;

@end
