//
//  YGAudioUnit.m
//  AudioQueueDemo
//
//  Created by wangyaoguo on 2018/2/1.
//  Copyright © 2018年 lianluo.com. All rights reserved.
//

#import "YGAudioUnit.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface YGAudioUnit() {
    AudioUnit IOAudioUnit;
}
@end

@implementation YGAudioUnit

-(instancetype)init {
    if (self = [super init]) {
        [self setSession];
        [self setUnit];
    }
    return self;
}

-(void)start {
    OSStatus status = AudioOutputUnitStart(IOAudioUnit);
    if (status != noErr) {
        NSLog(@"audio output unit start fail");
    }
}

-(void)stop {
    OSStatus stop = AudioOutputUnitStop(IOAudioUnit);
    if (stop != noErr) {
        NSLog(@"audio output unit stop fail");
    }
}



static OSStatus MyAURenderCallBack(void                       *inRefCon,
                                   AudioUnitRenderActionFlags *ioActionFlags,
                                   const AudioTimeStamp       *inTimeStamp,
                                   UInt32                     inBusNumber,
                                   UInt32                     inNumberFrames,
                                   AudioBufferList            *ioData) {
    YGAudioUnit *audioUnit = (__bridge YGAudioUnit *)(inRefCon);
    return 0;
}

-(void)setSession {
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    NSError *error = nil;
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    if (error) {
        NSLog(@"set category fail");
        return;
    }
    
    NSTimeInterval bufferDuration = .005;
    [session setPreferredIOBufferDuration:bufferDuration error:&error];
    if (error) {
        NSLog(@"set session buffer duration fail");
        return;
    }
    [session setActive:YES error:nil];
}

-(void)setUnit {
    
    //create a new instance of Remote IO
    AudioComponentDescription IOUnitDescription;
    IOUnitDescription.componentType = kAudioUnitType_Output;
    IOUnitDescription.componentSubType = kAudioUnitSubType_RemoteIO;
    IOUnitDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    IOUnitDescription.componentFlags = 0;
    IOUnitDescription.componentFlagsMask = 0;
    
    AudioComponent IOUnitComponent = AudioComponentFindNext(NULL, &IOUnitDescription);
    OSStatus status = AudioComponentInstanceNew(IOUnitComponent, &IOAudioUnit);
    if (status != noErr) {
        NSLog(@"set audio component instance fail");
        return;
    }

    //enable io for input
    UInt32 one = 1;
    status = AudioUnitSetProperty(IOAudioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &one, sizeof(one));
    if (status != noErr) {
        NSLog(@"set audio unit property enable io fail");
        return;
    }
    
    //enable io for output
    status = AudioUnitSetProperty(IOAudioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, 0, &one, sizeof(one));
    if (status != noErr) {
        NSLog(@"set audio unit property enable io fail");
        return;
    }
    
    //audio format
    AudioStreamBasicDescription desc = {0};
    desc.mSampleRate = 44100;
    desc.mFormatID = kAudioFormatLinearPCM;
    desc.mFormatFlags = kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked;
    desc.mFramesPerPacket = 1;
    desc.mChannelsPerFrame = 1;
    desc.mBytesPerFrame = desc.mBytesPerPacket = 0;
    desc.mReserved = 0;
    
    status = AudioUnitSetProperty(IOAudioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &desc, sizeof(desc));
    if (status != noErr) {
        NSLog(@"set audio unit property format fail");
        return;
    }
    
    status = AudioUnitSetProperty(IOAudioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &desc, sizeof(desc));
    if (status != noErr) {
        NSLog(@"set audio unit property format fail");
        return;
    }
    
    UInt32 maxFramesPerSlice = 4096;
    status = AudioUnitSetProperty(IOAudioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFramesPerSlice, sizeof(UInt32));
    if (status != noErr) {
        NSLog(@"set max num frames per slice fail");
        return;
    }
    
    status = AudioUnitSetProperty(IOAudioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &MyAURenderCallBack, sizeof(MyAURenderCallBack));
    if (status != noErr) {
        NSLog(@"set render callback fail");
        return;
    }
    
    AURenderCallbackStruct renderCallback;
    renderCallback.inputProc = MyAURenderCallBack;
    renderCallback.inputProcRefCon = NULL;
    status = AudioUnitSetProperty(IOAudioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &renderCallback, sizeof(renderCallback));
    if (status != noErr) {
        NSLog(@"set callback fail");
        return;
    }
    
    status = AudioUnitInitialize(IOAudioUnit);
    if (status != noErr) {
        NSLog(@"set unit initialize fail");
        return;
    }
}

@end
