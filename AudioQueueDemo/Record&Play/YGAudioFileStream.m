//
//  YGAudioFileStream.m
//  AudioQueueDemo
//
//  Created by wangyaoguo on 2018/1/19.
//  Copyright © 2018年 lianluo.com. All rights reserved.
//

#import "YGAudioFileStream.h"
#import <AudioToolbox/AudioToolbox.h>
#import "YGAudioOutputQueue.h"

const float kBufferDurationSeconds = 0.3;

@interface YGAudioFileStream() {
    AudioFileStreamID           audioFileStreamId;
    AudioFileTypeID             audioFileTypeId;
    AudioStreamBasicDescription format;
    
    NSData *                    cookieData;
    BOOL                        readyToProducePacket;
    UInt32                      maxPacketSize;
    UInt32                      bufferSize;
}

@property (nonatomic, assign) id<audioFileStreamDelegate> delegate;

@end

@implementation YGAudioFileStream

-(instancetype)initWithDelegate:(id<audioFileStreamDelegate>) delegate {
    if (self = [super init]) {
        self.delegate = delegate;
        [self open];
    }
    return self;
}


//Create a new audio file stream parser.
-(BOOL)open {
    OSStatus status = AudioFileStreamOpen((__bridge void * _Nullable)(self),
                                          YGAudioFileStreamPropertyListenerProc,
                                          YGAudioFileStreamPacketsProc,
                                          audioFileTypeId,
                                          &audioFileStreamId);
    if (status != noErr) {
        NSLog(@"AudioFileStreamOpen Failed");
        audioFileStreamId = NULL;
        return false;
    }
    return true;
}


-(void)close {
    AudioFileStreamClose(audioFileStreamId);
    audioFileStreamId = NULL;
}

//Parse data
-(BOOL)parseData:(NSData *)data {
    
    OSStatus status = AudioFileStreamParseBytes(audioFileStreamId, (UInt32)data.length, data.bytes, 0);
    if (status != noErr) {
        return false;
    }
    return true;
}

//Parse property callback
static void YGAudioFileStreamPropertyListenerProc(void *inClientData,
                                                  AudioFileStreamID inAudioFileStream,
                                                  AudioFileStreamPropertyID inPropertyID,
                                                  AudioFileStreamPropertyFlags *ioFlags) {
    YGAudioFileStream *audioFileStream = (__bridge YGAudioFileStream *)(inClientData);
    [audioFileStream handleAudioFileStreamPropertyListenerProc:inPropertyID];
}

//Parse packet callback
static void YGAudioFileStreamPacketsProc(void *inClientData,
                                         UInt32 inNumberBytes,
                                         UInt32 inNumberPackets,
                                         const void *inInputData,
                                         AudioStreamPacketDescription *inPacketDescriptions) {
    YGAudioFileStream *audioFileStream = (__bridge YGAudioFileStream *)(inClientData);
    [audioFileStream handleAudioFileStreamPacketsProcNumBytes:inNumberBytes numPackets:inNumberPackets inputData:inInputData packetDes:inPacketDescriptions];
}

-(void)handleAudioFileStreamPropertyListenerProc:(AudioFileStreamPropertyID)inPropertyID {
    
    switch (inPropertyID) {
        case kAudioFileStreamProperty_ReadyToProducePackets: {
            UInt32 cookieSize;
            AudioFileStreamGetPropertyInfo(audioFileStreamId, kAudioFileStreamProperty_MagicCookieData, &cookieSize, NULL);
            
            void *cookData = malloc(cookieSize);
            AudioFileStreamGetProperty(audioFileStreamId, kAudioFileStreamProperty_MagicCookieData, &cookieSize, cookData);
            cookieData = [NSData dataWithBytes:cookData length:cookieSize];
            free(cookData);
            if (self.delegate && [self.delegate respondsToSelector:@selector(audioFileStream:readyToProducePackets:)]) {
                [self.delegate audioFileStream:self readyToProducePackets:true];
            }
            break;
        }
        case kAudioFileStreamProperty_DataFormat: {
            UInt32 propertySize = sizeof(format);
            AudioFileStreamGetProperty(audioFileStreamId, kAudioFileStreamProperty_DataFormat, &propertySize, &format);
            [self calculateBufferSize];
            break;
        }
        case kAudioFileStreamProperty_PacketSizeUpperBound: {
            UInt32 propertySize = sizeof(maxPacketSize);
            OSStatus status = AudioFileStreamGetProperty(audioFileStreamId, kAudioFileStreamProperty_MaximumPacketSize, &propertySize, &maxPacketSize);
            if (status != noErr || maxPacketSize == 0) {
                status = AudioFileStreamGetProperty(audioFileStreamId, kAudioFileStreamProperty_MaximumPacketSize, &propertySize, &maxPacketSize);
            }
            break;
        }
        default:
            break;
    }
}

-(void)handleAudioFileStreamPacketsProcNumBytes:(UInt32)inNumberBytes
                                     numPackets:(UInt32)inNumberPackets
                                      inputData:(const void *)inInputData
                                      packetDes:(AudioStreamPacketDescription *)inPacketDescriptions {
    if (inNumberBytes == 0 || inNumberPackets == 0) {
        return;
    }
    
    for (int i = 0; i < inNumberPackets; ++i) {
        int packetLen = inNumberBytes / inNumberPackets;
        void *dst = malloc(packetLen);
        memcpy(dst, inInputData, i * packetLen);
        NSData *dstData = [NSData dataWithBytes:dst length:packetLen];
        free(dst);
        if (self.delegate && [self.delegate respondsToSelector:@selector(audioFileStream:audioData:)]) {
            [self.delegate audioFileStream:self audioData:dstData];
        }
    }
}

-(void)calculateBufferSize {
    static const int maxBufferSize = 0x10000;
    static const int minBufferSize = 0x4000;
    if (format.mFramesPerPacket) {
        Float64 numPacketsForTime = format.mSampleRate / format.mFramesPerPacket * kBufferDurationSeconds;
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
}

@end
