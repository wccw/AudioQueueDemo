//
//  PCMDataPlayer.m
//  AudioQueueDemo
//
//  Created by wangyaoguo on 2018/1/18.
//  Copyright © 2018年 lianluo.com. All rights reserved.
//

#import "PCMDataPlayer.h"
#import <AudioToolbox/AudioToolbox.h>

#define EVERY_READ_SIZE 1000
#define BUFFER_SIZE 2000
#define BUFFER_NUM 3

@interface PCMDataPlayer() {
    AudioQueueRef       audioQueue;
    AudioQueueBufferRef audioBuffers[BUFFER_NUM];
    AudioStreamBasicDescription audioForamt;
    FILE *pcmFile;
    Byte *pcmDataBuffer;
}
@end

@implementation PCMDataPlayer

-(instancetype)initWithPcmFilePath:(NSString *)path {
    if (self = [super init]) {
        pcmFile = fopen([path UTF8String], "r");
        if (pcmFile) {
            pcmDataBuffer = malloc(EVERY_READ_SIZE);
        } else {
            NSLog(@"open pcm file fail");
        }
        [self setAuido];
    }
    return self;
}

-(void)startPlay {
    for (int i = 0; i < BUFFER_NUM; ++i) {
        AQAudioQueueOutputCallback((__bridge void *)(self), audioQueue, audioBuffers[i]);
    }
    AudioQueueStart(audioQueue, NULL);
}

-(void)stopPlay {
    AudioQueueStop(audioQueue, true);
}

-(void)setAuido {
    audioForamt.mSampleRate = 8000;
    audioForamt.mFormatID = kAudioFormatLinearPCM;
    audioForamt.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    audioForamt.mChannelsPerFrame = 1;
    audioForamt.mFramesPerPacket = 1;
    audioForamt.mBitsPerChannel = 16;
    audioForamt.mBytesPerFrame = audioForamt.mBitsPerChannel / 8 * audioForamt.mChannelsPerFrame;
    audioForamt.mBytesPerPacket = audioForamt.mBytesPerFrame;
    
    AudioQueueNewOutput(&audioForamt, AQAudioQueueOutputCallback, (__bridge void * _Nullable)(self), NULL, NULL, 0, &audioQueue);
    
    for (int i = 0; i < BUFFER_NUM; i ++) {
        AudioQueueAllocateBuffer(audioQueue, BUFFER_SIZE, &audioBuffers[i]);
    }
}

static void AQAudioQueueOutputCallback(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer) {
    PCMDataPlayer *pcmPlayer = (__bridge PCMDataPlayer *)inUserData;
    [pcmPlayer processOutputCallback:inAQ withBuffer:inBuffer];
}

-(void)processOutputCallback:(AudioQueueRef) inAQ withBuffer:(AudioQueueBufferRef)inbuffer {
    size_t readLength = fread(pcmDataBuffer, 1, EVERY_READ_SIZE, pcmFile);
    if (readLength <= 0) {
        NSLog(@"play finished");
        fclose(pcmFile);
        return;
    }
    inbuffer->mAudioDataByteSize = (UInt32)readLength;
    memcpy(inbuffer->mAudioData, pcmDataBuffer, readLength);
    AudioQueueEnqueueBuffer(audioQueue, inbuffer, 0, NULL);
}

@end
