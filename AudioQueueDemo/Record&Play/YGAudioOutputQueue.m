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
    NSMutableData                *audioData;
    NSMutableArray               *audioPackets;
    NSLock                       *syncLock;
}
@end

@implementation YGAudioOutputQueue

-(void)playWithPacket:(NSData *)data withDescription:(AudioStreamPacketDescription)description {
    NSLog(@"----datalen:%lu",(unsigned long)data.length);
    
    [syncLock lock];
    NSLog(@"datadatadata");
    //buffer not finished
    YGAudioPacket *packet = [[YGAudioPacket alloc]initWithData:data withDescription:description];
    if (audioBufferSize - audioBufferCurrentSize >= data.length) {
        audioBufferCurrentSize += data.length;
        [audioPackets addObject:packet];
        [syncLock unlock];
        return;
    }
    
    //find buffer
    while (true) {
        if (!audioBufferUsed[audioBufferIndex]) {
            audioBufferUsed[audioBufferIndex] = true;
            break;
        }
        audioBufferIndex++;
        if (audioBufferIndex >= kAudioQueueBufferCount) {
            audioBufferIndex = 0;
        }
    }
    
    //buffer finished
    AudioStreamPacketDescription *descriptions = (AudioStreamPacketDescription *)malloc(sizeof(AudioStreamPacketDescription) * audioPackets.count);
    for (int i = 0; i < audioPackets.count; i++) {
        YGAudioPacket *packet = audioPackets[i];
        AudioStreamPacketDescription des = packet.packetDescription;
        des.mStartOffset = audioData.length;
        descriptions[i] = packet.packetDescription;
        [audioData appendData:packet.data];
    }
   
    NSLog(@"index:%d size:%lu",audioBufferIndex,(unsigned long)audioData.length);
    
    audioBuffer[audioBufferIndex]->mAudioDataByteSize = (UInt32)audioData.length;
    memcmp(audioBuffer[audioBufferIndex]->mAudioData, audioData.bytes, audioData.length);
    OSStatus status = AudioQueueEnqueueBuffer(audioQueue, audioBuffer[audioBufferIndex], (UInt32)audioPackets.count, descriptions);
    if (status != noErr) {
        NSLog(@"AudioQueueEnqueueBufferFailed");
        [syncLock unlock];
        return;
    }
    audioData = [[NSMutableData alloc]init];
    [audioPackets removeAllObjects];
    audioBufferCurrentSize = 0;
    [syncLock unlock];
}
/*
-(void)playWithPacket:(NSData *)data withDescription:(AudioStreamPacketDescription)description {
    [syncLock lock];
    //buffer fill finished
    if (audioBufferSize - audioBufferFillSize < data.length) {
        NSLog(@"Finish a packet %d index:%d packetnum:%d",audioBufferFillSize, audioBufferIndex,audioBufferPacketNum);
        AudioStreamPacketDescription *packetStream = (AudioStreamPacketDescription *)malloc(audioBufferPacketNum * sizeof(AudioStreamPacketDescription));
        if (packetStream != NULL) {
            for (int i = 0; i < audioBufferPacketNum; i++) {
                packetStream[i] = audioStreamPacketDesc[i];
            }
        }
       
        OSStatus status = AudioQueueEnqueueBuffer(audioQueue, audioBuffer[audioBufferIndex], audioBufferPacketNum, packetStream);
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

    NSLog(@"offset:%d length:%lu",audioBufferFillSize,(unsigned long)data.length);
    audioStreamPacketDesc[audioBufferPacketNum] = description;
    audioStreamPacketDesc[audioBufferPacketNum].mStartOffset = audioBufferFillSize;
    
    audioBufferFillSize += data.length;
    audioBufferPacketNum += 1;
    
    [syncLock unlock];
}
*/

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

@implementation YGAudioPacket
 -(instancetype)initWithData:(NSData *)data withDescription:(AudioStreamPacketDescription)description {
     if (self = [super init]) {
         self.data = data;
         self.packetDescription = description;
     }
     return self;
 }
                                 
@end
