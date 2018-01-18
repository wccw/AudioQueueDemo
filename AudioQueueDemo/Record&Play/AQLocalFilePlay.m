//
//  AQLocalFilePlay.m
//  AudioQueueDemo
//
//  Created by wangyaoguo on 2018/1/17.
//  Copyright © 2018年 lianluo.com. All rights reserved.
//

#import "AQLocalFilePlay.h"
#import <AudioToolbox/AudioToolbox.h>
#define KBufferDurationSeconds .5
#define KBufferNumbers 3

@interface AQLocalFilePlay() {
    AudioQueueRef               audioQueue;
    AudioQueueBufferRef         audioBuffers[KBufferNumbers];
    AudioStreamBasicDescription format;
    AudioFileID audioFieldID;
    UInt32 maxPacketSize;
    UInt32 numPacketsRead;
    UInt32 bufferSize;
    SInt64 currentPacket;
    BOOL isFormatVBR;
}

@end

@implementation AQLocalFilePlay

-(instancetype)init {
    if (self = [super init]) {
        [self openAudioFile];
    }
    return self;
}

-(void)startPlay {
    for (int i = 0; i < KBufferNumbers; i ++) {
        AQAudioQueueOutputCallback((__bridge void *)(self), audioQueue, audioBuffers[i]);
    }
    AudioQueueStart(audioQueue, NULL);
}

-(void)stopPlay {
    AudioQueueStop(audioQueue, true);
}

-(void)openAudioFile {
    NSString *filePath = [[NSBundle mainBundle]pathForResource:@"AACSample" ofType:@"aac"];
    CFURLRef fileUrl = CFURLCreateWithString(kCFAllocatorDefault, (CFStringRef)filePath, NULL);
    if (!fileUrl) {
        return;
    }
    OSStatus status = AudioFileOpenURL(fileUrl, kAudioFileReadPermission, 0, &audioFieldID);
    if (status != noErr) {
        NSLog(@"open audio file fail");
        return;
    }
    [self getAudioFileProperty];
    [self createAudioQueue];
}

-(void)getAudioFileProperty {
    currentPacket = 0;
    
    //get audio format
    UInt32 size = sizeof(format);
    OSStatus status = AudioFileGetProperty(audioFieldID, kAudioFilePropertyDataFormat, &size, &format);
    if (status != noErr) {
        return;
    }
    
    //get maxPacketSize
    size = sizeof(maxPacketSize);
    status = AudioFileGetProperty(audioFieldID, kAudioFilePropertyPacketSizeUpperBound, &size, &maxPacketSize);
    if (status != noErr) {
        return;
    }
    
    //isVBR
    isFormatVBR = (format.mBytesPerPacket == 0 || format.mFramesPerPacket == 0);

    //calculate numPacketToRead bufferSize
    [self calculateBytesForTime:KBufferDurationSeconds withPacket:maxPacketSize];
    
    //If the file has a cookie , we shoule get it and set it on the audioqueue
    size = sizeof(UInt32);
    status = AudioFileGetPropertyInfo(audioFieldID, kAudioFilePropertyMagicCookieData, &size, NULL);
    if (!status && size) {
        char *cookie = malloc(size);
        AudioFileGetProperty(audioFieldID, kAudioFilePropertyMagicCookieData, &size, cookie);
        AudioQueueSetProperty(audioQueue, kAudioQueueProperty_MagicCookie, cookie, size);
        free(cookie);
    }
    
    //channel layout
    status = AudioFileGetPropertyInfo(audioFieldID, kAudioFilePropertyChannelLayout, &size, NULL);
    if (!status && size) {
        AudioChannelLayout *acl = (AudioChannelLayout *)malloc(size);
        AudioFileGetProperty(audioFieldID, kAudioFilePropertyChannelLayout, &size, acl);
        AudioQueueSetProperty(audioQueue, kAudioQueueProperty_ChannelLayout, acl, size);
    }
}

-(void)calculateBytesForTime:(Float64)inSeconds withPacket:(UInt32)maxPacketSize {
    static const int maxBufferSize = 0x10000;
    static const int minBufferSize = 0x4000;
    
    if (format.mFramesPerPacket) {
        Float64 numPacketsForTime = format.mSampleRate / format.mFramesPerPacket * inSeconds;
        bufferSize = numPacketsForTime * maxPacketSize;
    } else {
        bufferSize = maxBufferSize > maxPacketSize ? maxBufferSize : maxPacketSize;
    }
    if (bufferSize > maxBufferSize && bufferSize > maxPacketSize) {
        bufferSize = maxBufferSize;
    } else {
        if (bufferSize < minBufferSize) {
            bufferSize = minBufferSize;
        }
    }
    numPacketsRead = bufferSize / maxPacketSize;
    NSLog(@"maxPacketSize:%d bufferSize:%d",maxPacketSize, bufferSize);
}

-(void)createAudioQueue {

    AudioQueueNewOutput(&format, AQAudioQueueOutputCallback, (__bridge void * _Nullable)(self), NULL, NULL, 0, &audioQueue);
    
    for (int i = 0; i < KBufferNumbers; ++i) {
        AudioQueueAllocateBufferWithPacketDescriptions(audioQueue, bufferSize, isFormatVBR ? numPacketsRead : 0, &audioBuffers[i]);
    }
    
    AudioQueueSetParameter(audioQueue, kAudioQueueParam_Volume, 1.0);
}

static void AQAudioQueueOutputCallback(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer) {
    AQLocalFilePlay *aqPlayer = (__bridge AQLocalFilePlay *)inUserData;
    [aqPlayer processOutputCallback:inAQ withBuffer:inBuffer];
}

-(void)processOutputCallback:(AudioQueueRef) inAQ withBuffer:(AudioQueueBufferRef)inbuffer {
    UInt32 numBytes;
    UInt32 numPackets = numPacketsRead;
    OSStatus result = AudioFileReadPackets(audioFieldID, false, &numBytes, inbuffer->mPacketDescriptions, currentPacket, &numPackets, inbuffer->mAudioData);
    if (result) {
        NSLog(@"AudioFileRead failed:%d", result);
    }
    if (numPackets > 0) {
        inbuffer->mAudioDataByteSize = numBytes;
        inbuffer->mPacketDescriptionCount = numPackets;
        AudioQueueEnqueueBuffer(inAQ, inbuffer, 0, NULL);
        currentPacket = currentPacket + numPackets;
    } else {
        AudioQueueStop(audioQueue, true);
    }
}

@end
