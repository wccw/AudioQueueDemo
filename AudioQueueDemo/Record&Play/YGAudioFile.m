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





/*
-(void)parseData:(BOOL *)isEof {
    UInt32 ioNumPackets = 15;
    UInt32 ioNumBytes = ioNumPackets * _maxPacketSize;
    void *outBuffer = (void *)malloc(ioNumBytes);
    
    AudioStreamPacketDescription *outPacketDescriptions = NULL;
    if (_format.mFormatID != kAudioFormatLinearPCM) {
        UInt32 descSize = sizeof(AudioStreamPacketDescription) *ioNumPackets;
        outPacketDescriptions = (AudioStreamPacketDescription *)malloc(descSize);
        status = AudioFileReadPacketData(_fileId, false, &ioNumBytes, outPacketDescriptions, _dataOffset, &ioNumPackets, outBuffer);
    } else {
        status = AudioFileReadPacketData(_fileId, false, &ioNumBytes, outPacketDescriptions, _dataOffset, &ioNumPackets, outBuffer);
    }
    if (status != noErr) {
        *isEof = status = kAudioFileEndOfFileError;
        free(outBuffer);
    }
    if (ioNumBytes == 0) {
        *isEof = YES;
    }
    _dataOffset += ioNumPackets;
    if (ioNumPackets > 0) {
        NSMutableArray *parsedDataArray = [[NSMutableArray alloc]init];
        for (int i = 0; i < ioNumPackets; ++i) {
            AudioStreamPacketDescription packetDescription;
            if (outPacketDescriptions) {
                packetDescription = outPacketDescriptions[i];
            } else {
                packetDescription.mStartOffset = i * _format.mBytesPerPacket;
                packetDescription.mDataByteSize = _format.mBytesPerPacket;
                packetDescription.mVariableFramesInPacket = _format.mFramesPerPacket;
            }
            
        }
    }
}
*/

























@end
