//
//  YGAudioFile.h
//  AudioQueueDemo
//
//  Created by wangyaoguo on 2018/1/17.
//  Copyright © 2018年 lianluo.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface YGAudioFile : NSObject

//file base inforamtion
@property (nonatomic, assign, readonly) UInt64 fileSize;
@property (nonatomic, assign, readonly) AudioFileID fileId;
@property (nonatomic, assign, readonly) AudioFileTypeID fileType;
@property (nonatomic, assign, readonly) AudioStreamBasicDescription format;
@property (nonatomic, assign, readonly) NSTimeInterval duration;
@property (nonatomic, assign, readonly) UInt32 bitRate;
@property (nonatomic, assign, readonly) UInt32 maxPacketSize;
@property (nonatomic, assign, readonly) SInt64 dataOffset;
@property (nonatomic, assign, readonly) UInt64 audioDataByteCount;

-(instancetype)initWithFilePath:(NSString *)filePath withFileID:(AudioFileTypeID)fileType;

@end
