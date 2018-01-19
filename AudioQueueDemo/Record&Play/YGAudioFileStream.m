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
    //kAudioFileStreamProperty_ReadyToProducePackets
    if (inPropertyID == kAudioFileStreamProperty_ReadyToProducePackets) {
        readyToProducePacket = YES;
    }
    //kAudioFileStreamProperty_DataFormat
    else if (inPropertyID == kAudioFileStreamProperty_DataFormat) {
        UInt32 formatSize = sizeof(foramt);
        AudioFileStreamGetProperty(audioFileStreamId, kAudioFileStreamProperty_DataFormat, &formatSize, &foramt);
    }
    //kAudioFileStreamProperty_BitRate
    else if (inPropertyID == kAudioFileStreamProperty_BitRate) {
        UInt32 bitRateSize = sizeof(bitRate);
        AudioFileStreamGetProperty(audioFileStreamId, kAudioFileStreamProperty_BitRate, &bitRateSize, &bitRate);
    }
    //kAudioFileStreamProperty_MaximumPacketSize
    else if (inPropertyID == kAudioFileStreamProperty_PacketSizeUpperBound) {
        UInt32 packetSize = sizeof(maxPacketSize);
        OSStatus status = AudioFileStreamGetProperty(audioFileStreamId, kAudioFileStreamProperty_MaximumPacketSize, &packetSize, &maxPacketSize);
        if (status != noErr || maxPacketSize == 0) {
            status = AudioFileStreamGetProperty(audioFileStreamId, kAudioFileStreamProperty_MaximumPacketSize, &packetSize, &maxPacketSize);
        }
    }
}



-(void)handleAudioFileStreamPacketsProcNumBytes:(UInt32)inNumberBytes
                                     numPackets:(UInt32)inNumberPackets
                                      inputData:(const void *)inInputData
                                      packetDes:(AudioStreamPacketDescription *)inPacketDescriptions {
    
}

@end
