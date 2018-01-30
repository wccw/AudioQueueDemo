//
//  YGPCMDataPlayer.m
//  AudioQueueDemo
//
//  Created by wangyaoguo on 2018/1/30.
//  Copyright © 2018年 lianluo.com. All rights reserved.
//

#import "YGPCMDataPlayer.h"
#import <AudioToolbox/AudioToolbox.h>

#define QUEUE_BUFFER_COUNT 5
#define QUEUE_BUFFER_SIZE 3000

@interface YGPCMDataPlayer() {
    AudioStreamBasicDescription audioDescription;
    AudioQueueRef audioQueue;
    AudioQueueBufferRef audioBuffers[QUEUE_BUFFER_COUNT];
    BOOL audioBufferUsed[QUEUE_BUFFER_COUNT];
    NSLock *syncLock;
}
@end

@implementation YGPCMDataPlayer

-(instancetype)init {
    if (self = [super init]) {
        [self reset];
    }
    return self;
}

-(void)reset {
    audioDescription.mFormatID = kAudioFormatLinearPCM;
    audioDescription.mSampleRate = 8000.0;
    audioDescription.mFramesPerPacket = 1;
    audioDescription.mChannelsPerFrame = 1;
    audioDescription.mBitsPerChannel = 16;
    audioDescription.mBytesPerFrame = audioDescription.mBitsPerChannel * audioDescription.mChannelsPerFrame / 8;
    audioDescription.mBytesPerPacket = audioDescription.mFramesPerPacket * audioDescription.mBytesPerFrame;
    audioDescription.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    
    OSStatus status = AudioQueueNewOutput(&audioDescription, YGAudioQueueOutputCallback, (__bridge void * _Nullable)(self), NULL, NULL, 0, &audioQueue);
    if (status != noErr) {
        NSLog(@"AudioQueueNewOutputError");
        return;
    }
    
    for (int i = 0; i < QUEUE_BUFFER_COUNT; i++) {
        status = AudioQueueAllocateBuffer(audioQueue, QUEUE_BUFFER_SIZE, &audioBuffers[i]);
        if (status != noErr) {
            NSLog(@"AudioQueueAllocateBufferError");
            return;
        }
    }
    
    AudioQueueSetParameter(audioQueue, kAudioQueueParam_Volume, 1);
    AudioQueueStart(audioQueue, NULL);
    
}
//http://blog.csdn.net/likui1989/article/details/52473313
//
-(void)play:(void *)pcmData length:(unsigned int)length {
    [syncLock lock];
    AudioQueueBufferRef audioBuffer = NULL;
    while (true) {
        audioBuffer = [self getReuseBuffer];
        if (audioBuffer != NULL) {
            break;
        }
    }
    NSLog(@"this is data : %d",length);
    memcpy(audioBuffer->mAudioData, pcmData, length);
    audioBuffer->mAudioDataByteSize = length;
    AudioQueueEnqueueBuffer(audioQueue, audioBuffer, 0, NULL);
    [syncLock unlock];
}

-(AudioQueueBufferRef)getReuseBuffer {
    for (int i = 0; i < QUEUE_BUFFER_COUNT; i++) {
        if (!audioBufferUsed[i]) {
            audioBufferUsed[i] = true;
            return audioBuffers[i];
        }
    }
    return NULL;
}

-(void)stop {
    if (audioQueue != nil) {
        AudioQueueStop(audioQueue, true);
        AudioQueueReset(audioQueue);
    }
    audioQueue = nil;
    syncLock = nil;
}



static void YGAudioQueueOutputCallback(void *inUserData, AudioQueueRef outAQ, AudioQueueBufferRef outBuffer) {
    YGPCMDataPlayer *audioOutput = (__bridge YGPCMDataPlayer *)(inUserData);
    [audioOutput handleQueueOutput:outBuffer];
}

-(void)handleQueueOutput:(AudioQueueBufferRef) outBuffer {
    for (int i = 0; i < QUEUE_BUFFER_COUNT; i++) {
        if (audioBuffers[i] == outBuffer) {
            NSLog(@"callbackis:%d",i);
            audioBufferUsed[i] = false;
        }
    }
}

 

@end
