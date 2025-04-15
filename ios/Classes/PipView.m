#import "PipView.h"

#import <AVFoundation/AVFoundation.h>

@interface PipView ()

@end

@implementation PipView

+ (Class)layerClass {
  return [AVSampleBufferDisplayLayer class];
}

- (AVSampleBufferDisplayLayer *)sampleBufferDisplayLayer {
  return (AVSampleBufferDisplayLayer *)self.layer;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    self.alpha = 0;
  }
  return self;
}

- (void)updateFrameSize:(CGSize)frameSize {
  CMTimebaseRef timebase;
  CMTimebaseCreateWithSourceClock(nil, CMClockGetHostTimeClock(), &timebase);
  CMTimebaseSetTime(timebase, kCMTimeZero);
  CMTimebaseSetRate(timebase, 1);
  self.sampleBufferDisplayLayer.controlTimebase = timebase;
  if (timebase) {
    CFRelease(timebase);
  }

  CMSampleBufferRef sampleBuffer =
      [self makeSampleBufferWithFrameSize:frameSize];
  if (sampleBuffer) {
    [self.sampleBufferDisplayLayer enqueueSampleBuffer:sampleBuffer];
    CFRelease(sampleBuffer);
  }
}

- (CMSampleBufferRef)makeSampleBufferWithFrameSize:(CGSize)frameSize {
  size_t width = (size_t)frameSize.width;
  size_t height = (size_t)frameSize.height;

  const int pixel = 0xFF000000; // {0x00, 0x00, 0x00, 0xFF};//BGRA

  CVPixelBufferRef pixelBuffer = NULL;
  CVPixelBufferCreate(NULL, width, height, kCVPixelFormatType_32BGRA,
                      (__bridge CFDictionaryRef)
                          @{(id)kCVPixelBufferIOSurfacePropertiesKey : @{}},
                      &pixelBuffer);
  CVPixelBufferLockBaseAddress(pixelBuffer, 0);
  int *bytes = CVPixelBufferGetBaseAddress(pixelBuffer);
  for (NSUInteger i = 0, length = height *
                                  CVPixelBufferGetBytesPerRow(pixelBuffer) / 4;
       i < length; ++i) {
    bytes[i] = pixel;
  }
  CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
  CMSampleBufferRef sampleBuffer =
      [self makeSampleBufferWithPixelBuffer:pixelBuffer];
  CVPixelBufferRelease(pixelBuffer);
  return sampleBuffer;
}

- (CMSampleBufferRef)makeSampleBufferWithPixelBuffer:
    (CVPixelBufferRef)pixelBuffer {
  CMSampleBufferRef sampleBuffer = NULL;
  OSStatus err = noErr;
  CMVideoFormatDescriptionRef formatDesc = NULL;
  err = CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault,
                                                     pixelBuffer, &formatDesc);

  if (err != noErr) {
    return nil;
  }

  CMSampleTimingInfo sampleTimingInfo = {
      .duration = CMTimeMakeWithSeconds(1, 600),
      .presentationTimeStamp =
          CMTimebaseGetTime(self.sampleBufferDisplayLayer.timebase),
      .decodeTimeStamp = kCMTimeInvalid};

  err = CMSampleBufferCreateReadyWithImageBuffer(
      kCFAllocatorDefault, pixelBuffer, formatDesc, &sampleTimingInfo,
      &sampleBuffer);

  if (err != noErr) {
    return nil;
  }

  CFRelease(formatDesc);

  return sampleBuffer;
}

@end