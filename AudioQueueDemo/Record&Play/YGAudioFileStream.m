//
//  YGAudioFileStream.m
//  AudioQueueDemo
//
//  Created by wangyaoguo on 2018/1/19.
//  Copyright © 2018年 lianluo.com. All rights reserved.
//

#import "YGAudioFileStream.h"
#import "YGAudioOutputQueue.h"

const float kBufferDurationSeconds = 0.3;

@interface YGAudioFileStream() {
    AudioFileStreamID           audioFileStreamId;
    AudioFileTypeID             audioFileTypeId;
    AudioStreamBasicDescription audioFormat;
    
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
    audioFileTypeId = kAudioFileM4AType;
    OSStatus status = AudioFileStreamOpen((__bridge void * _Nullable)(self),
                                          YGAudioFileStreamPropertyListenerProc,
                                          YGAudioFileStreamPacketsProc,
                                          audioFileTypeId,
                                          &audioFileStreamId);
    if (status != noErr) {
        NSLog(@"AudioFileStreamOpenFailed");
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
    NSLog(@"began parse data");
    OSStatus status = AudioFileStreamParseBytes(audioFileStreamId, (UInt32)data.length, data.bytes, 0);
    if (status != noErr) {
        NSLog(@"AudioFileStreamParseFailed");
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
    NSLog(@"parse property");
    switch (inPropertyID) {
        case kAudioFileStreamProperty_ReadyToProducePackets: {
            UInt32 cookieSize;
            OSStatus status = AudioFileStreamGetPropertyInfo(audioFileStreamId, kAudioFileStreamProperty_MagicCookieData, &cookieSize, NULL);
            if (status != noErr) {
                NSLog(@"AudioFileGetMagicCookieInfoDataError");
                return;
            }
            
            void *cookData = malloc(cookieSize);
            status = AudioFileStreamGetProperty(audioFileStreamId, kAudioFileStreamProperty_MagicCookieData, &cookieSize, cookData);
            if (status != noErr) {
                NSLog(@"AudioFileGetMagicCookieDataError");
                return;
            }
            
            cookieData = [NSData dataWithBytes:cookData length:cookieSize];
            free(cookData);
            if (self.delegate && [self.delegate respondsToSelector:@selector(audioStream:withFormat:withSize:withCookie:)]) {
                [self.delegate audioStream:self withFormat:audioFormat withSize:bufferSize withCookie:cookieData];
            }
            break;
        }
        case kAudioFileStreamProperty_DataFormat: {
            UInt32 propertySize = sizeof(audioFormat);
            AudioFileStreamGetProperty(audioFileStreamId, kAudioFileStreamProperty_DataFormat, &propertySize, &audioFormat);
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
    NSLog(@"parse packet");
    if (inNumberBytes == 0 || inNumberPackets == 0) {
        NSLog(@"AudioFileStreamPacketsEmpty");
        return;
    }
    
    //
    if (inPacketDescriptions == NULL) {
        NSLog(@"packetDescription is null");
        UInt32 packetSize = inNumberBytes / inNumberPackets;
        AudioStreamPacketDescription *descriptions = (AudioStreamPacketDescription *)malloc(sizeof(AudioStreamPacketDescription) * inNumberPackets);
        for (int i = 0; i < inNumberPackets; i++) {
            UInt32 packetOffset = packetSize * i;
            descriptions[i].mStartOffset = packetOffset;
            descriptions[i].mVariableFramesInPacket = 0;
            if (i == inNumberPackets - 1) {
                descriptions[i].mDataByteSize = inNumberBytes - packetOffset;
            } else {
                descriptions[i].mDataByteSize = packetSize;
            }
        }
        inPacketDescriptions = descriptions;
    }
    
    for (int i = 0; i < inNumberPackets; ++i) {
        SInt64 startOffset = inPacketDescriptions[i].mStartOffset;
        UInt32 dataByteSize = inPacketDescriptions[i].mDataByteSize;
        NSData *dstData = [NSData dataWithBytes:inInputData + startOffset length:dataByteSize];
        if (self.delegate && [self.delegate respondsToSelector:@selector(audioStream:audioData:withPacketDes:)]) {
            [self.delegate audioStream:self audioData:dstData withPacketDes:inPacketDescriptions[i]];
        }
    }
}

-(void)calculateBufferSize {
    static const int maxBufferSize = 0x10000;
    static const int minBufferSize = 0x4000;
    if (audioFormat.mFramesPerPacket) {
        Float64 numPacketsForTime = audioFormat.mSampleRate / audioFormat.mFramesPerPacket * kBufferDurationSeconds;
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
