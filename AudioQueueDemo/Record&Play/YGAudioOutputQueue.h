//
//  YGAudioOutputQueue.h
//  AudioQueueDemo
//
//  Created by wangyaoguo on 2018/1/22.
//  Copyright © 2018年 lianluo.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "YGAudioFileStream.h"

@interface YGAudioOutputQueue : NSObject

//required
-(instancetype)initWithFormat:(AudioStreamBasicDescription)format
               withBufferSize:(UInt32)size
              withMagicCookie:(NSData *)cookie;

-(void)playWithPackets:(NSData *)data withDescriptions:(AudioStreamPacketDescription*)descriptions;
-(void)playWithPacket:(NSData *)data withDescription:(AudioStreamPacketDescription)description;
-(void)playWithBuffer:(AudioQueueBufferRef)buffer withDesc:(const AudioStreamPacketDescription *)desc;

@end

 
