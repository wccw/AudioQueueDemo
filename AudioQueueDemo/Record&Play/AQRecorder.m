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
#import "YGAudioOutputQueue.h"
#import "YGPCMDataPlayer.h"

static const int kNumberBuffers = 3;
static const int kBufferSize = 2048;

@interface AQRecorder() {
    AudioQueueRef               audioQueue;
    AudioQueueBufferRef         audioBuffers[kNumberBuffers];
    AudioStreamBasicDescription audioFormat;
    BOOL                        recording;
    FILE                        *file;
    
    YGAudioOutputQueue *audioOutput;
    YGPCMDataPlayer *pcmPlayer;
 }
@end

@implementation AQRecorder

-(instancetype)init {
    if (self = [super init]) {
        [self setFormat];
        [self setAudio];
        [self localPath];
    }
    return self;
}

-(void)localPath {
    NSString *docpath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *filePath = [docpath stringByAppendingPathComponent:@"record.pcm"];
    file = fopen([filePath UTF8String], "wb");
    if (file) {
        NSLog(@"file success");
    }
    NSLog(@"path:%@",filePath);
}

-(void)setFormat {
    audioFormat.mFormatID = kAudioFormatLinearPCM;
    audioFormat.mSampleRate = 8000.0;
    audioFormat.mFramesPerPacket = 1;
    audioFormat.mChannelsPerFrame = 1;
    audioFormat.mBitsPerChannel = 16;
    audioFormat.mBytesPerFrame = audioFormat.mBitsPerChannel * audioFormat.mChannelsPerFrame / 8;
    audioFormat.mBytesPerPacket = audioFormat.mFramesPerPacket * audioFormat.mBytesPerFrame;
    audioFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
}

-(void)setAudio {
    
    //create audio queue
    OSStatus status = AudioQueueNewInput(&audioFormat, HandleInputBuffer, (__bridge void * _Nullable)(self), NULL, NULL, 0, &audioQueue);
    if (status != noErr) {
        NSLog(@"AudioQueueNewInputError");
        return;
    }
    
    //create audio buffers
    for (int i = 0; i < kNumberBuffers; ++i) {
        status = AudioQueueAllocateBuffer(audioQueue, kBufferSize, &audioBuffers[i]);
        if (status != noErr) {
            NSLog(@"AudioQueueAllocateBufferError");
            return;
        }
        status = AudioQueueEnqueueBuffer(audioQueue, audioBuffers[i], 0, NULL);
        if (status != noErr) {
            NSLog(@"AudioQueueEnqueeuBufferError");
            return;
        }
    }
}

-(void)startRecorder {
    OSStatus status = AudioQueueStart(audioQueue, NULL);
    if (status != noErr) {
        NSLog(@"AudioQueueStartError");
        return;
    }
    recording = YES;
}

-(void)stopRecorder {
    fclose(file);
    if (recording) {
        AudioQueueStop(audioQueue, true);
        AudioQueueDispose(audioQueue, true);
    }
}

static void HandleInputBuffer(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer, const AudioTimeStamp *inStartTime, UInt32 inNumPackets, const AudioStreamPacketDescription *inPacketDesc) {
    AQRecorder *recorder = (__bridge AQRecorder *)(inUserData);
    [recorder handleInputBuffer:inBuffer withPacketDesc:inPacketDesc withNumPackets:inNumPackets];
}

-(void)handleInputBuffer:(AudioQueueBufferRef)inBuffer withPacketDesc:(const AudioStreamPacketDescription*)inPacketDesc withNumPackets:(UInt32)inNumPackets {

    //size_t len = fwrite(inBuffer->mAudioData, 1, inBuffer->mAudioDataByteSize, file);
    //NSLog(@"len is %zu",len);
    if (!pcmPlayer) {
        pcmPlayer = [[YGPCMDataPlayer alloc]init];
    }
    [pcmPlayer play:inBuffer->mAudioData length:inBuffer->mAudioDataByteSize];
    
    /*
    if (!audioOutput) {
        audioOutput = [[YGAudioOutputQueue alloc]initWithFormat:audioFormat withBufferSize:2048 withMagicCookie:nil];
    }
    [audioOutput playWithBuffer:inBuffer withDesc:inPacketDesc];
    */
    
    if (recording) {
        OSStatus status = AudioQueueEnqueueBuffer(audioQueue, inBuffer, 0, NULL);
        if (status != noErr) {
            NSLog(@"AudioQueeuEnqueueBufferError");
            return;
        }
    }

}

@end
