//
//  YGAudioFileStream.h
//  AudioQueueDemo
//
//  Created by wangyaoguo on 2018/1/19.
//  Copyright © 2018年 lianluo.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@class YGAudioFileStream;

@protocol audioFileStreamDelegate <NSObject>

-(void)audioStream:(YGAudioFileStream *)audioStream audioData:(NSData *)audioData withPacketDes:(AudioStreamPacketDescription)packetDes;
-(void)audioStream:(YGAudioFileStream *)audioStream withFormat:(AudioStreamBasicDescription)format withSize:(UInt32)size withCookie:(NSData *)cookie ;

@end

@interface YGAudioFileStream : NSObject

-(instancetype)initWithDelegate:(id<audioFileStreamDelegate>) delegate;

-(BOOL)parseData:(NSData *)data;

@end
