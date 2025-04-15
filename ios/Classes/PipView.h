#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class AVSampleBufferDisplayLayer;

@interface PipView : UIView

@property (nonatomic) AVSampleBufferDisplayLayer *sampleBufferDisplayLayer;

- (void)updateFrameSize:(CGSize)frameSize;

@end

NS_ASSUME_NONNULL_END