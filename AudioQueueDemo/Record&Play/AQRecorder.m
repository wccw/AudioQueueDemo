//
//  AQRecorder.m
//  AudioQueueDemo
//
//  Created by wangyaoguo on 2018/1/12.
//  Copyright © 2018年 lianluo.com. All rights reserved.
//

#import "AQRecorder.h"
#import <AudioToolbox/AudioToolbox.h>

#define KbufferDurationSeconds 0.03
static const int kNumberBuffers = 3;
static BOOL audioIsRecording = NO;

@interface AQRecorder() {
    AudioStreamBasicDescription audioFormat;
    AudioQueueBufferRef         audioBuffers[kNumberBuffers];
    AudioQueueRef               audioQueue;
    UInt32                      audioBufferSize;
}
@property (nonatomic, assign) id<recorderDelegate> delegate;
@end


@implementation AQRecorder

-(instancetype)initWithDelegate:(id<recorderDelegate>)delegate {
    if (self = [super init]) {
        self.delegate = delegate;
        [self audioConfig];
    }
    return self;
}

-(void)audioConfig {
    //audio format
    audioFormat.mFormatID = kAudioFormatLinearPCM;
    audioFormat.mSampleRate = 44100.0;
    audioFormat.mFramesPerPacket = 1;
    audioFormat.mChannelsPerFrame = 1;
    audioFormat.mBitsPerChannel = 16;
    audioFormat.mBytesPerFrame = audioFormat.mBitsPerChannel * audioFormat.mChannelsPerFrame / 8;
    audioFormat.mBytesPerPacket = audioFormat.mFramesPerPacket * audioFormat.mBytesPerFrame;
    audioFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    
    //buffer size
    [self setBufferSizeWithSeconds:KbufferDurationSeconds];
    
    //audio queue
    AudioQueueNewInput(&audioFormat, HandleInputBuffer, (void *)CFBridgingRetain(self), NULL, NULL, 0, &audioQueue);
    
    //audio buffers
    for (int i = 0; i < kNumberBuffers; ++i) {
        AudioQueueAllocateBuffer(audioQueue, audioBufferSize, &audioBuffers[i]);
        AudioQueueEnqueueBuffer(audioQueue, audioBuffers[i], 0, NULL);
    }
}

- (void)setBufferSizeWithSeconds:(float)seconds {
    static const int maxBufferSize = 2048;
    int maxPacketSize = audioFormat.mBytesPerPacket;
    if (maxPacketSize == 0) {
        UInt32 maxVBRPacketSize = sizeof(maxPacketSize);
        AudioQueueGetProperty(audioQueue, kAudioQueueProperty_MaximumOutputPacketSize, &maxPacketSize, &maxVBRPacketSize);
    }
    
    Float64 numBytesForTime = audioFormat.mSampleRate * maxPacketSize * seconds;
    if (numBytesForTime < maxBufferSize) {
        audioBufferSize = numBytesForTime;
    } else {
        audioBufferSize = maxBufferSize;
    }
    NSLog(@"buffersize:%d",audioBufferSize);
}


- (void)beganRecorder {
    audioIsRecording = true;
    AudioQueueStart(audioQueue, NULL);
}

-(void)stopRecorder {
    if (audioIsRecording) {
        AudioQueueStop(audioQueue, true);
        AudioQueueDispose(audioQueue, true);
        audioIsRecording = false;
    }
}

static void HandleInputBuffer(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer, const AudioTimeStamp *inStartTime, UInt32 inNumPackets, const AudioStreamPacketDescription *inPacketDesc) {
    
    AQRecorder *aqr = (__bridge AQRecorder *)inUserData;
    if (inNumPackets > 0) {
        [aqr processAudioBuffer:inBuffer];
    }
    if (audioIsRecording) {
         AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
    }
}

- (void)processAudioBuffer:(AudioQueueBufferRef)buffer {
    NSData *data = [NSData dataWithBytes:buffer->mAudioData length:buffer->mAudioDataByteSize];
    if (self.delegate && [self.delegate respondsToSelector:@selector(recordData:)]) {
        [self.delegate recordData:data];
    }
}



@end
