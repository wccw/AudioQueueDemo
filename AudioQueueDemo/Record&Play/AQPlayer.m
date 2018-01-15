//
//  AQPlayer.m
//  AudioQueueDemo
//
//  Created by wangyaoguo on 2018/1/12.
//  Copyright © 2018年 lianluo.com. All rights reserved.
//

#import "AQPlayer.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
static const int kNumberBuffers = 3;

@interface AQPlayer() {
    AudioStreamBasicDescription audioFormat;
    AudioQueueRef               audioQueue;
    AudioQueueBufferRef         audioBuffers[kNumberBuffers];
    BOOL                        audioBufferUsed[kNumberBuffers];
    UInt32                      audioBufferSize;
    NSLock                      *syncLock;
    int                         currentIndex;
    NSData                      *pcmData;
}
@end

@implementation AQPlayer

-(instancetype)init {
    if (self = [super init]) {
        syncLock = [[NSLock alloc]init];
         [self setAudioQueue];
    }
    return self;
}

-(void)setAudioQueue {
    /* AudioQueueNewOutput创建输出音频的AudioQueue
     * 1.即将播放音频的数据格式
     * 2.使用完一个缓冲区的回调
     * 3.用户传入的数据指针，用于传递给回调函数
     * 4.指明回调时间发生在哪个RunLoop中，为NULL，表明为AudioQueue线程中执行回调，一般传NULL
     * 5.指明回调时间发生的RunLoop模式，为NULL，表明为kCFRunLoopCommonModes
     * 6.
     * 7.AudioQueue的引用实例
     */
    BOOL ret = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    if (!ret) {
        NSLog(@"设置声音环境失败");
        return;
    }
    
    ret = [[AVAudioSession sharedInstance] setActive:YES error:nil];
    if (!ret) {
        NSLog(@"启动失败");
        return;
    }
    
    audioBufferSize = 3000;
    
    audioFormat.mFormatID = kAudioFormatLinearPCM;
    audioFormat.mSampleRate = 44100.0;
    audioFormat.mFramesPerPacket = 1;
    audioFormat.mChannelsPerFrame = 1;
    audioFormat.mBitsPerChannel = 16;
    audioFormat.mBytesPerFrame = audioFormat.mBitsPerChannel * audioFormat.mChannelsPerFrame / 8;
    audioFormat.mBytesPerPacket = audioFormat.mFramesPerPacket * audioFormat.mBytesPerFrame;
    audioFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    
    AudioQueueNewOutput(&audioFormat, HandleOutputBuffer , (__bridge void*)self, NULL, NULL, 0, &audioQueue);
    AudioQueueSetParameter(audioQueue, kAudioQueueParam_Volume, 1.0);
    
    /* 为音频数据开辟缓冲区
     * 1.AudioQueue的引用实例
     * 2.开辟缓冲区大小
     * 3.开辟缓冲区引用实例
     */
    
    for (int i = 0; i < kNumberBuffers; ++i) {
        AudioQueueAllocateBuffer(audioQueue, audioBufferSize, &audioBuffers[i]);
    }
    
    //音频播放
    AudioQueueStart(audioQueue, NULL);
}

static void HandleOutputBuffer(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer) {
    AQPlayer *player = (__bridge AQPlayer*)inUserData;
    [player resetBufferState:inAQ withBuffer:inBuffer];
}

-(void)resetBufferState:(AudioQueueRef)inAQ withBuffer:(AudioQueueBufferRef)inBuffer {
    if (pcmData.length == 0) {
        NSLog(@"this is empty data");
        inBuffer->mAudioDataByteSize = 1;
        memcpy(inBuffer->mAudioData, "0", 1);
        AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
    }
    
    for (int i = 0; i < kNumberBuffers; ++i) {
        if (inBuffer == audioBuffers[i]) {
            NSLog(@"index is:%d",i);
            audioBufferUsed[i] = false;
        }
    }
}

-(void)playWithData:(NSData *)data {
   
    [syncLock lock];
    pcmData = data;
    for (int i = 0; i < kNumberBuffers; i ++) {
        if (audioBufferUsed[i]) {
            continue;
        }
        audioBuffers[i]->mAudioDataByteSize = (UInt32)data.length;
        memcpy(audioBuffers[i]->mAudioData, data.bytes, data.length);
        AudioQueueEnqueueBuffer(audioQueue, audioBuffers[i], 0, nil);
    }
    
    
    while (true) {
        if (!audioBufferUsed[currentIndex]) {
            audioBufferUsed[currentIndex] = true;
            break;
        } else {
            currentIndex++;
            if (currentIndex >= kNumberBuffers) {
                currentIndex = 0;
            }
        }
    }
    
    audioBuffers[currentIndex]->mAudioDataByteSize = (UInt32)data.length;
    memcpy(audioBuffers[currentIndex]->mAudioData, data.bytes, data.length);
    AudioQueueEnqueueBuffer(audioQueue, audioBuffers[currentIndex], 0, NULL);
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
