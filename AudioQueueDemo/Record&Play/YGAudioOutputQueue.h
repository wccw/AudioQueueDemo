//
//  YGAudioOutputQueue.h
//  AudioQueueDemo
//
//  Created by wangyaoguo on 2018/1/22.
//  Copyright © 2018年 lianluo.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface YGAudioOutputQueue : NSObject

//required
-(instancetype)initWithFormat:(AudioStreamBasicDescription)format
               withBufferSize:(UInt32)size
              withMagicCookie:(NSData *)cookie;

-(void)playWithData:(NSData *)data withPackDescription:(AudioStreamPacketDescription)packetDestription;

@end
