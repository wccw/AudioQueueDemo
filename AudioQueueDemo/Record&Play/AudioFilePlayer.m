//
//  AudioFilePlayer.m
//  AudioQueueDemo
//
//  Created by wangyaoguo on 2018/1/18.
//  Copyright © 2018年 lianluo.com. All rights reserved.
//

#import "AudioFilePlayer.h"
#import <AudioToolbox/AudioToolbox.h>

#define KBufferDurationSeconds .5
#define KBufferNumbers 3

@interface AudioFilePlayer() {
    AudioQueueRef               audioQueue;
    AudioQueueBufferRef         audioBuffers[KBufferNumbers];
    AudioStreamBasicDescription format;
    AudioFileID                 audioFieldID;
    UInt32                      maxPacketSize;
    UInt32                      numPacketsRead;
    UInt32                      bufferSize;
    SInt64                      currentPacket;
    BOOL                        isFormatVBR;
}
@end

@implementation AudioFilePlayer

-(instancetype)initWithPath:(NSString *)filePath {
    if (self = [super init]) {
        if([self openAudioFile:filePath]) {
            [self getAudioFileProperty];
            [self createAudioQueue];
        }
    }
    return self;
}

//open file
-(BOOL)openAudioFile:(NSString *)filePath {
    CFURLRef fileUrl = CFURLCreateWithString(kCFAllocatorDefault, (CFStringRef)filePath, NULL);
    if (!fileUrl) {
        NSLog(@"fileurl error");
        return false;
    }
    OSStatus status = AudioFileOpenURL(fileUrl, kAudioFileReadPermission, 0, &audioFieldID);
    if (status != noErr) {
        NSLog(@"open audio file fail");
        return false;
    }
    return true;
}

//audio queue
-(void)createAudioQueue {
    
    AudioQueueNewOutput(&format, AQAudioQueueOutputCallback, (__bridge void * _Nullable)(self), NULL, NULL, 0, &audioQueue);
    
    for (int i = 0; i < KBufferNumbers; ++i) {
        AudioQueueAllocateBufferWithPacketDescriptions(audioQueue, bufferSize, isFormatVBR ? numPacketsRead : 0, &audioBuffers[i]);
    }
    
    AudioQueueSetParameter(audioQueue, kAudioQueueParam_Volume, 1.0);
}

//output callback
static void AQAudioQueueOutputCallback(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer) {
    AudioFilePlayer *aqPlayer = (__bridge AudioFilePlayer *)inUserData;
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
        AudioFileClose(audioFieldID);
    }
}

//audio file property
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

//buffer size
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


@end
