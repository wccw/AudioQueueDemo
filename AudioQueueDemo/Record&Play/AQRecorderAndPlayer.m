//
//  AQRecorder.m
//  AudioQueueDemo
//
//  Created by wangyaoguo on 2018/1/12.
//  Copyright © 2018年 lianluo.com. All rights reserved.
//

#import "AQRecorderAndPlayer.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

static const int kNumberBuffers = 3;
static BOOL audioIsRecording = NO;

@interface AQRecorderAndPlayer() {
    AudioQueueBufferRef audioRecordBuffers[kNumberBuffers];
    AudioQueueRef       audioRecordQueue;
    
    AudioQueueBufferRef audioPlayerBuffers[kNumberBuffers];
    AudioQueueRef       audioPlayerQueue;
    BOOL                audioPlayerBufferUsed[kNumberBuffers];
    NSLock              *syncLock;
}
@end


@implementation AQRecorderAndPlayer

-(instancetype)init {
    if (self = [super init]) {
        [self audioConfig];
    }
    return self;
}

-(void)audioConfig {
    syncLock = [[NSLock alloc]init];
    
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
    
    //audio player queue
    AudioQueueNewOutput(&audioFormat, HandleOutputBuffer, (void *)CFBridgingRetain(self), NULL, NULL, 0, &audioPlayerQueue);
    
    //audio buffers
    for (int i = 0; i < kNumberBuffers; ++i) {
        AudioQueueAllocateBuffer(audioRecordQueue, audioBufferSize, &audioRecordBuffers[i]);
        AudioQueueAllocateBuffer(audioPlayerQueue, audioBufferSize, &audioPlayerBuffers[i]);
        AudioQueueEnqueueBuffer(audioRecordQueue, audioRecordBuffers[i], 0, NULL);
    }
    
}

static void HandleInputBuffer(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer, const AudioTimeStamp *inStartTime, UInt32 inNumPackets, const AudioStreamPacketDescription *inPacketDesc) {
    
    AQRecorderAndPlayer *aqr = (__bridge AQRecorderAndPlayer *)inUserData;
    if (inNumPackets > 0) {
        [aqr processAudioRecordBuffer:inBuffer];
    }
    if (audioIsRecording) {
         AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
    }
}

- (void)processAudioRecordBuffer:(AudioQueueBufferRef)buffer {
    NSData *data = [NSData dataWithBytes:buffer->mAudioData length:buffer->mAudioDataByteSize];
    
    [syncLock lock];
    for (int i = 0; i < kNumberBuffers; i++) {
        if (audioPlayerBufferUsed[i]) {
            continue;
        }
    
        audioPlayerBufferUsed[i] = YES;
        memcpy(audioPlayerBuffers[i]->mAudioData, data.bytes, data.length);
        audioPlayerBuffers[i]->mAudioDataByteSize = (UInt32)data.length;
        AudioQueueEnqueueBuffer(audioPlayerQueue, audioPlayerBuffers[i], 0, nil);
        break;
    }
    [syncLock unlock];
}

static void HandleOutputBuffer(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer) {
    AQRecorderAndPlayer *aqr = (__bridge AQRecorderAndPlayer *)inUserData;
    [aqr processAudioPlayerBuffer:inBuffer];
}

-(void)processAudioPlayerBuffer:(AudioQueueBufferRef)buffer {
    for (int i = 0; i < kNumberBuffers; i++) {
        if (buffer == audioPlayerBuffers[i]) {
            audioPlayerBufferUsed[i] = NO;
            break;
        }
    }
}



-(void) beganRecorderPlayer {
    audioIsRecording = true;
    AudioQueueStart(audioRecordQueue, NULL);
    AudioQueueStart(audioPlayerQueue, NULL);
}

- (void)stopRecorderPlayer {
    if (audioIsRecording) {
        AudioQueueStop(audioRecordQueue, true);
        AudioQueueDispose(audioRecordQueue, true);
        AudioQueueStop(audioPlayerQueue, true);
        AudioQueueDispose(audioPlayerQueue, true);
        audioIsRecording = false;
    }
}



/*
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
 */



@end
