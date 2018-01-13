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
@end


@implementation AQRecorder

-(instancetype)init {
    if (self = [super init]) {
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

- (void)setBufferSize {
    static const int maxBufferSize = 0x50000;
    int maxPacketSize = audioFormat.mBytesPerPacket;
    if (maxPacketSize == 0) {
        UInt32 maxVBRPacketSize = sizeof(maxPacketSize);
        AudioQueueGetProperty(audioQueue, kAudioQueueProperty_MaximumOutputPacketSize, &maxPacketSize, &maxVBRPacketSize);
    }
    
    Float64 numBytesForTime = audioFormat.mSampleRate * maxPacketSize * KbufferDurationSeconds;
    if (numBytesForTime < maxBufferSize) {
        audioBufferSize = numBytesForTime;
    } else {
        audioBufferSize = maxBufferSize;
    }
    NSLog(@"buffersize:%d",audioBufferSize);
}

-(void)setAudioQueue {
    AudioQueueNewInput(&audioFormat, HandleInputBuffer, (__bridge void *)(self), NULL, NULL, 0, &audioQueue);
    for (int i = 0; i < kNumberBuffers; ++i) {
        AudioQueueAllocateBuffer(audioQueue, audioBufferSize, &audioBuffers[i]);
        AudioQueueEnqueueBuffer(audioQueue, audioBuffers[i], 0, NULL);
    }
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

static void HandleInputBuffer(void                               *inUserData,
                              AudioQueueRef                      inAQ,
                              AudioQueueBufferRef                inBuffer,
                              const AudioTimeStamp               *inStartTime,
                              UInt32                             inNumPackets,
                              const AudioStreamPacketDescription *inPacketDesc) {
    
    NSData *data = [NSData dataWithBytes:inBuffer->mAudioData length:inBuffer->mAudioDataByteSize];
    
    if (inNumPackets > 0) {
        NSLog(@"dataLen:%d %d",inBuffer->mAudioDataByteSize,inNumPackets);

        //process audio buffer
        //NSLog(@"this is audio data");
        AQRecorder *rec = (__bridge AQRecorder *)inUserData;
        //[recorder precessData];
        //NSLog(@"this is audio1 data");
    }
    if (audioIsRecording) {
         AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
    }
}

-(void)precessData {
    
}



@end
