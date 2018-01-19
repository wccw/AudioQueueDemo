//
//  YGAudioFileStream.m
//  AudioQueueDemo
//
//  Created by wangyaoguo on 2018/1/19.
//  Copyright © 2018年 lianluo.com. All rights reserved.
//

#import "YGAudioFileStream.h"
#import <AudioToolbox/AudioToolbox.h>
@interface YGAudioFileStream() {
    
    AudioFileStreamID           audioFileStreamId;
    AudioFileTypeID             audioFileTypeId;
    AudioStreamBasicDescription foramt;
    
    BOOL                        readyToProducePacket;
    BOOL                        discontinuity;
    UInt32                      duration;
    UInt32                      bitRate;
    UInt32                      maxPacketSize;
    UInt64                      dataByteCount;
}
@end

@implementation YGAudioFileStream

-(instancetype)init {
    if (self = [super init]) {
        
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
    if (readyToProducePacket && duration == 0) {
        return false;
    }
    OSStatus status = AudioFileStreamParseBytes(audioFileStreamId,
                                                (UInt32)data.length,
                                                data.bytes,
                                                discontinuity ? kAudioFileStreamParseFlag_Discontinuity : 0);
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
            //get cookie size
            UInt32 cookieSize;
            AudioFileStreamGetPropertyInfo(audioFileStreamId, kAudioFileStreamProperty_MagicCookieData, &cookieSize, NULL);
            
            //get cookie data
            void *cookData = malloc(cookieSize);
            AudioFileStreamGetProperty(audioFileStreamId, kAudioFileStreamProperty_MagicCookieData, &cookieSize, cookData);
            
            //set cookie on queue
            AudioQueueSetProperty(<#AudioQueueRef  _Nonnull inAQ#>, <#AudioQueuePropertyID inID#>, <#const void * _Nonnull inData#>, <#UInt32 inDataSize#>)
            break;
        }
        case kAudioFileStreamProperty_DataFormat: {
            UInt32 propertySize = sizeof(foramt);
            AudioFileStreamGetProperty(audioFileStreamId, kAudioFileStreamProperty_DataFormat, &propertySize, &foramt);
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
        case kAudioFileStreamProperty_BitRate: {
            UInt32 propertySize = sizeof(bitRate);
            AudioFileStreamGetProperty(audioFileStreamId, kAudioFileStreamProperty_BitRate, &propertySize, &bitRate);
            break;
        }
        case kAudioFileStreamProperty_AudioDataByteCount: {
            UInt32 propertySize = sizeof(dataByteCount);
            AudioFileStreamGetProperty(audioFileStreamId, kAudioFileStreamProperty_AudioDataByteCount, &propertySize, &dataByteCount);
        }
        
 
        default:
            break;
    }
}



-(void)handleAudioFileStreamPacketsProcNumBytes:(UInt32)inNumberBytes
                                     numPackets:(UInt32)inNumberPackets
                                      inputData:(const void *)inInputData
                                      packetDes:(AudioStreamPacketDescription *)inPacketDescriptions {
    
}

@end
