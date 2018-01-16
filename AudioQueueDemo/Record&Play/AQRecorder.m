//
//  AQRecorder.m
//  AudioQueueDemo
//
//  Created by wangyaoguo on 2018/1/16.
//  Copyright © 2018年 lianluo.com. All rights reserved.
//

#import "AQRecorder.h"
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
    BOOL                        recording;
} RecordState;

@interface AQRecorder() {
    RecordState recordState;
    CFURLRef    fileURL;
}
@end

@implementation AQRecorder

-(instancetype)init {
    if (self = [super init]) {
        [self setAudio];
    }
    return self;
}

-(AudioStreamBasicDescription *)setFormat  {
    AudioStreamBasicDescription *format = &recordState.format;
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
    
    recordState.currentPacket= 0;
    
    recordState.bufferSize = 2048;
    
    //create audio queue
    AudioQueueNewInput([self setFormat], HandleInputBuffer, &recordState, NULL, NULL, 0, &recordState.queue);
    
    //crate audio buffers
    for (int i = 0; i < kNumberBuffers; ++i) {
        AudioQueueAllocateBuffer(recordState.queue, recordState.bufferSize, &recordState.buffers[i]);
        AudioQueueEnqueueBuffer(recordState.queue, recordState.buffers[i], 0, NULL);
    }
        
    //crate audio file
    NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *filePath = [docPath stringByAppendingPathComponent:@"recording.caf"];
    fileURL = CFURLCreateWithString(kCFAllocatorDefault, (CFStringRef)filePath, NULL);
    AudioFileCreateWithURL(fileURL, kAudioFileCAFType, &recordState.format, kAudioFileFlags_EraseFile, &recordState.fileId);
}

-(void)startRecorder {
    AudioQueueStart(recordState.queue, NULL);
    recordState.recording = YES;
}

-(void)stopRecorder {
    if (recordState.recording) {
        AudioQueueStop(recordState.queue, true);
        AudioQueueDispose(recordState.queue, true);
    }
}

static void HandleInputBuffer(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer, const AudioTimeStamp *inStartTime, UInt32 inNumPackets, const AudioStreamPacketDescription *inPacketDesc) {
    
    RecordState *recordState = (RecordState *)inUserData;
    NSData *data = [NSData dataWithBytes:inBuffer->mAudioData length:inBuffer->mAudioDataByteSize];
    NSLog(@"datasize:%lu",data.length);
    if (inNumPackets > 0) {
        AudioFileWritePackets(recordState->fileId, false, inBuffer->mAudioDataByteSize, inPacketDesc, recordState->currentPacket, &inNumPackets, inBuffer->mAudioData);
        recordState->currentPacket += inNumPackets;
    }
    
    if (recordState->recording) {
        AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
    }
}

@end
