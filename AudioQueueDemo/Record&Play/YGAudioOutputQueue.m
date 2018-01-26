//
//  YGAudioOutputQueue.m
//  AudioQueueDemo
//
//  Created by wangyaoguo on 2018/1/22.
//  Copyright © 2018年 lianluo.com. All rights reserved.
//

#import "YGAudioOutputQueue.h"

const int kAudioQueueBufferCount = 3;

@interface YGAudioOutputQueue() {
    AudioQueueRef                audioQueue;
    AudioQueueBufferRef          audioBuffer[kAudioQueueBufferCount];
    BOOL                         audioBufferUsed[kAudioQueueBufferCount];
    UInt32                       audioBufferSize;
    UInt32                       audioBufferIndex;
    UInt32                       audioBufferCurrentSize;
    UInt32                       audioBufferFillSize;
    UInt32                       audioBufferPacketNum;
    AudioStreamPacketDescription audioStreamPacketDesc[100];
    NSMutableData                *audioData;
    NSMutableArray               *audioPackets;
    NSLock                       *syncLock;
}
@end

@implementation YGAudioOutputQueue

-(void)playWithPacket:(NSData *)data withDescription:(AudioStreamPacketDescription)description {
 
     //buffer fill finished
     if (audioBufferSize - audioBufferFillSize < data.length) {
         NSLog(@"Finish a packet %d index:%d packetnum:%d",audioBufferFillSize, audioBufferIndex,audioBufferPacketNum);
         OSStatus status = AudioQueueEnqueueBuffer(audioQueue, audioBuffer[audioBufferIndex], audioBufferPacketNum, audioStreamPacketDesc);
         if (status != noErr) {
            NSLog(@"AudioQueueEnqueueBufferFailed");
            return;
         }
     
         audioBufferIndex = (++audioBufferIndex) % kAudioQueueBufferCount;
         audioBufferPacketNum = 0;
         audioBufferFillSize = 0;
         while (audioBufferUsed[audioBufferIndex]);
     }
     AudioQueueBufferRef currentBuffer = audioBuffer[audioBufferIndex];
     audioBufferUsed[audioBufferIndex] = true;
    
    
     memcmp(currentBuffer->mAudioData + audioBufferFillSize, data.bytes, data.length);
     currentBuffer->mAudioDataByteSize = audioBufferFillSize + (UInt32)data.length;
     NSLog(@"offset:%d size:%lu length:%u",audioBufferFillSize,data.length,(unsigned int)currentBuffer->mAudioDataByteSize);

     audioStreamPacketDesc[audioBufferPacketNum] = description;
     audioStreamPacketDesc[audioBufferPacketNum].mStartOffset = audioBufferFillSize;
     audioBufferFillSize += data.length;
     audioBufferPacketNum += 1;
    
    [syncLock unlock];
}


-(void)playWithPackets:(NSData *)data withDescriptions:(AudioStreamPacketDescription*)descriptions {
    [syncLock lock];
    
    int i = 0;
    while (true) {
        if (!audioBufferUsed[i]) {
            audioBufferUsed[i] = true;
            break;
        } else {
            i++;
            if (i >= kAudioQueueBufferCount ) {
                i = 0;
            }
        }
    }
    
    memcpy(audioBuffer[i]->mAudioData, data.bytes, data.length);
    audioBuffer[i]->mAudioDataByteSize = (UInt32)data.length;
    OSStatus status = AudioQueueEnqueueBuffer(audioQueue, audioBuffer[i], 7, descriptions);
    if (status != noErr) {
        NSLog(@"AudioQueueEnqueueBufferFailed");
        return;
    }

    [syncLock unlock];
}

-(instancetype)initWithFormat:(AudioStreamBasicDescription)format withBufferSize:(UInt32)size withMagicCookie:(NSData *)cookie {
    if (self = [super init]) {
        syncLock = [[NSLock alloc]init];
        audioBufferSize = 3000;
        audioData = [[NSMutableData alloc]init];
        audioPackets = [[NSMutableArray alloc]init];
        [self audioQueueWithFormat:format withCookie:cookie];
    }
    return self;
}

-(void)audioQueueWithFormat:(AudioStreamBasicDescription)format  withCookie:(NSData *)cookie  {
   
    OSStatus status = AudioQueueNewOutput(&format, YGAudioQueueOutputCallback, (__bridge void * _Nullable)(self), NULL, NULL, 0, &audioQueue);
    if (status != noErr) {
        audioQueue = NULL;
        NSLog(@"AudioQueueNewOutputError");
        return;
    }
    
    AudioQueueSetParameter(audioQueue, kAudioQueueParam_Volume, 1.0);
    
    for (int i = 0; i < kAudioQueueBufferCount; i++) {
        status = AudioQueueAllocateBuffer(audioQueue, audioBufferSize, &audioBuffer[i]);
        if (status != noErr) {
            NSLog(@"AudioQueueAllocateBufferError");
            return;
        }
    }
    
    if (cookie) {
        AudioQueueSetProperty(audioQueue, kAudioQueueProperty_MagicCookie, [cookie bytes], (UInt32)[cookie length]);
    }
 
    status = AudioQueueStart(audioQueue, NULL);

    if (status != noErr) {
        NSLog(@"AudioQueueStartError");
    }
}



/*
-(void)playWithPacket:(NSData *)data withDescription:(AudioStreamPacketDescription)description {
    [syncLock lock];
    
    int i = 0;
    while (true) {
        if (!audioBufferUsed[i]) {
            audioBufferUsed[i] = true;
            break;
        } else {
            i++;
            if (i >= kAudioQueueBufferCount ) {
                i = 0;
            }
        }
    }
    
    NSLog(@"playData:%lu---%lld",data.length, description.mStartOffset);
    memcpy(audioBuffer[i]->mAudioData, data.bytes, data.length);
    audioBuffer[i]->mAudioDataByteSize = (UInt32)data.length;
    description.mStartOffset = 0;
    OSStatus status = AudioQueueEnqueueBuffer(audioQueue, audioBuffer[i], 1, &description);
    if (status != noErr) {
        NSLog(@"AudioQueueEnqueueBufferFailed");
        return;
    }
    
    [syncLock unlock];
}
 */

#pragma mark this is delegate

static void YGAudioQueueOutputCallback(void *inUserData, AudioQueueRef outAQ, AudioQueueBufferRef outBuffer) {
    YGAudioOutputQueue *audioOutput = (__bridge YGAudioOutputQueue *)(inUserData);
    [audioOutput handleQueueOutput:outBuffer];
}

-(void)handleQueueOutput:(AudioQueueBufferRef) outBuffer {
    for (int i = 0; i < kAudioQueueBufferCount; ++i) {
        if (audioBuffer[i] == outBuffer) {
            NSLog(@"callbackis:%d",i);
            audioBufferUsed[i] = false;
        }
    }
}


@end

 
