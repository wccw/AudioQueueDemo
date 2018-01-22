//
//  YGAudioFileStream.h
//  AudioQueueDemo
//
//  Created by wangyaoguo on 2018/1/19.
//  Copyright © 2018年 lianluo.com. All rights reserved.
//

#import <Foundation/Foundation.h>
@class YGAudioFileStream;
@protocol audioFileStreamDelegate <NSObject>

-(void)audioFileStream:(YGAudioFileStream *)audioFileStream audioData:(NSData *)audioData;
-(void)audioFileStream:(YGAudioFileStream *)audioFileStream readyToProducePackets:(BOOL)ready;

@end

@interface YGAudioFileStream : NSObject

-(instancetype)initWithDelegate:(id<audioFileStreamDelegate>) delegate;

-(BOOL)parseData:(NSData *)data;

@end
