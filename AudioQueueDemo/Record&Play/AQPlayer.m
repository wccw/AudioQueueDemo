//
//  AQPlayer.m
//  AudioQueueDemo
//
//  Created by wangyaoguo on 2018/1/12.
//  Copyright © 2018年 lianluo.com. All rights reserved.
//

#import "AQPlayer.h"
#import <AudioToolbox/AudioToolbox.h>

static const int kNumberBuffers = 3;

typedef struct {
    AudioStreamBasicDescription  mDataFormat;
    AudioQueueRef                mQueue;
    AudioQueueBufferRef          mBuffers[kNumberBuffers];
    UInt32                       bufferByteSize;
    UInt32                       mNumPacketsToRead;
    AudioStreamPacketDescription *mPacketsDescs;
    BOOL                         mIsRunning;
} AQPlayerState;

@interface AQPlayer() {
    AQPlayerState aqData;
}
@end

@implementation AQPlayer

-(void)setBufferSize {
    static const int maxBufferSize = 0x50000;
    static const int minBufferSize = 0x40000;
    UInt32 maxPacketSize = 10;
    if (aqData.mDataFormat.mFramesPerPacket != 0) {
        Float64 numPacketsForTime = aqData.mDataFormat.mSampleRate / aqData.mDataFormat.mFramesPerPacket * 0.5;
        aqData.bufferByteSize = numPacketsForTime * maxPacketSize;
    } else {
        aqData.bufferByteSize = maxBufferSize > maxPacketSize ? maxBufferSize : maxPacketSize;
    }
    
    if (aqData.bufferByteSize > maxBufferSize && aqData.bufferByteSize > maxPacketSize) {
        aqData.bufferByteSize = maxPacketSize;
    } else {
        if (aqData.bufferByteSize < minBufferSize) {
            aqData.bufferByteSize = minBufferSize;
        }
    }
}

-(void)startPlayer {
    for (int i = 0; i < kNumberBuffers; ++i) {
        AudioQueueAllocateBuffer(aqData.mQueue, aqData.bufferByteSize, &aqData.mBuffers[i]);
        HandleOutputBuffer(&aqData, aqData.mQueue, aqData.mBuffers[i]);
    }
    AudioQueueNewOutput(&aqData.mDataFormat, HandleOutputBuffer, &aqData, CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &aqData.mQueue);
    AudioQueueStart(aqData.mQueue, NULL);
}

static void HandleOutputBuffer (void *aqData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer) {
    AQPlayerState *pAqData = (AQPlayerState *)aqData;
    if (pAqData->mIsRunning == 0) {
        return;
    }
    
    UInt32 numPackets = pAqData->mNumPacketsToRead;
    if (numPackets > 0) {
        AudioQueueEnqueueBuffer(pAqData->mQueue, inBuffer, pAqData->mPacketsDescs ? numPackets : 0, pAqData->mPacketsDescs);
    }
}

@end
