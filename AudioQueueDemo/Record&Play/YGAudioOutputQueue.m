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
        [self audioQueueWithFormat:format withBufferSize:size withCookie:cookie];
    }
    return self;
}

-(void)playWithData:(NSData *)data {
    
    //audio buffer not finishd
    if (audioBufferSize - audioData.length > data.length) {
        [audioData appendData:data];
        return;
    }
    //audio buffer finished
    else {
        [syncLock lock];
        //NSLog(@"finished length:%lu",(unsigned long)audioData.length);
        memcpy(audioBuffer[0], audioData.bytes, audioData.length);
        audioBuffer[0]->mAudioDataByteSize = (UInt32)audioData.length;
        OSStatus status = AudioQueueEnqueueBuffer(audioQueue, audioBuffer[0], 0, NULL);
        if (status != noErr) {
            NSLog(@"errorrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr %d",status);
        } else {
            NSLog(@"success");
        }
        [syncLock unlock];
        /*
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
        NSLog(@"used i is : %d",i);
        memcpy(audioBuffer[i], audioData.bytes, audioData.length);
        audioBuffer[i]->mAudioDataByteSize = (UInt32)audioData.length;
        AudioQueueEnqueueBuffer(audioQueue, audioBuffer[i], 0, NULL);
         */
    }
}

static void YGAudioQueueOutputCallback(void *inUserData, AudioQueueRef outAQ, AudioQueueBufferRef outBuffer) {
    NSLog(@"falseasfdasdfsdfs========");
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

static void YGAudioQueuePropertyCallback(void *inUserData, AudioQueueRef inAQ, AudioQueuePropertyID inID) {
    YGAudioOutputQueue *audioOutput = (__bridge YGAudioOutputQueue *)(inUserData);
    [audioOutput handleAudioQueuePropertyCallBack:inAQ property:inID];
}

- (void)handleAudioQueuePropertyCallBack:(AudioQueueRef)audioQueue property:(AudioQueuePropertyID)property {
    if (property == kAudioQueueProperty_IsRunning) {
        UInt32 isRunning = 0;
        UInt32 size = sizeof(isRunning);
        AudioQueueGetProperty(audioQueue, property, &isRunning, &size);
        NSLog(@"isRuning++++++++++++++++++:%d",isRunning);
    }
}


-(void)audioQueueWithFormat:(AudioStreamBasicDescription)format withBufferSize:(UInt32)bufferSize withCookie:(NSData *)cookie  {
    //create audio queue
    OSStatus status = AudioQueueNewOutput(&format, YGAudioQueueOutputCallback, (__bridge void * _Nullable)(self), NULL, NULL, 0, &audioQueue);
    if (status != noErr) {
        audioQueue = NULL;
        return;
    }
    
    //crate audio buffers
    for (int i = 0; i < kAudioQueueBufferCount; ++i) {
        status = AudioQueueAllocateBuffer(audioQueue, bufferSize, &audioBuffer[i]);
    }
    
    
    //property listen running
    /*
    status = AudioQueueAddPropertyListener(audioQueue, kAudioQueueProperty_IsRunning, YGAudioQueuePropertyCallback, (__bridge void * _Nullable)(self));
    if (status != noErr) {
        AudioQueueDispose(audioQueue, true);
        audioQueue = NULL;
        return;
    }
     */

    
    //set magic cookie
    if (cookie) {
        AudioQueueSetProperty(audioQueue, kAudioQueueProperty_MagicCookie, [cookie bytes], (UInt32)[cookie length]);
    }
    
    AudioQueueStart(audioQueue, NULL);
}

@end
