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
    
    YGAudioFileStream *stream;
    YGAudioOutputQueue *outQueue;
    FILE *file;
    UInt64 fileLength;
}
@end

@implementation ViewController

-(void)audioStreamPacketData:(NSData *)data withDescription:(AudioStreamPacketDescription)packetDes {
    [outQueue playWithPacket:data withDescription:packetDes];
}

-(void)audioStreamReadyProducePacket {
    outQueue = [[YGAudioOutputQueue alloc]initWithFormat:stream.format withBufferSize:stream.bufferSize withMagicCookie:stream.magicCookie];
}

//open file
-(void)openAudioFile {
    //mp3(true) ,m4a(true), flac(ture),wav(false)
    //caf(true) aac(ture)
    NSString *path = [[NSBundle mainBundle]pathForResource:@"MP3Sample" ofType:@"mp3"];
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
    stream = [[YGAudioFileStream alloc]initWithDelegate:self];
    
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
    
    int length = 50000;
    for (int i = 0; i < fileLength; i = i + length) {
        //NSLog(@"for i is %d",i);
        void *pcmDataBuffer = malloc(length);
        fread(pcmDataBuffer, 1, length, file);
        NSData *audioData = [NSData dataWithBytes:pcmDataBuffer length:length];
        free(pcmDataBuffer);
        [stream parseData:audioData];
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

