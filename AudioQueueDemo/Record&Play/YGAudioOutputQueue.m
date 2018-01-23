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
    AudioQueueRef               audioQueue;
    AudioQueueBufferRef         audioBuffer[kAudioQueueBufferCount];
    BOOL                        audioBufferUsed[kAudioQueueBufferCount];
    NSLock                      *syncLock;
    NSMutableData *             audioData;
    UInt32                      audioBufferSize;
}
@end

@implementation YGAudioOutputQueue

-(instancetype)initWithFormat:(AudioStreamBasicDescription)format withBufferSize:(UInt32)size withMagicCookie:(NSData *)cookie {
    if (self = [super init]) {
        syncLock = [[NSLock alloc]init];
        audioData = [[NSMutableData alloc]init];
        audioBufferSize = size;
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

-(void)playWithData:(NSData *)data withPacketDes:(AudioStreamPacketDescription)packetDes {
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
    NSLog(@"playData:%lu",data.length);
    memcpy(audioBuffer[i]->mAudioData, data.bytes, data.length);
    audioBuffer[i]->mAudioDataByteSize = (UInt32)data.length;
    OSStatus status = AudioQueueEnqueueBuffer(audioQueue, audioBuffer[i], 1, &packetDes);
    if (status != noErr) {
        NSLog(@"AudioQueueEnqueueBufferFailed");
        return;
    }
    
    /*
    if (audioBufferSize - audioData.length > data.length) {
        [audioData appendData:data];
        [syncLock unlock];
        return;
    } else {
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
        NSLog(@"playData:%lu",audioData.length);
        memcpy(audioBuffer[i]->mAudioData, audioData.bytes, audioData.length);
        audioBuffer[i]->mAudioDataByteSize = (UInt32)audioData.length;
        OSStatus status = AudioQueueEnqueueBuffer(audioQueue, audioBuffer[i], 0, NULL);
        if (status != noErr) {
            NSLog(@"AudioQueueEnqueueBufferFailed");
            return;
        }
    }
     */
    [syncLock unlock];
}

#pragma mark this is delegate

static void YGAudioQueueOutputCallback(void *inUserData, AudioQueueRef outAQ, AudioQueueBufferRef outBuffer) {
    NSLog(@"callback");
    YGAudioOutputQueue *audioOutput = (__bridge YGAudioOutputQueue *)(inUserData);
    [audioOutput handleQueueOutput:outBuffer];
}

-(void)handleQueueOutput:(AudioQueueBufferRef) outBuffer {
    for (int i = 0; i < kAudioQueueBufferCount; ++i) {
        if (audioBuffer[i] == outBuffer) {
            audioBufferUsed[i] = false;
        }
    }
}


@end
