//
//  YGAudioUnit.m
//  AudioQueueDemo
//
//  Created by wangyaoguo on 2018/2/1.
//  Copyright © 2018年 lianluo.com. All rights reserved.
//

#import "YGAudioUnit.h"
#import <AudioToolbox/AudioToolbox.h>
@implementation YGAudioUnit

-(void)dd {
    UInt32 busCount = 2;
    OSStatus result = AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &busCount, sizeof(busCount));
    
    AudioComponentDescription ioUnitDescription;
    ioUnitDescription.componentType = kAudioUnitType_Output;
    ioUnitDescription.componentSubType = kAudioUnitSubType_RemoteIO;
    ioUnitDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    ioUnitDescription.componentFlags = 0;
    ioUnitDescription.componentFlagsMask = 0;
    
    AUGraph processingGraph;
    NewAUGraph(&processingGraph);
    
    AUNode ioNode;
    AUGraphAddNode(processingGraph, &ioUnitDescription, &ioNode);
    AUGraphOpen(processingGraph);
    
    AudioUnit ioUnit;
    AUGraphNodeInfo(processingGraph, ioNode, NULL, &ioUnit);
    
//    AudioComponent foundIoUnitReference = AudioComponentFindNext(NULL, &ioUnitDescription);
//    AudioUnit ioUnitInstance;
//    AudioComponentInstanceNew(foundIoUnitReference, &ioUnitInstance);
}

@end
