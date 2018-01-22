//
//  YGAudioOutputQueue.m
//  AudioQueueDemo
//
//  Created by wangyaoguo on 2018/1/22.
//  Copyright © 2018年 lianluo.com. All rights reserved.
//

#import "YGAudioOutputQueue.h"

const int YGAudioQueueBufferCount = 3;

@interface YGAudioOutputQueue() {
    AudioQueueRef               audioQueue;
    AudioQueueBufferRef         audioBuffer[YGAudioQueueBufferCount];
    BOOL                        audioBufferUsed[YGAudioQueueBufferCount];
}
@end

@implementation YGAudioOutputQueue

-(instancetype)initWithFormat:(AudioStreamBasicDescription)format withBufferSize:(UInt32)size withMagicCookie:(NSData *)cookie {
    if (self = [super init]) {
        [self audioQueueWithFormat:format withBufferSize:size withCookie:cookie];
    }
    return self;
}

-(void)playData:(NSData *)data {

    for (int i = 0; i < YGAudioQueueBufferCount; ++i) {
        if (audioBufferUsed[i] == true) {
            i++;
            if (i > YGAudioQueueBufferCount) i = 0;
        } else {
            memcpy(audioBuffer[i]->mAudioData, data.bytes, data.length);
            audioBuffer[i]->mAudioDataByteSize = (UInt32)data.length;
            AudioQueueEnqueueBuffer(audioQueue, audioBuffer[i], 0, NULL);
            break;
        }
    }
}

static void YGAudioQueueOutputCallback(void *inUserData, AudioQueueRef outAQ, AudioQueueBufferRef outBuffer) {
    YGAudioOutputQueue *audioOutput = (__bridge YGAudioOutputQueue *)(inUserData);
    [audioOutput handleQueueOutput:outBuffer];
}

-(void)handleQueueOutput:(AudioQueueBufferRef) outBuffer {
    for (int i = 0; i < YGAudioQueueBufferCount; ++i) {
        if (audioBuffer[i] == outBuffer) {
            audioBufferUsed[i] = false;
        }
    }
}

static void YGAudioQueuePropertyCallback(void *inUserData, AudioQueueRef inAQ, AudioQueuePropertyID inID) {
    
}

-(void)audioQueueWithFormat:(AudioStreamBasicDescription)format withBufferSize:(UInt32)bufferSize withCookie:(NSData *)cookie  {
    //create audio queue
    OSStatus status = AudioQueueNewOutput(&format, YGAudioQueueOutputCallback, (__bridge void * _Nullable)(self), NULL, NULL, 0, &audioQueue);
    if (status != noErr) {
        audioQueue = NULL;
        return;
    }
    
    //property listen running
    status = AudioQueueAddPropertyListener(audioQueue, kAudioQueueProperty_IsRunning, YGAudioQueuePropertyCallback, (__bridge void * _Nullable)(self));
    if (status != noErr) {
        AudioQueueDispose(audioQueue, true);
        audioQueue = NULL;
        return;
    }
    
    //set magic cookie
    if (cookie) {
        AudioQueueSetProperty(audioQueue, kAudioQueueProperty_MagicCookie, [cookie bytes], (UInt32)[cookie length]);
    }
    
    //crate audio buffers
    for (int i = 0; i < YGAudioQueueBufferCount; ++i) {
        status = AudioQueueAllocateBuffer(audioQueue, bufferSize, &audioBuffer[i]);
        if (status != noErr) {
            AudioQueueDispose(audioQueue, true);
            audioQueue = NULL;
            break;
        }
    }
}

@end
