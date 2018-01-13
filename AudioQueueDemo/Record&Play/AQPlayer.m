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

@interface AQPlayer() {
    AudioStreamBasicDescription audioFormat;
    AudioQueueRef               audioQueue;
    AudioQueueBufferRef         audioBuffers[kNumberBuffers];
    BOOL                        audioBufferUsed[kNumberBuffers];
    UInt32                      audioBufferSize;
    NSLock                      *syncLock;
}
@end

@implementation AQPlayer


-(instancetype)init {
    if (self = [super init]) {
        syncLock = [[NSLock alloc]init];
        [self setAudioFormat];
        [self setBufferSize];
        [self setAudioQueue];
    }
    return self;
}

-(void)setAudioFormat {
    audioFormat.mFormatID = kAudioFormatLinearPCM;
    audioFormat.mSampleRate = 44100.0;
    audioFormat.mFramesPerPacket = 1;
    audioFormat.mChannelsPerFrame = 1;
    audioFormat.mBitsPerChannel = 16;
    audioFormat.mBytesPerFrame = audioFormat.mBitsPerChannel * audioFormat.mChannelsPerFrame / 8;
    audioFormat.mBytesPerPacket = audioFormat.mFramesPerPacket * audioFormat.mBytesPerFrame;
    audioFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
}

-(void)setBufferSize {
    static const int maxBufferSize = 0x50000;
    static const int minBufferSize = 0x40000;
    UInt32 maxPacketSize = 10;
    if (audioFormat.mFramesPerPacket != 0) {
        Float64 numPacketsForTime = audioFormat.mSampleRate / audioFormat.mFramesPerPacket * 0.5;
        audioBufferSize = numPacketsForTime * maxPacketSize;
    } else {
        audioBufferSize = maxBufferSize > maxPacketSize ? maxBufferSize : maxPacketSize;
    }
    
    if (audioBufferSize > maxBufferSize && audioBufferSize > maxPacketSize) {
        audioBufferSize = maxPacketSize;
    } else {
        if (audioBufferSize < minBufferSize) {
            audioBufferSize = minBufferSize;
        }
    }
}

-(void)setAudioQueue {
    AudioQueueNewOutput(&audioFormat, HandleOutputBuffer , (__bridge void*)self, nil, 0, 0, &audioQueue);
    AudioQueueSetParameter(audioQueue, kAudioQueueParam_Volume, 1.0);
    
    for (int i = 0; i < kNumberBuffers; ++i) {
        AudioQueueAllocateBuffer(audioQueue, audioBufferSize, &audioBuffers[i]);
    }
    AudioQueueStart(audioQueue, NULL);
}

static void HandleOutputBuffer(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer) {
    AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
}

-(void)playWithData:(NSData *)data {
    [syncLock lock];
    int i = 0;
    
    while (true) {
        if (!audioBufferUsed[i]) {
            audioBufferUsed[i] = true;
            break;
        } else {
            i++;
            if (i >= kNumberBuffers) {
                i = 0;
            }
        }
    }
    
    audioBuffers[i]->mAudioDataByteSize = (UInt32)data.length;
    memcpy(audioBuffers[i]->mAudioData, data.bytes, data.length);
    AudioQueueEnqueueBuffer(audioQueue, audioBuffers[i], 0, NULL);
    [syncLock unlock];
}

-(void)stop {
    if (audioQueue != nil) {
        AudioQueueStop(audioQueue, true);
    }
    audioQueue = nil;
    syncLock = nil;
}


@end
