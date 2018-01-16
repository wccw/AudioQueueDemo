//
//  AQRecorder.m
//  AudioQueueDemo
//
//  Created by wangyaoguo on 2018/1/16.
//  Copyright © 2018年 lianluo.com. All rights reserved.
//

#import "AQRecorder.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

static const int kNumberBuffers = 3;
static BOOL audioIsRecording = NO;

@interface AQRecorder() {
    AudioQueueBufferRef audioRecordBuffers[kNumberBuffers];
    AudioQueueRef       audioRecordQueue;
}
@end

@implementation AQRecorder

-(instancetype)init {
    if (self = [super init]) {
        [self audioConfig];
    }
    return self;
}

-(void)audioConfig {
    
    BOOL ret = [[AVAudioSession sharedInstance]setCategory:AVAudioSessionCategoryRecord error:nil];
    
    if (!ret) {
        NSLog(@"设置声音环境失败");
        return;
    }
    
    ret = [[AVAudioSession sharedInstance] setActive:YES error:nil];
    if (!ret) {
        NSLog(@"启动失败");
        return;
    }
    
    //audio format
    AudioStreamBasicDescription audioFormat;
    audioFormat.mFormatID = kAudioFormatLinearPCM;
    audioFormat.mSampleRate = 44100.0;
    audioFormat.mFramesPerPacket = 1;
    audioFormat.mChannelsPerFrame = 1;
    audioFormat.mBitsPerChannel = 16;
    audioFormat.mBytesPerFrame = audioFormat.mBitsPerChannel * audioFormat.mChannelsPerFrame / 8;
    audioFormat.mBytesPerPacket = audioFormat.mFramesPerPacket * audioFormat.mBytesPerFrame;
    audioFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    
    //buffer size
    UInt32 audioBufferSize = 2048;
    
    //audio record queue
    AudioQueueNewInput(&audioFormat, HandleInputBuffer, (void *)CFBridgingRetain(self), NULL, NULL, 0, &audioRecordQueue);
    
    //audio buffers
    for (int i = 0; i < kNumberBuffers; ++i) {
        AudioQueueAllocateBuffer(audioRecordQueue, audioBufferSize, &audioRecordBuffers[i]);
        AudioQueueEnqueueBuffer(audioRecordQueue, audioRecordBuffers[i], 0, NULL);
    }
}

static void HandleInputBuffer(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer, const AudioTimeStamp *inStartTime, UInt32 inNumPackets, const AudioStreamPacketDescription *inPacketDesc) {
    
    AQRecorder *aqr = (__bridge AQRecorder *)inUserData;
    if (inNumPackets > 0) {
        [aqr processAudioRecordBuffer:inBuffer];
    }
    if (audioIsRecording) {
        AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
    }
}

- (void)processAudioRecordBuffer:(AudioQueueBufferRef)buffer {
    NSData *data = [NSData dataWithBytes:buffer->mAudioData length:buffer->mAudioDataByteSize];
    
}

-(void)startRecorder {
    AudioQueueStart(audioRecordQueue, NULL);
    audioIsRecording = YES;
}

-(void)stopPlayer {
    if (audioIsRecording) {
        AudioQueueStop(audioRecordQueue, true);
        AudioQueueDispose(audioRecordQueue, true);
    }
}

@end
