//
//  AQRecorder.m
//  AudioQueueDemo
//
//  Created by wangyaoguo on 2018/1/12.
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
    
    AudioQueueBufferRef audioPlayerBuffers[kNumberBuffers];
    AudioQueueRef       audioPlayerQueue;
    BOOL                audioPlayerBufferUsed[kNumberBuffers];
}
@property (nonatomic, assign) id<recorderDelegate> delegate;
@end


@implementation AQRecorder

-(instancetype)initWithDelegate:(id<recorderDelegate>)delegate {
    if (self = [super init]) {
        self.delegate = delegate;
        [self audioConfig];
    }
    return self;
}

-(void)audioConfig {
    
    BOOL ret = [[AVAudioSession sharedInstance]setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];

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
    audioFormat.mSampleRate = 8000;
    audioFormat.mFramesPerPacket = 1;
    audioFormat.mChannelsPerFrame = 1;
    audioFormat.mBitsPerChannel = 16;
    audioFormat.mBytesPerFrame = audioFormat.mBitsPerChannel * audioFormat.mChannelsPerFrame / 8;
    audioFormat.mBytesPerPacket = audioFormat.mFramesPerPacket * audioFormat.mBytesPerFrame;
    audioFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    
    //buffer size
    UInt32 audioBufferSize = 1024;
    
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

- (void)beganRecorder {
    audioIsRecording = true;
    AudioQueueStart(audioRecordQueue, NULL);
}

- (void)beganPlayer {
    AudioQueueStart(audioPlayerQueue, NULL);
}

-(void)stopRecorder {
    if (audioIsRecording) {
        AudioQueueStop(audioRecordQueue, true);
        AudioQueueDispose(audioRecordQueue, true);
        audioIsRecording = false;
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
    if (self.delegate && [self.delegate respondsToSelector:@selector(recordData:)]) {
        [self.delegate recordData:data];
    }
}

static void HandleOutputBuffer(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer) {
    AQRecorder *aqr = (__bridge AQRecorder *)inUserData;
    [aqr processAudioPlayerBuffer:inBuffer];
}

-(void)processAudioPlayerBuffer:(AudioQueueBufferRef)buffer {
    for (int i = 0; i < kNumberBuffers; i++) {
        if (buffer == audioPlayerBuffers[i]) {
            audioPlayerBufferUsed[i] = NO;
            NSLog(@"buff(%d) 使用完成",i);
            break;
        }
    }
}

- (void)playerData:(NSData *)data {
    AudioQueueBufferRef currentBuffer = NULL;
    for (int i = 0; i < kNumberBuffers; i++) {
        if (audioPlayerBufferUsed[i]) {
            continue;
        }
        currentBuffer = audioPlayerBuffers[i];
        audioPlayerBufferUsed[i] = YES;
    
        memcpy(currentBuffer->mAudioData, data.bytes, data.length);
        currentBuffer->mAudioDataByteSize = (UInt32)data.length;
        AudioQueueEnqueueBuffer(audioPlayerQueue, currentBuffer, 0, nil);
        break;
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
