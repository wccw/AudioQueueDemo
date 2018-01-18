//
//  AudioFilePlayer.h
//  AudioQueueDemo
//
//  Created by wangyaoguo on 2018/1/18.
//  Copyright © 2018年 lianluo.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

//系统支持的音频文件格式
/*
CF_ENUM(AudioFileTypeID) {
    kAudioFileAIFFType                = 'AIFF',
    kAudioFileAIFCType                = 'AIFC',
    kAudioFileWAVEType                = 'WAVE',
    kAudioFileRF64Type                = 'RF64',
    kAudioFileSoundDesigner2Type      = 'Sd2f',
    kAudioFileNextType                = 'NeXT',
    kAudioFileMP3Type                 = 'MPG3',    // mpeg layer 3
    kAudioFileMP2Type                 = 'MPG2',    // mpeg layer 2
    kAudioFileMP1Type                 = 'MPG1',    // mpeg layer 1
    kAudioFileAC3Type                 = 'ac-3',
    kAudioFileAAC_ADTSType            = 'adts',
    kAudioFileMPEG4Type               = 'mp4f',
    kAudioFileM4AType                 = 'm4af',
    kAudioFileM4BType                 = 'm4bf',
    kAudioFileCAFType                 = 'caff',
    kAudioFile3GPType                 = '3gpp',
    kAudioFile3GP2Type                = '3gp2',
    kAudioFileAMRType                 = 'amrf',
    kAudioFileFLACType                = 'flac'
    };
 */

@interface AudioFilePlayer : NSObject

-(instancetype)initWithPath:(NSString *)filePath;
-(void)startPlay;
-(void)stopPlay;

@end
