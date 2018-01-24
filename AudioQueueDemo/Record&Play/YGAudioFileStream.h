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

//delegate
@protocol audioFileStreamDelegate <NSObject>

-(void)audioStreamPacketData:(NSData *)data withDescription:(AudioStreamPacketDescription)packetDes;
-(void)audioStreamReadyProducePacket;

@end

@interface YGAudioFileStream : NSObject

@property (nonatomic, assign, readonly) AudioStreamBasicDescription format;
@property (nonatomic, assign, readonly) UInt32                      bufferSize;
@property (nonatomic, retain, readonly) NSData                      *magicCookie;

-(instancetype)initWithDelegate:(id<audioFileStreamDelegate>) delegate;

-(BOOL)parseData:(NSData *)data;

@end


