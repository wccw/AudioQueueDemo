//
//  YGAudioFile.m
//  AudioQueueDemo
//
//  Created by wangyaoguo on 2018/1/17.
//  Copyright © 2018年 lianluo.com. All rights reserved.
//

#import "YGAudioFile.h"
@interface YGAudioFile() {
    OSStatus status;
}
@end

@implementation YGAudioFile

-(instancetype)initWithFilePath:(NSString *)filePath withFileID:(AudioFileTypeID)fileType {
    if (self = [super init]) {
        [self fileAttributes:filePath withFileID:fileType];
    }
    return self;
}

-(void)fileAttributes:(NSString *)filePath withFileID:(AudioFileTypeID)fileType {
    _fileType = fileType;
    if(![self openAudioFile])
        return;
    
    //foramt
    UInt32 size = sizeof(_format);
    status = AudioFileGetProperty(_fileId, kAudioFilePropertyFileFormat, &size, &_format);
    if (status != noErr) {
        return;
    }
    
    //bitRate
    size = sizeof(_bitRate);
    status = AudioFileGetProperty(_fileId, kAudioFilePropertyBitRate, &size, &_bitRate);
    if (status != noErr) {
        return;
    }
    
    //dataOffset
    size = sizeof(_dataOffset);
    status = AudioFileGetProperty(_fileId, kAudioFilePropertyDataOffset, &size, &_dataOffset);
    if (status != noErr) {
        return;
    }
    
    //maxPacketsize
    size = sizeof(_maxPacketSize);
    status = AudioFileGetProperty(_fileId, kAudioFilePropertyPacketSizeUpperBound, &size, &_maxPacketSize);
    if (status != noErr || _maxPacketSize == 0) {
        status = AudioFileGetProperty(_fileId, kAudioFilePropertyMaximumPacketSize, &size, &_maxPacketSize);
        if (status != noErr) {
            return;
        }
    }
    
    //duration
    size = sizeof(_duration);
    status = AudioFileGetProperty(_fileId, kAudioFilePropertyEstimatedDuration, &size, &_duration);
    if (status != noErr) {
        if (_fileSize > 0 && _bitRate > 0) {
            _duration = (_fileSize - _dataOffset) * 8 / _bitRate;
        }
    }
}


-(BOOL)openAudioFile {
    NSString *filePath = [[NSBundle mainBundle]pathForResource:@"MP3Sample" ofType:@"mp3"];
    CFURLRef fileUrl = CFURLCreateWithString(kCFAllocatorDefault, (CFStringRef)filePath, NULL);
    if (!fileUrl) {
        return false;
    }
    status = AudioFileOpenURL(fileUrl, kAudioFileReadPermission, 0, &_fileId);
    if (status != noErr) {
        return false;
    }
    return true;
}

@end
