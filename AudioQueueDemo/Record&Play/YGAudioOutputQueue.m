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
    UInt32                       audioBufferFillSize;
    UInt32                       audioBufferIndex;
    UInt32                       audioBufferPacketNum;
    AudioStreamPacketDescription audioStreamPacketDesc[10];
    NSLock                       *syncLock;
}
@end

@implementation YGAudioOutputQueue

-(void)playWithPacket:(NSData *)data withDescription:(AudioStreamPacketDescription)description {
    
    [syncLock lock];
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

    description.mStartOffset = audioBufferFillSize;
    NSLog(@"fileSize:%d",audioBufferFillSize);
    audioStreamPacketDesc[audioBufferPacketNum] = description;
    //audioStreamPacketDesc[audioBufferPacketNum].mStartOffset = audioBufferFillSize;
    
    audioBufferFillSize += data.length;
    audioBufferPacketNum += 1;
    
    [syncLock unlock];
}


-(instancetype)initWithFormat:(AudioStreamBasicDescription)format withBufferSize:(UInt32)size withMagicCookie:(NSData *)cookie {
    if (self = [super init]) {
        syncLock = [[NSLock alloc]init];
        audioBufferSize = 3000;
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
    NSData *packetData = packet.packetData;
    
    if (audioBufferSize - audioBufferFillNum < packetData.length) {
        NSLog(@"-----%d",audioBuffer[audioBufferIndex]->mAudioDataByteSize);
        OSStatus status = AudioQueueEnqueueBuffer(audioQueue, audioBuffer[audioBufferIndex], audioBufferPacketNum, audioStreamPacketDesc);
        if (status != noErr) {
            NSLog(@"AudioQueueEnqueueBufferFailed");
            return;
        }
        audioBufferPacketNum = 0;
        audioBufferFillNum = 0;
        
        while (true) {
            if (!audioBufferUsed[audioBufferIndex]) {
                audioBufferUsed[audioBufferIndex] = true;
                break;
            }
        }
    }
    
    AudioQueueBufferRef currentBuffer = audioBuffer[audioBufferIndex];
    currentBuffer->mAudioDataByteSize = audioBufferFillNum + (UInt32)packetData.length;
    memcmp(currentBuffer->mAudioData + audioBufferFillNum, packetData.bytes, packetData.length);
    audioStreamPacketDesc[audioBufferPacketNum] = packet.packetDescription;
    audioStreamPacketDesc[audioBufferPacketNum].mStartOffset = audioBufferFillNum;
    audioBufferFillNum += packetData.length;
    audioBufferPacketNum += 1;
    */
    /*
    AudioStreamPacketDescription packetDes = packet.packetDescription;
    NSData *packetData = packet.packetData;
    
    if (audioBufferSize - audioData.length >= packetData.length) {
        [audioData appendData:packetData];
        [audioPackets addObject:packet];
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
        OSStatus status = AudioQueueEnqueueBuffer(audioQueue, audioBuffer[i], (UInt32)audioPackets.count, NULL);
        if (status != noErr) {
            NSLog(@"AudioQueueEnqueueBufferFailed");
            return;
        }
        audioData = [[NSMutableData alloc]init];
        [audioPackets removeAllObjects];
    }
*/


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
            audioBufferUsed[i] = false;
        }
    }
}


@end
