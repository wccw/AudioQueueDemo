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
@implementation YGAudioUnit

static OSStatus MyAURenderCallBack(void                       *inRefCon,
                                   AudioUnitRenderActionFlags *ioActionFlags,
                                   const AudioTimeStamp       *inTimeStamp,
                                   UInt32                     inBusNumber,
                                   UInt32                     inNumberFrames,
                                   AudioBufferList            *ioData);

-(void)dd {
    AudioComponentDescription ioUnitDescription;
    ioUnitDescription.componentType = kAudioUnitType_Output;
    ioUnitDescription.componentSubType = kAudioUnitSubType_RemoteIO;
    ioUnitDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    ioUnitDescription.componentFlags = 0;
    ioUnitDescription.componentFlagsMask = 0;
    
    AudioComponentDescription mixerUnitDescription;
    
    AUGraph processingGraph;
    NewAUGraph(&processingGraph);
    
    AUNode ioNode;
    AUNode mixerNode;
    
    AUGraphAddNode(processingGraph, &ioUnitDescription, &ioNode);
    AUGraphAddNode(processingGraph, &mixerUnitDescription, &mixerNode);
    
    AUGraphOpen(processingGraph);
    
    //AUGraphNodeInfo(processingGraph, ioNode, NULL, &ioUnit);
    //AUGraphNodeInfo(processingGraph, mixerNode, NULL, &mixerUnit);
    
    AudioUnit ioUnit;
    AudioUnit mixerUnit;
    
    AudioUnitElement mixerUnitOutputBus = 0;
    AudioUnitElement ioUnitOutputElement = 0;
    AudioUnitConnection mixerOutToIoUnitIn;
    
    mixerOutToIoUnitIn.sourceAudioUnit = mixerUnit;
    mixerOutToIoUnitIn.sourceOutputNumber = mixerUnitOutputBus;
    mixerOutToIoUnitIn.destInputNumber = ioUnitOutputElement;
    
    AudioUnitSetProperty(ioUnit, kAudioUnitProperty_MakeConnection, kAudioUnitScope_Input, ioUnitOutputElement, &mixerOutToIoUnitIn, sizeof(mixerOutToIoUnitIn));
    
    OSStatus result = AUGraphInitialize(processingGraph);
    AUGraphStart(processingGraph);
    AUGraphStop(processingGraph);
    
}

@end
