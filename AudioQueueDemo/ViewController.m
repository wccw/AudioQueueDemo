//
//  ViewController.m
//  AudioQueueDemo
//
//  Created by wangyaoguo on 2018/1/12.
//  Copyright © 2018年 lianluo.com. All rights reserved.
//

#import "ViewController.h"
#import "AQRecorderAndPlayer.h"
#import <AVFoundation/AVFoundation.h>

#import "AQPlayer.h"
#import "AQRecorder.h"
#import "YGAudioFile.h"
#import "PCMFilePlayer.h"
#import "AudioFilePlayer.h"
#import "YGAudioFileStream.h"
#import "YGAudioOutputQueue.h"


@interface ViewController ()<audioFileStreamDelegate>
{
    AQRecorder    *record;
    PCMFilePlayer *pcmPlay;
    AudioFilePlayer *filePlay;
    
    YGAudioFileStream *fileStream;
    YGAudioOutputQueue *outQueue;
    FILE *file;
    UInt64 fileLength;
}
@end

@implementation ViewController

-(void)audioStream:(YGAudioFileStream *)audioStream audioData:(NSData *)audioData withPacketDes:(AudioStreamPacketDescription)packetDes{
    [outQueue playWithData:audioData withPacketDes:packetDes];
}

-(void)audioStream:(YGAudioFileStream *)audioStream withFormat:(AudioStreamBasicDescription)format withSize:(UInt32)size withCookie:(NSData *)cookie {
    outQueue = [[YGAudioOutputQueue alloc]initWithFormat:format withBufferSize:size withMagicCookie:cookie];
}

//open file
-(void)openAudioFile {
    NSString *path = [[NSBundle mainBundle]pathForResource:@"M4ASample" ofType:@"m4a"];
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:path];
    fileLength = [[handle availableData]length];
    file = fopen([path UTF8String], "r");
    if (!file) {
         NSLog(@"open file fail");
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self openAudioFile];
    
    fileStream = [[YGAudioFileStream alloc]initWithDelegate:self];
    
    /*
    NSString *aacPath = [[NSBundle mainBundle]pathForResource:@"AACSample" ofType:@"aac"];
    filePlay = [[AudioFilePlayer alloc]initWithPath:aacPath];
    
    //NSString *pcmPath = [[NSBundle mainBundle]pathForResource:@"record" ofType:@"pcm"];
    NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *pcmPath = [docPath stringByAppendingPathComponent:@"recording.pcm"];
    pcmPlay = [[PCMFilePlayer alloc]initWithPcmFilePath:pcmPath];
     */
}

- (IBAction)recorderplayerStart:(id)sender {
    /*
    int length = 300000;
    void *pcmDataBuffer = malloc(length);
    fread(pcmDataBuffer, 1, length, file);
    NSData *audioData = [NSData dataWithBytes:pcmDataBuffer length:length];
    free(pcmDataBuffer);
    [fileStream parseData:audioData];
     */
    
    int length = 3000;
    for (int i = 0; i < fileLength; i = i + length) {
        NSLog(@"for i is %d",i);
        void *pcmDataBuffer = malloc(length);
        fread(pcmDataBuffer, 1, length, file);
        NSData *audioData = [NSData dataWithBytes:pcmDataBuffer length:length];
        free(pcmDataBuffer);
        [fileStream parseData:audioData];
    }
}

- (IBAction)recorderplayerStop:(id)sender {
}

- (IBAction)recorderStart:(id)sender {
    [record startRecorder];
}

- (IBAction)recorderStop:(id)sender {
    [record stopRecorder];
}

- (IBAction)playerStart:(id)sender {
    //[filePlay startPlay];
    //[pcmPlay startPlay];
}

- (IBAction)playerStop:(id)sender {
    //[filePlay stopPlay];
    //[pcmPlay stopPlay];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

