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
    UInt32 bufferSize;
    OSStatus status;
}
@end

@implementation AQLocalFilePlay

-(instancetype)init {
    if (self = [super init]) {
        [self openAudioFile];
    }
    return self;
}

-(void)openAudioFile {
    NSString *filePath = [[NSBundle mainBundle]pathForResource:@"MP3Sample" ofType:@"mp3"];
    CFURLRef fileUrl = CFURLCreateWithString(kCFAllocatorDefault, (CFStringRef)filePath, NULL);
    if (!fileUrl) {
        return;
    }
    status = AudioFileOpenURL(fileUrl, kAudioFileReadPermission, 0, &audioFieldID);
    if (status != noErr) {
        return;
    }
    [self getAudioFileProperty];
    [self createAudioQueue];
}

-(void)getAudioFileProperty {
    
    bufferSize = 5000;
    
    //format
    UInt32 size = sizeof(format);
    status = AudioFileGetProperty(audioFieldID, kAudioFilePropertyDataFormat, &size, &format);
    if (status != noErr) {
        return;
    }
    
    //maxPacketSize
    status = AudioFileGetProperty(audioFieldID, kAudioFilePropertyPacketSizeUpperBound, &size, &maxPacketSize);
    if (status != noErr) {
        return;
    }
    
   
    
}

-(void)createAudioQueue {

    AudioQueueNewOutput(&format, AQAudioQueueOutputCallback, (__bridge void * _Nullable)(self), NULL, NULL, 0, &audioQueue);
    
    for (int i = 0; i < KBufferNumbers; ++i) {
        AudioQueueAllocateBuffer(audioQueue, bufferSize, &audioBuffers[i]);
    }
}

static void AQAudioQueueOutputCallback(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inCompleteAQBuffer) {
    
}



@end
