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

struct CallbackData {
   AudioUnit unit;
} cd;

@interface YGAudioUnit() {
    AudioUnit ioUnit;
}

@end

@implementation YGAudioUnit

-(instancetype)init {
    self = [super init];
    if (self) {
        NSLog(@"start audio unit");
        [self setupAudioSession];
        [self setupIOUnit];
    }
    return self;
}

-(void)start {
    OSStatus status = AudioOutputUnitStart(ioUnit);
    if (status != noErr) {
        NSLog(@"audio output unit start fail");
    }
}

-(void)stop {
    OSStatus stop = AudioOutputUnitStop(ioUnit);
    if (stop != noErr) {
        NSLog(@"audio output unit stop fail");
    }
}

-(void)setupAudioSession {
    NSLog(@"start audio session");
    AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
    
    NSError *error = nil;
    [sessionInstance setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    if (error) {
        NSLog(@"set session category fail");
        return;
    }
    
    NSTimeInterval bufferDuration = .005;
    [sessionInstance setPreferredIOBufferDuration:bufferDuration error:&error];
    if (error) {
        NSLog(@"set session buffer duration fail");
        return;
    }
    
    [sessionInstance setPreferredSampleRate:44100 error:&error];
    if (error) {
        NSLog(@"set setssion sample rate fail");
        return;
    }
    [sessionInstance setActive:YES error:nil];
}


-(void)setupIOUnit {
    NSLog(@"start io unit");
    
    //create a new instance of Remote IO
    AudioComponentDescription unitDescritpion;
    unitDescritpion.componentType = kAudioUnitType_Output;
    unitDescritpion.componentSubType = kAudioUnitSubType_RemoteIO;
    unitDescritpion.componentManufacturer = kAudioUnitManufacturer_Apple;
    unitDescritpion.componentFlags = 0;
    unitDescritpion.componentFlagsMask = 0;
    
    AudioComponent component = AudioComponentFindNext(NULL, &unitDescritpion);
    OSStatus status = AudioComponentInstanceNew(component, &ioUnit);
    if (status != noErr) {
        NSLog(@"set AudioComponentInstanceNew fail");
        return;
    }

    //enable IO
    UInt32 one = 1;
    status = AudioUnitSetProperty(ioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &one, sizeof(one));
    if (status != noErr) {
        NSLog(@"set audio unit property enable io fail");
        return;
    }
    
    status = AudioUnitSetProperty(ioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, 0, &one, sizeof(one));
    if (status != noErr) {
        NSLog(@"set audio unit property enable io fail");
        return;
    }
    
    //audio format
    
    AudioStreamBasicDescription desc = {0};
    desc.mSampleRate = 44100;
    desc.mFormatID = kAudioFormatLinearPCM;
    desc.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    desc.mFramesPerPacket = 1;
    desc.mChannelsPerFrame = 1;
    desc.mBytesPerFrame = desc.mBytesPerPacket = 16;
    desc.mReserved = 0;
    
    /*
    status = AudioUnitSetProperty(ioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &desc, sizeof(desc));
    if (status != noErr) {
        NSLog(@"set audio unit property format fail");
        return;
    }
    
    status = AudioUnitSetProperty(ioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &desc, sizeof(desc));
    if (status != noErr) {
        NSLog(@"set audio unit property format fail");
        return;
    }
     */
    
    UInt32 maxFramesPerSlice = 4096;
    status = AudioUnitSetProperty(ioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFramesPerSlice, sizeof(UInt32));
    if (status != noErr) {
        NSLog(@"set max num frames per slice fail");
        return;
    }
    
    UInt32 propSize = sizeof(UInt32);
    AudioUnitGetProperty(ioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFramesPerSlice, &propSize);
    
    cd.unit = ioUnit;
    
    AURenderCallbackStruct renderCallbackStruct;
    renderCallbackStruct.inputProcRefCon = playCallback;
    renderCallbackStruct.inputProcRefCon = NULL;
    status = AudioUnitSetProperty(ioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &renderCallbackStruct, sizeof(renderCallbackStruct));
    if (status != noErr) {
        NSLog(@"set render play callback fail");
        return;
    }
    
    status = AudioUnitInitialize(ioUnit);
    if (status != noErr) {
        NSLog(@"set unit initialize fail %d",status);
        return;
    }
    NSLog(@"audio unit finished");
}

static OSStatus playCallback(void                       *inRefCon,
                             AudioUnitRenderActionFlags *ioActionFlags,
                             const AudioTimeStamp       *inTimeStamp,
                             UInt32                     inBusNumber,
                             UInt32                     inNumberFrames,
                             AudioBufferList            *ioData) {
    
    AudioUnitRender(cd.unit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData);
    return 0;
}

@end
