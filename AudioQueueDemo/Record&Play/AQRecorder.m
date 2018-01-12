//
//  AQRecorder.m
//  AudioQueueDemo
//
//  Created by wangyaoguo on 2018/1/12.
//  Copyright © 2018年 lianluo.com. All rights reserved.
//

#import "AQRecorder.h"
#import <AudioToolbox/AudioToolbox.h>

#define KbufferDurationSeconds 0.2
static const int kNumberBuffers = 3;

typedef struct {
    AudioStreamBasicDescription mDataFormat;
    AudioQueueRef               mQueue;
    AudioQueueBufferRef         mBuffers[kNumberBuffers];
    UInt32                      bufferByteSize;
    BOOL                        mIsRunning;
} AQRecorderState;

@interface AQRecorder() {
    AQRecorderState aqData;
}

@end


@implementation AQRecorder

-(instancetype)init {
    if (self = [super init]) {
        [self setAudioFormat];
        [self setBufferSize];
    }
    return self;
}

- (void)setAudioFormat {
    aqData.mDataFormat.mFormatID = kAudioFormatLinearPCM;
    aqData.mDataFormat.mSampleRate = 44100.0;
    aqData.mDataFormat.mFramesPerPacket = 1;
    aqData.mDataFormat.mChannelsPerFrame = 1;
    aqData.mDataFormat.mBitsPerChannel = 16;
    aqData.mDataFormat.mBytesPerPacket = aqData.mDataFormat.mBitsPerChannel / 8 * aqData.mDataFormat.mChannelsPerFrame;
    aqData.mDataFormat.mBytesPerFrame = aqData.mDataFormat.mBytesPerPacket;
    aqData.mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
}

- (void)setBufferSize {
    static const int maxBufferSize = 0x50000;
    int maxPacketSize = aqData.mDataFormat.mBytesPerPacket;
    if (maxPacketSize == 0) {
        UInt32 maxVBRPacketSize = sizeof(maxPacketSize);
        AudioQueueGetProperty(aqData.mQueue, kAudioQueueProperty_MaximumOutputPacketSize, &maxPacketSize, &maxVBRPacketSize);
    }
    
    Float64 numBytesForTime = aqData.mDataFormat.mSampleRate * maxPacketSize * KbufferDurationSeconds;
    if (numBytesForTime < maxBufferSize) {
        aqData.bufferByteSize = numBytesForTime;
    }
    aqData.bufferByteSize = maxBufferSize;
}

- (void)beganRecorder {
    
    AudioQueueNewInput(&aqData.mDataFormat, HandleInputBuffer, &aqData, NULL, kCFRunLoopCommonModes, 0, &aqData.mQueue);
    for (int i = 0; i < kNumberBuffers; ++i) {
        AudioQueueAllocateBuffer(aqData.mQueue, aqData.bufferByteSize, &aqData.mBuffers[i]);
        AudioQueueEnqueueBuffer(aqData.mQueue, aqData.mBuffers[i], 0, NULL);
    }
    
    aqData.mIsRunning = true;
    AudioQueueStart(aqData.mQueue, NULL);
}

-(void)stopRecorder {
    AudioQueueStop(aqData.mQueue, true);
    AudioQueueDispose(aqData.mQueue, true);
    aqData.mIsRunning = false;
}

static void HandleInputBuffer(void                               *aq1Data,
                              AudioQueueRef                      inAQ,
                              AudioQueueBufferRef                inBuffer,
                              const AudioTimeStamp               *inStartTime,
                              UInt32                             inNumPackets,
                              const AudioStreamPacketDescription *inPacketDesc) {
    
    AQRecorderState *pAqData = (AQRecorderState *)aq1Data;

    //获取实时音频流
    //void *audioData = inBuffer->mAudioData;
    NSLog(@"THIS IS REAL TIME AUDIO DATA");
    if (pAqData->mIsRunning == 0) {
        NSLog(@"this is stop running");
        return;
    }
    AudioQueueEnqueueBuffer(pAqData->mQueue, inBuffer, 0, NULL);
}




@end
