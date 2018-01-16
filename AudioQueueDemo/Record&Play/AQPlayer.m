//
//  AQPlayer.m
//  AudioQueueDemo
//
//  Created by wangyaoguo on 2018/1/12.
//  Copyright © 2018年 lianluo.com. All rights reserved.
//

#import "AQPlayer.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
static const int kNumberBuffers = 3;

typedef struct {
    AudioQueueRef               queue;
    AudioQueueBufferRef         buffers[kNumberBuffers];
    AudioStreamBasicDescription format;
    AudioFileID                 fileId;
    SInt64                      currentPacket;
    UInt32                      bufferSize;
    BOOL                        playing;
} PlayState;

@interface AQPlayer() {
    PlayState playState;
    CFURLRef  fileURL;
}
@end

@implementation AQPlayer

-(instancetype)init {
    if (self = [super init]) {
        [self setAudio];
    }
    return self;
}

-(AudioStreamBasicDescription *)setFormat {
    AudioStreamBasicDescription *format = &playState.format;
    format->mFormatID = kAudioFormatLinearPCM;
    format->mSampleRate = 44100.0;
    format->mFramesPerPacket = 1;
    format->mChannelsPerFrame = 1;
    format->mBitsPerChannel = 16;
    format->mBytesPerFrame = format->mBitsPerChannel * format->mChannelsPerFrame / 8;
    format->mBytesPerPacket = format->mFramesPerPacket * format->mBytesPerFrame;
    format->mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    return format;
}

-(void)setAudio {
    playState.currentPacket = 0;
    playState.bufferSize = 2048;
    NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *filePath = [docPath stringByAppendingPathComponent:@"recording.caf"];
    fileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)filePath, kCFURLPOSIXPathStyle, false);
    if (!fileURL) {
        NSLog(@"can't parse fiel path");
        return;
    }
    
    AudioFileOpenURL(fileURL, kAudioFileReadPermission, kAudioFileAIFFType, &playState.fileId);
    
    AudioQueueNewOutput([self setFormat], HandleOutputBuffer , &playState, NULL, NULL, 0, &playState.queue);
    
    for (int i = 0; i < kNumberBuffers; ++i) {
        AudioQueueAllocateBuffer(playState.queue, playState.bufferSize, &playState.buffers[i]);
        HandleOutputBuffer(&playState, playState.queue, playState.buffers[i]);
    }
}

static void HandleOutputBuffer(void *inUserData, AudioQueueRef outAQ, AudioQueueBufferRef outBuffer) {
    PlayState *playerState = (PlayState *)inUserData;
    if (!playerState->playing) {
        NSLog(@"not start playing");
        return;
    }
    
    AudioStreamPacketDescription *packetDescs = NULL;
    UInt32 bytesRead;
    UInt32 numPackets = 1024;
    AudioFileReadPacketData(playerState->fileId, false, &bytesRead, packetDescs, playerState->currentPacket, &numPackets, outBuffer->mAudioData);
    if (numPackets) {
        outBuffer->mAudioDataByteSize = bytesRead;
        AudioQueueEnqueueBuffer(playerState->queue, outBuffer, 0, packetDescs);
        playerState->currentPacket += numPackets;
    }
}

-(void)startPlay{
    AudioQueueStart(playState.queue, NULL);
    playState.playing = true;
}

-(void)stopPlay {
    AudioQueueStop(playState.queue, true);
    AudioQueueDispose(playState.queue, true);
    playState.playing = false;
}


@end
