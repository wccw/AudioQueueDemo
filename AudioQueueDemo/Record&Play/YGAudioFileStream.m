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
    UInt32                      maxPacketSize;
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
    //audioFileTypeId = kAudioFileAAC_ADTSType;
    OSStatus status = AudioFileStreamOpen((__bridge void * _Nullable)(self),
                                          YGAudioFileStreamPropertyListenerProc,
                                          YGAudioFileStreamPacketsProc,
                                          0,
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
    
    switch (inPropertyID) {
        case kAudioFileStreamProperty_ReadyToProducePackets: {
            if (self.delegate && [self.delegate respondsToSelector:@selector(audioStreamReadyProducePacket)]) {
                [self.delegate audioStreamReadyProducePacket];
            }
            break;
        }
            
        case kAudioFileStreamProperty_MagicCookieData: {
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
            _magicCookie = [NSData dataWithBytes:cookData length:cookieSize];
            free(cookData);
        }
            
        case kAudioFileStreamProperty_DataFormat: {
            UInt32 propertySize = sizeof(_format);
            OSStatus status = AudioFileStreamGetProperty(audioFileStreamId, kAudioFileStreamProperty_DataFormat, &propertySize, &_format);
            if (status != noErr) {
                NSLog(@"AudioFileDataFormatError");
                return;
            }
            [self calculateBufferSize];
            break;
        }
        case kAudioFileStreamProperty_PacketSizeUpperBound: {
            UInt32 propertySize = sizeof(maxPacketSize);
            OSStatus status = AudioFileStreamGetProperty(audioFileStreamId, kAudioFileStreamProperty_PacketSizeUpperBound, &propertySize, &maxPacketSize);
            if (status != noErr || maxPacketSize == 0) {
                status = AudioFileStreamGetProperty(audioFileStreamId, kAudioFileStreamProperty_MaximumPacketSize, &propertySize, &maxPacketSize);
                if (status != noErr) {
                    NSLog(@"AudioFileMaxPacketSizeError");
                }
            } else {
                NSLog(@"AudioFileUpperBoundSizeError");
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
        NSLog(@"AudioFileStreamPacketsEmpty");
        return;
    }
    
    //如果为空，按照CBR处理
    if (inPacketDescriptions == NULL) {
        //NSLog(@"AudioStremPacketDescriptionNull");
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
    
    NSData *dstData = [NSData dataWithBytes:inInputData length:inNumberBytes];
    if (self.delegate && [self.delegate respondsToSelector:@selector(audioStreamPacketData:withDescriptions:)]) {
        [self.delegate audioStreamPacketData:dstData withDescriptions:inPacketDescriptions];
    }
 
    /*
    for (int i = 0; i < inNumberPackets; i++) {
        SInt64 startOffset = inPacketDescriptions[i].mStartOffset;
        UInt32 dataByteSize = inPacketDescriptions[i].mDataByteSize;
        //NSLog(@"bytes:%u packets:%d packetSize:%d offset:%lld",(unsigned int)inNumberBytes,inNumberPackets,dataByteSize,startOffset);
   
        NSData *dstData = [NSData dataWithBytes:inInputData + startOffset length:dataByteSize];
        if (self.delegate && [self.delegate respondsToSelector:@selector(audioStreamPacketData:withDescription:)]) {
            [self.delegate audioStreamPacketData:dstData withDescription:inPacketDescriptions[i]];
        }
    }
     */
}

-(void)calculateBufferSize {
    static const int maxBufferSize = 0x10000;
    static const int minBufferSize = 0x4000;
    if (_format.mFramesPerPacket) {
        Float64 numPacketsForTime = _format.mSampleRate / _format.mFramesPerPacket * kBufferDurationSeconds;
        _bufferSize = numPacketsForTime * maxPacketSize;
    } else {
        _bufferSize = maxBufferSize > maxPacketSize ? maxBufferSize : maxPacketSize;
    }
    
    if (_bufferSize > maxBufferSize && _bufferSize > maxPacketSize) {
        _bufferSize = maxBufferSize;
    } else {
        if (_bufferSize < minBufferSize) {
            _bufferSize = minBufferSize;
        }
    }
}

@end

 
